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

        if yy + 280 > pageRect.height - PDFLayout.marginBottom {
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
            left: ("DP", encounter.dip),
            mid: ("Tipo de lente", encounter.lensType),
            right: ("Uso", encounter.usage),
            x: x, y: yy, w: w
        ) + 10

        yy = PDFRows.drawLineRow2(
            left: ("Diagnóstico", encounter.diagnostico.isEmpty ? "—" : encounter.diagnostico),
            right: ("Fecha de consulta", encounter.followUpDate.map { DateUtils.formatShort($0) } ?? "—"),
            x: x, y: yy, w: w
        ) + 10

        yy = PDFRows.drawLineRow2(
            left: ("Ishihara", encounter.ishihara),
            right: ("Campimetría", encounter.campimetry),
            x: x, y: yy, w: w
        ) + 4

        // Garantía
        if encounter.isGuarantee {
            yy += 8
            let reason = encounter.guaranteeReason ?? ""
            yy = PDFRows.drawLongLine(
                label: "GARANTÍA",
                value: reason.isEmpty ? "—" : reason,
                x: x, y: yy, w: w
            ) + 4
        }

        // Firmas
        let hasSigs = encounter.patientSignatureData != nil || encounter.optometristSignatureData != nil
        if hasSigs {
            if yy + 160 > pageRect.height - PDFLayout.marginBottom {
                ctx.beginPage()
                yy = PDFLayout.marginTop
            }
            yy += 12
            yy = PDFSections.drawSectionTitle("FIRMAS", x: x, y: yy, w: w)
            yy += 6

            if let data = encounter.patientSignatureData, let img = UIImage(data: data) {
                yy = PDFRows.drawSignatureRow(label: "Firma del Paciente", image: img, x: x, y: yy, w: w) + 10
            }
            if let data = encounter.optometristSignatureData, let img = UIImage(data: data) {
                yy = PDFRows.drawSignatureRow(label: "Firma del Optometrista", image: img, x: x, y: yy, w: w) + 10
            }
        }

        return yy
    }
}


