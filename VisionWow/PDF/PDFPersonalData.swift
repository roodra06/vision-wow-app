//
//  PDFPersonalData.swift
//  VisionWow — Sección: Datos personales del paciente
//
import UIKit

enum PDFPersonalData {

    static func drawPersonalDataGrid(encounter: Encounter,
                                      x: CGFloat, y: CGFloat, w: CGFloat) -> CGFloat {
        let p  = encounter.patient
        var yy = y + 2

        // ── Foto + bloque de datos ────────────────────────────────────
        let photoSize: CGFloat = 54
        var contentX  = x
        var contentW  = w

        if let imgData = p?.profileImageData, let img = UIImage(data: imgData) {
            guard let ctx = UIGraphicsGetCurrentContext() else { return yy }
            let photoRect = CGRect(x: x, y: yy, width: photoSize, height: photoSize)

            ctx.saveGState()
            UIBezierPath(ovalIn: photoRect).addClip()
            img.draw(in: photoRect)
            ctx.restoreGState()

            PDFStyles.cLavanda.setStroke()
            let circle = UIBezierPath(ovalIn: photoRect.insetBy(dx: 0.5, dy: 0.5))
            circle.lineWidth = 1.5
            circle.stroke()

            contentX = x + photoSize + 10
            contentW = w - photoSize - 10
        }

        // ── Etiqueta "Nombre del paciente" ────────────────────────────
        PDFDraw.drawText("Nombre del Paciente",
                         in: CGRect(x: contentX, y: yy, width: contentW, height: 9),
                         font: .systemFont(ofSize: 7, weight: .semibold),
                         color: PDFStyles.cSecondary,
                         alignment: .left)
        yy += 10

        // ── Nombre destacado ──────────────────────────────────────────
        let nombre = "\(p?.firstName ?? "") \(p?.lastName ?? "")".trimmingCharacters(in: .whitespaces)
        PDFDraw.drawText(nombre.isEmpty ? "—" : nombre,
                         in: CGRect(x: contentX, y: yy, width: contentW, height: 15),
                         font: .systemFont(ofSize: 12, weight: .black),
                         color: PDFStyles.cPrimary,
                         alignment: .left)

        // Subrayado decorativo
        PDFStyles.cLavanda.withAlphaComponent(0.60).setFill()
        UIGraphicsGetCurrentContext()?.fill(
            CGRect(x: contentX, y: yy + 16, width: contentW * 0.35, height: 1.5))
        yy += 22

        // ── Fila 2: Fecha Nac | Edad | Sexo | Tel. Casa ──────────────
        let dob     = p?.dob
        let dobText = dob.map { PDFDate.formatDMY($0) } ?? ""
        let ageText = dob.map { "\(PDFDate.age(from: $0)) Años" } ?? ""

        yy = PDFRows.drawLineRow4(
            a: ("Fecha de Nacimiento", dobText),
            b: ("Edad", ageText),
            c: ("Sexo", p?.sex ?? ""),
            d: ("Tel. Casa", p?.homePhone ?? ""),
            x: contentX, y: yy, w: contentW
        ) + 8

        // ── Fila 3: Tel. Celular | Correo Personal ───────────────────
        yy = PDFRows.drawLineRow2(
            left:  ("Tel. Celular",    p?.cellPhone ?? ""),
            right: ("Correo Personal", p?.personalEmail ?? ""),
            x: contentX, y: yy, w: contentW
        ) + 4

        return max(yy, y + 2 + photoSize + 4)
    }
}
