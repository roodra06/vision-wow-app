//
//  PDFHeader.swift
//  VisionWow — Encabezado del documento de paciente
//
import UIKit

enum PDFHeader {

    // MARK: - Constantes de contacto Vission Wow

    private static let vwTelefono  = "55 7209 8995"
    private static let vwWhatsApp  = "@vissionwow"
    private static let vwCorreo    = "visionwow@gmail.com"
    private static let vwSucursal  = "Valle de Chalco, Edo. Méx."
    private static let vwCP        = "C.P. 56610"
    private static let vwSlogan    = "La mejor atención en servicio óptico"

    // MARK: - Header principal (degradado de marca)

    @discardableResult
    static func drawTopHeaderRow(
        ctx: UIGraphicsPDFRendererContext,
        pageRect: CGRect,
        x: CGFloat, y: CGFloat, w: CGFloat,
        logo: UIImage
    ) -> CGFloat {
        let cg = ctx.cgContext
        var yy = y

        // ── Franja 1: degradado de marca (62 pt) ──────────────────────
        let brandH: CGFloat = 62
        let brandRect = CGRect(x: 0, y: yy, width: pageRect.width, height: brandH)
        PDFStyles.drawBrandGradient(in: brandRect, ctx: cg)

        // ── Logo CIRCULAR ─────────────────────────────────────────────
        let logoSize: CGFloat = 52
        let logoRect = CGRect(x: x, y: yy + (brandH - logoSize) / 2,
                              width: logoSize, height: logoSize)

        // Fondo circular blanco suave
        UIColor.white.withAlphaComponent(0.22).setFill()
        UIBezierPath(ovalIn: logoRect).fill()

        // Clip circular y dibujar logo
        cg.saveGState()
        UIBezierPath(ovalIn: logoRect.insetBy(dx: 1.5, dy: 1.5)).addClip()
        logo.draw(in: logoRect.insetBy(dx: 1.5, dy: 1.5))
        cg.restoreGState()

        // Borde blanco del círculo
        UIColor.white.withAlphaComponent(0.65).setStroke()
        let circleBorder = UIBezierPath(ovalIn: logoRect.insetBy(dx: 0.5, dy: 0.5))
        circleBorder.lineWidth = 1.5
        circleBorder.stroke()

        // ── Nombre + subtítulo (centro-izquierda) ────────────────────
        let centerX = x + logoSize + 14
        let centerW = w - logoSize - 14 - 162

        PDFDraw.drawText("VISSION WOW",
                         in: CGRect(x: centerX, y: yy + 11, width: centerW, height: 24),
                         font: .systemFont(ofSize: 18, weight: .black),
                         color: PDFStyles.cBlanco,
                         alignment: .left)
        PDFDraw.drawText("Historial Clínico Visual",
                         in: CGRect(x: centerX, y: yy + 36, width: centerW, height: 14),
                         font: .systemFont(ofSize: 9.5, weight: .semibold),
                         color: PDFStyles.cBlanco.withAlphaComponent(0.85),
                         alignment: .left)
        PDFDraw.drawText(vwSlogan,
                         in: CGRect(x: centerX, y: yy + 51, width: centerW, height: 12),
                         font: .systemFont(ofSize: 8, weight: .regular),
                         color: PDFStyles.cBlanco.withAlphaComponent(0.60),
                         alignment: .left)

        // ── Contacto (derecha) ────────────────────────────────────────
        let rightX = x + w - 158
        PDFDraw.drawText("Tel.  \(vwTelefono)",
                         in: CGRect(x: rightX, y: yy + 9, width: 158, height: 13),
                         font: .systemFont(ofSize: 8.5, weight: .semibold),
                         color: PDFStyles.cBlanco,
                         alignment: .right)
        PDFDraw.drawText("WA  \(vwWhatsApp)",
                         in: CGRect(x: rightX, y: yy + 24, width: 158, height: 12),
                         font: .systemFont(ofSize: 8.5, weight: .regular),
                         color: PDFStyles.cBlanco.withAlphaComponent(0.85),
                         alignment: .right)
        PDFDraw.drawText(vwCorreo,
                         in: CGRect(x: rightX, y: yy + 38, width: 158, height: 12),
                         font: .systemFont(ofSize: 8, weight: .regular),
                         color: PDFStyles.cBlanco.withAlphaComponent(0.75),
                         alignment: .right)
        PDFDraw.drawText("\(vwSucursal)   \(vwCP)",
                         in: CGRect(x: rightX, y: yy + 52, width: 158, height: 12),
                         font: .systemFont(ofSize: 7.5, weight: .regular),
                         color: PDFStyles.cBlanco.withAlphaComponent(0.60),
                         alignment: .right)

        yy += brandH

        // ── Franja 2: aviso de privacidad (58 pt) ────────────────────
        let privH: CGFloat = 58
        PDFStyles.cGrisFondo.setFill()
        cg.fill(CGRect(x: 0, y: yy, width: pageRect.width, height: privH))
        PDFStyles.cGrisLinea.setFill()
        cg.fill(CGRect(x: 0, y: yy, width: pageRect.width, height: 0.6))

        drawPrivacyBox(in: CGRect(x: x, y: yy + 4, width: w, height: privH - 8))

        yy += privH

        // ── Franja 3: fecha (18 pt) ───────────────────────────────────
        let dateH: CGFloat = 18
        let dateRect = CGRect(x: 0, y: yy, width: pageRect.width, height: dateH)
        PDFStyles.cPrimary.withAlphaComponent(0.08).setFill()
        cg.fill(dateRect)
        PDFStyles.cPrimary.withAlphaComponent(0.20).setFill()
        cg.fill(CGRect(x: 0, y: yy, width: pageRect.width, height: 0.6))

        let dateText = PDFDate.formatDMY(Date())
        PDFDraw.drawText("FECHA DE CONSULTA:",
                         in: CGRect(x: x + w - 192, y: yy + 5, width: 102, height: 13),
                         font: .systemFont(ofSize: 8, weight: .semibold),
                         color: PDFStyles.cSecondary,
                         alignment: .right)
        PDFDraw.drawText(dateText,
                         in: CGRect(x: x + w - 86, y: yy + 5, width: 86, height: 13),
                         font: .systemFont(ofSize: 9, weight: .bold),
                         color: PDFStyles.cPrimary,
                         alignment: .right)

        yy += dateH
        return yy
    }

