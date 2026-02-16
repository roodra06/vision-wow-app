//
//  ShiftOption.swift
//  VisionWow
//
//  Created by Rodrigo Marcos on 27/12/25.
//

import Foundation

enum ShiftOption: String, CaseIterable, Identifiable {
    case manana = "Mañana"
    case tarde  = "Tarde"
    case noche  = "Noche"
    case mixto  = "Mixto"

    var id: String { rawValue }
}
