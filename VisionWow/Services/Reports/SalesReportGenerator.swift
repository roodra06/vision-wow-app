//
//  SalesReportGenerator.swift
//  VisionWow
//

import UIKit
import PDFKit

enum SalesReportGenerator {

    // MARK: - Brand Colors (UIKit)
    // Fuente: Colors.swift → BrandColors

    private static let brandPrimary   = UIColor(red: 0.906, green: 0.220, blue: 0.498, alpha: 1) // #E7387F magenta
    private static let brandSecondary = UIColor(red: 0.463, green: 0.224, blue: 0.463, alpha: 1) // #763976 morado
    private static let brandAccent    = UIColor(red: 0.714, green: 0.451, blue: 0.678, alpha: 1) // #B673AD lavanda
    private static let brandSoft      = UIColor(red: 0.918, green: 0.816, blue: 0.878, alpha: 1) // #EAD0E0 rosa suave
    private static let brandWarning   = UIColor(red: 0.753, green: 0.478, blue: 0.173, alpha: 1) // #C07A2C ámbar
    private static let brandSuccess   = UIColor(red: 0.180, green: 0.545, blue: 0.424, alpha: 1) // #2E8B6C verde

    // MARK: - CSV

    static func generateCSV(companyName: String, encounters: [Encounter]) throws -> URL {
        var lines: [String] = []

        lines.append([
            "Fecha", "Paciente", "Optometrista", "Total Venta",
            "Descuento", "Método Pago", "Estatus", "A Cuenta", "Resta por Pagar",
            "Inversión Lente", "Garantía"
        ].map { "\"\($0)\"" }.joined(separator: ","))

        let fmt = DateFormatter()
        fmt.dateStyle = .short
        fmt.timeStyle = .none
        fmt.locale = Locale(identifier: "es_MX")

        for enc in encounters {
            let resta = calcResta(enc)
            let row: [String] = [
                fmt.string(from: enc.createdAt),
                enc.patientFullName.isEmpty ? "Sin nombre" : enc.patientFullName,
                enc.optometristName ?? "",
                enc.payTotal,
                formatDiscount(enc.payDiscount),
                enc.payMethod, enc.payStatus,
                enc.payDeposit,
                resta > 0 ? String(format: "%.2f", resta) : "0.00",
                enc.lensCost,
                enc.isGuarantee ? (enc.guaranteeReason ?? "Sí") : ""
            ]
            lines.append(row.map { "\"\($0.replacingOccurrences(of: "\"", with: "\"\""))\"" }.joined(separator: ","))
        }

        let data = (lines.joined(separator: "\n")).data(using: .utf8) ?? Data()
        return try saveToDocuments(data: data, fileName: csvFileName(companyName: companyName), ext: "csv")
    }

    // MARK: - PDF (Landscape A4 · branding completo)

    static func generatePDF(companyName: String, encounters: [Encounter]) throws -> URL {
        let logo = UIImage(named: "visionwow_logo")

        // Landscape A4
        let pageW: CGFloat = 841.89
        let pageH: CGFloat = 595.28
        let margin: CGFloat = 24
        let contentW = pageW - margin * 2

        // Layout constants
        let headerBandH: CGFloat = 56   // franja de color con logo
        let summaryH: CGFloat    = 44   // resumen de totales
        let colHdrH: CGFloat     = 22   // fila de encabezados de columna
        let rowH: CGFloat        = 18   // altura de cada fila de datos
        let sectionPad: CGFloat  = 6    // separación entre bloques

        // Filas disponibles por página
        let firstPageUsed = headerBandH + sectionPad + summaryH + sectionPad + colHdrH
        let rowsPerFirstPage = max(1, Int((pageH - firstPageUsed - margin) / rowH))
        let rowsPerOtherPage = max(1, Int((pageH - margin - colHdrH - margin) / rowH))

        // Columnas: (título, peso relativo)
        let cols: [(String, CGFloat)] = [
            ("Fecha",        6),
            ("Paciente",     12),
            ("Optometrista", 10),
            ("Total",        7),
            ("Descuento",    9),
            ("Método",       8),
            ("Estatus",      8),
            ("A Cuenta",     7),
            ("Resta",        7),
            ("Inversión",    7),
            ("Garantía",     7)
        ]
        let totalWeight  = cols.reduce(0) { $0 + $1.1 }
        let colWidths    = cols.map { $0.1 / totalWeight * contentW }

        // Colores
        let altRowBg    = brandSoft.withAlphaComponent(0.18)
        let guaranteeBg = brandSoft.withAlphaComponent(0.55)
        let borderColor = brandAccent.withAlphaComponent(0.22)

        // Fuentes
        let titleFont       = UIFont.systemFont(ofSize: 15, weight: .bold)
        let subtitleFont    = UIFont.systemFont(ofSize: 8,  weight: .regular)
        let summaryLblFont  = UIFont.systemFont(ofSize: 7,  weight: .semibold)
        let summaryValFont  = UIFont.systemFont(ofSize: 11, weight: .bold)
        let colHdrFont      = UIFont.systemFont(ofSize: 8,  weight: .bold)
        let cellFont        = UIFont.systemFont(ofSize: 8,  weight: .regular)
        let cellBoldFont    = UIFont.systemFont(ofSize: 8,  weight: .semibold)
        let footerFont      = UIFont.systemFont(ofSize: 7,  weight: .light)

        let dateFmt = DateFormatter()
        dateFmt.dateFormat = "dd/MM/yy"
        let fullDateFmt = DateFormatter()
        fullDateFmt.dateStyle = .long
        fullDateFmt.timeStyle = .none
        fullDateFmt.locale = Locale(identifier: "es_MX")

        // Totales para resumen
        let totalVentas    = encounters.reduce(0.0) { $0 + (Double($1.payTotal)   ?? 0) }
        let totalDeposit   = encounters.reduce(0.0) { $0 + (Double($1.payDeposit) ?? 0) }
        let totalResta     = encounters.reduce(0.0) { $0 + calcResta($1) }
        let totalInversion = encounters.reduce(0.0) { $0 + (Double($1.lensCost)   ?? 0) }

        // ── Helpers de dibujo ────────────────────────────────────────

        func drawGradientRect(cgCtx: CGContext, rect: CGRect,
                              from: UIColor, to: UIColor, horizontal: Bool = true) {
            cgCtx.saveGState()
            cgCtx.clip(to: rect)
            let colors = [from.cgColor, to.cgColor] as CFArray
            if let gradient = CGGradient(
                colorsSpace: CGColorSpaceCreateDeviceRGB(),
                colors: colors,
                locations: [0, 1]
            ) {
                let start = horizontal
                    ? CGPoint(x: rect.minX, y: rect.midY)
                    : CGPoint(x: rect.midX, y: rect.minY)
                let end   = horizontal
                    ? CGPoint(x: rect.maxX, y: rect.midY)
                    : CGPoint(x: rect.midX, y: rect.maxY)
                cgCtx.drawLinearGradient(gradient, start: start, end: end, options: [])
            }
            cgCtx.restoreGState()
        }

        func drawHline(cgCtx: CGContext, x1: CGFloat, x2: CGFloat, y: CGFloat,
                       color: UIColor, width: CGFloat = 0.5) {
            cgCtx.saveGState()
            cgCtx.setStrokeColor(color.cgColor)
            cgCtx.setLineWidth(width)
            cgCtx.move(to: CGPoint(x: x1, y: y))
            cgCtx.addLine(to: CGPoint(x: x2, y: y))
            cgCtx.strokePath()
            cgCtx.restoreGState()
        }

        // ── Franja de cabecera (logo + título + fecha) ───────────────

        func drawHeaderBand(cgCtx: CGContext) {
            let bandRect = CGRect(x: 0, y: 0, width: pageW, height: headerBandH)
            drawGradientRect(cgCtx: cgCtx, rect: bandRect, from: brandPrimary, to: brandSecondary)

            var textX: CGFloat = margin + 10

            // Logo
            if let logo = logo {
                let logoH: CGFloat = 38
                let logoW = (logo.size.width / logo.size.height) * logoH
                let logoRect = CGRect(
                    x: margin + 8,
                    y: (headerBandH - logoH) / 2,
                    width: logoW,
                    height: logoH
                )
                logo.draw(in: logoRect)
                textX = logoRect.maxX + 12
            }

            // Título
            let titleAttrs: [NSAttributedString.Key: Any] = [
                .font: titleFont,
                .foregroundColor: UIColor.white
            ]
            "Reporte de Ventas · \(companyName)".draw(
                at: CGPoint(x: textX, y: 11),
                withAttributes: titleAttrs
            )

            let subAttrs: [NSAttributedString.Key: Any] = [
                .font: subtitleFont,
                .foregroundColor: UIColor.white.withAlphaComponent(0.78)
            ]
            "\(encounters.count) registro(s)".draw(
                at: CGPoint(x: textX, y: 33),
                withAttributes: subAttrs
            )

            // Fecha — alineada a la derecha
            let dateStr = "Generado: \(fullDateFmt.string(from: Date()))"
            let dateAttrs: [NSAttributedString.Key: Any] = [
                .font: subtitleFont,
                .foregroundColor: UIColor.white.withAlphaComponent(0.82)
            ]
            let dateSize = (dateStr as NSString).size(withAttributes: dateAttrs)
            dateStr.draw(
                at: CGPoint(x: pageW - margin - dateSize.width,
                            y: (headerBandH - dateSize.height) / 2),
                withAttributes: dateAttrs
            )
        }

        // ── Fila de resumen de totales ───────────────────────────────

        func drawSummaryRow(y: CGFloat) {
            let bgRect = CGRect(x: margin, y: y, width: contentW, height: summaryH)
            brandSoft.withAlphaComponent(0.45).setFill()
            UIRectFill(bgRect)
            brandAccent.withAlphaComponent(0.28).setStroke()
            UIRectFrame(bgRect)

            let items: [(String, Double, UIColor)] = [
                ("Total Ventas",    totalVentas,    brandPrimary),
                ("A Cuenta",        totalDeposit,   brandAccent),
                ("Por Cobrar",      totalResta,     brandWarning),
                ("Inv. Lentes",     totalInversion, brandSecondary)
            ]
            let itemW = contentW / CGFloat(items.count)

            for (i, item) in items.enumerated() {
                let ix = margin + CGFloat(i) * itemW

                // Separador vertical entre celdas
                if i > 0 {
                    brandAccent.withAlphaComponent(0.25).setStroke()
                    let sep = UIBezierPath()
                    sep.move(to: CGPoint(x: ix, y: y + 8))
                    sep.addLine(to: CGPoint(x: ix, y: y + summaryH - 8))
                    sep.lineWidth = 0.5
                    sep.stroke()
                }

                let labelAttrs: [NSAttributedString.Key: Any] = [
                    .font: summaryLblFont,
                    .foregroundColor: UIColor.darkGray
                ]
                let valueAttrs: [NSAttributedString.Key: Any] = [
                    .font: summaryValFont,
                    .foregroundColor: item.2
                ]
                item.0.draw(in: CGRect(x: ix + 10, y: y + 6,  width: itemW - 14, height: 13), withAttributes: labelAttrs)
                fmtDouble(item.1).draw(in: CGRect(x: ix + 10, y: y + 20, width: itemW - 14, height: 20), withAttributes: valueAttrs)
            }
        }

        // ── Encabezados de columna ───────────────────────────────────

        func drawColHeaders(cgCtx: CGContext, y: CGFloat) {
            let hdrRect = CGRect(x: margin, y: y, width: contentW, height: colHdrH)
            drawGradientRect(cgCtx: cgCtx, rect: hdrRect,
                             from: brandPrimary.withAlphaComponent(0.88),
                             to: brandAccent.withAlphaComponent(0.82))
            var hx = margin
            for (i, col) in cols.enumerated() {
                let attrs: [NSAttributedString.Key: Any] = [.font: colHdrFont, .foregroundColor: UIColor.white]
                col.0.draw(in: CGRect(x: hx + 3, y: y + 6, width: colWidths[i] - 6, height: colHdrH), withAttributes: attrs)
                hx += colWidths[i]
            }
        }

        // ── Filas de datos ───────────────────────────────────────────

        func drawRows(_ pageEncounters: [Encounter], startY: CGFloat) {
            for (rowIdx, enc) in pageEncounters.enumerated() {
                let rowY = startY + CGFloat(rowIdx) * rowH
                let rowBg: UIColor = enc.isGuarantee ? guaranteeBg
                                   : (rowIdx % 2 == 0 ? UIColor.white : altRowBg)
                rowBg.setFill()
                UIRectFill(CGRect(x: margin, y: rowY, width: contentW, height: rowH))
                borderColor.setStroke()
                UIRectFrame(CGRect(x: margin, y: rowY, width: contentW, height: rowH))

                let resta = calcResta(enc)
                let discountDisplay = formatDiscount(enc.payDiscount)
                let cellValues: [String] = [
                    dateFmt.string(from: enc.createdAt),
                    enc.patientFullName.isEmpty ? "Sin nombre" : enc.patientFullName,
                    enc.optometristName ?? "—",
                    enc.payTotal.isEmpty    ? "—" : "$\(enc.payTotal)",
                    discountDisplay,
                    enc.payMethod.isEmpty   ? "—" : enc.payMethod,
                    enc.payStatus.isEmpty   ? "—" : enc.payStatus,
                    enc.payDeposit.isEmpty  ? "—" : "$\(enc.payDeposit)",
                    resta > 0 ? String(format: "$%.2f", resta) : "—",
                    enc.lensCost.isEmpty    ? "—" : "$\(enc.lensCost)",
                    enc.isGuarantee ? (enc.guaranteeReason ?? "Sí") : "—"
                ]

                var cx = margin
                for (i, val) in cellValues.enumerated() {
                    let font  = (i == 1) ? cellBoldFont : cellFont
                    let color: UIColor
                    switch i {
                    case 4 where discountDisplay != "—":                      color = brandSuccess
                    case 6 where enc.payStatus.lowercased().contains("pag"):  color = brandSuccess
                    case 8 where resta > 0:                                   color = brandWarning
                    case 10 where enc.isGuarantee:                            color = brandPrimary
                    default:                                                   color = .darkGray
                    }
                    let attrs: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: color]
                    val.draw(in: CGRect(x: cx + 3, y: rowY + 4, width: colWidths[i] - 6, height: rowH - 4), withAttributes: attrs)
                    cx += colWidths[i]
                }
            }
        }

        // ── Pie de página ────────────────────────────────────────────

        func drawFooter(cgCtx: CGContext, pageNum: Int, totalPages: Int) {
            let footerY = pageH - margin + 4

            drawHline(cgCtx: cgCtx, x1: margin, x2: pageW - margin, y: footerY - 3,
                      color: brandAccent.withAlphaComponent(0.3))

            let leftAttrs: [NSAttributedString.Key: Any] = [
                .font: footerFont,
                .foregroundColor: brandAccent.withAlphaComponent(0.55)
            ]
            "VisionWow · Reporte de Ventas".draw(at: CGPoint(x: margin, y: footerY), withAttributes: leftAttrs)

            let pageLabel = "Pág. \(pageNum) / \(totalPages)"
            let pgAttrs: [NSAttributedString.Key: Any] = [
                .font: footerFont,
                .foregroundColor: UIColor.gray
            ]
            let pgSize = (pageLabel as NSString).size(withAttributes: pgAttrs)
            pageLabel.draw(at: CGPoint(x: pageW - margin - pgSize.width, y: footerY), withAttributes: pgAttrs)
        }

        // ── Renderizado por página ───────────────────────────────────

        // ── Paginado ─────────────────────────────────────────────────

        let renderer = UIGraphicsPDFRenderer(bounds: CGRect(x: 0, y: 0, width: pageW, height: pageH))

        let data = renderer.pdfData { ctx in
            func drawPage(pageEncounters: [Encounter], pageNum: Int, totalPages: Int, isFirst: Bool) {
                ctx.beginPage()
                let cgCtx = ctx.cgContext
                var y: CGFloat

                if isFirst {
                    drawHeaderBand(cgCtx: cgCtx)
                    y = headerBandH + sectionPad
                    drawSummaryRow(y: y)
                    y += summaryH + sectionPad
                } else {
                    y = margin
                }

                drawColHeaders(cgCtx: cgCtx, y: y)
                y += colHdrH

                drawRows(pageEncounters, startY: y)
                drawFooter(cgCtx: cgCtx, pageNum: pageNum, totalPages: totalPages)
            }

            var pages: [[Encounter]] = []
            if encounters.isEmpty {
                pages = [[]]
            } else {
                var remaining = Array(encounters)
                pages.append(Array(remaining.prefix(rowsPerFirstPage)))
                remaining = Array(remaining.dropFirst(rowsPerFirstPage))
                while !remaining.isEmpty {
                    pages.append(Array(remaining.prefix(rowsPerOtherPage)))
                    remaining = Array(remaining.dropFirst(rowsPerOtherPage))
                }
            }
            let totalPages = max(1, pages.count)
            for (i, page) in pages.enumerated() {
                drawPage(pageEncounters: page, pageNum: i + 1, totalPages: totalPages, isFirst: i == 0)
            }
        }

        return try saveToDocuments(data: data, fileName: pdfFileName(companyName: companyName), ext: "pdf")
    }

    // MARK: - Helpers

    /// Converts stored "BASE:3500|FAMILIA:10,PROMO5:5" to "FAMILIA −10%, PROMO5 −5%", or "—" if none.
    static func formatDiscount(_ raw: String?) -> String {
        guard let raw = raw, raw.hasPrefix("BASE:"),
              let pipeIdx = raw.firstIndex(of: "|") else {
            // Legacy or empty
            if let raw = raw, !raw.isEmpty { return raw }
            return "—"
        }
        let codesPart = String(raw[raw.index(after: pipeIdx)...])
        let parts = codesPart.split(separator: ",").compactMap { token -> String? in
            let kv = token.split(separator: ":")
            guard kv.count == 2 else { return nil }
            return "\(kv[0]) −\(kv[1])%"
        }
        return parts.isEmpty ? "—" : parts.joined(separator: ", ")
    }

    private static func calcResta(_ enc: Encounter) -> Double {
        let total   = Double(enc.payTotal.trimmingCharacters(in: .whitespacesAndNewlines))   ?? 0
        let deposit = Double(enc.payDeposit.trimmingCharacters(in: .whitespacesAndNewlines)) ?? 0
        return max(0, total - deposit)
    }

    private static func fmtDouble(_ v: Double) -> String {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.minimumFractionDigits = 2
        f.maximumFractionDigits = 2
        f.groupingSeparator = ","
        return "$\(f.string(from: NSNumber(value: v)) ?? String(format: "%.2f", v))"
    }

    private static func saveToDocuments(data: Data, fileName: String, ext: String) throws -> URL {
        let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("VisionWow", isDirectory: true)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let url = dir.appendingPathComponent("\(fileName).\(ext)")
        try data.write(to: url)
        return url
    }

    private static func csvFileName(companyName: String) -> String {
        "VentasReporte_\(companyName.replacingOccurrences(of: " ", with: "_"))_\(Int(Date().timeIntervalSince1970))"
    }

    private static func pdfFileName(companyName: String) -> String {
        "VentasReporte_\(companyName.replacingOccurrences(of: " ", with: "_"))_\(Int(Date().timeIntervalSince1970))"
    }
}
