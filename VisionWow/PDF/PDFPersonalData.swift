//
//  PDFPersonalData.swift
//  VisionWow
//
//  Created by Rodrigo Marcos on 28/12/25.
//
import UIKit

enum PDFPersonalData {

    static func drawPersonalDataGrid(encounter: Encounter, x: CGFloat, y: CGFloat, w: CGFloat) -> CGFloat {
        var yy = y

        // Fuente de datos personales
        let p = encounter.patient

        yy = PDFRows.drawLineRow2(
            left: ("Nombre(s)", p?.firstName ?? ""),
            right: ("Apellidos", p?.lastName ?? ""),
            x: x, y: yy, w: w
        ) + 8

        // Si tu Patient usa otro nombre para la fecha (ej. birthDate), cámbialo aquí:
        let dob = p?.dob
        let dobText = dob.map { PDFDate.formatDMY($0) } ?? ""
        let ageText = dob.map { String(PDFDate.age(from: $0)) } ?? ""

        yy = PDFRows.drawLineRow4(
            a: ("Fecha Nac", dobText),
            b: ("Edad", ageText),
            c: ("Sexo", p?.sex ?? ""),
            d: ("Tel. Casa", p?.homePhone ?? ""),
            x: x, y: yy, w: w
        ) + 8

        yy = PDFRows.drawLineRow2(
            left: ("Tel. Cel", p?.cellPhone ?? ""),
            right: ("", ""),
            x: x, y: yy, w: w
        ) + 2

        return yy
    }
}
