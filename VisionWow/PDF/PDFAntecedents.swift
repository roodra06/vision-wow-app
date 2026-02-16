//
//  PDFAntecedents.swift
//  VisionWow
//
//  Created by Rodrigo Marcos on 28/12/25.
//
import UIKit

enum PDFAntecedents {

    static func drawAntecedentsGrid(encounter: Encounter, x: CGFloat, y: CGFloat, w: CGFloat) -> CGFloat {
        var yy = y

        let title = "ANTECEDENTES / SÍNTOMAS"
        yy = PDFSections.drawSectionTitle(title, x: x, y: yy, w: w)
        yy += 2

        let a = decodeAntecedents(encounter.antecedentesJSON)

        let cols = 4
        let gap: CGFloat = 10
        let colW = (w - gap * CGFloat(cols - 1)) / CGFloat(cols)

        let cards: [(String, [String: Bool])] = [
            ("Antecedentes", a?.antecedentes ?? [:]),
            ("Síntomas", a?.sintomas ?? [:]),
            ("Anexos", a?.anexos ?? [:]),
            ("Salud ocular", a?.saludOcular ?? [:]),
            ("Conjuntivitis", a?.conjuntivitis ?? [:]),
            ("Computadora", a?.computadora ?? [:]),
            ("Salud", a?.salud ?? [:]),
            ("Consultas", a?.consultas ?? [:])
        ]

        var idx = 0
        while idx < cards.count {
            let row = Array(cards[idx..<min(idx + cols, cards.count)])
            let cardH: CGFloat = 118

            for c in 0..<row.count {
                let cx = x + CGFloat(c) * (colW + gap)
                let rect = CGRect(x: cx, y: yy, width: colW, height: cardH)
                PDFCards.drawCheckCard(title: row[c].0, items: row[c].1, in: rect)
            }

            yy += cardH + 10
            idx += cols
        }

        yy += 4
        yy = PDFRows.drawLongLine(label: "Observaciones", value: encounter.payNotes ?? "", x: x, y: yy, w: w) + 10

        return yy
    }

    private static func decodeAntecedents(_ json: String) -> Antecedents? {
        guard !json.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              let data = json.data(using: .utf8) else { return nil }
        return try? JSONDecoder().decode(Antecedents.self, from: data)
    }
}

