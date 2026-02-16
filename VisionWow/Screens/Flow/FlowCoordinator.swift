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
            AntecedentsStep2Screen(encounter: encounter)
        case 3:
            ExamStep3Screen(encounter: encounter, errors: errors)
        case 4:
            PaymentStep4Screen(encounter: encounter, errors: errors)
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
        // Valida todo lo esencial antes de PDF
        let map = validate(step: 1)
            .merging(validate(step: 3), uniquingKeysWith: { $1 })
            .merging(validate(step: 4), uniquingKeysWith: { $1 })

        errors = map
        if !map.isEmpty {
            step = 1
            return
        }

        persist()

        do {
            let output = try PDFService.generate(encounter: encounter)
            lastGeneratedPDFURL = output.url
            showPDFPreview = true

            // Share Sheet (WhatsApp)
            ShareService.share(items: [output.url])
        } catch {
            errors = ["pdf": error.localizedDescription]
        }
    }
}

