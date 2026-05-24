//
//  PDFSections.swift
//  VisionWow — Encabezados de sección con diseño de marca
//
import UIKit

enum PDFSections {

    static let sectionH: CGFloat = 18   // altura del banner de sección (comprimido)
    static let miniH:    CGFloat = 13   // altura del mini-título (comprimido)

    // MARK: - Título principal de sección (gradiente de marca)

    @discardableResult
    static func drawSectionTitle(_ text: String,
                                  x: CGFloat,
                                  y: CGFloat,
                                  w: CGFloat) -> CGFloat {
        guard let ctx = UIGraphicsGetCurrentContext() else { return y + sectionH + 5 }

        let rect = CGRect(x: x, y: y, width: w, height: sectionH)
        PDFStyles.drawBrandGradient(in: rect, ctx: ctx)

        // Línea inferior de acento
        PDFStyles.cAccent.withAlphaComponent(0.55).setFill()
        ctx.fill(CGRect(x: x, y: y + sectionH - 1, width: w, height: 1))

        PDFDraw.drawText(text.uppercased(),
                         in: CGRect(x: x + 8, y: y + 3, width: w - 12, height: sectionH - 4),
                         font: PDFStyles.sectionTitleFont,
                         color: PDFStyles.cBlanco,
                         alignment: .left)

        return y + sectionH + 5
    }

    // MARK: - Mini-título de sub-sección (fondo suave con acento)

    @discardableResult
    static func drawMiniGridTitle(_ s: String,
                                   x: CGFloat,
                                   y: CGFloat,
                                   w: CGFloat) -> CGFloat {
        guard let ctx = UIGraphicsGetCurrentContext() else { return y + miniH + 3 }

        let rect = CGRect(x: x, y: y, width: w, height: miniH)

        PDFStyles.cPrimary.withAlphaComponent(0.08).setFill()
        UIBezierPath(roundedRect: rect, cornerRadius: 2).fill()

        PDFStyles.cAccent.setFill()
        ctx.fill(CGRect(x: x, y: y, width: 3, height: miniH))

        PDFDraw.drawText(s.uppercased(),
                         in: CGRect(x: x + 7, y: y + 2, width: w - 10, height: miniH - 2),
                         font: PDFStyles.miniTitleFont,
                         color: PDFStyles.cPrimary,
                         alignment: .left)

        return y + miniH + 3
    }
}
