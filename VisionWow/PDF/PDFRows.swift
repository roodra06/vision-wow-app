//
//  PDFRows.swift
//  VisionWow
//
//  Created by Rodrigo Marcos on 28/12/25.
//
import UIKit

enum PDFRows {

    static func drawLineRow2(left: (String, String), right: (String, String), x: CGFloat, y: CGFloat, w: CGFloat) -> CGFloat {
        let gap: CGFloat = 12
        let h: CGFloat = 22
        let colW = (w - gap) / 2

        PDFFields.drawLineField(label: left.0, value: left.1, in: CGRect(x: x, y: y, width: colW, height: h))
        PDFFields.drawLineField(label: right.0, value: right.1, in: CGRect(x: x + colW + gap, y: y, width: colW, height: h))
        return y + h
    }

    static func drawLineRow3(left: (String, String), mid: (String, String), right: (String, String), x: CGFloat, y: CGFloat, w: CGFloat) -> CGFloat {
        let gap: CGFloat = 12
        let h: CGFloat = 22
        let colW = (w - gap * 2) / 3

        PDFFields.drawLineField(label: left.0, value: left.1, in: CGRect(x: x, y: y, width: colW, height: h))
        PDFFields.drawLineField(label: mid.0, value: mid.1, in: CGRect(x: x + colW + gap, y: y, width: colW, height: h))
        PDFFields.drawLineField(label: right.0, value: right.1, in: CGRect(x: x + (colW + gap) * 2, y: y, width: colW, height: h))
        return y + h
    }

    static func drawLineRow4(a: (String, String), b: (String, String), c: (String, String), d: (String, String), x: CGFloat, y: CGFloat, w: CGFloat) -> CGFloat {
        let gap: CGFloat = 10
        let h: CGFloat = 22
        let colW = (w - gap * 3) / 4

        PDFFields.drawLineField(label: a.0, value: a.1, in: CGRect(x: x, y: y, width: colW, height: h))
        PDFFields.drawLineField(label: b.0, value: b.1, in: CGRect(x: x + (colW + gap), y: y, width: colW, height: h))
        PDFFields.drawLineField(label: c.0, value: c.1, in: CGRect(x: x + (colW + gap) * 2, y: y, width: colW, height: h))
        PDFFields.drawLineField(label: d.0, value: d.1, in: CGRect(x: x + (colW + gap) * 3, y: y, width: colW, height: h))
        return y + h
    }

    static func drawLongLine(label: String, value: String, x: CGFloat, y: CGFloat, w: CGFloat) -> CGFloat {
        let h: CGFloat = 22
        let labelW: CGFloat = 96
        let rect = CGRect(x: x, y: y, width: w, height: h)

        PDFDraw.drawText(label, in: CGRect(x: rect.minX, y: rect.minY, width: labelW, height: rect.height),
                 font: .systemFont(ofSize: 9.0, weight: .semibold),
                 color: .black,
                 alignment: .left)

        let valueRect = CGRect(x: rect.minX + labelW, y: rect.minY, width: rect.width - labelW, height: rect.height)
        PDFDraw.drawText(value.isEmpty ? "" : value, in: valueRect,
                 font: .systemFont(ofSize: 9.0, weight: .regular),
                 color: .black,
                 alignment: .left)

        PDFDraw.drawLine(from: CGPoint(x: valueRect.minX, y: valueRect.maxY - 2),
                 to: CGPoint(x: valueRect.maxX, y: valueRect.maxY - 2),
                 color: UIColor.black.withAlphaComponent(0.25),
                 width: 1)

        return y + h
    }
}

