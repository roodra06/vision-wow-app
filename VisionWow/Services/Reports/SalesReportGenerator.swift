//
//  SalesReportGenerator.swift
//  VisionWow
//

import UIKit
import PDFKit

enum SalesReportGenerator {

    // MARK: - CSV

    static func generateCSV(companyName: String, encounters: [Encounter]) throws -> URL {
        var lines: [String] = []

        // Header
        lines.append([
            "Fecha",
            "Paciente",
            "Optometrista",
            "Total Venta",
            "Método Pago",
            "Estatus",
            "A Cuenta",
            "Resta por Pagar",
            "Inversión Lente",
            "Garantía"
        ].map { "\"\($0)\"" }.joined(separator: ","))

        let fmt = DateFormatter()
        fmt.dateStyle = .short
        fmt.timeStyle = .none
        fmt.locale = Locale(identifier: "es_MX")

        for enc in encounters {
            let resta = calcResta(enc)
            let restaStr = resta > 0 ? String(format: "%.2f", resta) : "0.00"

            let row: [String] = [
                fmt.string(from: enc.createdAt),
                enc.patientFullName.isEmpty ? "Sin nombre" : enc.patientFullName,
                enc.optometristName ?? "",
                enc.payTotal,
                enc.payMethod,
                enc.payStatus,
                enc.payDeposit,
                restaStr,
                enc.lensCost,
                enc.isGuarantee ? (enc.guaranteeReason ?? "Sí") : ""
            ]
            lines.append(row.map { "\"\($0.replacingOccurrences(of: "\"", with: "\"\""))\"" }.joined(separator: ","))
        }

        let csv = lines.joined(separator: "\n")
        let data = csv.data(using: .utf8) ?? Data()
        return try saveToDocuments(data: data, fileName: csvFileName(companyName: companyName), ext: "csv")
    }

    // MARK: - PDF (landscape table)

    static func generatePDF(companyName: String, encounters: [Encounter]) throws -> URL {
        // Landscape A4
        let pageW: CGFloat = 841.89
        let pageH: CGFloat = 595.28
        let margin: CGFloat = 28
        let contentW = pageW - margin * 2

        let renderer = UIGraphicsPDFRenderer(
            bounds: CGRect(x: 0, y: 0, width: pageW, height: pageH)
        )

        let data = renderer.pdfData { ctx in
            // Column definitions: (header, relative flex weight)
            let cols: [(String, CGFloat)] = [
                ("Fecha",        6),
                ("Paciente",     14),
                ("Optometrista", 12),
                ("Total",        7),
                ("Método",       8),
                ("Estatus",      8),
                ("A Cuenta",     7),
                ("Resta",        7),
                ("Inversión",    7),
                ("Garantía",     8)
            ]
            let totalWeight = cols.reduce(0) { $0 + $1.1 }
            let colWidths = cols.map { $0.1 / totalWeight * contentW }

            let headerH: CGFloat   = 22
            let rowH: CGFloat      = 18
            let titleH: CGFloat    = 36
            let summaryH: CGFloat  = 24
            let sectionPad: CGFloat = 8
            let rowsPerPage: Int   = Int((pageH - margin * 2 - titleH - headerH - summaryH - sectionPad) / rowH)

            // Colors
            let primaryColor  = UIColor(red: 0.13, green: 0.45, blue: 0.78, alpha: 1)
            let headerBg      = UIColor(red: 0.13, green: 0.45, blue: 0.78, alpha: 0.85)
            let altRowBg      = UIColor(red: 0.96, green: 0.97, blue: 0.99, alpha: 1)
            let guaranteeBg   = UIColor(red: 1.0,  green: 0.94, blue: 0.94, alpha: 1)
            let borderColor   = UIColor.lightGray.withAlphaComponent(0.5)

            // Fonts
            let titleFont    = UIFont.systemFont(ofSize: 14, weight: .bold)
            let subFont      = UIFont.systemFont(ofSize: 9,  weight: .regular)
            let colHdrFont   = UIFont.systemFont(ofSize: 8,  weight: .bold)
            let cellFont     = UIFont.systemFont(ofSize: 8,  weight: .regular)
            let cellBoldFont = UIFont.systemFont(ofSize: 8,  weight: .semibold)
            let summaryFont  = UIFont.systemFont(ofSize: 8,  weight: .semibold)

            let dateFmt = DateFormatter()
            dateFmt.dateFormat = "dd/MM/yy"

            // Summary values
            let totalVentas    = encounters.reduce(0.0) { $0 + (Double($1.payTotal)    ?? 0) }
            let totalDeposit   = encounters.reduce(0.0) { $0 + (Double($1.payDeposit)  ?? 0) }
            let totalResta     = encounters.reduce(0.0) { $0 + calcResta($1) }
            let totalInversion = encounters.reduce(0.0) { $0 + (Double($1.lensCost)    ?? 0) }

            func drawPage(pageEncounters: [Encounter], pageNum: Int, totalPages: Int, isFirst: Bool) {
                ctx.beginPage()
                var y = margin

                if isFirst {
                    // Title
                    let titleAttrs: [NSAttributedString.Key: Any] = [.font: titleFont, .foregroundColor: primaryColor]
                    let title = "Reporte de Ventas · \(companyName)"
                    title.draw(at: CGPoint(x: margin, y: y), withAttributes: titleAttrs)
                    y += 18

                    let subAttrs: [NSAttributedString.Key: Any] = [.font: subFont, .foregroundColor: UIColor.gray]
                    "\(encounters.count) registro(s) · Generado: \(dateFmt.string(from: Date()))".draw(at: CGPoint(x: margin, y: y), withAttributes: subAttrs)
                    y += 18 + sectionPad

                    // Summary row
                    let summaryY = y
                    let summaryBg = UIColor(red: 0.94, green: 0.97, blue: 1.0, alpha: 1)
                    summaryBg.setFill()
                    UIRectFill(CGRect(x: margin, y: summaryY, width: contentW, height: summaryH))
                    borderColor.setStroke()
                    UIRectFrame(CGRect(x: margin, y: summaryY, width: contentW, height: summaryH))

                    let summaryItems: [(String, Double)] = [
                        ("Total Ventas", totalVentas),
                        ("Total A Cuenta", totalDeposit),
                        ("Total Por Cobrar", totalResta),
                        ("Total Inversión", totalInversion)
                    ]
                    let summaryItemW = contentW / CGFloat(summaryItems.count)
                    for (i, item) in summaryItems.enumerated() {
                        let sx = margin + CGFloat(i) * summaryItemW + 6
                        let label = item.0 + ":"
                        let value = String(format: "$%.2f", item.1)
                        let labelAttrs: [NSAttributedString.Key: Any] = [.font: summaryFont, .foregroundColor: UIColor.gray]
                        let valueAttrs: [NSAttributedString.Key: Any] = [.font: UIFont.systemFont(ofSize: 9, weight: .bold), .foregroundColor: primaryColor]
                        label.draw(at: CGPoint(x: sx, y: summaryY + 5), withAttributes: labelAttrs)
                        value.draw(at: CGPoint(x: sx + 64, y: summaryY + 5), withAttributes: valueAttrs)
                    }
                    y += summaryH + sectionPad
                }

                // Column headers
                headerBg.setFill()
                UIRectFill(CGRect(x: margin, y: y, width: contentW, height: headerH))
                var hx = margin
                for (i, col) in cols.enumerated() {
                    let hdrAttrs: [NSAttributedString.Key: Any] = [.font: colHdrFont, .foregroundColor: UIColor.white]
                    let rect = CGRect(x: hx + 3, y: y + 5, width: colWidths[i] - 6, height: headerH)
                    col.0.draw(in: rect, withAttributes: hdrAttrs)
                    hx += colWidths[i]
                }
                y += headerH

                // Rows
                for (rowIdx, enc) in pageEncounters.enumerated() {
                    let rowY = y + CGFloat(rowIdx) * rowH
                    let rowBg: UIColor = enc.isGuarantee ? guaranteeBg : (rowIdx % 2 == 0 ? UIColor.white : altRowBg)
                    rowBg.setFill()
                    UIRectFill(CGRect(x: margin, y: rowY, width: contentW, height: rowH))
                    borderColor.setStroke()
                    UIRectFrame(CGRect(x: margin, y: rowY, width: contentW, height: rowH))

                    let resta = calcResta(enc)
                    let cellValues: [String] = [
                        dateFmt.string(from: enc.createdAt),
                        enc.patientFullName.isEmpty ? "Sin nombre" : enc.patientFullName,
                        enc.optometristName ?? "—",
                        enc.payTotal.isEmpty ? "—" : "$\(enc.payTotal)",
                        enc.payMethod.isEmpty ? "—" : enc.payMethod,
                        enc.payStatus.isEmpty ? "—" : enc.payStatus,
                        enc.payDeposit.isEmpty ? "—" : "$\(enc.payDeposit)",
                        resta > 0 ? String(format: "$%.2f", resta) : "—",
                        enc.lensCost.isEmpty ? "—" : "$\(enc.lensCost)",
                        enc.isGuarantee ? (enc.guaranteeReason ?? "Sí") : "—"
                    ]

                    var cx = margin
                    for (i, val) in cellValues.enumerated() {
                        let font = (i == 1) ? cellBoldFont : cellFont
                        let color: UIColor = (i == 7 && resta > 0) ? UIColor(red: 0.8, green: 0.4, blue: 0.0, alpha: 1)
                                          : (i == 5 && enc.payStatus.lowercased().contains("pag")) ? UIColor(red: 0.1, green: 0.6, blue: 0.3, alpha: 1)
                                          : UIColor.darkGray
                        let attrs: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: color]
                        let cellRect = CGRect(x: cx + 3, y: rowY + 4, width: colWidths[i] - 6, height: rowH - 4)
                        val.draw(in: cellRect, withAttributes: attrs)
                        cx += colWidths[i]
                    }
                }

                // Page number
                let pageLabel = "Pág. \(pageNum) / \(totalPages)"
                let pgAttrs: [NSAttributedString.Key: Any] = [.font: subFont, .foregroundColor: UIColor.lightGray]
                let pgSize = (pageLabel as NSString).size(withAttributes: pgAttrs)
                pageLabel.draw(at: CGPoint(x: pageW - margin - pgSize.width, y: pageH - margin - 12), withAttributes: pgAttrs)
            }

            // Paginate
            let pages = encounters.isEmpty ? [[Encounter]()]
                      : stride(from: 0, to: encounters.count, by: rowsPerPage).map {
                          Array(encounters[$0 ..< min($0 + rowsPerPage, encounters.count)])
                      }
            let totalPages = pages.count
            for (i, page) in pages.enumerated() {
                drawPage(pageEncounters: page, pageNum: i + 1, totalPages: totalPages, isFirst: i == 0)
            }
        }

        return try saveToDocuments(data: data, fileName: pdfFileName(companyName: companyName), ext: "pdf")
    }

    // MARK: - Helpers

    private static func calcResta(_ enc: Encounter) -> Double {
        let total   = Double(enc.payTotal.trimmingCharacters(in: .whitespacesAndNewlines)) ?? 0
        let deposit = Double(enc.payDeposit.trimmingCharacters(in: .whitespacesAndNewlines)) ?? 0
        return max(0, total - deposit)
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
        let safe = companyName.replacingOccurrences(of: " ", with: "_")
        let ts = Int(Date().timeIntervalSince1970)
        return "VentasReporte_\(safe)_\(ts)"
    }

    private static func pdfFileName(companyName: String) -> String {
        let safe = companyName.replacingOccurrences(of: " ", with: "_")
        let ts = Int(Date().timeIntervalSince1970)
        return "VentasReporte_\(safe)_\(ts)"
    }
}
