import SwiftUI
import SwiftData

struct CompanyCard: View {
    let company: Company
    let onEdit: () -> Void
    let onDelete: () -> Void

    // ✅ Total digitado en el formulario (opcional)
    private var totalDigitado: Int? {
        company.expectedPatients
    }

    // ✅ Atendidos = pacientes capturados en la empresa
    private var atendidos: Int {
        company.encounters.count
    }

    private var progressText: String {
        if let total = totalDigitado, total > 0 {
            return "\(atendidos) / \(total) pacientes atendidos"
        } else {
            return "\(atendidos) pacientes atendidos"
        }
    }

    private var progressPercent: Double {
        guard let total = totalDigitado, total > 0 else { return 0 }
        return min(1.0, Double(atendidos) / Double(total))
    }

    private var progressCaption: String {
        guard let total = totalDigitado, total > 0 else { return "Meta no definida" }
        if atendidos >= total { return "Meta completada" }
        let faltan = total - atendidos
        return "Faltan \(faltan)"
    }

    var body: some View {
        HStack(spacing: 12) {
            // Avatar redondo (icono)
            ZStack {
                Circle()
                    .fill(BrandColors.primary.opacity(0.12))
                    .frame(width: 46, height: 46)

                Circle()
                    .stroke(BrandColors.strokeGradient, lineWidth: 2)
                    .frame(width: 46, height: 46)

                Text(initials(from: company.name))
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(BrandColors.secondary)
            }

            // Texto principal
            VStack(alignment: .leading, spacing: 6) {
                Text(company.name)
                    .font(.headline)
                    .foregroundStyle(.primary)
                    .lineLimit(1)

                // ✅ KPI: atendidos / total digitado
                HStack(spacing: 8) {
                    Image(systemName: "person.2.fill")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(BrandColors.accent)

                    Text(progressText)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                // ✅ Progreso (solo “fuerte” si existe meta)
                HStack(spacing: 10) {
                    ProgressView(value: progressPercent)
                        .progressViewStyle(.linear)
                        .tint(BrandColors.primary)
                        .frame(maxWidth: 220)

                    Text(progressCaption)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                .opacity((totalDigitado ?? 0) > 0 ? 1.0 : 0.45)
            }

            Spacer(minLength: 8)

            // Acciones (edit/delete) con estilo iOS
            HStack(spacing: 10) {
                Button(action: onEdit) {
                    Image(systemName: "pencil")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(BrandColors.info) // azul consistente
                        .frame(width: 34, height: 34)
                        .background(
                            Circle().fill(BrandColors.info.opacity(0.12))
                        )
                }
                .buttonStyle(.plain)

                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(BrandColors.danger)
                        .frame(width: 34, height: 34)
                        .background(
                            Circle().fill(BrandColors.danger.opacity(0.12))
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.white.opacity(0.86))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(BrandColors.accent.opacity(0.18), lineWidth: 1)
                )
                .shadow(color: BrandColors.secondary.opacity(0.08), radius: 14, x: 0, y: 8)
        )
        .contentShape(Rectangle())
    }

    private func initials(from name: String) -> String {
        let parts = name
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .split(separator: " ")
            .prefix(2)
        let initials = parts.compactMap { $0.first }.map { String($0) }.joined()
        return initials.isEmpty ? "VW" : initials.uppercased()
    }
}
