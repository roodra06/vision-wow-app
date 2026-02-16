//
//  ValueTypes.swift
//  VisionWow
//
//  Created by Rodrigo Marcos on 27/12/25.
//

import Foundation

struct FormValidationError: Identifiable, Hashable {
    var id: String { fieldKey + ":" + message }
    let fieldKey: String
    let message: String
}

enum SexOption: String, CaseIterable, Identifiable {
    case masculino = "Masculino"
    case femenino = "Femenino"
    case noEspecificado = "No especificado"

    var id: String { rawValue }
}


