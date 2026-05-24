//
//  PDFExam.swift
//  VisionWow — Sección: Agudeza visual, refracción y diagnóstico
//
import UIKit

enum PDFExam {

    static func drawExamBlock(encounter: Encounter,
                               x: CGFloat, y: CGFloat, w: CGFloat,
                               pageRect: CGRect,
                               ctx: UIGraphicsPDFRendererContext) -> CGFloat {
        var yy = y

        if yy + 260 > pageRect.height - PDFLayout.marginBottom {
            ctx.beginPage()
            yy = PDFLayout.marginTop
        }

        yy = PDFSections.drawSectionTitle("AGUDEZA VISUAL Y REFRACCIÓN", x: x, y: yy, w: w)

        // ── Agudeza Visual ─────────────────────────────────────────────
        yy = PDFSections.drawMiniGridTitle("AGUDEZA VISUAL", x: x, y: yy, w: w)
        yy = drawEyeSubHeader(x: x, y: yy, w: w)
        yy = drawVARow(
            odSc: encounter.vaOdSc, osSc: encounter.vaOsSc,
            odCc: encounter.vaOdCc, osCc: encounter.vaOsCc,
            x: x, y: yy, w: w
        ) + 8

        // ── RX OD ──────────────────────────────────────────────────────
        yy = PDFSections.drawMiniGridTitle("RX OJO DERECHO  (OD)", x: x, y: yy, w: w)
        yy = drawRxRow(sph: encounter.rxOdSph, cyl: encounter.rxOdCyl,
                        axis: encounter.rxOdAxis, add: encounter.rxOdAdd,
                        eyeColor: PDFStyles.cPrimary,
                        x: x, y: yy, w: w) + 8

        // ── RX OS ──────────────────────────────────────────────────────
        yy = PDFSections.drawMiniGridTitle("RX OJO IZQUIERDO  (OS)", x: x, y: yy, w: w)
        yy = drawRxRow(sph: encounter.rxOsSph, cyl: encounter.rxOsCyl,
                        axis: encounter.rxOsAxis, add: encounter.rxOsAdd,
                        eyeColor: PDFStyles.cAccent,
                        x: x, y: yy, w: w) + 8

        // ── Prescripción ───────────────────────────────────────────────
        yy = PDFSections.drawMiniGridTitle("PRESCRIPCIÓN", x: x, y: yy, w: w)
        yy = PDFRows.drawLineRow3(
            left:  ("DP",            encounter.dip),
            mid:   ("Tipo de Lente", encounter.lensType),
            right: ("Uso",           encounter.usage),
            x: x, y: yy, w: w
        ) + 6

        yy = PDFRows.drawLineRow2(
            left:  ("Diagnóstico",      encounter.diagnostico.isEmpty ? "—" : encounter.diagnostico),
            right: ("Próxima Consulta", encounter.followUpDate.map { PDFDate.formatDMY($0) } ?? "—"),
            x: x, y: yy, w: w
        ) + 6

        yy = PDFRows.drawLineRow2(
            left:  ("Ishihara",    encounter.ishihara.isEmpty   ? "—" : encounter.ishihara),
            right: ("Campimetría", encounter.campimetry.isEmpty ? "—" : encounter.campimetry),
            x: x, y: yy, w: w
        ) + 6

        // ── Garantía ───────────────────────────────────────────────────
        if encounter.isGuarantee {
            yy += 2
            let reason = encounter.guaranteeReason ?? ""
            yy = PDFRows.drawLongLine(
                label: "GARANTÍA",
                value: reason.isEmpty ? "—" : reason,
                x: x, y: yy, w: w
            ) + 6
        }

        // ── Firmas (siempre horizontales) ──────────────────────────────
        if yy + 100 > pageRect.height - PDFLayout.marginBottom {
            ctx.beginPage()
            yy = PDFLayout.marginTop
        }
        yy += 4
        yy = PDFSections.drawSectionTitle("FIRMAS", x: x, y: yy, w: w)
        yy += 2

        let colW = (w - 20) / 2
        let sigY = yy

        let patImg = encounter.patientSignatureData.flatMap { UIImage(data: $0) }
        drawSignatureCard(label: "FIRMA DEL PACIENTE", image: patImg,
                          x: x, y: sigY, w: colW)

        let optImg = encounter.optometristSignatureData.flatMap { UIImage(data: $0) }
        drawSignatureCard(label: "FIRMA DEL OPTOMETRISTA", image: optImg,
                          x: x + colW + 20, y: sigY, w: colW)

        yy = sigY + 72

        return yy
    }

    // MARK: - Cabecera OD / OS con indicadores visuales de ojo

