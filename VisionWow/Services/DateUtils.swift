//
//  DateUtils.swift
//  VisionWow
//
//  Created by Rodrigo Marcos on 27/12/25.
//
import Foundation

enum DateUtils {
    static func age(from dob: Date) -> Int {
        Calendar.current.dateComponents([.year], from: dob, to: Date()).year ?? 0
    }

    static func formatShort(_ date: Date) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "es_MX")
        f.dateStyle = .short
        f.timeStyle = .none
        return f.string(from: date)
    }

    static func formatStamp(_ date: Date = Date()) -> String {
        let f = DateFormatter()
        f.dateFormat = "dd-MM-yyyy"
        return f.string(from: date)
    }
}

