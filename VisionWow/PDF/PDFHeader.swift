//
//  PDFHeader.swift
//  VisionWow
//
//  Created by Rodrigo Marcos on 28/12/25.
//
import UIKit

enum PDFHeader {

    static func drawTopHeaderRow(
        ctx: UIGraphicsPDFRendererContext,
        pageRect: CGRect,
        x: CGFloat,
        y: CGFloat,
        w: CGFloat,
        logo: UIImage
    ) -> CGFloat {

        let rowH: CGFloat = 78

        let logoW: CGFloat = 92
        let rightW: CGFloat = 190
        let gap: CGFloat = 10
        let privacyW = w - logoW - rightW - gap * 2

        let logoRect = CGRect(x: x, y: y, width: logoW, height: rowH)
        let privacyRect = CGRect(x: logoRect.maxX + gap, y: y, width: privacyW, height: rowH)
        let rightRect = CGRect(x: privacyRect.maxX + gap, y: y, width: rightW, height: rowH)

        // Logo aspect fit (sin estirar)
        PDFDraw.drawImageAspectFit(logo, in: logoRect.insetBy(dx: 4, dy: 6))

        // Slogan (opcional)
        let topSlogan = "La mejor atención en servicio óptico"
        let sloganRect = CGRect(x: privacyRect.minX, y: privacyRect.minY - 2, width: privacyRect.width, height: 12)
        PDFDraw.drawText(topSlogan, in: sloganRect, font: .systemFont(ofSize: 8.5, weight: .semibold), color: .darkGray, alignment: .center)

        // Aviso (UN SOLO CUADRO)
        PDFHeader.drawPrivacyBox(in: privacyRect.insetBy(dx: 4, dy: 14))

        // Derecha: sucursales / tel / whatsapp (letra más chica)
        let rightText =
        """
        Sucursales Cd. México / Toluca   Tels: 555754-5423
        WhatsApp: 553342-8515
        """
        PDFDraw.drawText(rightText, in: rightRect.insetBy(dx: 0, dy: 8), font: .systemFont(ofSize: 8.2, weight: .semibold), color: .black, alignment: .right)

        return y + rowH
    }

    static func drawPrivacyBox(in rect: CGRect) {
        let title = "AVISO DE PRIVACIDAD"

        // Texto completo (tu versión)
        let body =
        """
        Sus datos están protegidos por Atención Integral en Servicios de Salud Solher S de RL de C.V. y/o Cover Pay S.A. de C.V quienes utilizarán sus datos personales recabados con los siguientes fines:
        • Fines médicos     • Fines bancarios.
        Para mayor información sobre el tratamiento de sus datos personales usted puede acudir a nuestras instalaciones o a: www.grupoopticosolher.com.mx
        TIENDA EN LÍNEA: www.grupoopticosolher.com.mx/tienda/
        """

        let path = UIBezierPath(roundedRect: rect, cornerRadius: 6)
        UIColor.white.setFill()
        path.fill()

        UIColor.black.withAlphaComponent(0.35).setStroke()
        path.lineWidth = 0.8
        path.stroke()

        let pad: CGFloat = 6
        let titleRect = CGRect(x: rect.minX + pad, y: rect.minY + 3, width: rect.width - pad * 2, height: 10)
        PDFDraw.drawText(title, in: titleRect, font: .systemFont(ofSize: 8.2, weight: .bold), color: .black, alignment: .center)

        let bodyRect = CGRect(
            x: rect.minX + pad,
            y: titleRect.maxY + 2,
            width: rect.width - pad * 2,
            height: rect.maxY - (titleRect.maxY + 2)
        )
        PDFDraw.drawText(body, in: bodyRect, font: .systemFont(ofSize: 7.2, weight: .regular), color: .black, alignment: .left)
    }

    static func drawDateRow(ctx: UIGraphicsPDFRendererContext, pageRect: CGRect, x: CGFloat, y: CGFloat, w: CGFloat) -> CGFloat {
        let dateText = PDFDate.formatDMY(Date())

        let labelFont = UIFont.systemFont(ofSize: 9.5, weight: .semibold)
        let valueFont = UIFont.systemFont(ofSize: 9.5, weight: .regular)

        let rightW: CGFloat = 220
        let rect = CGRect(x: x + w - rightW, y: y, width: rightW, height: 16)

        PDFDraw.drawText("Fecha:", in: CGRect(x: rect.minX, y: rect.minY, width: 38, height: rect.height),
                 font: labelFont, color: .black, alignment: .left)

        let valueRect = CGRect(x: rect.minX + 40, y: rect.minY, width: rect.width - 40, height: rect.height)
        PDFDraw.drawText(dateText, in: valueRect, font: valueFont, color: .black, alignment: .left)

        PDFDraw.drawLine(
            from: CGPoint(x: valueRect.minX, y: valueRect.maxY - 2),
            to: CGPoint(x: valueRect.maxX, y: valueRect.maxY - 2),
            color: UIColor.black.withAlphaComponent(0.25),
            width: 1
        )

        return y + rect.height
    }
}