    private static func drawEyeSubHeader(x: CGFloat, y: CGFloat, w: CGFloat) -> CGFloat {
        guard let ctx = UIGraphicsGetCurrentContext() else { return y }
        let halfW = (w - 10) / 2
        let h: CGFloat = 14

        // OD — morado
        let odRect = CGRect(x: x, y: y, width: halfW, height: h)
        PDFStyles.cPrimary.withAlphaComponent(0.09).setFill()
        UIBezierPath(roundedRect: odRect, cornerRadius: 2).fill()
        PDFStyles.cPrimary.withAlphaComponent(0.25).setStroke()
        let odBorder = UIBezierPath(roundedRect: odRect.insetBy(dx: 0.4, dy: 0.4), cornerRadius: 2)
        odBorder.lineWidth = 0.5; odBorder.stroke()
        // Ojo
        PDFStyles.cPrimary.withAlphaComponent(0.65).setFill()
        ctx.fillEllipse(in: CGRect(x: x + 5, y: y + 3, width: 8, height: 8))
        PDFStyles.cBlanco.setFill()
        ctx.fillEllipse(in: CGRect(x: x + 7, y: y + 5, width: 4, height: 4))
        PDFDraw.drawText("OJO DERECHO  —  OD",
                         in: CGRect(x: x + 17, y: y + 2, width: halfW - 20, height: 10),
                         font: .systemFont(ofSize: 7.5, weight: .bold),
                         color: PDFStyles.cPrimary, alignment: .left)

        // OS — fucsia
        let osX = x + halfW + 10
        let osRect = CGRect(x: osX, y: y, width: halfW, height: h)
        PDFStyles.cAccent.withAlphaComponent(0.09).setFill()
        UIBezierPath(roundedRect: osRect, cornerRadius: 2).fill()
        PDFStyles.cAccent.withAlphaComponent(0.25).setStroke()
        let osBorder = UIBezierPath(roundedRect: osRect.insetBy(dx: 0.4, dy: 0.4), cornerRadius: 2)
        osBorder.lineWidth = 0.5; osBorder.stroke()
        PDFStyles.cAccent.withAlphaComponent(0.65).setFill()
        ctx.fillEllipse(in: CGRect(x: osX + 5, y: y + 3, width: 8, height: 8))
        PDFStyles.cBlanco.setFill()
        ctx.fillEllipse(in: CGRect(x: osX + 7, y: y + 5, width: 4, height: 4))
        PDFDraw.drawText("OJO IZQUIERDO  —  OS",
                         in: CGRect(x: osX + 17, y: y + 2, width: halfW - 20, height: 10),
                         font: .systemFont(ofSize: 7.5, weight: .bold),
                         color: PDFStyles.cAccent, alignment: .left)

        return y + h + 4
    }

    // MARK: - Fila Agudeza Visual con color por ojo

    private static func drawVARow(odSc: String, osSc: String,
                                   odCc: String, osCc: String,
                                   x: CGFloat, y: CGFloat, w: CGFloat) -> CGFloat {
        guard let ctx = UIGraphicsGetCurrentContext() else {
            return PDFRows.drawLineRow4(
                a: ("OD S/C", odSc), b: ("OS S/C", osSc),
                c: ("OD C/C", odCc), d: ("OS C/C", osCc),
                x: x, y: y, w: w)
        }

        let colW  = (w - 18) / 4
        let rowH: CGFloat = 22
        let lineY = y + rowH - 1.5
        let textH: CGFloat = 11
        let textY = lineY - textH - 1

        let fields: [(String, String, UIColor)] = [
            ("OD  S/C", odSc, PDFStyles.cPrimary),
            ("OS  S/C", osSc, PDFStyles.cAccent),
            ("OD  C/C", odCc, PDFStyles.cPrimary),
            ("OS  C/C", osCc, PDFStyles.cAccent)
        ]

        for (i, (label, value, color)) in fields.enumerated() {
            let cx   = x + CGFloat(i) * (colW + 6)
            let rect = CGRect(x: cx, y: y, width: colW, height: rowH)

            color.withAlphaComponent(0.07).setFill()
            UIBezierPath(roundedRect: rect, cornerRadius: 3).fill()

            // Borde lateral
            color.withAlphaComponent(0.28).setFill()
            ctx.fill(CGRect(x: cx, y: y, width: 2.5, height: rowH))

            // Etiqueta
            PDFDraw.drawText(label,
                             in: CGRect(x: cx + 6, y: y + 1, width: colW - 8, height: 9),
                             font: .systemFont(ofSize: 7, weight: .semibold),
                             color: color, alignment: .left)

            // Valor
            PDFDraw.drawText(value.isEmpty ? "—" : value,
                             in: CGRect(x: cx + 6, y: textY, width: colW - 8, height: textH),
                             font: .systemFont(ofSize: 10, weight: .bold),
                             color: value.isEmpty ? PDFStyles.cGrisLinea : PDFStyles.cGrisTitulo,
                             alignment: .left)

            // Línea color
            color.withAlphaComponent(0.22).setFill()
            ctx.fill(CGRect(x: cx + 3, y: lineY, width: colW - 3, height: 0.8))
        }

        return y + rowH
    }

