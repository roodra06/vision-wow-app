//
//  PDFFields.swift
//  VisionWow
//
//  Created by Rodrigo Marcos on 28/12/25.
//
import UIKit

enum PDFFields {

    static func drawLineField(label: String, value: String, in rect: CGRect) {
        let labelFont = UIFont.systemFont(ofSize: 8.5, weight: .semibold)
        let valueFont = UIFont.systemFont(ofSize: 9.0, weight: .regular)

        let labelW: CGFloat = min(80, rect.width * 0.40)

        PDFDraw.drawText(label, in: CGRect(x: rect.minX, y: rect.minY, width: labelW, height: rect.height),
                 font: labelFont, color: .black, alignment: .left)

        let valueRect = CGRect(x: rect.minX + labelW + 4, y: rect.minY, width: rect.width - labelW - 4, height: rect.height)
        PDFDraw.drawText(value.isEmpty ? "" : value, in: valueRect,
                 font: valueFont, color: .black, alignment: .left)

        PDFDraw.drawLine(from: CGPoint(x: valueRect.minX, y: rect.maxY - 2),
                 to: CGPoint(x: rect.maxX, y: rect.maxY - 2),
                 color: UIColor.black.withAlphaComponent(0.25),
                 width: 1)
    }

    static func drawInlineLabel(_ text: String, in rect: CGRect, labelW: CGFloat) {
        PDFDraw.drawText(text, in: CGRect(x: rect.minX, y: rect.minY, width: labelW, height: rect.height),
                 font: .systemFont(ofSize: 9.0, weight: .semibold),
                 color: .black,
                 alignment: .left)
    }

    static func drawSmallLineField(label: String, value: String, x: CGFloat, y: CGFloat, w: CGFloat, h: CGFloat) {
        PDFDraw.drawText(label, in: CGRect(x: x, y: y - 2, width: w, height: 10),
                 font: .systemFont(ofSize: 7.8, weight: .semibold),
                 color: UIColor.black.withAlphaComponent(0.75),
                 alignment: .left)

        let valueRect = CGRect(x: x, y: y + 8, width: w, height: h - 8)
        PDFDraw.drawText(value.isEmpty ? "" : value, in: valueRect,
                 font: .systemFont(ofSize: 9.0, weight: .regular),
                 color: .black,
                 alignment: .left)

        PDFDraw.drawLine(from: CGPoint(x: x, y: y + h - 2),
                 to: CGPoint(x: x + w, y: y + h - 2),
                 color: UIColor.black.withAlphaComponent(0.25),
                 width: 1)
    }

    static func drawCheckBox(label: String, checked: Bool, x: CGFloat, y: CGFloat, w: CGFloat, h: CGFloat) {
        let boxSize: CGFloat = 11
        let boxRect = CGRect(x: x, y: y + 3, width: boxSize, height: boxSize)

        PDFCards.drawSquareCheck(checked: checked, in: boxRect)

        let textRect = CGRect(x: boxRect.maxX + 5, y: y, width: w - boxSize - 5, height: h)
        PDFDraw.drawText(label,
                 in: textRect,
                 font: .systemFont(ofSize: 8.6, weight: .semibold),
                 color: .black,
                 alignment: .left)
    }
}

