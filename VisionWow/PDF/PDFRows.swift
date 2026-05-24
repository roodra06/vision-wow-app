//
//  PDFRows.swift
//  VisionWow — Filas de campos de datos
//
import UIKit

enum PDFRows {

    static func drawLineRow2(left: (String, String), right: (String, String),
                              x: CGFloat, y: CGFloat, w: CGFloat) -> CGFloat {
        let gap:  CGFloat = 10
        let h:    CGFloat = 18   // comprimido de 22 → 18
        let colW = (w - gap) / 2

        PDFFields.drawLineField(label: left.0,  value: left.1,
                                 in: CGRect(x: x, y: y, width: colW, height: h))
        PDFFields.drawLineField(label: right.0, value: right.1,
                                 in: CGRect(x: x + colW + gap, y: y, width: colW, height: h))
        return y + h
    }

    static func drawLineRow3(left: (String, String), mid: (String, String), right: (String, String),
                              x: CGFloat, y: CGFloat, w: CGFloat) -> CGFloat {
        let gap:  CGFloat = 10
        let h:    CGFloat = 18
        let colW = (w - gap * 2) / 3

        PDFFields.drawLineField(label: left.0,  value: left.1,
                                 in: CGRect(x: x, y: y, width: colW, height: h))
        PDFFields.drawLineField(label: mid.0,   value: mid.1,
                                 in: CGRect(x: x + colW + gap, y: y, width: colW, height: h))
        PDFFields.drawLineField(label: right.0, value: right.1,
                                 in: CGRect(x: x + (colW + gap) * 2, y: y, width: colW, height: h))
        return y + h
    }

    static func drawLineRow4(a: (String, String), b: (String, String),
                              c: (String, String), d: (String, String),
                              x: CGFloat, y: CGFloat, w: CGFloat) -> CGFloat {
        let gap:  CGFloat = 8
        let h:    CGFloat = 18
        let colW = (w - gap * 3) / 4

        PDFFields.drawLineField(label: a.0, value: a.1,
                                 in: CGRect(x: x, y: y, width: colW, height: h))
        PDFFields.drawLineField(label: b.0, value: b.1,
                                 in: CGRect(x: x + (colW + gap),     y: y, width: colW, height: h))
        PDFFields.drawLineField(label: c.0, value: c.1,
                                 in: CGRect(x: x + (colW + gap) * 2, y: y, width: colW, height: h))
        PDFFields.drawLineField(label: d.0, value: d.1,
                                 in: CGRect(x: x + (colW + gap) * 3, y: y, width: colW, height: h))
        return y + h
    }

    static func drawSignatureRow(label: String, image: UIImage,
                                  x: CGFloat, y: CGFloat, w: CGFloat) -> CGFloat {
        let labelH: CGFloat = 12
        let imgH:   CGFloat = 55
        let totalH  = labelH + imgH + 6

        PDFDraw.drawText(label,
                         in: CGRect(x: x, y: y, width: w, height: labelH),
                         font: .systemFont(ofSize: 8, weight: .semibold),
                         color: PDFStyles.cSecondary,
                         alignment: .left)
        let imgRect = CGRect(x: x, y: y + labelH + 2, width: w / 2, height: imgH)
        image.draw(in: imgRect)
        PDFDraw.drawLine(from: CGPoint(x: imgRect.minX, y: imgRect.maxY + 2),
                         to:   CGPoint(x: imgRect.maxX, y: imgRect.maxY + 2),
                         color: PDFStyles.cGrisLinea, width: 0.8)
        return y + totalH
    }

    static func drawLongLine(label: String, value: String,
                              x: CGFloat, y: CGFloat, w: CGFloat) -> CGFloat {
        let h:      CGFloat = 18
        let labelW: CGFloat = 90
        let rect = CGRect(x: x, y: y, width: w, height: h)
        let lineY = rect.maxY - 1.5
        let textH: CGFloat = 11
        let textY = lineY - textH - 1

        PDFDraw.drawText(label,
                         in: CGRect(x: rect.minX, y: textY, width: labelW, height: textH),
                         font: .systemFont(ofSize: 8, weight: .semibold),
                         color: PDFStyles.cSecondary,
                         alignment: .left)

        let valueRect = CGRect(x: rect.minX + labelW + 4, y: textY,
                               width: rect.width - labelW - 4, height: textH)
        PDFDraw.drawText(value.isEmpty ? "—" : value,
                         in: valueRect,
                         font: .systemFont(ofSize: 9, weight: .regular),
                         color: PDFStyles.cGrisTitulo,
                         alignment: .left)

        PDFDraw.drawLine(from: CGPoint(x: valueRect.minX, y: lineY),
                         to:   CGPoint(x: rect.maxX,      y: lineY),
                         color: PDFStyles.cPrimary.withAlphaComponent(0.22), width: 0.8)
        return y + h
    }
}
