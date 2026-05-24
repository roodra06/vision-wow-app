//
//  PDFClinicalHistory.swift
//  VisionWow — Sección: Historia clínica / datos laborales
//
import UIKit
import Foundation

enum PDFClinicalHistory {

    static func drawClinicalHistoryGrid(encounter: Encounter,
                                         x: CGFloat, y: CGFloat, w: CGFloat) -> CGFloat {
        guard let ctx = UIGraphicsGetCurrentContext() else {
            return drawContent(encounter: encounter, x: x, y: y, w: w)
        }

        // Tarjeta de fondo: 5 filas × (18+8) + padding ≈ 140pt
        let cardH: CGFloat = 5 * 27 + 8
        let cardRect = CGRect(x: x - 6, y: y - 4, width: w + 12, height: cardH)
        PDFStyles.drawSectionCard(in: cardRect, ctx: ctx)

        return drawContent(encounter: encounter, x: x, y: y, w: w)
    }

    // MARK: - Contenido

    private static func drawContent(encounter: Encounter,
                                     x: CGFloat, y: CGFloat, w: CGFloat) -> CGFloat {
        var yy  = y + 4
        let rowH: CGFloat = 18
        let gap:  CGFloat = 8

        // ── Fila 1: Antigüedad (solo el campo con valor) + Planta/Eventual ──
        let leftW:  CGFloat = w * 0.55
        let rightW: CGFloat = w - leftW - gap

        // Construir el valor único de antigüedad
        let (antigValue, antigUnit) = resolveAntiguedad(encounter)

        // Campo antigüedad como una sola línea: etiqueta | valor con unidad
        let antigLabelW: CGFloat = 74  // "Antigüedad:"
        PDFFields.drawInlineLabel("Antigüedad:",
                                   in: CGRect(x: x, y: yy, width: antigLabelW, height: rowH),
                                   labelW: antigLabelW)
        // Valor + unidad en el campo restante de la parte izquierda
        let fieldRect = CGRect(x: x + antigLabelW + 4, y: yy,
                               width: leftW - antigLabelW - 4, height: rowH)
        PDFDraw.drawText(antigValue.isEmpty ? "—" : "\(antigValue) \(antigUnit)",
                         in: fieldRect.insetBy(dx: 0, dy: (rowH - 11) / 2 + 1),
                         font: .systemFont(ofSize: 9, weight: antigValue.isEmpty ? .light : .regular),
                         color: antigValue.isEmpty ? PDFStyles.cGrisLinea : PDFStyles.cGrisTitulo,
                         alignment: .left)
        PDFDraw.drawLine(
            from: CGPoint(x: fieldRect.minX, y: yy + rowH - 1.5),
            to:   CGPoint(x: fieldRect.maxX, y: yy + rowH - 1.5),
            color: PDFStyles.cPrimary.withAlphaComponent(0.22), width: 0.8)

        // Checkboxes Planta / Eventual en la parte derecha
        let checkX = x + leftW + gap
        let checkW = (rightW - gap) / 2
        PDFFields.drawCheckBox(label: "Planta",   checked: false,
                                x: checkX, y: yy, w: checkW, h: rowH)
        PDFFields.drawCheckBox(label: "Eventual", checked: false,
                                x: checkX + checkW + gap, y: yy, w: checkW, h: rowH)

        yy += rowH + gap

        // ── Fila 2: Empresa | Sucursal | No. Empleado ────────────────
        yy = PDFRows.drawLineRow3(
            left:  ("Empresa",      encounter.companyName.isEmpty  ? "N/A" : encounter.companyName),
            mid:   ("Sucursal",     encounter.branch.isEmpty       ? "N/A" : encounter.branch),
            right: ("No. Empleado", encounter.employeeNumber       ?? "—"),
            x: x, y: yy, w: w
        ) + gap

        // ── Fila 3: Departamento | Jefe Inmediato ────────────────────
        yy = PDFRows.drawLineRow2(
            left:  ("Departamento",   encounter.department.isEmpty  ? "N/A" : encounter.department),
            right: ("Jefe Inmediato", encounter.directBoss.isEmpty  ? "N/A" : encounter.directBoss),
            x: x, y: yy, w: w
        ) + gap

        // ── Fila 4: Turno | Horario | Tel. Oficina | Ext. ────────────
        yy = drawTurnoHorarioTelExtRow(
            turno:   encounter.shift.isEmpty   ? "N/A" : encounter.shift,
            entrada: encounter.entryTime       ?? "",
            salida:  encounter.exitTime        ?? "",
            tel:     encounter.officePhone     ?? "",
            ext:     encounter.extensionNumber ?? "",
            x: x, y: yy, w: w
        ) + gap

        // ── Fila 5: Correo Empresa | Correo Personal ─────────────────
        let personalEmail = encounter.patient?.personalEmail ?? ""
        yy = PDFRows.drawLineRow2(
            left:  ("Correo Empresa",  encounter.companyEmail.isEmpty ? "N/A" : encounter.companyEmail),
            right: ("Correo Personal", personalEmail.isEmpty          ? "—"   : personalEmail),
            x: x, y: yy, w: w
        ) + 4

        return yy
    }

    // MARK: - Resolver antigüedad (un solo campo)

    private static func resolveAntiguedad(_ encounter: Encounter) -> (String, String) {
        if let years = encounter.seniorityYears, years > 0 {
            return (String(years), "Años")
        } else if let months = encounter.seniorityMonths, months > 0 {
            return (String(months), "Meses")
        } else if let weeks = encounter.seniorityWeeks, weeks > 0 {
            return (String(weeks), "Semanas")
        }
        return ("", "Años")
    }

    // MARK: - Fila Turno / Horario / Tel. / Ext.

    static func drawTurnoHorarioTelExtRow(
        turno: String, entrada: String, salida: String,
        tel: String, ext: String,
        x: CGFloat, y: CGFloat, w: CGFloat
    ) -> CGFloat {
        let h:   CGFloat = 18
        let gap: CGFloat = 8

        let turnoW:   CGFloat = w * 0.22
        let horarioW: CGFloat = w * 0.36
        let telW:     CGFloat = w * 0.28
        let extW = w - turnoW - horarioW - telW - gap * 3

        PDFFields.drawLineField(label: "Turno",        value: turno,
                                 in: CGRect(x: x, y: y, width: turnoW, height: h))
        PDFFields.drawLineField(label: "Horario",      value: makeHorarioValue(entrada: entrada, salida: salida),
                                 in: CGRect(x: x + turnoW + gap, y: y, width: horarioW, height: h))
        PDFFields.drawLineField(label: "Tel. Oficina", value: tel.isEmpty ? "—" : tel,
                                 in: CGRect(x: x + turnoW + gap + horarioW + gap, y: y, width: telW, height: h))
        PDFFields.drawLineField(label: "Ext.",         value: ext.isEmpty ? "—" : ext,
                                 in: CGRect(x: x + turnoW + gap + horarioW + gap + telW + gap, y: y, width: extW, height: h))
        return y + h
    }

    static func makeHorarioValue(entrada: String, salida: String) -> String {
        let e = entrada.trimmingCharacters(in: .whitespacesAndNewlines)
        let s = salida.trimmingCharacters(in: .whitespacesAndNewlines)
        if e.isEmpty && s.isEmpty { return "N/A" }
        return "\(e.isEmpty ? "___" : e) — \(s.isEmpty ? "___" : s)"
    }
}
