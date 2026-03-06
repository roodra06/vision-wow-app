import SwiftUI
import UIKit

struct ExamStep3Screen: View {
    @Bindable var encounter: Encounter
    let errors: [String: String]

    @State private var showLensPicker = false

    var stepNumber: Int = 4
    var totalSteps: Int = 4

    private static let diagnosisSuggestions: [String] = [
        "Miopía",
        "Hipermetropía",
        "Astigmatismo",
        "Presbicia",
        "Miopía + Astigmatismo",
        "Hipermetropía + Astigmatismo",
        "Sin corrección necesaria",
        "Ambliopía"
    ]

    private var patientIdText: String {
        let raw = String(describing: encounter.id)
        return "ID: \(raw.prefix(8))"
    }

    private var fullNameText: String {
        let first = (encounter.patient?.firstName ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        let last  = (encounter.patient?.lastName ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        let combined = [first, last].filter { !$0.isEmpty }.joined(separator: " ")
        return combined.isEmpty ? "Sin nombre" : combined
    }

    private var profileUIImage: UIImage? {
        guard let data = encounter.patient?.profileImageData else { return nil }
        return UIImage(data: data)
    }

    private var todayFormatted: String {
        DateUtils.formatShort(encounter.followUpDate ?? Date())
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                headerCard
                examCard
                TestsView(encounter: encounter, errors: errors)
            }
            .padding(.horizontal, 16)
            .padding(.top, 14)
            .padding(.bottom, 28)
        }
        .onAppear {
            // Solo fijar la fecha si es un encounter nuevo (sin fecha previa)
            if encounter.followUpDate == nil {
                encounter.followUpDate = Date()
            }
        }
        .sheet(isPresented: $showLensPicker) {
            LensPickerSheet(lensType: $encounter.lensType, lensCost: $encounter.lensCost) { }
        }
    }

    // MARK: - Header

    private var headerCard: some View {
        VStack(spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                avatar

                VStack(alignment: .leading, spacing: 8) {
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 6) {
                            Image(systemName: "eye.fill")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(BrandColors.accent)

                            Text("Examen visual")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.secondary)
                        }

                        Text(fullNameText)
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundStyle(.primary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.85)
                    }

                    HStack(spacing: 8) {
                        Image(systemName: "building.2.fill")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(BrandColors.accent)

                        Text(encounter.companyName.isEmpty ? "Empresa" : encounter.companyName)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }

                    HStack(spacing: 8) {
                        Image(systemName: "number")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(BrandColors.accent)

                        Text(patientIdText)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }

