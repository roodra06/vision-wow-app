//
//  Encounter.swift
//  VisionWow
//
//  Created by Rodrigo Marcos on 27/12/25.
//

import Foundation
import SwiftData

@Model
final class Encounter {
    var id: UUID
    var createdAt: Date
    var updatedAt: Date
    var completedAt: Date?

    // ✅ Relación al paciente
    @Relationship(inverse: \Patient.encounters)
    var patient: Patient?

    // ✅ Empresa (si es empresa o “Óptica”)
    @Relationship(inverse: \Company.encounters)
    var company: Company?
    var companyName: String
    var branch: String
    var employeeNumber: String?
    var department: String
    var directBoss: String
    var shift: String
    var entryTime: String?
    var exitTime: String?
    var officePhone: String?
    var extensionNumber: String?
    var companyEmail: String

    // ✅ Antigüedad (empleado)
    var seniorityYears: Int?
    var seniorityMonths: Int?
    var seniorityWeeks: Int?

    // Antecedentes (si lo quieres por visita)
    var antecedentesJSON: String

    // Pruebas
    var ishihara: String
    var campimetry: String

    // Examen visual
    var vaOdSc: String
    var vaOsSc: String
    var vaOdCc: String
    var vaOsCc: String

    var rxOdSph: String
    var rxOdCyl: String
    var rxOdAxis: String
    var rxOdAdd: String
    var rxOsSph: String
    var rxOsCyl: String
    var rxOsAxis: String
    var rxOsAdd: String
    var dp: String

    var lensType: String
    var usage: String
    var followUpDate: Date?

    // Pago
    var payStatus: String
    var payTotal: String
    var payMethod: String
    var payReference: String
    var payDiscount: String?
    var payNotes: String?

    // Helpers (conveniencia para UI/PDF)
    var patientFirstName: String { patient?.firstName ?? "" }
    var patientLastName: String { patient?.lastName ?? "" }
    var patientFullName: String {
        let fn = patientFirstName.trimmingCharacters(in: .whitespacesAndNewlines)
        let ln = patientLastName.trimmingCharacters(in: .whitespacesAndNewlines)
        return [fn, ln].filter { !$0.isEmpty }.joined(separator: " ")
    }

    init() {
        self.id = UUID()
        self.createdAt = Date()
        self.updatedAt = Date()
        self.completedAt = nil

        self.patient = nil
        self.company = nil

        self.companyName = ""
        self.branch = ""
        self.employeeNumber = nil
        self.department = ""
        self.directBoss = ""
        self.shift = ""
        self.entryTime = nil
        self.exitTime = nil
        self.officePhone = nil
        self.extensionNumber = nil
        self.companyEmail = ""

        self.seniorityYears = nil
        self.seniorityMonths = nil
        self.seniorityWeeks = nil

        let defaults = Antecedents.defaults()
        self.antecedentesJSON = (try? JSONEncoder().encode(defaults))
            .flatMap { String(data: $0, encoding: .utf8) } ?? "{}"

        self.ishihara = ""
        self.campimetry = ""

        self.vaOdSc = ""
        self.vaOsSc = ""
        self.vaOdCc = ""
        self.vaOsCc = ""

        self.rxOdSph = ""
        self.rxOdCyl = ""
        self.rxOdAxis = ""
        self.rxOdAdd = ""
        self.rxOsSph = ""
        self.rxOsCyl = ""
        self.rxOsAxis = ""
        self.rxOsAdd = ""
        self.dp = ""

        self.lensType = ""
        self.usage = ""
        self.followUpDate = nil

        self.payStatus = ""
        self.payTotal = ""
        self.payMethod = ""
        self.payReference = ""
        self.payDiscount = nil
        self.payNotes = nil
    }
}
