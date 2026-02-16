//
//  PDFDate.swift
//  VisionWow
//
//  Created by Rodrigo Marcos on 28/12/25.
//
import Foundation

enum PDFDate {

    static func formatDMY(_ date: Date) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "es_MX")
        f.dateFormat = "dd / MM / yy"
        return f.string(from: date)
    }

    static func age(from dob: Date) -> Int {
        let cal = Calendar.current
        let comps = cal.dateComponents([.year], from: dob, to: Date())
        return comps.year ?? 0
    }
}

