import SwiftUI
import SwiftData

struct EncounterWizardView: View {
    @Binding var encounter: Encounter
    @Bindable var company: Company

    let onCancel: () -> Void
    let onFinish: (Encounter) -> Void

    // ✅ NUEVO: permitir iniciar en Step 1 (empresa) o Step 2 (óptica)
    var startAt: Step = .clinicalHistory

    @State private var stepIndex: Int = 0
    @State private var errors: [String: String] = [:]

    enum Step: Int, CaseIterable {
        case clinicalHistory
        case personalData
        case antecedents
        case exam
        case payment  // ✅ nuevo

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

            // ✅ HEADER REMOVIDO (BrandHeader ya no se usa)

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
            // ✅ Inicializa el índice según el flujo
            stepIndex = startIndex

            // ✅ Si es óptica, prefill del step 1 (clinicalHistory) para pasar validación
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
        // Tu validación de .clinicalHistory exige:
        // seniority (alguno), companyName, branch, department, directBoss, shift, companyEmail válido

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

        // Tipo de contratación (por si tus vistas lo usan)
        encounter.isPlanta = false
        encounter.isEventual = false
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

    // MARK: - Validación por step (sin cambios)

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
            if encounter.firstName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                e["firstName"] = "Campo obligatorio."
            }

            if encounter.lastName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                e["lastName"] = "Campo obligatorio."
            }

            if encounter.dob == nil {
                e["dob"] = "Selecciona una fecha."
            }

            if encounter.sex.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                e["sex"] = "Selecciona una opción."
            }

            if encounter.cellPhone.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                e["cellPhone"] = "Campo obligatorio."
            }

            let email = encounter.personalEmail.trimmingCharacters(in: .whitespacesAndNewlines)
            if email.isEmpty {
                e["personalEmail"] = "Campo obligatorio."
            } else if !email.contains("@") {
                e["personalEmail"] = "Correo no válido."
            }

        case .antecedents:
            break

        case .exam:
            func req(_ value: String) -> Bool {
                value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            }

            if req(encounter.vaOdSc) { e["vaOdSc"] = "Campo obligatorio." }
            if req(encounter.vaOsSc) { e["vaOsSc"] = "Campo obligatorio." }
            if req(encounter.vaOdCc) { e["vaOdCc"] = "Campo obligatorio." }
            if req(encounter.vaOsCc) { e["vaOsCc"] = "Campo obligatorio." }

            if req(encounter.rxOdSph)  { e["rxOdSph"]  = "Campo obligatorio." }
            if req(encounter.rxOdCyl)  { e["rxOdCyl"]  = "Campo obligatorio." }
            if req(encounter.rxOdAxis) { e["rxOdAxis"] = "Campo obligatorio." }
            if req(encounter.rxOdAdd)  { e["rxOdAdd"]  = "Campo obligatorio." }

            if req(encounter.rxOsSph)  { e["rxOsSph"]  = "Campo obligatorio." }
            if req(encounter.rxOsCyl)  { e["rxOsCyl"]  = "Campo obligatorio." }
            if req(encounter.rxOsAxis) { e["rxOsAxis"] = "Campo obligatorio." }
            if req(encounter.rxOsAdd)  { e["rxOsAdd"]  = "Campo obligatorio." }

            if req(encounter.dp) { e["dp"] = "Campo obligatorio." }

            if req(encounter.lensType) { e["lensType"] = "Campo obligatorio." }
            if req(encounter.usage)    { e["usage"]    = "Campo obligatorio." }

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
