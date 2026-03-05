//
//  Encounter+DisplayHelpers.swift
//  VisionWow
//
//  Helpers de presentación compartidos por CompanyDetailScreen y OpticaPatientsScreen.
//

import SwiftUI

extension Encounter {

    /// Nombre completo del paciente; "Paciente" si está vacío.
    var displayName: String {
        let first = (patient?.firstName ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        let last  = (patient?.lastName  ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        let full  = [first, last].filter { !$0.isEmpty }.joined(separator: " ")
        return full.isEmpty ? "Paciente" : full
    }

    /// Resumen de pago legible: "Pagado • $1,500" o "Sin compra".
    var paymentSummary: String {
        let status = payStatus.trimmingCharacters(in: .whitespacesAndNewlines)
        let total  = payTotal.trimmingCharacters(in: .whitespacesAndNewlines)
        if status.isEmpty && total.isEmpty { return "Sin compra" }
        if !status.isEmpty && !total.isEmpty { return "\(status) • $\(total)" }
        if !status.isEmpty { return status }
        return "Total • $\(total)"
    }

    /// SF Symbol que representa el estado de pago.
    var paymentIconName: String {
        let s = payStatus.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if s.contains("pag")  { return "checkmark.seal.fill" }
        if s.contains("pend") { return "clock.fill" }
        if s.contains("cort") { return "gift.fill" }
        return payTotal.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            ? "cart.badge.minus" : "cart.fill"
    }

    /// Color semántico del estado de pago.
    var paymentColor: Color {
        let s = payStatus.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if s.contains("pag")  { return BrandColors.success }
        if s.contains("pend") { return BrandColors.warning }
        if s.contains("cort") { return BrandColors.info }
        return payTotal.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            ? .secondary : BrandColors.secondary
    }
}
