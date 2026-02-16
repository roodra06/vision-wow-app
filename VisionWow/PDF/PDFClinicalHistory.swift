//
//  PDFClinicalHistory.swift
//  VisionWow
//
//  Created by Rodrigo Marcos on 28/12/25.
//

import UIKit
import Foundation

enum PDFClinicalHistory {

    static func drawClinicalHistoryGrid(encounter: Encounter, x: CGFloat, y: CGFloat, w: CGFloat) -> CGFloat {
        var yy = y

        let rowH: CGFloat = 22
        let gap: CGFloat = 10

        let smallW = (w * 0.44) / 3
        let checksW = w - (smallW * 3) - gap * 4
        let checkEach = checksW / 2

        let r1y = yy

        // Antigüedad label + mini fields
        let antigRect = CGRect(x: x, y: r1y, width: smallW * 3 + gap * 2, height: rowH)
        PDFFields.drawInlineLabel("Antigüedad", in: antigRect, labelW: 72)

        PDFFields.drawSmallLineField(
            label: "Años",
            value: encounter.seniorityYears.map(String.init) ?? "",
            x: x + 80, y: r1y, w: smallW - 10, h: rowH
        )
        PDFFields.drawSmallLineField(
            label: "Meses",
            value: encounter.seniorityMonths.map(String.init) ?? "",
            x: x + 80 + (smallW + gap), y: r1y, w: smallW - 10, h: rowH
        )
        PDFFields.drawSmallLineField(
            label: "Semanas",
            value: encounter.seniorityWeeks.map(String.init) ?? "",
            x: x + 80 + (smallW + gap) * 2, y: r1y, w: smallW - 10, h: rowH
        )

        // Checks (por ahora dummy: Encounter no tiene isPlanta/isEventual)
        let plantaChecked = false
        let eventualChecked = false
        PDFFields.drawCheckBox(
            label: "Planta",
            checked: plantaChecked,
            x: x + w - (checkEach * 2) - gap, y: r1y + 2, w: checkEach, h: rowH
        )
        PDFFields.drawCheckBox(
            label: "Eventual",
            checked: eventualChecked,
            x: x + w - checkEach, y: r1y + 2, w: checkEach, h: rowH
        )

        yy += rowH + 8

        yy = PDFRows.drawLineRow3(
            left: ("Empresa", encounter.companyName),
            mid: ("Suc", encounter.branch),
            right: ("No. Empleado", encounter.employeeNumber ?? ""),
            x: x, y: yy, w: w
        ) + 8

        yy = PDFRows.drawLineRow2(
            left: ("Depto", encounter.department),
            right: ("Jefe inmediato", encounter.directBoss),
            x: x, y: yy, w: w
        ) + 8

        yy = drawTurnoHorarioTelExtRow(
            turno: encounter.shift,
            entrada: encounter.entryTime ?? "",
            salida: encounter.exitTime ?? "",
            tel: encounter.officePhone ?? "",
            ext: encounter.extensionNumber ?? "",
            x: x, y: yy, w: w
        ) + 8

        let personalEmail = encounter.patient?.personalEmail ?? ""
        yy = PDFRows.drawLineRow2(
            left: ("Correo Empresa", encounter.companyEmail),
            right: ("Correo Personal", personalEmail),
            x: x, y: yy, w: w
        ) + 8

        return yy
    }

    static func drawTurnoHorarioTelExtRow(
        turno: String,
        entrada: String,
        salida: String,
        tel: String,
        ext: String,
        x: CGFloat,
        y: CGFloat,
        w: CGFloat
    ) -> CGFloat {

        let h: CGFloat = 22
        let gap: CGFloat = 10

        let turnoW: CGFloat = w * 0.22
        let horarioW: CGFloat = w * 0.38
        let telW: CGFloat = w * 0.28
        let extW = w - turnoW - horarioW - telW - gap * 3

        let turnoRect = CGRect(x: x, y: y, width: turnoW, height: h)
        let horarioRect = CGRect(x: turnoRect.maxX + gap, y: y, width: horarioW, height: h)
        let telRect = CGRect(x: horarioRect.maxX + gap, y: y, width: telW, height: h)
        let extRect = CGRect(x: telRect.maxX + gap, y: y, width: extW, height: h)

        PDFFields.drawLineField(label: "Turno", value: turno, in: turnoRect)

        let hv = makeHorarioValue(entrada: entrada, salida: salida)
        PDFFields.drawLineField(label: "Horario", value: hv, in: horarioRect)

        PDFFields.drawLineField(label: "Tel. Oficina", value: tel, in: telRect)
        PDFFields.drawLineField(label: "Ext", value: ext, in: extRect)

        return y + h
    }

    static func makeHorarioValue(entrada: String, salida: String) -> String {
        let e = entrada.trimmingCharacters(in: .whitespacesAndNewlines)
        let s = salida.trimmingCharacters(in: .whitespacesAndNewlines)
        if e.isEmpty && s.isEmpty { return "de ____ a ____" }
        let left = e.isEmpty ? "____" : e
        let right = s.isEmpty ? "____" : s
        return "de \(left) a \(right)"
    }
}
