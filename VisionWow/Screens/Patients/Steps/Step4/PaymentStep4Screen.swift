//
//  PaymentStep4Screen.swift
//  VisionWow
//

import SwiftUI
import UIKit

// MARK: - Discount codes table
// Modifica los valores para ajustar porcentajes.
// Códigos disponibles: FAMILIA (10%), PROMO5 (5%), PRIMERA (5%)
private let kDiscountCodes: [String: (label: String, pct: Int)] = [
    "FAMILIA": ("Descuento familiar", 10),
    "PROMO5":  ("Promoción del mes",  5),
    "PRIMERA": ("Primera visita",     5)
]

struct PaymentStep4Screen: View {
    @Bindable var encounter: Encounter
    let errors: [String: String]
    var stepNumber: Int = 5
    var totalSteps: Int = 6

    // MARK: - Discount state

    @State private var discountCodeInput: String = ""
    /// Codes applied so far: (code, label, pct, savingAmount)
    @State private var appliedCodes: [(code: String, label: String, pct: Int, saving: Double)] = []
    @State private var discountError: String? = nil
    /// The payTotal at the moment the FIRST code was applied (our reference "base")
    @State private var baseTotal: String = ""
    @State private var didLoadDiscounts = false
    @State private var showTotalChangedAlert = false

    // MARK: - Helpers

    private var patientIdText: String {
        "ID: \(String(describing: encounter.id).prefix(8))"
    }

    private var fullNameText: String {
        let first = (encounter.patient?.firstName ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        let last  = (encounter.patient?.lastName  ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        let combined = [first, last].filter { !$0.isEmpty }.joined(separator: " ")
        return combined.isEmpty ? "Sin nombre" : combined
    }

    private var profileUIImage: UIImage? {
        guard let data = encounter.patient?.profileImageData else { return nil }
        return UIImage(data: data)
    }

    private var baseTotalValue: Double {
        Double(baseTotal.trimmingCharacters(in: .whitespacesAndNewlines)) ?? 0
    }

    private var lensCostValue: Double {
        Double(encounter.lensCost.trimmingCharacters(in: .whitespacesAndNewlines)) ?? 0
    }

    private var totalDiscountPct: Int {
        appliedCodes.reduce(0) { $0 + $1.pct }
    }

    private var totalSaving: Double {
        appliedCodes.reduce(0) { $0 + $1.saving }
    }

    private var discountedTotal: Double {
        max(0, baseTotalValue - totalSaving)
    }

    private var canAddMoreCodes: Bool {
        appliedCodes.count < 3
    }

    // MARK: - Body

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                headerCard
                paymentCard
            }
            .padding(.horizontal, 16)
            .padding(.top, 14)
            .padding(.bottom, 28)
        }
        .onAppear { loadExistingDiscounts() }
        .alert("Total modificado", isPresented: $showTotalChangedAlert) {
            Button("Quitar descuentos", role: .destructive) { clearDiscounts() }
            Button("Cancelar", role: .cancel) {
                // Revertir el total al valor con descuento previo
                encounter.payTotal = String(format: "%.2f", discountedTotal)
            }
        } message: {
            Text("Cambiaste el precio total mientras hay descuentos aplicados. ¿Deseas quitar los descuentos y usar el nuevo precio?")
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
                            Image(systemName: "creditcard.fill")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(BrandColors.accent)
                            Text("Pago")
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
                            .font(.subheadline).foregroundStyle(.secondary).lineLimit(1)
                    }

