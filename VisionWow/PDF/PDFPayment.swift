//
//  PDFPayment.swift
//  VisionWow
//
//  Created by Rodrigo Marcos on 28/12/25.
//
import UIKit

enum PDFPayment {

    static func drawPaymentBlock(encounter: Encounter, x: CGFloat, y: CGFloat, w: CGFloat, pageRect: CGRect, ctx: UIGraphicsPDFRendererContext) -> CGFloat {
        var yy = y

        if yy + 90 > pageRect.height - PDFLayout.marginBottom {
            ctx.beginPage()
            yy = PDFLayout.marginTop
        }

        yy = PDFSections.drawSectionTitle("PAGO", x: x, y: yy, w: w)
        yy += 4

        yy = PDFRows.drawLineRow4(
            a: ("Estatus", encounter.payStatus),
            b: ("Total", encounter.payTotal),
            c: ("Método", encounter.payMethod),
            d: ("Referencia", encounter.payReference),
            x: x, y: yy, w: w
        ) + 8

        yy = PDFRows.drawLineRow2(
            left: ("Descuento", encounter.payDiscount ?? ""),
            right: ("Notas", encounter.payNotes ?? ""),
            x: x, y: yy, w: w
        ) + 2

        return yy
    }
}


