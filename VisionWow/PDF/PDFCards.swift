//
//  PDFCards.swift
//  VisionWow
//
//  Created by Rodrigo Marcos on 28/12/25.
//
import UIKit

enum PDFCards {

    static func drawCheckCard(title: String, items: [String: Bool], in rect: CGRect) {
        UIColor.black.withAlphaComponent(0.25).setStroke()
        let outer = UIBezierPath(rect: rect)
        outer.lineWidth = 0.8
        outer.stroke()

        let headerH: CGFloat = 16
        let headerRect = CGRect(x: rect.minX, y: rect.minY, width: rect.width, height: headerH)
        UIColor.black.withAlphaComponent(0.10).setFill()
        UIBezierPath(rect: headerRect).fill()

        PDFDraw.drawText(title.uppercased(),
                 in: headerRect.insetBy(dx: 6, dy: 2),
                 font: .systemFont(ofSize: 8.0, weight: .bold),
                 color: .black,
                 alignment: .center)

        let sortedKeys = items.keys.sorted()
        let maxItems = min(sortedKeys.count, 7)
        let itemFont = UIFont.systemFont(ofSize: 7.6, weight: .regular)

        let startY = headerRect.maxY + 4
        let lineH: CGFloat = 13
        let checkSize: CGFloat = 10

        var row = 0
        for key in sortedKeys {
            if row >= maxItems { break }
            if key == "Otra" { continue }

            let iy = startY + CGFloat(row) * lineH
            let textRect = CGRect(x: rect.minX + 6, y: iy, width: rect.width - 6 - checkSize - 6, height: lineH)
            PDFDraw.drawText(key, in: textRect, font: itemFont, color: .black, alignment: .left)

            let boxRect = CGRect(x: rect.maxX - checkSize - 6, y: iy + 1, width: checkSize, height: checkSize)
            drawSquareCheck(checked: items[key] == true, in: boxRect)

            row += 1
        }
    }

    static func drawSquareCheck(checked: Bool, in rect: CGRect) {
        UIColor.black.withAlphaComponent(0.45).setStroke()
        let p = UIBezierPath(rect: rect)
        p.lineWidth = 0.8
        p.stroke()

        if checked {
            let check = UIBezierPath()
            check.move(to: CGPoint(x: rect.minX + 2, y: rect.midY))
            check.addLine(to: CGPoint(x: rect.midX - 1, y: rect.maxY - 2))
            check.addLine(to: CGPoint(x: rect.maxX - 2, y: rect.minY + 2))
            UIColor.black.withAlphaComponent(0.7).setStroke()
            check.lineWidth = 1.6
            check.stroke()
        }
    }
}

