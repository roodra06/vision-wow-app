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

    // ✅ Permitir iniciar en Step 1 (empresa) o Step 2 (óptica)
    var startAt: Step = .clinicalHistory

    @State private var stepIndex: Int = 0
    @State private var errors: [String: String] = [:]

    enum Step: Int, CaseIterable {
        case clinicalHistory
        case personalData
        case antecedents
        case exam
        case payment

        var title: String {
            switch self {
            case .clinicalHistory: return "Historia clínica"
            case .personalData:    return "Datos personales"
            case .antecedents:     return "Antecedentes"
            case .exam:            return "Examen"
            case .payment:         return "Pago"
            }
        }
    }

    private var currentStep: Step {
        Step.allCases[min(stepIndex, Step.allCases.count - 1)]
    }

    private var isLastStep: Bool {
        stepIndex == Step.allCases.count - 1
    }

    private var isOpticaFlow: Bool {
        // ✅ Si arrancas en personalData, asumimos “paciente externo”
        startAt == .personalData
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
                    if stepIndex == startIndex {
                        onCancel()
                    } else {
                        stepIndex -= 1
                        errors = [:]
                    }
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
            stepIndex = startIndex

            // ✅ Si es óptica, prefill del step 1 para pasar validación
            if isOpticaFlow {
                prefillClinicalHistoryForOpticaIfNeeded()
            }
        }
    }

    // ✅ índice inicial según Step
    private var startIndex: Int {
        let idx = startAt.rawValue
        return max(0, min(idx, Step.allCases.count - 1))
    }

    // MARK: - Prefill Step 1 para Óptica

    private func prefillClinicalHistoryForOpticaIfNeeded() {
        // companyName
        if encounter.companyName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            encounter.companyName = company.name
        }

        // Campos obligatorios
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

        // Correo válido (tu validación exige que tenga "@")
        let email = encounter.companyEmail.trimmingCharacters(in: .whitespacesAndNewlines)
        if email.isEmpty || !email.contains("@") {
            encounter.companyEmail = "optica@visionwow.mx"
        }

        // Antigüedad: basta con llenar uno
        if encounter.seniorityYears == nil && encounter.seniorityMonths == nil && encounter.seniorityWeeks == nil {
            encounter.seniorityYears = 0
        }
    }

    // MARK: - Navegación

    private func next() {
        errors = validate(step: currentStep)
        guard errors.isEmpty else { return }

        if isLastStep {
            onFinish(encounter)
        } else {
            stepIndex += 1
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
            break

        case .exam:
            func isEmpty(_ value: String) -> Bool {
                value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            }

            if isEmpty(encounter.vaOdSc) { e["vaOdSc"] = "Campo obligatorio." }
            if isEmpty(encounter.vaOsSc) { e["vaOsSc"] = "Campo obligatorio." }
            if isEmpty(encounter.vaOdCc) { e["vaOdCc"] = "Campo obligatorio." }
            if isEmpty(encounter.vaOsCc) { e["vaOsCc"] = "Campo obligatorio." }

            if isEmpty(encounter.rxOdSph)  { e["rxOdSph"]  = "Campo obligatorio." }
            if isEmpty(encounter.rxOdCyl)  { e["rxOdCyl"]  = "Campo obligatorio." }
            if isEmpty(encounter.rxOdAxis) { e["rxOdAxis"] = "Campo obligatorio." }
            if isEmpty(encounter.rxOdAdd)  { e["rxOdAdd"]  = "Campo obligatorio." }

            if isEmpty(encounter.rxOsSph)  { e["rxOsSph"]  = "Campo obligatorio." }
            if isEmpty(encounter.rxOsCyl)  { e["rxOsCyl"]  = "Campo obligatorio." }
            if isEmpty(encounter.rxOsAxis) { e["rxOsAxis"] = "Campo obligatorio." }
            if isEmpty(encounter.rxOsAdd)  { e["rxOsAdd"]  = "Campo obligatorio." }

            if isEmpty(encounter.dp) { e["dp"] = "Campo obligatorio." }

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
