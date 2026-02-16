//
//  PDFExam.swift
//  VisionWow
//
//  Created by Rodrigo Marcos on 28/12/25.
//
import UIKit

enum PDFExam {

    static func drawExamBlock(encounter: Encounter, x: CGFloat, y: CGFloat, w: CGFloat, pageRect: CGRect, ctx: UIGraphicsPDFRendererContext) -> CGFloat {
        var yy = y

        if yy + 220 > pageRect.height - PDFLayout.marginBottom {
            ctx.beginPage()
            yy = PDFLayout.marginTop
        }

        yy = PDFSections.drawSectionTitle("AGUDEZA VISUAL / REFRACTION", x: x, y: yy, w: w)
        yy += 6

        yy = PDFRows.drawLineRow4(
            a: ("OD S/C", encounter.vaOdSc),
            b: ("OS S/C", encounter.vaOsSc),
            c: ("OD C/C", encounter.vaOdCc),
            d: ("OS C/C", encounter.vaOsCc),
            x: x, y: yy, w: w
        ) + 10

        yy = PDFSections.drawMiniGridTitle("RX OD", x: x, y: yy, w: w) + 2
        yy = PDFRows.drawLineRow4(
            a: ("SPH", encounter.rxOdSph),
            b: ("CYL", encounter.rxOdCyl),
            c: ("AXIS", encounter.rxOdAxis),
            d: ("ADD", encounter.rxOdAdd),
            x: x, y: yy, w: w
        ) + 10

        yy = PDFSections.drawMiniGridTitle("RX OS", x: x, y: yy, w: w) + 2
        yy = PDFRows.drawLineRow4(
            a: ("SPH", encounter.rxOsSph),
            b: ("CYL", encounter.rxOsCyl),
            c: ("AXIS", encounter.rxOsAxis),
            d: ("ADD", encounter.rxOsAdd),
            x: x, y: yy, w: w
        ) + 10

        yy = PDFRows.drawLineRow3(
            left: ("DP", encounter.dp),
            mid: ("Tipo de lente", encounter.lensType),
            right: ("Uso", encounter.usage),
            x: x, y: yy, w: w
        ) + 10

        yy = PDFRows.drawLineRow2(
            left: ("Ishihara", encounter.ishihara),
            right: ("Campimetría", encounter.campimetry),
            x: x, y: yy, w: w
        ) + 4

        return yy
    }
}


