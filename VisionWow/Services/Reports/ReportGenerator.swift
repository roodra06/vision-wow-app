//
//  ReportGenerator.swift
//  VisionWow
//
//  Created by Rodrigo Marcos on 19/02/26.
//

import Foundation
import UIKit

struct ReportGenerator {

    // ✅ Conserva tu generateCSV como lo tengas (aquí lo dejo como stub)
    static func generateCSV(company: Company, encounters: [Encounter]) throws -> URL {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("Reporte-\(company.name.sanitizedFileName)-\(Date().timeIntervalSince1970).csv")
        try "pendiente".write(to: url, atomically: true, encoding: .utf8)
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

        let pageRect = CGRect(x: 0, y: 0, width: 595, height: 842) // A4 @72dpi
        let margin: CGFloat = 40
        let contentWidth = pageRect.width - (margin * 2)

        let renderer = UIGraphicsPDFRenderer(bounds: pageRect)

        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("Reporte-\(company.name.sanitizedFileName)-\(Date().timeIntervalSince1970).pdf")

        // Paleta corporativa simple
        let primary = UIColor(red: 0.58, green: 0.17, blue: 0.94, alpha: 1.0) // morado
        let accent  = UIColor(red: 0.98, green: 0.24, blue: 0.75, alpha: 1.0) // magenta
        let text    = UIColor.black
        let subtext = UIColor.darkGray
        let cardBG  = UIColor(white: 0.97, alpha: 1.0)
        let yesColor = accent.withAlphaComponent(0.85)      // “Sí”
        let noColor  = UIColor(white: 0.85, alpha: 1.0)     // “No”

        try renderer.writePDF(to: url) { ctx in
            var y: CGFloat = 0

            func newPage() {
                ctx.beginPage()
                y = margin
                drawHeader()
            }

            func drawHeader() {
                let headerRect = CGRect(x: 0, y: 0, width: pageRect.width, height: 92)
                let cg = ctx.cgContext
                cg.saveGState()
                cg.setFillColor(primary.withAlphaComponent(0.10).cgColor)
                cg.fill(headerRect)

                cg.setFillColor(accent.cgColor)
                cg.fill(CGRect(x: 0, y: 92, width: pageRect.width, height: 3))
                cg.restoreGState()

                drawText("VisionWow — Reporte corporativo", font: .boldSystemFont(ofSize: 16), color: text,
                         rect: CGRect(x: margin, y: 18, width: contentWidth, height: 22))

                drawText(company.name, font: .boldSystemFont(ofSize: 24), color: primary,
                         rect: CGRect(x: margin, y: 40, width: contentWidth, height: 28))

                drawText("Generado: \(Date().formatted(date: .long, time: .shortened))",
                         font: .systemFont(ofSize: 11), color: subtext,
                         rect: CGRect(x: margin, y: 70, width: contentWidth, height: 16))

                y = 110
            }

            func drawCard(title: String, height: CGFloat, draw: (CGRect) -> Void) {
                let rect = CGRect(x: margin, y: y, width: contentWidth, height: height)

                if rect.maxY > pageRect.height - margin {
                    newPage()
                    return drawCard(title: title, height: height, draw: draw)
                }

                let cg = ctx.cgContext
                cg.saveGState()
                cg.setFillColor(cardBG.cgColor)
                cg.fill(rect)
                cg.setStrokeColor(primary.withAlphaComponent(0.18).cgColor)
                cg.setLineWidth(1)
                cg.stroke(rect)
                cg.restoreGState()

                drawText(title, font: .boldSystemFont(ofSize: 14), color: text,
                         rect: CGRect(x: rect.minX + 14, y: rect.minY + 12, width: rect.width - 28, height: 18))

                let inner = CGRect(x: rect.minX + 14, y: rect.minY + 36, width: rect.width - 28, height: rect.height - 50)
                draw(inner)

                y = rect.maxY + 14
            }

            func drawText(_ text: String, font: UIFont, color: UIColor, rect: CGRect, align: NSTextAlignment = .left) {
                let paragraph = NSMutableParagraphStyle()
                paragraph.alignment = align
                paragraph.lineBreakMode = .byTruncatingTail

                let attrs: [NSAttributedString.Key: Any] = [
                    .font: font,
                    .foregroundColor: color,
                    .paragraphStyle: paragraph
                ]
                (text as NSString).draw(in: rect, withAttributes: attrs)
            }

            func drawPill(_ label: String, value: String, x: CGFloat, y: CGFloat, w: CGFloat) {
                let cg = ctx.cgContext
                let h: CGFloat = 44
                let rect = CGRect(x: x, y: y, width: w, height: h)

                cg.saveGState()
                cg.setFillColor(UIColor.white.cgColor)
                cg.fill(rect)
                cg.setStrokeColor(primary.withAlphaComponent(0.16).cgColor)
                cg.setLineWidth(1)
                cg.stroke(rect)
                cg.restoreGState()

                drawText(label, font: .systemFont(ofSize: 10), color: subtext,
                         rect: CGRect(x: rect.minX + 10, y: rect.minY + 7, width: rect.width - 20, height: 12))
                drawText(value, font: .boldSystemFont(ofSize: 16), color: text,
                         rect: CGRect(x: rect.minX + 10, y: rect.minY + 20, width: rect.width - 20, height: 20))
            }

            // MARK: - Donut chart (Sí / No)
            func drawDonutChart(
                title: String,
                yes: Int,
                no: Int,
                rect: CGRect
            ) {
                let cg = ctx.cgContext

                drawText(title, font: .systemFont(ofSize: 12, weight: .semibold), color: subtext,
                         rect: CGRect(x: rect.minX, y: rect.minY, width: rect.width, height: 16))

                let total = max(1, yes + no)
                let yesPct = CGFloat(yes) / CGFloat(total)

                let size = min(rect.width * 0.40, rect.height - 22)
                let donutRect = CGRect(x: rect.minX, y: rect.minY + 22, width: size, height: size)

                let center = CGPoint(x: donutRect.midX, y: donutRect.midY)
                let radius = min(donutRect.width, donutRect.height) / 2.0
                let lineW: CGFloat = 14

                let start = -CGFloat.pi / 2
                let yesEnd = start + (2 * CGFloat.pi * yesPct)

                // Track (No / base)
                cg.saveGState()
                cg.setLineWidth(lineW)
                cg.setStrokeColor(noColor.cgColor)
                cg.addArc(center: center, radius: radius - lineW/2, startAngle: 0, endAngle: 2 * .pi, clockwise: false)
                cg.strokePath()

                // Yes arc
                cg.setStrokeColor(yesColor.cgColor)
                cg.addArc(center: center, radius: radius - lineW/2, startAngle: start, endAngle: yesEnd, clockwise: false)
                cg.strokePath()
                cg.restoreGState()

                // Center text
                drawText("\(Int(round(yesPct * 100)))%", font: .boldSystemFont(ofSize: 18), color: text,
                         rect: CGRect(x: donutRect.minX, y: donutRect.midY - 12, width: donutRect.width, height: 24),
                         align: .center)

                drawText("Sí", font: .systemFont(ofSize: 10), color: subtext,
                         rect: CGRect(x: donutRect.minX, y: donutRect.midY + 12, width: donutRect.width, height: 14),
                         align: .center)

                // Legend right
                let legendX = donutRect.maxX + 18
                let legendW = rect.maxX - legendX

                func legendRow(y0: CGFloat, color: UIColor, label: String, value: Int) {
                    let dot = CGRect(x: legendX, y: y0 + 3, width: 10, height: 10)
                    cg.saveGState()
                    cg.setFillColor(color.cgColor)
                    cg.fillEllipse(in: dot)
                    cg.restoreGState()

                    drawText(label, font: .systemFont(ofSize: 11), color: text,
                             rect: CGRect(x: legendX + 16, y: y0, width: legendW * 0.70, height: 16))
                    drawText("\(value)", font: .systemFont(ofSize: 11, weight: .semibold), color: subtext,
                             rect: CGRect(x: legendX + legendW * 0.72, y: y0, width: legendW * 0.28, height: 16),
                             align: .right)
                }

                legendRow(y0: rect.minY + 28, color: yesColor, label: "Sí", value: yes)
                legendRow(y0: rect.minY + 48, color: noColor, label: "No", value: no)
                legendRow(y0: rect.minY + 74, color: UIColor.clear, label: "Total revisados", value: yes + no)
            }

            // MARK: - Stacked Yes/No bar list (Top N)
            func drawYesNoStackedBars(
                title: String,
                total: Int,
                dataYesCounts: [(String, Int)], // label -> yesCount
                rect: CGRect
            ) {
                drawText(title, font: .systemFont(ofSize: 12, weight: .semibold), color: subtext,
                         rect: CGRect(x: rect.minX, y: rect.minY, width: rect.width, height: 16))

                // Legend
                let legendY = rect.minY + 18
                drawLegendDot(x: rect.minX, y: legendY, color: yesColor)
                drawText("Sí", font: .systemFont(ofSize: 10), color: text,
                         rect: CGRect(x: rect.minX + 14, y: legendY - 2, width: 40, height: 14))
                drawLegendDot(x: rect.minX + 54, y: legendY, color: noColor)
                drawText("No", font: .systemFont(ofSize: 10), color: text,
                         rect: CGRect(x: rect.minX + 68, y: legendY - 2, width: 40, height: 14))

                let tableTop = rect.minY + 36
                let rowH: CGFloat = 18
                let maxRows = Int((rect.maxY - tableTop) / rowH)

                // Columns
                let labelW = rect.width * 0.45
                let barW   = rect.width * 0.37
                let numW   = rect.width - labelW - barW

                var yRow = tableTop
                let safeTotal = max(1, total)

                for (label, yesCount) in dataYesCounts.prefix(maxRows) {
                    let noCount = max(0, safeTotal - yesCount)

                    // label
                    drawText(label, font: .systemFont(ofSize: 10), color: text,
                             rect: CGRect(x: rect.minX, y: yRow, width: labelW - 6, height: rowH))

                    // stacked bar
                    let barX = rect.minX + labelW
                    let barRect = CGRect(x: barX, y: yRow + 3, width: barW, height: rowH - 6)

                    let yesW = barRect.width * (CGFloat(yesCount) / CGFloat(safeTotal))
                    let noW  = barRect.width - yesW

                    let cg = ctx.cgContext
                    cg.saveGState()
                    cg.setFillColor(noColor.cgColor)
                    cg.fill(barRect)

                    cg.setFillColor(yesColor.cgColor)
                    cg.fill(CGRect(x: barRect.minX, y: barRect.minY, width: yesW, height: barRect.height))

                    cg.setStrokeColor(UIColor(white: 0.75, alpha: 1).cgColor)
                    cg.setLineWidth(0.6)
                    cg.stroke(barRect)
                    cg.restoreGState()

                    // numbers “yes / no”
                    let numText = "\(yesCount) / \(noCount)"
                    drawText(numText, font: .systemFont(ofSize: 10, weight: .semibold), color: subtext,
                             rect: CGRect(x: rect.minX + labelW + barW + 6, y: yRow, width: numW - 6, height: rowH),
                             align: .right)

                    yRow += rowH
                    if yRow + rowH > rect.maxY { break }
                }

                func drawLegendDot(x: CGFloat, y: CGFloat, color: UIColor) {
                    let cg = ctx.cgContext
                    cg.saveGState()
                    cg.setFillColor(color.cgColor)
                    cg.fillEllipse(in: CGRect(x: x, y: y, width: 10, height: 10))
                    cg.restoreGState()
                }
            }

            func drawBarChart(title: String, data: [(String, Int)], rect: CGRect) {
                let cg = ctx.cgContext

                drawText(title, font: .systemFont(ofSize: 12, weight: .semibold), color: subtext,
                         rect: CGRect(x: rect.minX, y: rect.minY, width: rect.width, height: 16))

                let chartRect = CGRect(x: rect.minX, y: rect.minY + 20, width: rect.width, height: rect.height - 20)

                let maxValue = max(1, data.map { $0.1 }.max() ?? 1)
                let barH: CGFloat = 14
                let gap: CGFloat = 10

                var yBar = chartRect.minY
                for (label, value) in data.prefix(10) {
                    if yBar + barH > chartRect.maxY { break }

                    let pct = CGFloat(value) / CGFloat(maxValue)
                    let barW = (chartRect.width * 0.62) * pct

                    drawText(label, font: .systemFont(ofSize: 10), color: text,
                             rect: CGRect(x: chartRect.minX, y: yBar - 1, width: chartRect.width * 0.36, height: barH + 2))

                    let barX = chartRect.minX + chartRect.width * 0.38
                    let barRect = CGRect(x: barX, y: yBar, width: barW, height: barH)

                    cg.saveGState()
                    cg.setFillColor(primary.withAlphaComponent(0.85).cgColor)
                    cg.fill(barRect)
                    cg.restoreGState()

                    drawText("\(value)", font: .systemFont(ofSize: 10, weight: .semibold), color: subtext,
                             rect: CGRect(x: barX + barW + 6, y: yBar - 1, width: chartRect.maxX - (barX + barW + 6), height: barH + 2))

                    yBar += barH + gap
                }
            }

            // ======= PDF START =======
            newPage()

            // Resumen / KPIs
            if includeOverview {
                drawCard(title: "Resumen ejecutivo", height: 130) { rect in
                    let colW = (rect.width - 20) / 3
                    drawPill("Pacientes revisados", value: "\(summary.totalEncounters)",
                             x: rect.minX, y: rect.minY, w: colW)

                    drawPill("Compraron lentes", value: "\(summary.boughtCount)",
                             x: rect.minX + colW + 10, y: rect.minY, w: colW)

                    drawPill("Tasa de compra", value: "\(summary.buyRatePercent)%",
                             x: rect.minX + (colW + 10) * 2, y: rect.minY, w: colW)

                    drawText("Periodo: Todo el histórico", font: .systemFont(ofSize: 11), color: subtext,
                             rect: CGRect(x: rect.minX, y: rect.minY + 58, width: rect.width, height: 16))
                    drawText("Nota: las métricas se calculan sobre el total de pacientes revisados en este reporte.",
                             font: .systemFont(ofSize: 10), color: subtext,
                             rect: CGRect(x: rect.minX, y: rect.minY + 76, width: rect.width, height: 34))
                }
            }

            // Compra: ahora con DONA “Sí/No” del total
            if includePaymentStats {
                drawCard(title: "Conversión / compra (sobre el total)", height: 190) { rect in
                    let yes = summary.boughtCount
                    let no = summary.notBoughtCount
                    drawDonutChart(title: "Compraron lentes", yes: yes, no: no, rect: rect)
                }
            }

            // Dioptrías
            if includeDiopterStats {
                let diopData = summary.diopterDistribution.map { ($0.label, $0.count) }
                drawCard(title: "Distribución de graduación (dioptrías – esfera)", height: 220) { rect in
                    drawBarChart(title: "Distribución por rangos", data: diopData, rect: rect)
                }
            }

            // Antecedentes: Top con barras apiladas Sí/No
            if includeAntecedentStats {
                let total = summary.totalEncounters

                // Top global marcado por pacientes
                let top = summary.topAntecedents // [(String, Int)] ya viene ordenado

                drawCard(title: "Antecedentes / síntomas (Top 10 — Sí vs No)", height: 280) { rect in
                    drawYesNoStackedBars(
                        title: "Del total revisado (\(total)), cuántos SÍ lo marcaron y cuántos NO",
                        total: total,
                        dataYesCounts: top,
                        rect: rect
                    )
                }

                // Bloque extra: si usaron filtros en el builder, reflejarlo también
                if !selectedAntecedentKeys.isEmpty {
                    let selectedData = summary.antecedentCountsSelectedFilterKeys
                        .sorted { $0.value > $1.value }
                        .map { ($0.key, $0.value) }

                    drawCard(title: "Filtros seleccionados (Sí vs No)", height: 240) { rect in
                        drawYesNoStackedBars(
                            title: "Frecuencia de los filtros elegidos (sobre el total del reporte)",
                            total: total,
                            dataYesCounts: selectedData,
                            rect: rect
                        )
                    }
                }
            }

            // Lista de pacientes (compacta)
            if includePatientList {
                drawCard(title: "Listado (extracto)", height: 330) { rect in
                    let cg = ctx.cgContext
                    cg.saveGState()
                    cg.setStrokeColor(UIColor(white: 0.85, alpha: 1).cgColor)
                    cg.setLineWidth(1)

                    var yRow = rect.minY
                    let rowH: CGFloat = 18

                    func row(_ left: String, _ right: String, bold: Bool = false) {
                        let font = bold ? UIFont.boldSystemFont(ofSize: 10) : UIFont.systemFont(ofSize: 10)
                        drawText(left, font: font, color: text,
                                 rect: CGRect(x: rect.minX, y: yRow, width: rect.width * 0.70, height: rowH))
                        drawText(right, font: font, color: subtext,
                                 rect: CGRect(x: rect.minX + rect.width * 0.72, y: yRow, width: rect.width * 0.28, height: rowH),
                                 align: .right)
                        yRow += rowH
                        cg.stroke(CGRect(x: rect.minX, y: yRow - 2, width: rect.width, height: 1))
                    }

                    row("Paciente", "Compra", bold: true)

                    for e in encounters.prefix(14) {
                        let name = [
                            (e.patient?.firstName ?? "").trimmingCharacters(in: .whitespacesAndNewlines),
                            (e.patient?.lastName ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
                        ].filter { !$0.isEmpty }.joined(separator: " ")
                        let buy = ReportComputer.didBuy(e) ? "Sí" : "No"
                        row(name.isEmpty ? "Paciente" : name, buy)
                        if yRow > rect.maxY - rowH { break }
                    }

                    cg.restoreGState()
                }
            }
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
