//
//  PDFBody.swift
//  VisionWow — Orquestador de secciones del cuerpo del documento
//
import UIKit

enum PDFBody {

    @discardableResult
    static func drawBody(
        ctx: UIGraphicsPDFRendererContext,
        pageRect: CGRect,
        x: CGFloat,
        y: CGFloat,
        w: CGFloat,
        encounter: Encounter
    ) -> CGFloat {

        var yy = y

        // ── Datos personales (nombre del paciente va aquí, sin franja separada) ──
        yy = PDFSections.drawSectionTitle("DATOS PERSONALES", x: x, y: yy, w: w)
        yy = PDFPersonalData.drawPersonalDataGrid(encounter: encounter, x: x, y: yy, w: w)
        yy += 8

        // ── Historia clínica / datos laborales ───────────────────────
        yy = PDFSections.drawSectionTitle("HISTORIA CLÍNICA", x: x, y: yy, w: w)
        yy = PDFClinicalHistory.drawClinicalHistoryGrid(encounter: encounter, x: x, y: yy, w: w)
        yy += 8

        // ── Antecedentes y síntomas ───────────────────────────────────
        // Necesita ~260 pt; forzar nueva página si no hay espacio
        if yy + 260 > pageRect.height - PDFLayout.marginBottom {
            ctx.beginPage()
            yy = PDFLayout.marginTop
        }
        yy = PDFAntecedents.drawAntecedentsGrid(encounter: encounter, x: x, y: yy, w: w)
        yy += 8

        // ── Examen visual ─────────────────────────────────────────────
        yy = PDFExam.drawExamBlock(encounter: encounter,
                                   x: x, y: yy, w: w,
                                   pageRect: pageRect, ctx: ctx)
        yy += 8

        // ── Pago ──────────────────────────────────────────────────────
        yy = PDFPayment.drawPaymentBlock(encounter: encounter,
                                         x: x, y: yy, w: w,
                                         pageRect: pageRect, ctx: ctx)
        yy += 12

        // ── Pie de página ─────────────────────────────────────────────
        PDFFooter.draw(pageRect: pageRect, x: x, w: w, ctx: ctx)

        return yy
    }
}
