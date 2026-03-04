//
//  EncounterWizardView.swift
//  VisionWow
//
//  Created by Rodrigo Marcos on 27/12/25.
//

import SwiftUI
import SwiftData

struct EncounterWizardView: View {
    @Bindable var encounter: Encounter
    @Bindable var company: Company

    let onCancel: () -> Void
    let onFinish: (Encounter) -> Void

    var startAt: Step = .clinicalHistory

    @State private var stepIndex: Int = 0
    @State private var errors: [String: String] = [:]

    // ✅ Intermedia (handoff)
    @State private var goHandoff = false

    // ✅ Evita resetear stepIndex al volver de navegación
    @State private var didInit = false

    enum Step: Int, CaseIterable {
        case clinicalHistory
        case personalData
        case antecedents
        case exam
        case payment
    }

    private var currentStep: Step {
        Step.allCases[min(stepIndex, Step.allCases.count - 1)]
    }

    private var isLastStep: Bool {
        stepIndex == Step.allCases.count - 1
    }

    private var isOpticaFlow: Bool {
        startAt == .personalData
    }

    private var startIndex: Int {
        let idx = startAt.rawValue
        return max(0, min(idx, Step.allCases.count - 1))
    }

    private var hasOptometristAssigned: Bool {
        !(encounter.optometristName ?? "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .isEmpty
    }

    var body: some View {
        VStack(spacing: 14) {

            Group {
                switch currentStep {
                case .clinicalHistory:
                    ClinicalHistoryView(encounter: encounter, errors: errors)

                case .personalData:
                    PersonalDataView(encounter: encounter, errors: errors)

                case .antecedents:
                    AntecedentsStep2Screen(encounter: encounter)
                        .onAppear {
                            // ✅ Candado duro: si llegan aquí sin optometrista, no debe pasar
                            if !hasOptometristAssigned {
                                // Regresa a datos personales y abre handoff
                                stepIndex = Step.personalData.rawValue
                                goHandoff = true
                            }
                        }

                case .exam:
                    ExamStep3Screen(encounter: encounter, errors: errors)

                case .payment:
                    PaymentStep4Screen(encounter: encounter, errors: errors)
                }
            }
            .padding(.top, 6)

            Spacer()

            HStack(spacing: 12) {
                SecondaryButton(title: stepIndex == startIndex ? "Cancelar" : "Atrás") {
                    back()
                }

                PrimaryButton(title: isLastStep ? "Finalizar" : "Continuar") {
                    next()
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 12)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .onAppear {
            guard !didInit else { return }
            didInit = true

            stepIndex = startIndex

            if isOpticaFlow {
                prefillClinicalHistoryForOpticaIfNeeded()
            }
        }
        .background(
            NavigationLink(
                destination: OptometristHandoffScreen(encounter: encounter) {
                    // ✅ SOLO si confirma (y guardó nombre) avanzamos a antecedentes
                    stepIndex = Step.antecedents.rawValue
                    goHandoff = false
                },
                isActive: $goHandoff
            ) { EmptyView() }
            .hidden()
        )
    }

    // MARK: - Back

    private func back() {
        if stepIndex == startIndex {
            onCancel()
        } else {
            stepIndex -= 1
            errors = [:]
        }
    }

    // MARK: - Next

    private func next() {
        errors = validate(step: currentStep)
        guard errors.isEmpty else { return }

        if isLastStep {
            onFinish(encounter)
            return
        }

        // ✅ Interceptar PersonalData -> (handoff) -> Antecedents
        if currentStep == .personalData {
            // NO movemos stepIndex aquí.
            // Solo abrimos la intermedia. El avance real ocurre al confirmar nombre.
            goHandoff = true
            return
        }

        stepIndex += 1
    }

    // MARK: - Prefill Step 1 para Óptica

    private func prefillClinicalHistoryForOpticaIfNeeded() {
        if encounter.companyName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            encounter.companyName = company.name
        }

        if encounter.branch.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            encounter.branch = "Óptica"
        }
        if encounter.department.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            encounter.department = "Particular"
        }
        if encounter.directBoss.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            encounter.directBoss = "N/A"
        }
        if encounter.shift.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            encounter.shift = "N/A"
        }

        let email = encounter.companyEmail.trimmingCharacters(in: .whitespacesAndNewlines)
        if email.isEmpty || !email.contains("@") {
            encounter.companyEmail = "optica@visionwow.mx"
        }

        if encounter.seniorityYears == nil && encounter.seniorityMonths == nil && encounter.seniorityWeeks == nil {
            encounter.seniorityYears = 0
        }
    }

    // MARK: - Validación por step

    private func validate(step: Step) -> [String: String] {
        var e: [String: String] = [:]

        switch step {
        case .clinicalHistory:
            let years = encounter.seniorityYears
            let months = encounter.seniorityMonths
            let weeks = encounter.seniorityWeeks
            if years == nil && months == nil && weeks == nil {
                e["seniorityYears"] = "Captura antigüedad en años, meses o semanas."
            }

            if encounter.companyName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                e["companyName"] = "Campo obligatorio."
            }
            if encounter.branch.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                e["branch"] = "Campo obligatorio."
            }
            if encounter.department.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                e["department"] = "Campo obligatorio."
            }
            if encounter.directBoss.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                e["directBoss"] = "Campo obligatorio."
            }
            if encounter.shift.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                e["shift"] = "Selecciona un turno."
            }

            let email = encounter.companyEmail.trimmingCharacters(in: .whitespacesAndNewlines)
            if email.isEmpty {
                e["companyEmail"] = "Campo obligatorio."
            } else if !email.contains("@") {
                e["companyEmail"] = "Correo no válido."
            }

        case .personalData:
            guard let p = encounter.patient else {
                e["patient"] = "Selecciona o crea un paciente."
                break
            }

            if p.firstName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                e["firstName"] = "Campo obligatorio."
            }
            if p.lastName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                e["lastName"] = "Campo obligatorio."
            }
            if p.dob == nil {
                e["dob"] = "Selecciona una fecha."
            }

            let sexTrim = p.sex.trimmingCharacters(in: .whitespacesAndNewlines)
            if sexTrim.isEmpty || p.sex == SexOption.noEspecificado.rawValue {
                e["sex"] = "Selecciona una opción."
            }

            if p.cellPhone.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                e["cellPhone"] = "Campo obligatorio."
            }

            let email = p.personalEmail.trimmingCharacters(in: .whitespacesAndNewlines)
            if email.isEmpty {
                e["personalEmail"] = "Campo obligatorio."
            } else if !email.contains("@") {
                e["personalEmail"] = "Correo no válido."
            }

        case .antecedents:
            // ✅ Puedes dejarlo vacío o meter validación específica
            break

        case .exam:
            func isEmpty(_ s: String) -> Bool { s.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }

            // Agudeza visual lejana (según tus nuevos campos)
            if isEmpty(encounter.vaOdSc) { e["vaOdSc"] = "Campo obligatorio." }
            if isEmpty(encounter.vaOsSc) { e["vaOsSc"] = "Campo obligatorio." }
            if isEmpty(encounter.vaOuSc) { e["vaOuSc"] = "Campo obligatorio." }

            if isEmpty(encounter.vaOdCc) { e["vaOdCc"] = "Campo obligatorio." }
            if isEmpty(encounter.vaOsCc) { e["vaOsCc"] = "Campo obligatorio." }
            if isEmpty(encounter.vaOuCc) { e["vaOuCc"] = "Campo obligatorio." }

            // Agudeza visual cercana
            if isEmpty(encounter.nearVaOdSc) { e["nearVaOdSc"] = "Campo obligatorio." }
            if isEmpty(encounter.nearVaOsSc) { e["nearVaOsSc"] = "Campo obligatorio." }
            if isEmpty(encounter.nearVaOuSc) { e["nearVaOuSc"] = "Campo obligatorio." }

            if isEmpty(encounter.nearVaOdCc) { e["nearVaOdCc"] = "Campo obligatorio." }
            if isEmpty(encounter.nearVaOsCc) { e["nearVaOsCc"] = "Campo obligatorio." }
            if isEmpty(encounter.nearVaOuCc) { e["nearVaOuCc"] = "Campo obligatorio." }

            // Refracción (ADD NO obligatorio)
            if isEmpty(encounter.rxOdSph)  { e["rxOdSph"]  = "Campo obligatorio." }
            if isEmpty(encounter.rxOdCyl)  { e["rxOdCyl"]  = "Campo obligatorio." }
            if isEmpty(encounter.rxOdAxis) { e["rxOdAxis"] = "Campo obligatorio." }

            if isEmpty(encounter.rxOsSph)  { e["rxOsSph"]  = "Campo obligatorio." }
            if isEmpty(encounter.rxOsCyl)  { e["rxOsCyl"]  = "Campo obligatorio." }
            if isEmpty(encounter.rxOsAxis) { e["rxOsAxis"] = "Campo obligatorio." }

            if isEmpty(encounter.dip) { e["dip"] = "Campo obligatorio." }

            if isEmpty(encounter.lensType) { e["lensType"] = "Campo obligatorio." }
            if isEmpty(encounter.usage)    { e["usage"]    = "Campo obligatorio." }

            if encounter.followUpDate == nil {
                e["followUpDate"] = "Selecciona una fecha."
            }

        case .payment:
            if encounter.payStatus.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                e["payStatus"] = "Selecciona un estatus."
            }
            if encounter.payTotal.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                e["payTotal"] = "Campo obligatorio."
            }
            if encounter.payMethod.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                e["payMethod"] = "Selecciona un método."
            }
            if encounter.payReference.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                e["payReference"] = "Campo obligatorio."
            }
        }

        return e
    }
}
