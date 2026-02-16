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

        yy = PDFRows.drawLineRow2(
            left: ("Nombre(s)", encounter.firstName),
            right: ("Apellidos", encounter.lastName),
            x: x, y: yy, w: w
        ) + 8

        let dobText = encounter.dob.map { PDFDate.formatDMY($0) } ?? ""
        let ageText = encounter.dob.map { String(PDFDate.age(from: $0)) } ?? ""

        yy = PDFRows.drawLineRow4(
            a: ("Fecha Nac", dobText),
            b: ("Edad", ageText),
            c: ("Sexo", encounter.sex),
            d: ("Tel. Casa", encounter.homePhone ?? ""),
            x: x, y: yy, w: w
        ) + 8

        yy = PDFRows.drawLineRow2(
            left: ("Tel. Cel", encounter.cellPhone),
            right: ("", ""),
            x: x, y: yy, w: w
        ) + 2

        return yy
    }
}

