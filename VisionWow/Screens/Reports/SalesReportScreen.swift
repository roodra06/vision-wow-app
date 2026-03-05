//
//  SalesReportScreen.swift
//  VisionWow
//

import SwiftUI

struct SalesReportScreen: View {
    let companyName: String
    let encounters: [Encounter]
    let showDateFilter: Bool        // true para Óptica

    @State private var filterEnabled = false
    @State private var startDate: Date = Calendar.current.startOfDay(for: Date())
    @State private var endDate: Date = Date()
    @State private var pdfError: String? = nil
    @State private var shareURL: URL? = nil

    // MARK: - Filtered data

    private var filtered: [Encounter] {
        let base = encounters.sorted { $0.createdAt > $1.createdAt }
        guard filterEnabled else { return base }
        let end = Calendar.current.date(bySettingHour: 23, minute: 59, second: 59, of: endDate) ?? endDate
        return base.filter { $0.createdAt >= startDate && $0.createdAt <= end }
    }

    // MARK: - Summary helpers

    private func toDouble(_ s: String) -> Double {
        Double(s.trimmingCharacters(in: .whitespacesAndNewlines)) ?? 0
    }

    private var totalVentas: Double   { filtered.reduce(0) { $0 + toDouble($1.payTotal) } }
    private var totalCobrado: Double  { filtered.reduce(0) { $0 + toDouble($1.payDeposit) + (isPaid($1) ? toDouble($1.payTotal) - toDouble($1.payDeposit) : 0) } }
    private var totalPendiente: Double { filtered.reduce(0) { $0 + restaPagar($1) } }
    private var totalInversion: Double { filtered.reduce(0) { $0 + toDouble($1.lensCost) } }

    private func isPaid(_ e: Encounter) -> Bool {
        e.payStatus.lowercased().contains("pag")
    }

