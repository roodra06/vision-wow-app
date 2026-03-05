//
//  ReportGenerator.swift
//  VisionWow
//

import Foundation
import UIKit

struct ReportGenerator {

    // MARK: - Brand Colors (UIKit) — mismos que SalesReportGenerator
    private static let brandPrimary   = UIColor(red: 0.906, green: 0.220, blue: 0.498, alpha: 1) // #E7387F magenta
    private static let brandSecondary = UIColor(red: 0.463, green: 0.224, blue: 0.463, alpha: 1) // #763976 morado
    private static let brandAccent    = UIColor(red: 0.714, green: 0.451, blue: 0.678, alpha: 1) // #B673AD lavanda
    private static let brandSoft      = UIColor(red: 0.918, green: 0.816, blue: 0.878, alpha: 1) // #EAD0E0 rosa suave
    private static let brandWarning   = UIColor(red: 0.753, green: 0.478, blue: 0.173, alpha: 1) // #C07A2C ámbar
    private static let brandSuccess   = UIColor(red: 0.180, green: 0.545, blue: 0.424, alpha: 1) // #2E8B6C verde

    static func generateCSV(company: Company, encounters: [Encounter]) throws -> URL {
        var lines: [String] = []

        lines.append([
            "Fecha", "Paciente", "Optometrista", "Diagnóstico", "Lentes", "Compra"
        ].map { "\"\($0)\"" }.joined(separator: ","))

        let fmt = DateFormatter()
        fmt.dateStyle = .short
        fmt.timeStyle = .none
        fmt.locale = Locale(identifier: "es_MX")

        for enc in encounters {
            let row: [String] = [
                fmt.string(from: enc.createdAt),
                enc.patientFullName.isEmpty ? "Sin nombre" : enc.patientFullName,
                enc.optometristName ?? "",
                enc.diagnostico,
                enc.lensType,
                ReportComputer.didBuy(enc) ? "Sí" : "No"
            ]
            lines.append(row.map { "\"\($0.replacingOccurrences(of: "\"", with: "\"\""))\"" }.joined(separator: ","))
        }

        let data = (lines.joined(separator: "\n")).data(using: .utf8) ?? Data()
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("Reporte-\(company.name.sanitizedFileName)-\(Date().timeIntervalSince1970).csv")
        try data.write(to: url)
        return url
    }

    static func generatePDF(
        company: Company,
        encounters: [Encounter],
        summary: ReportSummary,
        includeOverview: Bool,
        includePaymentStats: Bool,
        includeAntecedentStats: Bool,
        includeDiopterStats: Bool,
        includePatientList: Bool,
        selectedAntecedentKeys: [String]
    ) throws -> URL {

        let logo = UIImage(named: "visionwow_logo")

        // Portrait A4
        let pageRect   = CGRect(x: 0, y: 0, width: 595, height: 842)
        let margin: CGFloat  = 36
        let contentW = pageRect.width - margin * 2

        // Layout
        let headerBandH: CGFloat = 80
        let accentLineH: CGFloat = 3
        let headerTotal = headerBandH + accentLineH

        // Fuentes
        let titleFont      = UIFont.systemFont(ofSize: 16, weight: .bold)
        let subtitleFont   = UIFont.systemFont(ofSize: 9,  weight: .regular)
        let sectionFont    = UIFont.systemFont(ofSize: 12, weight: .bold)
        let bodyFont       = UIFont.systemFont(ofSize: 10, weight: .regular)
        let bodyBoldFont   = UIFont.systemFont(ofSize: 10, weight: .semibold)
        let footerFont     = UIFont.systemFont(ofSize: 7,  weight: .light)

        let fullDateFmt = DateFormatter()
        fullDateFmt.dateStyle = .long
        fullDateFmt.timeStyle = .none
        fullDateFmt.locale = Locale(identifier: "es_MX")

        let yesColor: UIColor = brandAccent.withAlphaComponent(0.85)
        let noColor:  UIColor = brandSoft.withAlphaComponent(0.85)
        let cardBG:   UIColor = brandSoft.withAlphaComponent(0.22)

        let renderer = UIGraphicsPDFRenderer(bounds: pageRect)
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("Reporte-\(company.name.sanitizedFileName)-\(Date().timeIntervalSince1970).pdf")

        try renderer.writePDF(to: url) { ctx in
            var y: CGFloat = 0
            var pageNum = 1

            // MARK: helpers

            func drawGradient(cgCtx: CGContext, rect: CGRect, from: UIColor, to: UIColor) {
                cgCtx.saveGState()
                cgCtx.clip(to: rect)
                let colors  = [from.cgColor, to.cgColor] as CFArray
                if let grad = CGGradient(
                    colorsSpace: CGColorSpaceCreateDeviceRGB(),
                    colors: colors, locations: [0, 1]
                ) {
                    cgCtx.drawLinearGradient(
                        grad,
                        start: CGPoint(x: rect.minX, y: rect.midY),
                        end:   CGPoint(x: rect.maxX, y: rect.midY),
                        options: []
                    )
                }
                cgCtx.restoreGState()
            }

            func drawText(
                _ text: String, font: UIFont, color: UIColor,
                rect: CGRect, align: NSTextAlignment = .left
            ) {
                let ps = NSMutableParagraphStyle()
                ps.alignment = align
                ps.lineBreakMode = .byTruncatingTail
                let attrs: [NSAttributedString.Key: Any] = [
                    .font: font, .foregroundColor: color, .paragraphStyle: ps
                ]
                (text as NSString).draw(in: rect, withAttributes: attrs)
            }

            // MARK: Header band

            func drawHeader() {
                let cg = ctx.cgContext
                let bandRect = CGRect(x: 0, y: 0, width: pageRect.width, height: headerBandH)
                drawGradient(cgCtx: cg, rect: bandRect, from: brandPrimary, to: brandSecondary)

                // Accent line
                cg.saveGState()
                cg.setFillColor(brandAccent.cgColor)
                cg.fill(CGRect(x: 0, y: headerBandH, width: pageRect.width, height: accentLineH))
                cg.restoreGState()

                var textX: CGFloat = margin

                // Logo
                if let logo = logo {
                    let logoH: CGFloat = 54
                    let logoW = (logo.size.width / logo.size.height) * logoH
                    let logoRect = CGRect(
                        x: margin,
                        y: (headerBandH - logoH) / 2,
                        width: logoW, height: logoH
                    )
                    logo.draw(in: logoRect)
                    textX = logoRect.maxX + 14
                }

                // Título
                drawText(
                    "VisionWow — Reporte Corporativo",
                    font: titleFont, color: .white,
                    rect: CGRect(x: textX, y: 14, width: contentW - (textX - margin), height: 22)
                )
                drawText(
                    company.name,
                    font: UIFont.systemFont(ofSize: 22, weight: .bold), color: UIColor.white.withAlphaComponent(0.95),
                    rect: CGRect(x: textX, y: 36, width: contentW - (textX - margin), height: 28)
                )

                // Fecha alineada a la derecha
                let dateStr = "Generado: \(fullDateFmt.string(from: Date()))"
                let dateAttrs: [NSAttributedString.Key: Any] = [
                    .font: subtitleFont,
                    .foregroundColor: UIColor.white.withAlphaComponent(0.80)
                ]
                let dateSize = (dateStr as NSString).size(withAttributes: dateAttrs)
                (dateStr as NSString).draw(
                    at: CGPoint(
                        x: pageRect.width - margin - dateSize.width,
                        y: (headerBandH - dateSize.height) / 2
                    ),
                    withAttributes: dateAttrs
                )

                y = headerTotal + 16
            }

            // MARK: Footer

            func drawFooter() {
                let cg = ctx.cgContext
                let footerY = pageRect.height - margin + 4

                cg.saveGState()
                cg.setStrokeColor(brandAccent.withAlphaComponent(0.3).cgColor)
                cg.setLineWidth(0.5)
                cg.move(to:    CGPoint(x: margin, y: footerY - 3))
                cg.addLine(to: CGPoint(x: pageRect.width - margin, y: footerY - 3))
                cg.strokePath()
                cg.restoreGState()

                drawText(
                    "VisionWow · Reporte Corporativo",
                    font: footerFont, color: brandAccent.withAlphaComponent(0.55),
                    rect: CGRect(x: margin, y: footerY, width: 200, height: 10)
                )
                drawText(
                    "Pág. \(pageNum)",
                    font: footerFont, color: .gray,
                    rect: CGRect(x: pageRect.width - margin - 40, y: footerY, width: 40, height: 10),
                    align: .right
                )
                pageNum += 1
            }

            // MARK: New page

            func newPage() {
                drawFooter()
                ctx.beginPage()
                y = margin
                drawHeader()
            }

            // MARK: Card

            func drawCard(title: String, height: CGFloat, draw: (CGRect) -> Void) {
                if y + height > pageRect.height - margin - 12 {
                    newPage()
                    drawCard(title: title, height: height, draw: draw)
                    return
                }

                let cg = ctx.cgContext
                let rect = CGRect(x: margin, y: y, width: contentW, height: height)

                cg.saveGState()
                cg.setFillColor(cardBG.cgColor)
                cg.fill(rect)
                cg.setStrokeColor(brandPrimary.withAlphaComponent(0.22).cgColor)
                cg.setLineWidth(1)
                cg.stroke(rect)
                cg.restoreGState()

                // Section title bar
                let titleBar = CGRect(x: margin, y: y, width: contentW, height: 22)
                cg.saveGState()
                cg.setFillColor(brandPrimary.withAlphaComponent(0.12).cgColor)
                cg.fill(titleBar)
                cg.restoreGState()

                drawText(
                    title, font: sectionFont, color: brandSecondary,
                    rect: CGRect(x: margin + 10, y: y + 4, width: contentW - 20, height: 16)
                )

                let inner = CGRect(
                    x: margin + 14, y: y + 32,
                    width: contentW - 28, height: height - 44
                )
                draw(inner)

                y += height + 14
            }

            // MARK: Pill

            func drawPill(_ label: String, value: String, color: UIColor, x: CGFloat, y0: CGFloat, w: CGFloat) {
                let cg = ctx.cgContext
                let rect = CGRect(x: x, y: y0, width: w, height: 48)
                cg.saveGState()
                cg.setFillColor(UIColor.white.cgColor)
                cg.fill(rect)
                cg.setStrokeColor(brandPrimary.withAlphaComponent(0.18).cgColor)
                cg.setLineWidth(1)
                cg.stroke(rect)
                cg.restoreGState()

                drawText(
                    label, font: UIFont.systemFont(ofSize: 9, weight: .semibold), color: .darkGray,
                    rect: CGRect(x: rect.minX + 10, y: rect.minY + 7, width: rect.width - 20, height: 13)
                )
                drawText(
                    value, font: UIFont.systemFont(ofSize: 18, weight: .bold), color: color,
                    rect: CGRect(x: rect.minX + 10, y: rect.minY + 22, width: rect.width - 20, height: 22)
                )
            }

            // MARK: Donut chart

            func drawDonutChart(yes: Int, no: Int, rect: CGRect) {
                let cg = ctx.cgContext
                let total = max(1, yes + no)
                let yesPct = CGFloat(yes) / CGFloat(total)

                let size = min(rect.width * 0.40, rect.height)
                let donutRect = CGRect(x: rect.minX, y: rect.minY, width: size, height: size)
                let center = CGPoint(x: donutRect.midX, y: donutRect.midY)
                let radius = min(donutRect.width, donutRect.height) / 2.0
                let lineW: CGFloat = 16
                let start = -CGFloat.pi / 2
                let yesEnd = start + (2 * CGFloat.pi * yesPct)

                cg.saveGState()
                cg.setLineWidth(lineW)
                cg.setStrokeColor(noColor.cgColor)
                cg.addArc(center: center, radius: radius - lineW / 2,
                          startAngle: 0, endAngle: 2 * .pi, clockwise: false)
                cg.strokePath()
                cg.setStrokeColor(yesColor.cgColor)
                cg.addArc(center: center, radius: radius - lineW / 2,
                          startAngle: start, endAngle: yesEnd, clockwise: false)
                cg.strokePath()
                cg.restoreGState()

                drawText(
                    "\(Int(round(yesPct * 100)))%",
                    font: UIFont.boldSystemFont(ofSize: 18), color: brandSecondary,
                    rect: CGRect(x: donutRect.minX, y: donutRect.midY - 12,
                                 width: donutRect.width, height: 24),
                    align: .center
                )
                drawText(
                    "Sí",
                    font: UIFont.systemFont(ofSize: 10), color: .darkGray,
                    rect: CGRect(x: donutRect.minX, y: donutRect.midY + 12,
                                 width: donutRect.width, height: 14),
                    align: .center
                )

                // Legend
                let legendX = donutRect.maxX + 18
                let legendW = rect.maxX - legendX

                func legendRow(y0: CGFloat, color: UIColor, label: String, value: Int) {
                    let dot = CGRect(x: legendX, y: y0 + 3, width: 10, height: 10)
                    cg.saveGState()
                    cg.setFillColor(color.cgColor)
                    cg.fillEllipse(in: dot)
                    cg.restoreGState()
                    drawText(label, font: bodyFont, color: .darkGray,
                             rect: CGRect(x: legendX + 16, y: y0, width: legendW * 0.70, height: 16))
                    drawText("\(value)", font: bodyBoldFont, color: .darkGray,
                             rect: CGRect(x: legendX + legendW * 0.72, y: y0,
                                          width: legendW * 0.28, height: 16), align: .right)
                }

                legendRow(y0: rect.minY + 10, color: yesColor,    label: "Sí",              value: yes)
                legendRow(y0: rect.minY + 30, color: noColor,     label: "No",              value: no)
                legendRow(y0: rect.minY + 56, color: .clear,      label: "Total revisados", value: yes + no)
            }

            // MARK: Stacked bars

            func drawStackedBars(total: Int, dataYesCounts: [(String, Int)], rect: CGRect) {
                let cg = ctx.cgContext

                // Legend header
                func legendDot(x: CGFloat, y0: CGFloat, color: UIColor) {
                    cg.saveGState()
                    cg.setFillColor(color.cgColor)
                    cg.fillEllipse(in: CGRect(x: x, y: y0, width: 10, height: 10))
                    cg.restoreGState()
                }

                let legendY = rect.minY
                legendDot(x: rect.minX, y0: legendY, color: yesColor)
                drawText("Sí", font: bodyFont, color: .darkGray,
                         rect: CGRect(x: rect.minX + 14, y: legendY - 2, width: 30, height: 14))
                legendDot(x: rect.minX + 50, y0: legendY, color: noColor)
                drawText("No", font: bodyFont, color: .darkGray,
                         rect: CGRect(x: rect.minX + 64, y: legendY - 2, width: 30, height: 14))

                let tableTop = rect.minY + 20
                let rowH: CGFloat = 18
                let labelW = rect.width * 0.44
                let barW   = rect.width * 0.38
                let numW   = rect.width - labelW - barW
                var yRow   = tableTop
                let safeTotal = max(1, total)

                for (label, yesCount) in dataYesCounts {
                    if yRow + rowH > rect.maxY { break }
                    let noCount = max(0, safeTotal - yesCount)

                    drawText(label, font: bodyFont, color: .darkGray,
                             rect: CGRect(x: rect.minX, y: yRow, width: labelW - 6, height: rowH))

                    let barX   = rect.minX + labelW
                    let barRect = CGRect(x: barX, y: yRow + 3, width: barW, height: rowH - 6)
                    let yesW    = barRect.width * (CGFloat(yesCount) / CGFloat(safeTotal))

                    cg.saveGState()
                    cg.setFillColor(noColor.cgColor)
                    cg.fill(barRect)
                    cg.setFillColor(yesColor.cgColor)
                    cg.fill(CGRect(x: barRect.minX, y: barRect.minY, width: yesW, height: barRect.height))
                    cg.setStrokeColor(brandAccent.withAlphaComponent(0.3).cgColor)
                    cg.setLineWidth(0.5)
                    cg.stroke(barRect)
                    cg.restoreGState()

                    drawText("\(yesCount) / \(noCount)", font: bodyBoldFont, color: .darkGray,
                             rect: CGRect(x: rect.minX + labelW + barW + 6, y: yRow,
                                          width: numW - 6, height: rowH), align: .right)
                    yRow += rowH
                }
            }

            // MARK: Bar chart

            func drawBarChart(data: [(String, Int)], rect: CGRect) {
                let cg = ctx.cgContext
                let maxValue = max(1, data.map { $0.1 }.max() ?? 1)
                let barH: CGFloat = 14
                let gap:  CGFloat = 10
                var yBar  = rect.minY

                for (label, value) in data.prefix(10) {
                    if yBar + barH > rect.maxY { break }
                    let pct  = CGFloat(value) / CGFloat(maxValue)
                    let barW = (rect.width * 0.60) * pct
                    let barX = rect.minX + rect.width * 0.38

                    drawText(label, font: bodyFont, color: .darkGray,
                             rect: CGRect(x: rect.minX, y: yBar - 1, width: rect.width * 0.36, height: barH + 2))

                    cg.saveGState()
                    cg.setFillColor(brandPrimary.withAlphaComponent(0.82).cgColor)
                    cg.fill(CGRect(x: barX, y: yBar, width: barW, height: barH))
                    cg.restoreGState()

                    drawText("\(value)", font: bodyBoldFont, color: .darkGray,
                             rect: CGRect(x: barX + barW + 6, y: yBar - 1,
                                          width: rect.maxX - (barX + barW + 6), height: barH + 2))
                    yBar += barH + gap
                }
            }

            // ── PDF START ──────────────────────────────────────────────────────

            ctx.beginPage()
            drawHeader()

            // Resumen / KPIs
            if includeOverview {
                drawCard(title: "Resumen ejecutivo", height: 130) { rect in
                    let colW = (rect.width - 20) / 3
                    drawPill("Pacientes revisados", value: "\(summary.totalEncounters)",
                             color: brandSecondary,
                             x: rect.minX, y0: rect.minY, w: colW)
                    drawPill("Compraron lentes", value: "\(summary.boughtCount)",
                             color: brandPrimary,
                             x: rect.minX + colW + 10, y0: rect.minY, w: colW)
                    drawPill("Tasa de compra", value: "\(summary.buyRatePercent)%",
                             color: brandSuccess,
                             x: rect.minX + (colW + 10) * 2, y0: rect.minY, w: colW)
                    drawText(
                        "Las métricas se calculan sobre el total de pacientes revisados en este reporte.",
                        font: bodyFont, color: .gray,
                        rect: CGRect(x: rect.minX, y: rect.minY + 58, width: rect.width, height: 24)
                    )
                }
            }

            // Conversión compra
            if includePaymentStats {
                drawCard(title: "Conversión · Compraron lentes (Sí / No)", height: 180) { rect in
                    drawDonutChart(yes: summary.boughtCount, no: summary.notBoughtCount, rect: rect)
                }
            }

            // Dioptrías
            if includeDiopterStats {
                let diopData = summary.diopterDistribution.map { ($0.label, $0.count) }
                drawCard(title: "Distribución de graduación (dioptrías — esfera)", height: 220) { rect in
                    drawBarChart(data: diopData, rect: rect)
                }
            }

            // Antecedentes: Top con barras apiladas Sí/No
            if includeAntecedentStats {
                let top = summary.topAntecedents
                drawCard(title: "Antecedentes / síntomas — Top 10 (Sí vs No)", height: 280) { rect in
                    drawStackedBars(total: summary.totalEncounters, dataYesCounts: top, rect: rect)
                }

                if !selectedAntecedentKeys.isEmpty {
                    let selectedData = summary.antecedentCountsSelectedFilterKeys
                        .sorted { $0.value > $1.value }
                        .map { ($0.key, $0.value) }
                    drawCard(title: "Filtros seleccionados (Sí vs No)", height: 240) { rect in
                        drawStackedBars(total: summary.totalEncounters, dataYesCounts: selectedData, rect: rect)
                    }
                }
            }

            // Lista de pacientes
            if includePatientList {
                drawCard(title: "Listado de pacientes revisados", height: 340) { rect in
                    let cg = ctx.cgContext
                    let colW = rect.width
                    let rowH: CGFloat = 18
                    var yRow = rect.minY

                    func row(_ left: String, _ right: String, bold: Bool = false, rowIdx: Int = -1) {
                        if rowIdx >= 0 {
                            let bg: UIColor = rowIdx % 2 == 0 ? .white : brandSoft.withAlphaComponent(0.18)
                            cg.saveGState()
                            cg.setFillColor(bg.cgColor)
                            cg.fill(CGRect(x: rect.minX, y: yRow, width: colW, height: rowH))
                            cg.restoreGState()
                        }
                        let font = bold ? bodyBoldFont : bodyFont
                        drawText(left,  font: font, color: bold ? brandSecondary : .darkGray,
                                 rect: CGRect(x: rect.minX + 4, y: yRow, width: colW * 0.70, height: rowH))
                        drawText(right, font: font, color: bold ? brandSecondary : .darkGray,
                                 rect: CGRect(x: rect.minX + colW * 0.72, y: yRow,
                                              width: colW * 0.28, height: rowH), align: .right)
                        cg.saveGState()
                        cg.setStrokeColor(brandSoft.cgColor)
                        cg.setLineWidth(0.5)
                        cg.stroke(CGRect(x: rect.minX, y: yRow + rowH - 1, width: colW, height: 0.5))
                        cg.restoreGState()
                        yRow += rowH
                    }

                    // Column header row
                    cg.saveGState()
                    cg.setFillColor(brandPrimary.withAlphaComponent(0.88).cgColor)
                    cg.fill(CGRect(x: rect.minX, y: yRow, width: colW, height: rowH))
                    cg.restoreGState()
                    let hdrAttrs: [NSAttributedString.Key: Any] = [
                        .font: bodyBoldFont, .foregroundColor: UIColor.white
                    ]
                    "Paciente".draw(
                        in: CGRect(x: rect.minX + 4, y: yRow, width: colW * 0.70, height: rowH),
                        withAttributes: hdrAttrs
                    )
                    "Compra".draw(
                        in: CGRect(x: rect.minX + colW * 0.72, y: yRow, width: colW * 0.28, height: rowH),
                        withAttributes: hdrAttrs
                    )
                    yRow += rowH

                    for (idx, e) in encounters.prefix(16).enumerated() {
                        if yRow > rect.maxY - rowH { break }
                        let name = [
                            (e.patient?.firstName ?? "").trimmingCharacters(in: .whitespacesAndNewlines),
                            (e.patient?.lastName  ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
                        ].filter { !$0.isEmpty }.joined(separator: " ")
                        let buy = ReportComputer.didBuy(e) ? "Sí" : "No"
                        row(name.isEmpty ? "Paciente" : name, buy, rowIdx: idx)
                    }
                }
            }

            drawFooter()
        }

        return url
    }
}

private extension String {
    var sanitizedFileName: String {
        let invalid = CharacterSet(charactersIn: "/\\?%*|\"<>:")
        return self.components(separatedBy: invalid).joined(separator: "-")
    }
}
