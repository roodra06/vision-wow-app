//
//  RevisionTypePickerSheet.swift
//  VisionWow
//

import SwiftUI

struct RevisionTypePickerSheet: View {
    @Bindable var patient: Patient
    var opticaCompany: Company
    let onCreate: (Encounter) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var selectedType: RevisionType? = nil
    @State private var guaranteeReason: String = ""

    enum RevisionType { case guarantee, newRevision }

    var body: some View {
        ZStack {
            BrandColors.backgroundGradient.ignoresSafeArea()

            VStack(spacing: 0) {
                // Handle bar
                RoundedRectangle(cornerRadius: 3)
                    .fill(Color.secondary.opacity(0.3))
                    .frame(width: 40, height: 5)
                    .padding(.top, 12)
                    .padding(.bottom, 20)

                Text("¿Tipo de consulta?")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(BrandColors.secondary)
                    .padding(.bottom, 24)

                VStack(spacing: 14) {
                    typeCard(
                        type: .newRevision,
                        icon: "eye.fill",
                        title: "Nueva Revisión",
                        subtitle: "Consulta completa con examen visual y posible nueva venta."
                    )

                    typeCard(
                        type: .guarantee,
                        icon: "shield.checkmark.fill",
                        title: "Garantía",
                        subtitle: "Ajuste o corrección sin costo a lentes comprados previamente."
                    )
                }
                .padding(.horizontal, 20)

                // Campo de motivo (solo garantía)
                if selectedType == .guarantee {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Motivo de garantía")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(.secondary)

                        HStack(spacing: 10) {
                            Image(systemName: "note.text")
                                .font(.system(size: 13))
                                .foregroundStyle(.secondary)
                            TextField("Ej. Cambio de graduación...", text: $guaranteeReason)
                                .autocorrectionDisabled()
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 12)
                        .background(Color.black.opacity(0.04))
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(BrandColors.accent.opacity(0.2), lineWidth: 1)
                        )
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .transition(.opacity.combined(with: .move(edge: .top)))
                    .animation(.easeInOut(duration: 0.2), value: selectedType)
                }

                Spacer()

                // Botones
                VStack(spacing: 10) {
                    Button {
                        createAndContinue()
                    } label: {
                        Text("Comenzar consulta")
                            .font(.system(size: 17, weight: .bold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .foregroundStyle(.white)
                            .background(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .fill(isValid ? BrandColors.primary : Color.gray.opacity(0.4))
                            )
                    }
                    .disabled(!isValid)
                    .buttonStyle(.plain)

                    Button("Cancelar") {
                        dismiss()
                    }
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 28)
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.hidden)
    }

    // MARK: - Type Card

    private func typeCard(type: RevisionType, icon: String, title: String, subtitle: String) -> some View {
        let isSelected = selectedType == type
        return Button {
            withAnimation(.easeInOut(duration: 0.15)) {
                selectedType = type
                if type == .newRevision { guaranteeReason = "" }
            }
        } label: {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(isSelected ? BrandColors.primary.opacity(0.15) : BrandColors.accent.opacity(0.08))
                        .frame(width: 48, height: 48)
                    Image(systemName: icon)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(isSelected ? BrandColors.primary : BrandColors.secondary.opacity(0.6))
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(isSelected ? BrandColors.primary : .primary)
                    Text(subtitle)
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }

                Spacer()

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 20))
                    .foregroundStyle(isSelected ? BrandColors.primary : Color.secondary.opacity(0.4))
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color.white.opacity(isSelected ? 0.95 : 0.75))
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(
                                isSelected ? BrandColors.primary.opacity(0.5) : BrandColors.accent.opacity(0.12),
                                lineWidth: isSelected ? 2 : 1
                            )
                    )
                    .shadow(color: BrandColors.secondary.opacity(isSelected ? 0.1 : 0.04), radius: 10, x: 0, y: 6)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Validation

    private var isValid: Bool {
        guard let type = selectedType else { return false }
        if type == .guarantee {
            return !guaranteeReason.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
        return true
    }

    // MARK: - Create Encounter

    private func createAndContinue() {
        guard let type = selectedType else { return }

        let enc = Encounter()
        enc.patient = patient
        enc.company = opticaCompany
        enc.companyName = opticaCompany.name
        enc.branch = "Óptica"
        enc.department = "Particular"
        enc.directBoss = "N/A"
        enc.shift = "N/A"
        enc.seniorityYears = 0
        enc.companyEmail = "optica@visionwow.mx"

        switch type {
        case .guarantee:
            enc.isGuarantee = true
            enc.guaranteeReason = guaranteeReason.trimmingCharacters(in: .whitespacesAndNewlines)
        case .newRevision:
            enc.isGuarantee = false
        }

        onCreate(enc)
    }
}
