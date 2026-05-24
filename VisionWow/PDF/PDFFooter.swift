//
//  PDFFooter.swift
//  VisionWow — Pie de página con redes sociales y datos de contacto
//
import UIKit

enum PDFFooter {

    private static let footerH:   CGFloat = 46
    private static let vwTelefono = "55 7209 8995"
    private static let vwWhatsApp  = "@vissionwow"
    private static let vwCorreo    = "visionwow@gmail.com"
    private static let vwSucursal  = "Valle de Chalco, Edo. Mex."

    // MARK: - Dibuja el pie de página en la parte inferior de la página actual

    static func draw(pageRect: CGRect, x: CGFloat, w: CGFloat,
                     ctx: UIGraphicsPDFRendererContext) {
        let cg = ctx.cgContext
        let startY = pageRect.height - PDFLayout.marginBottom - footerH

        // ── Línea degradada superior ──────────────────────────────────
        PDFStyles.drawBrandGradient(
            in: CGRect(x: 0, y: startY, width: pageRect.width, height: 2), ctx: cg)

        // ── Fondo del footer ──────────────────────────────────────────
        PDFStyles.cGrisFondo.setFill()
        cg.fill(CGRect(x: 0, y: startY + 2, width: pageRect.width, height: footerH - 2))

        // ── Cuatro columnas de info ───────────────────────────────────
        let colW = w / 4
        let items: [(String, String, String)] = [
            ("●", "TEL.", vwTelefono),
            ("◆", "WHATSAPP", vwWhatsApp),
            ("✉", "CORREO", vwCorreo),
            ("◎", "SUCURSAL", vwSucursal)
        ]

        for (i, (icon, label, value)) in items.enumerated() {
            let ix  = x + CGFloat(i) * colW
            let iy  = startY + 8

            // Separador vertical (excepto primera columna)
            if i > 0 {
                PDFStyles.cGrisLinea.setFill()
                cg.fill(CGRect(x: ix - 1, y: iy, width: 0.6, height: 30))
            }

            // Icono en color de acento
            PDFDraw.drawText(icon,
                             in: CGRect(x: ix + 4, y: iy + 1, width: 14, height: 14),
                             font: .systemFont(ofSize: 10, weight: .regular),
                             color: PDFStyles.cAccent,
                             alignment: .center)

            // Etiqueta
            PDFDraw.drawText(label,
                             in: CGRect(x: ix + 20, y: iy, width: colW - 24, height: 11),
                             font: .systemFont(ofSize: 6.5, weight: .semibold),
                             color: PDFStyles.cSecondary,
                             alignment: .left)

            // Valor
            PDFDraw.drawText(value,
                             in: CGRect(x: ix + 20, y: iy + 12, width: colW - 24, height: 12),
                             font: .systemFont(ofSize: 8, weight: .semibold),
                             color: PDFStyles.cGrisTitulo,
                             alignment: .left)
        }

        // ── Línea inferior con slogan ─────────────────────────────────
        let sloganY = startY + footerH - 14
        PDFStyles.cPrimary.withAlphaComponent(0.12).setFill()
        cg.fill(CGRect(x: 0, y: sloganY - 2, width: pageRect.width, height: 14))

        PDFDraw.drawText("VISSION WOW  ·  La mejor atención en servicio óptico  ·  Valle de Chalco, Edo. Méx.",
                         in: CGRect(x: x, y: sloganY, width: w, height: 11),
                         font: .systemFont(ofSize: 7, weight: .regular),
                         color: PDFStyles.cSecondary,
                         alignment: .center)
    }
}
