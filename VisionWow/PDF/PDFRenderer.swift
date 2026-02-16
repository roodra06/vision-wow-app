import UIKit

enum PDFRenderer {

    static func render(encounter: Encounter, logo: UIImage) -> Data {
        let pageRect = PDFLayout.pageRectLetterPortrait
        let x = PDFLayout.marginX
        let marginTop = PDFLayout.marginTop
        let w = pageRect.width - x * 2

        let renderer = UIGraphicsPDFRenderer(bounds: pageRect)

        return renderer.pdfData { ctx in
            ctx.beginPage()
            var y: CGFloat = marginTop

            // Header triple: Logo | Aviso Privacidad | Sucursales/WhatsApp
            y = PDFHeader.drawTopHeaderRow(
                ctx: ctx,
                pageRect: pageRect,
                x: x,
                y: y,
                w: w,
                logo: logo
            )

            // Fecha
            y += 8
            y = PDFHeader.drawDateRow(ctx: ctx, pageRect: pageRect, x: x, y: y, w: w)
            y += 10

            // Body
            y = PDFBody.drawBody(ctx: ctx, pageRect: pageRect, x: x, y: y, w: w, encounter: encounter)

            _ = y
        }
    }
}
