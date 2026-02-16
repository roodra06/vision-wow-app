//
//  PDFBody.swift
//  VisionWow
//
//  Created by Rodrigo Marcos on 28/12/25.
//
import UIKit

enum PDFBody {

    static func drawBody(
        ctx: UIGraphicsPDFRendererContext,
        pageRect: CGRect,
        x: CGFloat,
        y: CGFloat,
        w: CGFloat,
        encounter: Encounter
    ) -> CGFloat {

        var yy = y

        yy = PDFSections.drawSectionTitle("HISTORIA CLÍNICA", x: x, y: yy, w: w)
        yy += 6

        yy = PDFClinicalHistory.drawClinicalHistoryGrid(encounter: encounter, x: x, y: yy, w: w)
        yy += 10

        yy = PDFPersonalData.drawPersonalDataGrid(encounter: encounter, x: x, y: yy, w: w)
        yy += 10

        yy = PDFAntecedents.drawAntecedentsGrid(encounter: encounter, x: x, y: yy, w: w)
        yy += 10

        yy = PDFExam.drawExamBlock(encounter: encounter, x: x, y: yy, w: w, pageRect: pageRect, ctx: ctx)
        yy += 10

        yy = PDFPayment.drawPaymentBlock(encounter: encounter, x: x, y: yy, w: w, pageRect: pageRect, ctx: ctx)

        return yy
    }
}

