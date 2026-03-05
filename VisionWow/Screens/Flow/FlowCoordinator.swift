//
//  FlowCoordinator.swift
//  VisionWow
//
//  Created by Rodrigo Marcos on 27/12/25.
//
import SwiftUI
import SwiftData

struct FlowCoordinator: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var encounter: Encounter

    @State private var step: Int = 1
    @State private var errors: [String: String] = [:]

    @State private var lastGeneratedPDFURL: URL? = nil
    @State private var showPDFPreview: Bool = false

    private let totalSteps = 4

    var body: some View {
        ZStack {
            BrandColors.backgroundGradient.ignoresSafeArea()

            VStack(spacing: 16) {
                StepHeader(
                    title: "Registro • Antecedentes • Evaluación • Pago",
                    subtitle: "Flujo de \(totalSteps) pasos con validación.",
                    step: step,
                    total: totalSteps,
                    showError: !errors.isEmpty
                )

                content

                HStack(spacing: 12) {
                    if step > 1 {
                        SecondaryButton(title: "Volver") {
                            persist()
                            step -= 1
                        }
                    }

                    Spacer()

                    if step < totalSteps {
                        PrimaryButton(title: "Continuar") {
                            goNext()
                        }
                        .frame(maxWidth: 260)
                    } else {
                        SecondaryButton(title: "Generar / Compartir PDF") {
                            generatePDF()
                        }
                        .frame(maxWidth: 260)

                        PrimaryButton(title: "Finalizar") {
                            finalize()
                        }
                        .frame(maxWidth: 220)
                    }
                }
            }
            .padding(16)
        }
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showPDFPreview) {
            if let url = lastGeneratedPDFURL {
                PDFPreviewScreen(fileURL: url)
            } else {
                Text("No hay PDF.")
            }
        }
    }

    @ViewBuilder
    private var content: some View {
        switch step {
        case 1:
            IntakeStep1Screen(encounter: encounter, errors: errors)
        case 2:
            AntecedentsStep2Screen(encounter: encounter, stepNumber: 2, totalSteps: 4)
        case 3:
            ExamStep3Screen(encounter: encounter, errors: errors, stepNumber: 3, totalSteps: 4)
        case 4:
            PaymentStep4Screen(encounter: encounter, errors: errors, stepNumber: 4, totalSteps: 4)
        default:
            IntakeStep1Screen(encounter: encounter, errors: errors)
        }
    }

    private func persist() {
        encounter.updatedAt = Date()
        try? modelContext.save()
    }

    private func goNext() {
        let map = validate(step: step)
        errors = map
        if !map.isEmpty { return }
        persist()
        step += 1
    }

    private func finalize() {
        let map = validate(step: 4)
        errors = map
        if !map.isEmpty { return }
        persist()
        generatePDF()
    }

    private func validate(step: Int) -> [String: String] {
        let errs: [FormValidationError]
        if step == 1 {
            errs = EncounterValidator.validateStep1(encounter)
        } else if step == 3 {
            errs = EncounterValidator.validateStep3(encounter)
        } else if step == 4 {
            errs = EncounterValidator.validateStep4(encounter)
        } else {
            errs = []
        }

        var map: [String: String] = [:]
        for e in errs { map[e.fieldKey] = e.message }
        return map
    }

    private func generatePDF() {
        let step1Errs = validate(step: 1)
        let step3Errs = validate(step: 3)
        let step4Errs = validate(step: 4)

        let allErrs = step1Errs
            .merging(step3Errs, uniquingKeysWith: { $1 })
            .merging(step4Errs, uniquingKeysWith: { $1 })

        errors = allErrs

        if !allErrs.isEmpty {
            // Navega al primer paso que tiene errores
            if !step1Errs.isEmpty { step = 1 }
            else if !step3Errs.isEmpty { step = 3 }
            else { step = 4 }
            return
        }

        persist()

        do {
            let output = try PDFService.generate(encounter: encounter)
            lastGeneratedPDFURL = output.url
            showPDFPreview = true
        } catch {
            errors = ["pdf": error.localizedDescription]
        }
    }
}