    // MARK: - Aviso de privacidad (Vission Wow)

    static func drawPrivacyBox(in rect: CGRect) {
        let title = "AVISO DE PRIVACIDAD"
        // Texto completo sin cortes — estructurado en dos líneas lógicas
        let body =
            "Sus datos personales están protegidos por Vission Wow, con domicilio en Valle de Chalco, " +
            "Estado de México C.P. 56610, conforme a la Ley Federal de Protección de Datos Personales " +
            "en Posesión de los Particulares. Serán utilizados exclusivamente para fines de atención " +
            "médica visual, seguimiento optométrico y registro de paciente, sin ser compartidos con " +
            "terceros sin su consentimiento expreso. Informes: Tel. \(vwTelefono)   " +
            "Escríbenos a: \(vwCorreo)"

        // Borde izquierdo de acento
        PDFStyles.cAccent.withAlphaComponent(0.55).setFill()
        UIGraphicsGetCurrentContext()?.fill(
            CGRect(x: rect.minX, y: rect.minY, width: 3, height: rect.height))

        let pad: CGFloat = 10
        let cx = rect.minX + pad
        let cw = rect.width - pad

        PDFDraw.drawText(title,
                         in: CGRect(x: cx, y: rect.minY + 1, width: cw, height: 12),
                         font: .systemFont(ofSize: 8, weight: .black),
                         color: PDFStyles.cPrimary,
                         alignment: .left)

        PDFDraw.drawText(body,
                         in: CGRect(x: cx, y: rect.minY + 15, width: cw, height: rect.height - 15),
                         font: .systemFont(ofSize: 7, weight: .regular),
                         color: PDFStyles.cGrisTexto,
                         alignment: .justified)
    }

    // MARK: - Franja de identificación del paciente

    @discardableResult
    static func drawPatientStrip(
        encounter: Encounter,
        x: CGFloat, y: CGFloat, w: CGFloat,
        pageRect: CGRect,
        ctx: UIGraphicsPDFRendererContext
    ) -> CGFloat {
        let cg = ctx.cgContext
        let stripH: CGFloat = 36

        // Fondo gris suave (full width)
        PDFStyles.cGrisFondo.setFill()
        cg.fill(CGRect(x: 0, y: y, width: pageRect.width, height: stripH))

        // Barra degradada izquierda (acento de marca)
        PDFStyles.drawBrandGradient(
            in: CGRect(x: 0, y: y, width: 5, height: stripH), ctx: cg)

        // Línea inferior sutil
        PDFStyles.cGrisLinea.setFill()
        cg.fill(CGRect(x: 0, y: y + stripH - 0.6, width: pageRect.width, height: 0.6))

        // Etiqueta "PACIENTE" pequeña
        PDFDraw.drawText("PACIENTE",
                         in: CGRect(x: x + 5, y: y + 10, width: 55, height: 12),
                         font: .systemFont(ofSize: 7, weight: .semibold),
                         color: PDFStyles.cSecondary,
                         alignment: .left)

        // Separador vertical mini
        PDFStyles.cGrisLinea.setFill()
        cg.fill(CGRect(x: x + 64, y: y + 9, width: 0.8, height: 18))

        // Nombre del paciente — tipografía grande, color de marca
        let firstName = encounter.patient?.firstName ?? ""
        let lastName  = encounter.patient?.lastName  ?? ""
        let nombre    = "\(firstName) \(lastName)".trimmingCharacters(in: .whitespaces)
        PDFDraw.drawText(nombre.isEmpty ? "SIN NOMBRE" : nombre,
                         in: CGRect(x: x + 70, y: y + 7, width: w * 0.58, height: 22),
                         font: .systemFont(ofSize: 13, weight: .black),
                         color: PDFStyles.cPrimary,
                         alignment: .left)

        // Badge garantía (si aplica)
        if encounter.isGuarantee {
            let reason = encounter.guaranteeReason ?? ""
            let badge  = reason.isEmpty ? "★  GARANTIA" : "★  GARANTIA — \(reason)"
            PDFDraw.drawText(badge,
                             in: CGRect(x: x + w - 182, y: y + 10, width: 182, height: 16),
                             font: .systemFont(ofSize: 9, weight: .black),
                             color: PDFStyles.cAmbar,
                             alignment: .right)
        }

        return y + stripH + 8
    }

    // MARK: - Compatibilidad (no-op — fecha ya va en header)

    @discardableResult
    static func drawDateRow(
        ctx: UIGraphicsPDFRendererContext,
        pageRect: CGRect,
        x: CGFloat, y: CGFloat, w: CGFloat
    ) -> CGFloat { return y }
}
