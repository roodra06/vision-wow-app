//
//  PDFFields.swift
//  VisionWow — Campos de datos con etiquetas en color de marca
//
import UIKit

enum PDFFields {

    // MARK: - Campo estándar: etiqueta (izq) + valor (der) + subrayado

    static func drawLineField(label: String, value: String, in rect: CGRect) {
        // Texto posicionado justo encima de la línea de subrayado
        let lineY   = rect.maxY - 1.5
        let textH:  CGFloat = 11          // altura que ocupa el texto
        let textY   = lineY - textH - 1   // 1 pt de holgura sobre la línea

        let labelW: CGFloat = min(76, rect.width * 0.40)

        // Etiqueta de marca (izquierda)
        PDFDraw.drawText(label,
                         in: CGRect(x: rect.minX, y: textY, width: labelW, height: textH),
                         font: .systemFont(ofSize: 7.5, weight: .semibold),
                         color: PDFStyles.cSecondary,
                         alignment: .left)

        // Valor (derecha de la etiqueta)
        let valueRect = CGRect(x: rect.minX + labelW + 4,
                               y: textY,
                               width: rect.width - labelW - 4,
                               height: textH)
        PDFDraw.drawText(value.isEmpty ? "—" : value,
                         in: valueRect,
                         font: .systemFont(ofSize: 9, weight: value.isEmpty ? .light : .regular),
                         color: value.isEmpty ? PDFStyles.cGrisLinea : PDFStyles.cGrisTitulo,
                         alignment: .left)

        // Subrayado de marca (desde el valor)
        PDFDraw.drawLine(
            from: CGPoint(x: valueRect.minX, y: lineY),
            to:   CGPoint(x: rect.maxX,      y: lineY),
            color: PDFStyles.cPrimary.withAlphaComponent(0.22),
            width: 0.8
        )
    }

    // MARK: - Etiqueta inline (sin campo)

    static func drawInlineLabel(_ text: String, in rect: CGRect, labelW: CGFloat) {
        // Alineada al fondo igual que drawLineField
        let lineY  = rect.maxY - 1.5
        let textH: CGFloat = 11
        let textY  = lineY - textH - 1
        PDFDraw.drawText(text,
                         in: CGRect(x: rect.minX, y: textY, width: labelW, height: textH),
                         font: .systemFont(ofSize: 8, weight: .semibold),
                         color: PDFStyles.cSecondary,
                         alignment: .left)
    }

    // MARK: - Campo compacto: etiqueta (arriba) + valor (sobre la línea)

    static func drawSmallLineField(label: String, value: String,
                                    x: CGFloat, y: CGFloat, w: CGFloat, h: CGFloat) {
        let lineY  = y + h - 1.5
        let textH: CGFloat = 11
        let textY  = lineY - textH - 1   // valor justo sobre la línea

        // Etiqueta mini en la parte superior
        PDFDraw.drawText(label,
                         in: CGRect(x: x, y: y, width: w, height: 9),
                         font: .systemFont(ofSize: 7, weight: .semibold),
                         color: PDFStyles.cSecondary,
                         alignment: .left)

        // Valor justo sobre la línea
        PDFDraw.drawText(value.isEmpty ? "—" : value,
                         in: CGRect(x: x, y: textY, width: w, height: textH),
                         font: .systemFont(ofSize: 9, weight: value.isEmpty ? .light : .regular),
                         color: value.isEmpty ? PDFStyles.cGrisLinea : PDFStyles.cGrisTitulo,
                         alignment: .left)

        // Subrayado
        PDFDraw.drawLine(
            from: CGPoint(x: x,     y: lineY),
            to:   CGPoint(x: x + w, y: lineY),
            color: PDFStyles.cPrimary.withAlphaComponent(0.22),
            width: 0.8
        )
    }

    // MARK: - Checkbox con etiqueta

    static func drawCheckBox(label: String, checked: Bool,
                              x: CGFloat, y: CGFloat, w: CGFloat, h: CGFloat) {
        let boxSize: CGFloat = 10
        // Centrar verticalmente el box en el rect
        let boxY = y + (h - boxSize) / 2
        let boxRect = CGRect(x: x, y: boxY, width: boxSize, height: boxSize)

        PDFCards.drawSquareCheck(checked: checked, in: boxRect)

        let textRect = CGRect(x: boxRect.maxX + 4, y: y, width: w - boxSize - 4, height: h)
        PDFDraw.drawText(label,
                         in: textRect,
                         font: .systemFont(ofSize: 8, weight: .semibold),
                         color: checked ? PDFStyles.cPrimary : PDFStyles.cGrisTexto,
                         alignment: .left)
    }
}