                Spacer(minLength: 0)
            }

            VStack(spacing: 6) {
                HStack {
                    Text("Paso \(stepNumber) de \(totalSteps)")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                    Spacer()
                }

                ProgressPillBar(
                    progress: CGFloat(stepNumber) / CGFloat(totalSteps),
                    height: 10
                )
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.white.opacity(0.72))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(BrandColors.accent.opacity(0.16), lineWidth: 1)
                )
                .shadow(color: BrandColors.secondary.opacity(0.06), radius: 14, x: 0, y: 8)
        )
    }

    private var avatar: some View {
        ZStack {
            Circle()
                .fill(BrandColors.primary.opacity(0.12))
                .frame(width: 76, height: 76)

            Circle()
                .stroke(BrandColors.strokeGradient, lineWidth: 3)
                .frame(width: 76, height: 76)

            if let img = profileUIImage {
                Image(uiImage: img)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 70, height: 70)
                    .clipShape(Circle())
            } else {
                Image(systemName: "person.fill")
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundStyle(BrandColors.secondary.opacity(0.85))
            }
        }
    }

    // MARK: - Main Card

    private var examCard: some View {
        VStack(spacing: 16) {

            // =========================================================
            // 1) AGUDEZA VISUAL (LEJANA)
            // =========================================================
            sectionHeader(icon: "eye.fill", title: "Agudeza visual (lejana)")

            HStack(spacing: 12) {
                FieldRow("OD S/C", required: true, error: errors["vaOdSc"]) {
                    iconTextField(systemName: "eye", text: $encounter.vaOdSc, isError: errors["vaOdSc"] != nil)
                }
                FieldRow("OI S/C", required: true, error: errors["vaOsSc"]) {
                    iconTextField(systemName: "eye", text: $encounter.vaOsSc, isError: errors["vaOsSc"] != nil)
                }
                FieldRow("AO S/C", required: true, error: errors["vaOuSc"]) {
                    iconTextField(systemName: "eye", text: $encounter.vaOuSc, isError: errors["vaOuSc"] != nil)
                }
            }

            HStack(spacing: 12) {
                FieldRow("OD C/C", required: true, error: errors["vaOdCc"]) {
                    iconTextField(systemName: "eyeglasses", text: $encounter.vaOdCc, isError: errors["vaOdCc"] != nil)
                }
                FieldRow("OI C/C", required: true, error: errors["vaOsCc"]) {
                    iconTextField(systemName: "eyeglasses", text: $encounter.vaOsCc, isError: errors["vaOsCc"] != nil)
                }
                FieldRow("AO C/C", required: true, error: errors["vaOuCc"]) {
                    iconTextField(systemName: "eyeglasses", text: $encounter.vaOuCc, isError: errors["vaOuCc"] != nil)
                }
            }

            Divider().opacity(0.35)

            // =========================================================
            // 2) AGUDEZA VISUAL CERCANA
            // =========================================================
            sectionHeader(icon: "text.magnifyingglass", title: "Agudeza visual (cercana)")

            HStack(spacing: 12) {
                FieldRow("OD S/C", required: true, error: errors["nearVaOdSc"]) {
                    iconTextField(systemName: "eye", text: $encounter.nearVaOdSc, isError: errors["nearVaOdSc"] != nil)
                }
                FieldRow("OI S/C", required: true, error: errors["nearVaOsSc"]) {
                    iconTextField(systemName: "eye", text: $encounter.nearVaOsSc, isError: errors["nearVaOsSc"] != nil)
                }
                FieldRow("AO S/C", required: true, error: errors["nearVaOuSc"]) {
                    iconTextField(systemName: "eye", text: $encounter.nearVaOuSc, isError: errors["nearVaOuSc"] != nil)
                }
            }

            HStack(spacing: 12) {
                FieldRow("OD C/C", required: true, error: errors["nearVaOdCc"]) {
                    iconTextField(systemName: "eyeglasses", text: $encounter.nearVaOdCc, isError: errors["nearVaOdCc"] != nil)
                }
                FieldRow("OI C/C", required: true, error: errors["nearVaOsCc"]) {
                    iconTextField(systemName: "eyeglasses", text: $encounter.nearVaOsCc, isError: errors["nearVaOsCc"] != nil)
                }
                FieldRow("AO C/C", required: true, error: errors["nearVaOuCc"]) {
                    iconTextField(systemName: "eyeglasses", text: $encounter.nearVaOuCc, isError: errors["nearVaOuCc"] != nil)
                }
            }

            Divider().opacity(0.35)

            // =========================================================
            // 3) REFRACCIÓN
            // =========================================================
            sectionHeader(icon: "scope", title: "Refracción")

            subsectionLabel("OD", icon: "r.circle.fill")

            HStack(spacing: 12) {
                FieldRow("SPH", required: true, error: errors["rxOdSph"]) {
                    iconTextField(systemName: "plus.forwardslash.minus", text: $encounter.rxOdSph, isError: errors["rxOdSph"] != nil)
                }
                FieldRow("CYL", required: true, error: errors["rxOdCyl"]) {
                    iconTextField(systemName: "circlebadge.2.fill", text: $encounter.rxOdCyl, isError: errors["rxOdCyl"] != nil)
                }
                FieldRow("AXIS", required: true, error: errors["rxOdAxis"]) {
                    iconTextField(systemName: "dial.high.fill", text: $encounter.rxOdAxis, isError: errors["rxOdAxis"] != nil)
                }
                FieldRow("ADD", required: false, error: errors["rxOdAdd"]) {
                    iconTextField(systemName: "plus.circle.fill", text: $encounter.rxOdAdd, isError: errors["rxOdAdd"] != nil)
                }
            }

            subsectionLabel("OI", icon: "l.circle.fill")

            HStack(spacing: 12) {
                FieldRow("SPH", required: true, error: errors["rxOsSph"]) {
                    iconTextField(systemName: "plus.forwardslash.minus", text: $encounter.rxOsSph, isError: errors["rxOsSph"] != nil)
                }
                FieldRow("CYL", required: true, error: errors["rxOsCyl"]) {
                    iconTextField(systemName: "circlebadge.2.fill", text: $encounter.rxOsCyl, isError: errors["rxOsCyl"] != nil)
                }
                FieldRow("AXIS", required: true, error: errors["rxOsAxis"]) {
                    iconTextField(systemName: "dial.high.fill", text: $encounter.rxOsAxis, isError: errors["rxOsAxis"] != nil)
                }
                FieldRow("ADD", required: false, error: errors["rxOsAdd"]) {
                    iconTextField(systemName: "plus.circle.fill", text: $encounter.rxOsAdd, isError: errors["rxOsAdd"] != nil)
                }
            }

            HStack(spacing: 12) {
                FieldRow("DIP", required: true, error: errors["dip"]) {
                    iconTextField(systemName: "ruler.fill", text: $encounter.dip, isError: errors["dip"] != nil)
                }
                Spacer()
            }

            Divider().opacity(0.35)

            // =========================================================
            // 4) RECOMENDACIÓN
            // =========================================================
            sectionHeader(icon: "sparkles", title: "Recomendación")

            // Tipo de lente — botón que abre el wizard
            FieldRow("Tipo de lente", required: true, error: errors["lensType"]) {
                lensTypeButton
            }

            FieldRow("Uso", required: true, error: errors["usage"]) {
                iconTextField(systemName: "person.fill.checkmark", text: $encounter.usage, isError: errors["usage"] != nil)
            }

            Divider().opacity(0.35)

            // =========================================================
            // 5) DIAGNÓSTICO
            // =========================================================
            sectionHeader(icon: "stethoscope", title: "Diagnóstico")

            FieldRow("Diagnóstico del optometrista", required: false, error: nil) {
                HStack(spacing: 10) {
                    Image(systemName: "stethoscope")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.secondary)
                    TextField("Ej. Miopía, Astigmatismo...", text: $encounter.diagnostico)
                        .visionTextField(isError: false)
                        .textInputAutocapitalization(.sentences)
                }
            }

            // Sugerencias siempre visibles: tocando uno agrega/reemplaza el diagnóstico
            diagnosisSuggestionsView

            Divider().opacity(0.35)

            // =========================================================
            // 6) FECHA DE CONSULTA (bloqueada a hoy)
            // =========================================================
            FieldRow("Fecha de consulta", required: true, error: nil) {
                lockedDateField
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.white.opacity(0.82))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(BrandColors.accent.opacity(0.16), lineWidth: 1)
                )
                .shadow(color: BrandColors.secondary.opacity(0.06), radius: 14, x: 0, y: 8)
        )
    }

    // MARK: - Lens type button

    private var lensTypeButton: some View {
        Button {
            showLensPicker = true
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "eyeglasses")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(encounter.lensType.isEmpty ? Color.secondary : BrandColors.secondary)

                if encounter.lensType.isEmpty {
                    Text("Seleccionar tipo de lente...")
                        .foregroundStyle(Color.secondary.opacity(0.7))
                        .font(.system(size: 15))
                } else {
                    Text(encounter.lensType)
                        .foregroundStyle(BrandColors.secondary)
                        .font(.system(size: 14, weight: .medium))
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                }

                Spacer(minLength: 4)

                Image(systemName: encounter.lensType.isEmpty ? "chevron.right" : "pencil.circle.fill")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(encounter.lensType.isEmpty ? Color.secondary.opacity(0.5) : BrandColors.primary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color.black.opacity(0.04))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(
                        errors["lensType"] != nil
                            ? BrandColors.danger.opacity(0.90)
                            : (encounter.lensType.isEmpty ? BrandColors.accent.opacity(0.12) : BrandColors.primary.opacity(0.30)),
                        lineWidth: errors["lensType"] != nil || !encounter.lensType.isEmpty ? 1.5 : 1
                    )
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Diagnosis suggestions

    private var diagnosisSuggestionsView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Sugerencias rápidas:")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

            FlowWrap(Self.diagnosisSuggestions) { suggestion in
                let isSelected = encounter.diagnostico == suggestion
                Button {
                    if isSelected {
                        encounter.diagnostico = ""
                    } else {
                        encounter.diagnostico = suggestion
                    }
                } label: {
                    HStack(spacing: 4) {
                        if isSelected {
                            Image(systemName: "checkmark")
                                .font(.system(size: 10, weight: .bold))
                        }
                        Text(suggestion)
                            .font(.system(size: 13, weight: .medium))
                    }
                    .foregroundStyle(isSelected ? .white : BrandColors.secondary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        isSelected
                            ? BrandColors.primary.opacity(0.85)
                            : BrandColors.soft.opacity(0.75)
                    )
                    .clipShape(Capsule())
                    .overlay(
                        Capsule()
                            .stroke(
                                isSelected
                                    ? BrandColors.primary.opacity(0.0)
                                    : BrandColors.accent.opacity(0.35),
                                lineWidth: 1
                            )
                    )
                }
                .buttonStyle(.plain)
                .animation(.easeInOut(duration: 0.15), value: isSelected)
            }
            .frame(minHeight: 72)
        }
    }

    // MARK: - Locked date field

    private var lockedDateField: some View {
        HStack(spacing: 10) {
            Image(systemName: "calendar.badge.checkmark")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(BrandColors.primary.opacity(0.75))

            Text(todayFormatted)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(.primary)

            Spacer()

            Text("Hoy")
                .font(.caption.weight(.semibold))
                .foregroundStyle(BrandColors.primary)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(BrandColors.primary.opacity(0.10))
                .clipShape(Capsule())
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(BrandColors.primary.opacity(0.04))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(BrandColors.primary.opacity(0.18), lineWidth: 1)
        )
    }

    // MARK: - UI helpers

    private func sectionHeader(icon: String, title: String) -> some View {
        HStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(BrandColors.primary.opacity(0.10))
                    .frame(width: 28, height: 28)

                Image(systemName: icon)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(BrandColors.secondary.opacity(0.90))
            }

            Text(title)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(BrandColors.secondary)

            Spacer()
        }
        .padding(.top, 2)
    }

    private func subsectionLabel(_ title: String, icon: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(BrandColors.secondary.opacity(0.85))

            Text(title)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.primary)

            Spacer()
        }
        .padding(.top, 2)
    }

    private func iconTextField(systemName: String, text: Binding<String>, isError: Bool) -> some View {
        HStack(spacing: 10) {
            Image(systemName: systemName)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.secondary)

            TextField("", text: text)
                .visionTextField(isError: isError)
                .textInputAutocapitalization(.never)
        }
    }
}