                    HStack(spacing: 8) {
                        Image(systemName: "number")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(BrandColors.accent)
                        Text(patientIdText)
                            .font(.subheadline).foregroundStyle(.secondary).lineLimit(1)
                    }
                }
                Spacer(minLength: 0)
            }

            VStack(spacing: 6) {
                HStack {
                    Text("Paso \(stepNumber) de \(totalSteps)")
                        .font(.caption.weight(.semibold)).foregroundStyle(.secondary)
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
                .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(BrandColors.accent.opacity(0.16), lineWidth: 1))
                .shadow(color: BrandColors.secondary.opacity(0.06), radius: 14, x: 0, y: 8)
        )
    }

    private var avatar: some View {
        ZStack {
            Circle().fill(BrandColors.primary.opacity(0.12)).frame(width: 76, height: 76)
            Circle().stroke(BrandColors.strokeGradient, lineWidth: 3).frame(width: 76, height: 76)
            if let img = profileUIImage {
                Image(uiImage: img).resizable().scaledToFill()
                    .frame(width: 70, height: 70).clipShape(Circle())
            } else {
                Image(systemName: "person.fill")
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundStyle(BrandColors.secondary.opacity(0.85))
            }
        }
    }

    // MARK: - Payment Card

    private var paymentCard: some View {
        VStack(spacing: 16) {
            sectionHeader(icon: "creditcard.fill", title: "Estatus y método")

            HStack(spacing: 12) {
                FieldRow("Estatus", required: true, error: errors["payStatus"]) {
                    menuPickerInput(
                        icon: "checkmark.seal.fill",
                        selection: $encounter.payStatus,
                        placeholder: "Selecciona…",
                        isError: errors["payStatus"] != nil,
                        options: ["Pagado", "Pendiente", "Cortesía"]
                    )
                }

                FieldRow("Total", required: true, error: errors["payTotal"]) {
                    iconTextField(
                        icon: "dollarsign.circle.fill",
                        placeholder: "0.00",
                        text: $encounter.payTotal,
                        isError: errors["payTotal"] != nil
                    )
                    .keyboardType(.decimalPad)
                    .onChange(of: encounter.payTotal) {
                        if appliedCodes.isEmpty {
                            // Sin descuentos: mantener base en sync
                            baseTotal = encounter.payTotal
                        } else {
                            // Con descuentos activos: pedir confirmación
                            showTotalChangedAlert = true
                        }
                    }
                }
            }

            HStack(spacing: 12) {
                FieldRow("Método", required: true, error: errors["payMethod"]) {
                    menuPickerInput(
                        icon: "creditcard.and.123",
                        selection: $encounter.payMethod,
                        placeholder: "Selecciona…",
                        isError: errors["payMethod"] != nil,
                        options: ["Efectivo", "Tarjeta", "Transferencia", "Mixto"]
                    )
                }

                FieldRow("Referencia", required: true, error: errors["payReference"]) {
                    iconTextField(
                        icon: "number.circle.fill",
                        placeholder: "",
                        text: $encounter.payReference,
                        isError: errors["payReference"] != nil
                    )
                }
            }

            HStack(spacing: 12) {
                FieldRow("A cuenta (anticipo)") {
                    iconTextField(
                        icon: "arrow.down.circle.fill",
                        placeholder: "0.00",
                        text: $encounter.payDeposit,
                        isError: false
                    )
                    .keyboardType(.decimalPad)
                }

                FieldRow("Costo lente (inversión)") {
                    iconTextField(
                        icon: "tag.fill",
                        placeholder: "0.00",
                        text: $encounter.lensCost,
                        isError: false
                    )
                    .keyboardType(.decimalPad)
                }
            }

            Divider().opacity(0.35)

            // ── Discount section ──────────────────────────────────────────
            discountSection

            Divider().opacity(0.35)

            sectionHeader(icon: "note.text", title: "Notas")

            FieldRow("Notas (opcional)") {
                iconTextField(
                    icon: "note.text",
                    placeholder: "",
                    text: Binding(
                        get: { encounter.payNotes ?? "" },
                        set: { encounter.payNotes = $0.isEmpty ? nil : $0 }
                    ),
                    isError: false
                )
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.white.opacity(0.82))
                .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(BrandColors.accent.opacity(0.16), lineWidth: 1))
                .shadow(color: BrandColors.secondary.opacity(0.06), radius: 14, x: 0, y: 8)
        )
    }

    // MARK: - Discount Section

    private var discountSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(icon: "percent", title: "Códigos de descuento")

            // Hint
            Text("Disponibles: FAMILIA (−10%), PROMO5 (−5%), PRIMERA (−5%)")
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.top, -6)

            // Code input row
            if canAddMoreCodes {
                HStack(spacing: 10) {
                    HStack(spacing: 8) {
                        Image(systemName: "ticket.fill")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(BrandColors.accent)

                        TextField("Ingresar código…", text: $discountCodeInput)
                            .textInputAutocapitalization(.characters)
                            .autocorrectionDisabled()
                            .font(.system(size: 14, weight: .semibold))
                            .submitLabel(.done)
                            .onSubmit { applyDiscountCode() }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 11)
                    .background(Color.black.opacity(0.04))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(BrandColors.accent.opacity(discountError != nil ? 0.0 : 0.14), lineWidth: 1)
                    )

                    Button {
                        applyDiscountCode()
                    } label: {
                        Text("Aplicar")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 11)
                            .background(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .fill(BrandColors.primary)
                            )
                    }
                    .buttonStyle(BounceButtonStyle())
                }

                // Error feedback
                if let err = discountError {
                    HStack(spacing: 6) {
                        Image(systemName: "exclamationmark.circle.fill")
                            .font(.system(size: 12))
                        Text(err)
                            .font(.caption)
                    }
                    .foregroundStyle(BrandColors.danger)
                    .padding(.top, -4)
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }

            // Applied codes list
            if !appliedCodes.isEmpty {
                VStack(spacing: 6) {
                    ForEach(appliedCodes, id: \.code) { d in
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 13))
                                .foregroundStyle(BrandColors.success)

                            Text(d.code)
                                .font(.system(size: 13, weight: .bold))
                                .foregroundStyle(BrandColors.secondary)

                            Text("· \(d.label) · −\(d.pct)%")
                                .font(.system(size: 12))
                                .foregroundStyle(.secondary)

                            Spacer()

                            Text("−$\(String(format: "%.0f", d.saving))")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(BrandColors.success)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 7)
                        .background(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(BrandColors.success.opacity(0.07))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                                        .stroke(BrandColors.success.opacity(0.20), lineWidth: 1)
                                )
                        )
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
                .animation(.spring(response: 0.4, dampingFraction: 0.8), value: appliedCodes.count)

                // Summary row
                VStack(spacing: 4) {
                    HStack {
                        Text("Precio original")
                            .font(.caption).foregroundStyle(.secondary)
                        Spacer()
                        Text("$\(String(format: "%.2f", baseTotalValue))")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                    HStack {
                        Text("Descuento total (−\(totalDiscountPct)%)")
                            .font(.caption.weight(.semibold)).foregroundStyle(BrandColors.success)
                        Spacer()
                        Text("−$\(String(format: "%.2f", totalSaving))")
                            .font(.caption.weight(.semibold)).foregroundStyle(BrandColors.success)
                    }
                    Divider().opacity(0.3)
                    HStack {
                        Text("Precio final")
                            .font(.system(size: 14, weight: .bold)).foregroundStyle(.primary)
                        Spacer()
                        Text("$\(String(format: "%.2f", discountedTotal))")
                            .font(.system(size: 14, weight: .bold)).foregroundStyle(BrandColors.primary)
                    }
                    if lensCostValue > 0 {
                        HStack {
                            Image(systemName: discountedTotal >= lensCostValue
                                  ? "checkmark.seal.fill" : "exclamationmark.triangle.fill")
                                .font(.system(size: 11))
                            Text(discountedTotal >= lensCostValue
                                 ? "Por encima del costo de inversión ✓"
                                 : "Precio final por debajo del costo ($\(String(format: "%.0f", lensCostValue)))")
                                .font(.caption)
                        }
                        .foregroundStyle(discountedTotal >= lensCostValue
                                         ? BrandColors.success : BrandColors.danger)
                    }
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color.white.opacity(0.7))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(BrandColors.primary.opacity(0.15), lineWidth: 1)
                        )
                )

                // Clear button
                Button(role: .destructive) {
                    clearDiscounts()
                } label: {
                    Label("Quitar todos los descuentos", systemImage: "xmark.circle")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(BrandColors.danger)
                }
                .buttonStyle(.plain)
                .padding(.top, -2)
            }
        }
    }

    // MARK: - Discount Logic

    private func applyDiscountCode() {
        let code = discountCodeInput.uppercased().trimmingCharacters(in: .whitespacesAndNewlines)
        guard !code.isEmpty else { return }

        // Validate code exists
        guard let info = kDiscountCodes[code] else {
            withAnimation { discountError = "Código «\(code)» no válido. Usa: FAMILIA, PROMO5 o PRIMERA." }
            return
        }

        // Check not already applied
        if appliedCodes.contains(where: { $0.code == code }) {
            withAnimation { discountError = "El código \(code) ya fue aplicado." }
            return
        }

        // Max 3
        if appliedCodes.count >= 3 {
            withAnimation { discountError = "Máximo 3 descuentos por venta." }
            return
        }

        // Ensure base price is set
        let base = baseTotalValue
        guard base > 0 else {
            withAnimation { discountError = "Ingresa el precio total antes de aplicar descuentos." }
            return
        }

        // Validate against cost
        let newTotalPct = totalDiscountPct + info.pct
        let newFinal = base * (1.0 - Double(newTotalPct) / 100.0)
        if lensCostValue > 0 && newFinal < lensCostValue {
            withAnimation {
                discountError = "No permitido: el precio final ($\(String(format: "%.0f", newFinal))) quedaría por debajo del costo ($\(String(format: "%.0f", lensCostValue)))."
            }
            return
        }

        // Apply
        let saving = base * Double(info.pct) / 100.0
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            appliedCodes.append((code: code, label: info.label, pct: info.pct, saving: saving))
            discountError = nil
            discountCodeInput = ""
        }

        // Update encounter fields
        encounter.payTotal = String(format: "%.2f", newFinal)
        persistDiscounts(base: base, final: newFinal)
    }

    private func clearDiscounts() {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            encounter.payTotal = baseTotal
            encounter.payDiscount = nil
            appliedCodes = []
            discountError = nil
        }
    }

    private func persistDiscounts(base: Double, final: Double) {
        if appliedCodes.isEmpty {
            encounter.payDiscount = nil
            return
        }
        // Store machine-readable format: "BASE:3500|FAMILIA:10,PROMO5:5"
        let codesStr = appliedCodes.map { "\($0.code):\($0.pct)" }.joined(separator: ",")
        encounter.payDiscount = "BASE:\(String(format: "%.2f", base))|\(codesStr)"
    }

    /// On appear: parse existing payDiscount to restore applied codes
    private func loadExistingDiscounts() {
        guard !didLoadDiscounts else { return }
        didLoadDiscounts = true

        guard let raw = encounter.payDiscount,
              raw.hasPrefix("BASE:"),
              let pipeIdx = raw.firstIndex(of: "|") else {
            baseTotal = encounter.payTotal
            return
        }

        let basePart = String(raw[raw.index(raw.startIndex, offsetBy: 5)..<pipeIdx])
        baseTotal = basePart

        let codesPart = String(raw[raw.index(after: pipeIdx)...])
        let baseVal = Double(basePart) ?? 0

        var parsed: [(code: String, label: String, pct: Int, saving: Double)] = []
        for token in codesPart.split(separator: ",") {
            let parts = token.split(separator: ":")
            guard parts.count == 2,
                  let pct = Int(parts[1]),
                  let info = kDiscountCodes[String(parts[0])] else { continue }
            let saving = baseVal * Double(pct) / 100.0
            parsed.append((code: String(parts[0]), label: info.label, pct: pct, saving: saving))
        }
        appliedCodes = parsed
    }

    // MARK: - UI Helpers

    private func sectionHeader(icon: String, title: String) -> some View {
        HStack(spacing: 10) {
            ZStack {
                Circle().fill(BrandColors.primary.opacity(0.10)).frame(width: 28, height: 28)
                Image(systemName: icon)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(BrandColors.secondary.opacity(0.9))
            }
            Text(title)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(BrandColors.secondary)
            Spacer()
        }
        .padding(.top, 2)
    }

    private func iconTextField(icon: String, placeholder: String,
                               text: Binding<String>, isError: Bool) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .semibold)).foregroundStyle(.secondary)
            TextField(placeholder, text: text).visionTextField(isError: isError)
        }
    }

    private func menuPickerInput(icon: String, selection: Binding<String>,
                                 placeholder: String, isError: Bool,
                                 options: [String]) -> some View {
        Menu {
            ForEach(options, id: \.self) { opt in
                Button {
                    selection.wrappedValue = opt
                } label: {
                    if selection.wrappedValue == opt {
                        Label(opt, systemImage: "checkmark")
                    } else {
                        Text(opt)
                    }
                }
            }
        } label: {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 13, weight: .semibold)).foregroundStyle(.secondary)
                Text(selection.wrappedValue.isEmpty ? placeholder : selection.wrappedValue)
                    .foregroundStyle(selection.wrappedValue.isEmpty ? .secondary : .primary)
                    .lineLimit(1)
                Spacer()
                Image(systemName: "chevron.down")
                    .font(.system(size: 12, weight: .semibold)).foregroundStyle(.secondary)
            }
            .padding(.horizontal, 12)
            .frame(maxWidth: .infinity, minHeight: 44)
            .background(Color.black.opacity(0.04))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(isError ? BrandColors.danger.opacity(0.90)
                                    : BrandColors.accent.opacity(0.12), lineWidth: 1)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity, minHeight: 44)
    }
}
