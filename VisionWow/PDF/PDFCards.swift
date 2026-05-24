//
//  PDFCards.swift
//  VisionWow — Tarjetas de antecedentes / síntomas con diseño de marca
//
import UIKit

enum PDFCards {

    // MARK: - Tarjeta de checkboxes (antecedentes / síntomas)

    /// Dibuja una tarjeta con encabezado de marca y lista de ítems con checkboxes.
    /// Mantiene la estructura original (8 tarjetas × 4 col), renovada visualmente.
    static func drawCheckCard(title: String, items: [String: Bool], in rect: CGRect) {
        guard let ctx = UIGraphicsGetCurrentContext() else { return }

        // ── Fondo de la tarjeta ───────────────────────────────────────
        // Borde redondeado suave con fondo muy claro
        ctx.saveGState()
        UIBezierPath(roundedRect: rect, cornerRadius: 5).addClip()
        PDFStyles.cGrisFondo.setFill()
        UIBezierPath(roundedRect: rect, cornerRadius: 5).fill()
        ctx.restoreGState()

        // Borde exterior suave
        PDFStyles.cGrisLinea.setStroke()
        let border = UIBezierPath(roundedRect: rect.insetBy(dx: 0.4, dy: 0.4), cornerRadius: 5)
        border.lineWidth = 0.6
        border.stroke()

        // ── Encabezado con degradado de marca ────────────────────────
        let headerH: CGFloat = 18
        let headerRect = CGRect(x: rect.minX, y: rect.minY, width: rect.width, height: headerH)
        PDFStyles.drawBrandGradientRounded(in: headerRect, radius: 5, ctx: ctx)

        // Redondear solo la parte superior (volver a recortar)
        // El fondo ya se dibujó con clip, el header está encima

        PDFDraw.drawText(title.uppercased(),
                         in: headerRect.insetBy(dx: 6, dy: 3),
                         font: .systemFont(ofSize: 7.5, weight: .black),
                         color: PDFStyles.cBlanco,
                         alignment: .center)

        // ── Ítems con checkboxes ──────────────────────────────────────
        let sortedKeys = items.keys.sorted()
        let maxItems   = min(sortedKeys.count, 7)
        let startY     = rect.minY + headerH + 4
        let lineH: CGFloat = 13
        let checkSize: CGFloat = 10
        let padX: CGFloat = 6

        var row = 0
        for key in sortedKeys {
            if row >= maxItems { break }
            if key == "Otra" { continue }

            let iy       = startY + CGFloat(row) * lineH
            let checked  = items[key] == true

            // Fondo alternado muy suave
            if row % 2 == 0 {
                PDFStyles.cPrimary.withAlphaComponent(0.04).setFill()
                ctx.fill(CGRect(x: rect.minX, y: iy, width: rect.width, height: lineH))
            }

            // Texto del ítem
            let textColor = checked ? PDFStyles.cGrisTitulo : PDFStyles.cGrisTexto
            let textFont  = UIFont.systemFont(ofSize: 7.5, weight: checked ? .semibold : .regular)
            PDFDraw.drawText(key,
                             in: CGRect(x: rect.minX + padX,
                                        y: iy + 1,
                                        width: rect.width - padX - checkSize - padX,
                                        height: lineH),
                             font: textFont,
                             color: textColor,
                             alignment: .left)

            // Checkbox a la derecha
            let boxRect = CGRect(x: rect.maxX - checkSize - padX,
                                 y: iy + 1.5,
                                 width: checkSize,
                                 height: checkSize)
            drawSquareCheck(checked: checked, in: boxRect, ctx: ctx)

            row += 1
        }
    }

    // MARK: - Checkbox individual con colores de marca

    static func drawSquareCheck(checked: Bool, in rect: CGRect) {
        guard let ctx = UIGraphicsGetCurrentContext() else { return }
        drawSquareCheck(checked: checked, in: rect, ctx: ctx)
    }

    static func drawSquareCheck(checked: Bool, in rect: CGRect, ctx: CGContext) {
        if checked {
            // Fondo de marca cuando está marcado
            PDFStyles.cPrimary.withAlphaComponent(0.15).setFill()
            UIBezierPath(roundedRect: rect, cornerRadius: 2).fill()

            // Borde de marca
            PDFStyles.cPrimary.setStroke()
            let p = UIBezierPath(roundedRect: rect, cornerRadius: 2)
            p.lineWidth = 0.8
            p.stroke()

            // Checkmark en color de acento
            let check = UIBezierPath()
            check.move(to:    CGPoint(x: rect.minX + 1.5, y: rect.midY + 0.5))
            check.addLine(to: CGPoint(x: rect.midX - 1,   y: rect.maxY - 2))
            check.addLine(to: CGPoint(x: rect.maxX - 1.5, y: rect.minY + 2))
            PDFStyles.cAccent.setStroke()
            check.lineWidth = 1.8
            check.lineCapStyle = .round
            check.stroke()
        } else {
            // Caja vacía — borde sutil
            PDFStyles.cGrisLinea.setStroke()
            let p = UIBezierPath(roundedRect: rect, cornerRadius: 2)
            p.lineWidth = 0.7
            p.stroke()
        }
    }
}