    private func restaPagar(_ e: Encounter) -> Double {
        let total   = toDouble(e.payTotal)
        let deposit = toDouble(e.payDeposit)
        let resta = total - deposit
        return max(0, resta)
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            BrandColors.backgroundGradient.ignoresSafeArea()

            VStack(spacing: 0) {
                ScrollView {
                    VStack(spacing: 16) {
                        if showDateFilter {
                            dateFilterCard
                        }
                        summaryCard
                        encountersList
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 14)
                    .padding(.bottom, 100)
                }

                exportBar
            }
        }
        .navigationTitle("Reporte de Ventas")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Error al exportar", isPresented: Binding(
            get: { pdfError != nil },
            set: { if !$0 { pdfError = nil } }
        )) {
            Button("Aceptar", role: .cancel) { pdfError = nil }
        } message: {
            Text(pdfError ?? "")
        }
        .sheet(item: Binding(
            get: { shareURL.map { ShareURLItem(url: $0) } },
            set: { if $0 == nil { shareURL = nil } }
        )) { item in
            ActivityView(url: item.url)
        }
    }

    // MARK: - Date Filter Card

    private var dateFilterCard: some View {
        VStack(spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "calendar.badge.clock")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(BrandColors.accent)
                Text("Rango de fechas")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(BrandColors.secondary)
                Spacer()
                Toggle("", isOn: $filterEnabled)
                    .labelsHidden()
                    .tint(BrandColors.primary)
            }

            if filterEnabled {
                Divider().opacity(0.4)

                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Desde")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                        DatePicker("", selection: $startDate, displayedComponents: .date)
                            .labelsHidden()
                            .datePickerStyle(.compact)
                    }

                    Divider().frame(height: 44)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Hasta")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                        DatePicker("", selection: $endDate, in: startDate..., displayedComponents: .date)
                            .labelsHidden()
                            .datePickerStyle(.compact)
                    }

                    Spacer()
                }

                HStack(spacing: 8) {
                    quickRangeButton("Hoy")      { setRange(.today) }
                    quickRangeButton("Semana")   { setRange(.week) }
                    quickRangeButton("Mes")      { setRange(.month) }
                    quickRangeButton("Año")      { setRange(.year) }
                }
            }
        }
        .padding(14)
        .background(cardBackground)
    }

    private func quickRangeButton(_ label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(.caption.weight(.semibold))
                .foregroundStyle(BrandColors.primary)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    Capsule().fill(BrandColors.primary.opacity(0.10))
                )
        }
        .buttonStyle(.plain)
    }

    private enum QuickRange { case today, week, month, year }
    private func setRange(_ range: QuickRange) {
        filterEnabled = true
        let cal = Calendar.current
        let now = Date()
        switch range {
        case .today:
            startDate = cal.startOfDay(for: now)
            endDate = now
        case .week:
            startDate = cal.date(byAdding: .day, value: -6, to: cal.startOfDay(for: now)) ?? now
            endDate = now
        case .month:
            startDate = cal.date(byAdding: .month, value: -1, to: cal.startOfDay(for: now)) ?? now
            endDate = now
        case .year:
            startDate = cal.date(byAdding: .year, value: -1, to: cal.startOfDay(for: now)) ?? now
            endDate = now
        }
    }

    // MARK: - Summary Card

    private var summaryCard: some View {
        VStack(spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "chart.bar.fill")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(BrandColors.accent)
                Text("Resumen · \(filtered.count) venta\(filtered.count == 1 ? "" : "s")")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(BrandColors.secondary)
                Spacer()
            }

            Divider().opacity(0.4)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                summaryTile(label: "Total ventas",    value: fmt(totalVentas),    icon: "cart.fill",            color: BrandColors.primary)
                summaryTile(label: "Total cobrado",   value: fmt(totalCobrado),   icon: "checkmark.seal.fill",  color: BrandColors.success)
                summaryTile(label: "Por cobrar",      value: fmt(totalPendiente), icon: "clock.fill",           color: BrandColors.warning)
                summaryTile(label: "Inv. lentes",     value: fmt(totalInversion), icon: "eyeglasses",           color: BrandColors.secondary)
            }
        }
        .padding(14)
        .background(cardBackground)
    }

    private func summaryTile(label: String, value: String, icon: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(color)
                Text(label)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
            Text(value)
                .font(.system(size: 17, weight: .bold))
                .foregroundStyle(color)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(color.opacity(0.07))
        )
    }

    // MARK: - Encounters List

    private var encountersList: some View {
        VStack(spacing: 10) {
            if filtered.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "tray")
                        .font(.system(size: 32))
                        .foregroundStyle(BrandColors.accent.opacity(0.5))
                    Text("Sin ventas en este período")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
            } else {
                ForEach(filtered) { enc in
                    saleRow(enc)
                }
            }
        }
    }

    private func saleRow(_ enc: Encounter) -> some View {
        let resta = restaPagar(enc)

        return VStack(alignment: .leading, spacing: 10) {
            // Header row
            HStack(spacing: 6) {
                if enc.isGuarantee {
                    Label("GARANTÍA", systemImage: "shield.checkmark.fill")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(BrandColors.danger)
                        .clipShape(Capsule())
                }
                Text(DateUtils.formatShort(enc.createdAt))
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                Spacer()
                statusBadge(enc.payStatus)
            }

            Text(enc.patientFullName.isEmpty ? "Sin nombre" : enc.patientFullName)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(.primary)

            if let opt = enc.optometristName, !opt.isEmpty {
                Label(opt, systemImage: "stethoscope")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Divider().opacity(0.3)

            // Payment grid
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                payCell(label: "Total",    value: fmtField(enc.payTotal),   icon: "dollarsign.circle")
                payCell(label: "Método",   value: enc.payMethod.isEmpty ? "—" : enc.payMethod, icon: "creditcard")
                payCell(label: "A cuenta", value: fmtField(enc.payDeposit), icon: "arrow.down.circle")
                payCell(label: "Resta",    value: resta > 0 ? fmt(resta) : "—", icon: "clock", highlight: resta > 0)
                payCell(label: "Inversión",value: fmtField(enc.lensCost),   icon: "tag")
                if enc.isGuarantee {
                    payCell(label: "Garantía", value: enc.guaranteeReason ?? "Sí", icon: "shield.checkmark", highlight: false)
                } else {
                    payCell(label: "Garantía", value: "—", icon: "shield")
                }
            }
        }
        .padding(14)
        .background(cardBackground)
    }

    private func payCell(label: String, value: String, icon: String, highlight: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(highlight ? BrandColors.warning : BrandColors.accent.opacity(0.7))
                Text(label)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(.secondary)
            }
            Text(value)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(highlight ? BrandColors.warning : .primary)
                .lineLimit(1)
        }
    }

    private func statusBadge(_ status: String) -> some View {
        let s = status.lowercased()
        let color: Color = s.contains("pag") ? BrandColors.success
                         : s.contains("pend") ? BrandColors.warning
                         : s.isEmpty ? .secondary : BrandColors.accent
        return Text(status.isEmpty ? "Sin estatus" : status)
            .font(.caption.weight(.bold))
            .foregroundStyle(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(color)
            .clipShape(Capsule())
    }

    // MARK: - Export Bar

    private var exportBar: some View {
        VStack(spacing: 0) {
            Divider()
            HStack(spacing: 12) {
                Button {
                    exportCSV()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "tablecells")
                            .font(.system(size: 14, weight: .semibold))
                        Text("Exportar CSV")
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .foregroundStyle(BrandColors.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 13)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(Color.white.opacity(0.88))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .stroke(BrandColors.accent.opacity(0.25), lineWidth: 1)
                            )
                    )
                }
                .buttonStyle(.plain)

                Button {
                    exportPDF()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "doc.richtext.fill")
                            .font(.system(size: 14, weight: .semibold))
                        Text("Exportar PDF")
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 13)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(BrandColors.primary)
                    )
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.white.opacity(0.95))
        }
    }

    // MARK: - Export Actions

    private func exportCSV() {
        do {
            let url = try SalesReportGenerator.generateCSV(
                companyName: companyName,
                encounters: filtered
            )
            shareURL = url
        } catch {
            pdfError = error.localizedDescription
        }
    }

    private func exportPDF() {
        do {
            let url = try SalesReportGenerator.generatePDF(
                companyName: companyName,
                encounters: filtered
            )
            shareURL = url
        } catch {
            pdfError = error.localizedDescription
        }
    }

    // MARK: - Helpers

    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 18, style: .continuous)
            .fill(Color.white.opacity(0.86))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(BrandColors.accent.opacity(0.16), lineWidth: 1)
            )
            .shadow(color: BrandColors.secondary.opacity(0.06), radius: 14, x: 0, y: 8)
    }

    private func fmt(_ value: Double) -> String {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.minimumFractionDigits = 2
        f.maximumFractionDigits = 2
        f.groupingSeparator = ","
        return "$\(f.string(from: NSNumber(value: value)) ?? String(format: "%.2f", value))"
    }

    private func fmtField(_ s: String) -> String {
        let trimmed = s.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, let v = Double(trimmed) else { return trimmed.isEmpty ? "—" : trimmed }
        return fmt(v)
    }
}

// MARK: - Share helpers

private struct ShareURLItem: Identifiable {
    let id = UUID()
    let url: URL
}

private struct ActivityView: UIViewControllerRepresentable {
    let url: URL
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: [url], applicationActivities: nil)
    }
    func updateUIViewController(_ vc: UIActivityViewController, context: Context) {}
}
