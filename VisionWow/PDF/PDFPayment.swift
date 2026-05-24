//
//  PDFPayment.swift
//  VisionWow — Sección: Pago con diseño ejecutivo de marca
//
import UIKit

enum PDFPayment {

    static func drawPaymentBlock(encounter: Encounter,
                                  x: CGFloat, y: CGFloat, w: CGFloat,
                                  pageRect: CGRect,
                                  ctx: UIGraphicsPDFRendererContext) -> CGFloat {
        var yy = y

        if yy + 130 > pageRect.height - PDFLayout.marginBottom {
            ctx.beginPage()
            yy = PDFLayout.marginTop
        }

        yy = PDFSections.drawSectionTitle("PAGO", x: x, y: yy, w: w)
        yy += 6

        let cctx = ctx.cgContext
        yy = drawPaymentCard(encounter: encounter, x: x, y: yy, w: w, ctx: cctx)
        return yy
    }

    // MARK: - Tarjeta de pago

    private static func drawPaymentCard(encounter: Encounter,
                                         x: CGFloat, y: CGFloat, w: CGFloat,
                                         ctx: CGContext) -> CGFloat {
        // ── Altura total estimada ─────────────────────────────────────
        let cardH: CGFloat = 98
        let cardRect = CGRect(x: x, y: y - 4, width: w, height: cardH)

        // ── 1. Fondo de tarjeta (primero) ─────────────────────────────
        drawCardBackground(in: cardRect, ctx: ctx)

        let pad: CGFloat = 12
        let innerX = x + pad
        let innerW = w - pad * 2
        var yy = y + 6

        // ── 2. Fila superior: Status + Total ──────────────────────────
        let statusColor = payStatusColor(encounter.payStatus)
        drawStatusBadge(text: encounter.payStatus.isEmpty ? "PENDIENTE" : encounter.payStatus.uppercased(),
                        color: statusColor, x: innerX, y: yy, ctx: ctx)

        // Total destacado (derecha)
        let totalValue = encounter.payTotal.isEmpty ? "—" : encounter.payTotal
        PDFDraw.drawText("TOTAL A PAGAR",
                         in: CGRect(x: x + w - 140, y: yy, width: 128, height: 11),
                         font: .systemFont(ofSize: 7.5, weight: .semibold),
                         color: PDFStyles.cSecondary,
                         alignment: .right)
        PDFDraw.drawText(totalValue,
                         in: CGRect(x: x + w - 140, y: yy + 12, width: 128, height: 20),
                         font: .systemFont(ofSize: 16, weight: .black),
                         color: PDFStyles.cPrimary,
                         alignment: .right)

        yy += 34

        // ── 3. Separador ──────────────────────────────────────────────
        PDFStyles.cGrisLinea.setStroke()
        let sep = UIBezierPath()
        sep.move(to: CGPoint(x: innerX, y: yy))
        sep.addLine(to: CGPoint(x: innerX + innerW, y: yy))
        sep.lineWidth = 0.5
        sep.stroke()
        yy += 8

        // ── 4. Fila: Método de pago | Referencia ─────────────────────
        yy = PDFRows.drawLineRow2(
            left:  ("Método de Pago", encounter.payMethod.isEmpty    ? "—" : encounter.payMethod),
            right: ("Referencia",     encounter.payReference.isEmpty ? "—" : encounter.payReference),
            x: innerX, y: yy, w: innerW
        ) + 8

        // ── 5. Fila: Descuento | Notas ────────────────────────────────
        yy = PDFRows.drawLineRow2(
            left:  ("Descuento Aplicado", PDFStyles.formatDiscount(encounter.payDiscount)),
            right: ("Notas / Observaciones", encounter.payNotes ?? ""),
            x: innerX, y: yy, w: innerW
        ) + 6

        return yy
    }

    // MARK: - Fondo de tarjeta con degradado izquierdo

    private static func drawCardBackground(in rect: CGRect, ctx: CGContext) {
        ctx.saveGState()
        UIBezierPath(roundedRect: rect, cornerRadius: 6).addClip()
        PDFStyles.cGrisFondo.setFill()
        UIBezierPath(roundedRect: rect, cornerRadius: 6).fill()
        ctx.restoreGState()

        // Borde degradado izquierdo
        let accentRect = CGRect(x: rect.minX, y: rect.minY, width: 4, height: rect.height)
        PDFStyles.drawBrandGradientRounded(in: accentRect, radius: 2, ctx: ctx)

        // Borde exterior sutil
        PDFStyles.cGrisLinea.setStroke()
        let border = UIBezierPath(roundedRect: rect.insetBy(dx: 0.5, dy: 0.5), cornerRadius: 6)
        border.lineWidth = 0.6
        border.stroke()
    }

    // MARK: - Pill de estatus semántico

    private static func drawStatusBadge(text: String, color: UIColor,
                                         x: CGFloat, y: CGFloat, ctx: CGContext) {
        let pillW: CGFloat = 100
        let pillH: CGFloat = 22
        let pillRect = CGRect(x: x, y: y + 2, width: pillW, height: pillH)

        ctx.saveGState()
        UIBezierPath(roundedRect: pillRect, cornerRadius: 6).addClip()
        color.withAlphaComponent(0.12).setFill()
        UIBezierPath(roundedRect: pillRect, cornerRadius: 6).fill()
        ctx.restoreGState()

        color.withAlphaComponent(0.50).setStroke()
        let b = UIBezierPath(roundedRect: pillRect.insetBy(dx: 0.4, dy: 0.4), cornerRadius: 6)
        b.lineWidth = 0.8
        b.stroke()

        // Dot de color
        color.withAlphaComponent(0.80).setFill()
        ctx.fillEllipse(in: CGRect(x: pillRect.minX + 7, y: pillRect.midY - 3.5, width: 7, height: 7))

        PDFDraw.drawText(text,
                         in: CGRect(x: pillRect.minX + 18, y: pillRect.minY + 4, width: pillW - 22, height: 14),
                         font: .systemFont(ofSize: 8, weight: .bold),
                         color: color,
                         alignment: .left)
    }

    // MARK: - Color semántico por estatus

    private static func payStatusColor(_ status: String) -> UIColor {
        let s = status.lowercased()
        if s.contains("pagado") || s.contains("liquidado") || s.contains("completo") {
            return PDFStyles.cVerde
        } else if s.contains("pendiente") || s.contains("parcial") {
            return PDFStyles.cAmbar
        } else {
            return PDFStyles.cSecondary
        }
    }
}