    // MARK: - Fila RX con color por ojo

    private static func drawRxRow(sph: String, cyl: String, axis: String, add: String,
                                   eyeColor: UIColor,
                                   x: CGFloat, y: CGFloat, w: CGFloat) -> CGFloat {
        guard let ctx = UIGraphicsGetCurrentContext() else {
            return PDFRows.drawLineRow4(a: ("SPH", sph), b: ("CYL", cyl),
                                        c: ("EJE", axis), d: ("ADD", add),
                                        x: x, y: y, w: w)
        }

        let colW   = (w - 18) / 4
        let rowH:  CGFloat = 22
        let lineY  = y + rowH - 1.5
        let textH: CGFloat = 11
        let textY  = lineY - textH - 1
        let fields = [("SPH", sph), ("CYL", cyl), ("EJE", axis), ("ADD", add)]

        for (i, (label, value)) in fields.enumerated() {
            let cx   = x + CGFloat(i) * (colW + 6)
            let rect = CGRect(x: cx, y: y, width: colW, height: rowH)

            if !value.isEmpty {
                eyeColor.withAlphaComponent(0.06).setFill()
                UIBezierPath(roundedRect: rect, cornerRadius: 3).fill()
            }

            PDFDraw.drawText(label,
                             in: CGRect(x: cx + 3, y: y + 1, width: colW - 6, height: 9),
                             font: .systemFont(ofSize: 7, weight: .semibold),
                             color: PDFStyles.cSecondary, alignment: .left)

            PDFDraw.drawText(value.isEmpty ? "—" : value,
                             in: CGRect(x: cx + 3, y: textY, width: colW - 6, height: textH),
                             font: .systemFont(ofSize: 10, weight: .bold),
                             color: value.isEmpty ? PDFStyles.cGrisLinea : PDFStyles.cGrisTitulo,
                             alignment: .left)

            eyeColor.withAlphaComponent(0.22).setFill()
            ctx.fill(CGRect(x: cx + 3, y: lineY, width: colW - 6, height: 0.8))
        }

        return y + rowH
    }

    // MARK: - Tarjeta de firma (siempre visible — imagen opcional)

    private static func drawSignatureCard(label: String, image: UIImage?,
                                           x: CGFloat, y: CGFloat, w: CGFloat) {
        let h: CGFloat = 68
        let rect = CGRect(x: x, y: y, width: w, height: h)

        PDFStyles.cGrisFondo.setFill()
        UIBezierPath(roundedRect: rect, cornerRadius: 4).fill()

        PDFStyles.cGrisLinea.setStroke()
        let border = UIBezierPath(roundedRect: rect.insetBy(dx: 0.4, dy: 0.4), cornerRadius: 4)
        border.lineWidth = 0.6; border.stroke()

        // Borde superior degradado
        if let cg = UIGraphicsGetCurrentContext() {
            PDFStyles.drawBrandGradientRounded(
                in: CGRect(x: rect.minX, y: rect.minY, width: rect.width, height: 2.5),
                radius: 2, ctx: cg)
        }

        // Etiqueta
        PDFDraw.drawText(label,
                         in: CGRect(x: x + 5, y: y + 5, width: w - 10, height: 10),
                         font: .systemFont(ofSize: 6.5, weight: .black),
                         color: PDFStyles.cSecondary, alignment: .center)

        if let img = image {
            let imgRect = CGRect(x: x + 6, y: y + 17, width: w - 12, height: 32)
            PDFDraw.drawImageAspectFit(img, in: imgRect)
        } else {
            PDFDraw.drawText("PENDIENTE DE FIRMA",
                             in: CGRect(x: x + 6, y: y + 26, width: w - 12, height: 12),
                             font: .systemFont(ofSize: 7, weight: .light),
                             color: PDFStyles.cGrisLinea, alignment: .center)
        }

        // Línea de firma
        PDFStyles.cLavanda.withAlphaComponent(0.70).setStroke()
        let line = UIBezierPath()
        line.move(to:    CGPoint(x: x + 10,     y: y + h - 8))
        line.addLine(to: CGPoint(x: x + w - 10, y: y + h - 8))
        line.lineWidth = 0.8; line.stroke()
    }
}
