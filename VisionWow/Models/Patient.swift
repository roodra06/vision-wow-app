//
//  Patient.swift
//  VisionWow
//
//  Created by Rodrigo Marcos on 13/01/26.
//
import Foundation
import SwiftData

@Model
final class Patient {
    @Attribute(.unique) var id: UUID
    var createdAt: Date
    var updatedAt: Date

    // Datos personales (persisten)
    var profileImageData: Data?
    var firstName: String
    var lastName: String
    var dob: Date?
    var sex: String
    var homePhone: String?
    var cellPhone: String
    var personalEmail: String

    // Opcional: identificadores internos
    var externalPatientNumber: String?

    // Historial (visitas)
    @Relationship(deleteRule: .cascade)
    var encounters: [Encounter] = []

    init() {
        self.id = UUID()
        self.createdAt = Date()
        self.updatedAt = Date()

        self.profileImageData = nil
        self.firstName = ""
        self.lastName = ""
        self.dob = nil
        self.sex = SexOption.noEspecificado.rawValue
        self.homePhone = nil
        self.cellPhone = ""
        self.personalEmail = ""
        self.externalPatientNumber = nil
    }
}

