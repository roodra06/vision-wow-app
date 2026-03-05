//
//  ExportImportService.swift
//  VisionWow
//
//  Serializa Encounters + Patients a JSON (.vwsync) para sincronizar
//  datos entre múltiples iPads que atienden la misma empresa.
//  Imágenes (fotos, firmas) NO se incluyen por tamaño.
//

import Foundation
import SwiftData
import UIKit

// MARK: - DTOs Codable

struct PatientDTO: Codable {
    var id: UUID
    var createdAt: Date
    var updatedAt: Date
    var firstName: String
    var lastName: String
    var dob: Date?
    var sex: String
    var homePhone: String?
    var cellPhone: String
    var personalEmail: String
    var externalPatientNumber: String?
}

struct EncounterDTO: Codable {
    // Identidad
    var id: UUID
    var createdAt: Date
    var updatedAt: Date
    var completedAt: Date?

    // Paciente embebido
    var patient: PatientDTO?

    // Empresa
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
    var seniorityYears: Int?
    var seniorityMonths: Int?
    var seniorityWeeks: Int?

    // Antecedentes
    var antecedentesJSON: String

    // Pruebas
    var ishihara: String
    var campimetry: String

    // Agudeza visual
    var vaOdSc: String
    var vaOsSc: String
    var vaOuSc: String
    var vaOdCc: String
    var vaOsCc: String
    var vaOuCc: String
    var nearVaOdSc: String
    var nearVaOsSc: String
    var nearVaOuSc: String
    var nearVaOdCc: String
    var nearVaOsCc: String
    var nearVaOuCc: String

    // Refracción
    var rxOdSph: String
    var rxOdCyl: String
    var rxOdAxis: String
    var rxOdAdd: String
    var rxOsSph: String
    var rxOsCyl: String
    var rxOsAxis: String
    var rxOsAdd: String
    var dip: String

    // Recomendación
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
    var payDeposit: String
    var lensCost: String

    // Diagnóstico / optometrista
    var diagnostico: String
    var optometristName: String?
    var signatureVideoFileName: String?

    // Garantía
    var isGuarantee: Bool
    var guaranteeReason: String?
}

struct SyncPackage: Codable {
    var exportedAt: Date
    var deviceName: String
    var appVersion: String
    var encounters: [EncounterDTO]
}

// MARK: - Service

enum ExportImportService {

    // MARK: Export

    static func export(encounters: [Encounter]) throws -> Data {
        let dtos = encounters.map { EncounterDTO(from: $0) }
        let package = SyncPackage(
            exportedAt: Date(),
            deviceName: UIDevice.current.name,
            appVersion: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "?",
            encounters: dtos
        )
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return try encoder.encode(package)
    }

    // MARK: Import

    struct ImportResult {
        var inserted: Int = 0
        var updated: Int = 0
        var skipped: Int = 0
        var errors: [String] = []
    }

    @MainActor
    static func importPackage(data: Data, modelContext: ModelContext) throws -> ImportResult {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let package = try decoder.decode(SyncPackage.self, from: data)

        var result = ImportResult()

        for dto in package.encounters {
            do {
                try merge(dto: dto, into: modelContext, result: &result)
            } catch {
                result.errors.append("Encounter \(dto.id): \(error.localizedDescription)")
            }
        }

        try modelContext.save()
        return result
    }

    // MARK: - Private merge logic

    @MainActor
    private static func merge(dto: EncounterDTO, into context: ModelContext, result: inout ImportResult) throws {
        // 1. ¿Ya existe el encounter?
        let eid = dto.id
        let encFetch = FetchDescriptor<Encounter>(predicate: #Predicate { $0.id == eid })
        let existing = try context.fetch(encFetch)

        if let enc = existing.first {
            // Solo actualiza si el remoto es más nuevo
            if dto.updatedAt > enc.updatedAt {
                apply(dto: dto, to: enc, context: context)
                result.updated += 1
            } else {
                result.skipped += 1
            }
            return
        }

        // 2. Encounter nuevo — buscar o crear el paciente
        let enc = Encounter()
        enc.id = dto.id
        apply(dto: dto, to: enc, context: context)

        if let patDTO = dto.patient {
            enc.patient = findOrCreatePatient(dto: patDTO, context: context)
        }

        context.insert(enc)
        result.inserted += 1
    }

    @MainActor
    private static func findOrCreatePatient(dto: PatientDTO, context: ModelContext) -> Patient {
        let pid = dto.id
        let fetch = FetchDescriptor<Patient>(predicate: #Predicate { $0.id == pid })
        if let existing = try? context.fetch(fetch), let p = existing.first {
            // Actualiza datos si el remoto es más nuevo
            if dto.updatedAt > p.updatedAt {
                p.firstName = dto.firstName
                p.lastName = dto.lastName
                p.dob = dto.dob
                p.sex = dto.sex
                p.homePhone = dto.homePhone
                p.cellPhone = dto.cellPhone
                p.personalEmail = dto.personalEmail
                p.externalPatientNumber = dto.externalPatientNumber
                p.updatedAt = dto.updatedAt
            }
            return p
        }
        let p = Patient()
        p.id = dto.id
        p.createdAt = dto.createdAt
        p.updatedAt = dto.updatedAt
        p.firstName = dto.firstName
        p.lastName = dto.lastName
        p.dob = dto.dob
        p.sex = dto.sex
        p.homePhone = dto.homePhone
        p.cellPhone = dto.cellPhone
        p.personalEmail = dto.personalEmail
        p.externalPatientNumber = dto.externalPatientNumber
        context.insert(p)
        return p
    }

    private static func apply(dto: EncounterDTO, to enc: Encounter, context: ModelContext) {
        enc.createdAt = dto.createdAt
        enc.updatedAt = dto.updatedAt
        enc.completedAt = dto.completedAt
        enc.companyName = dto.companyName
        enc.branch = dto.branch
        enc.employeeNumber = dto.employeeNumber
        enc.department = dto.department
        enc.directBoss = dto.directBoss
        enc.shift = dto.shift
        enc.entryTime = dto.entryTime
        enc.exitTime = dto.exitTime
        enc.officePhone = dto.officePhone
        enc.extensionNumber = dto.extensionNumber
        enc.companyEmail = dto.companyEmail
        enc.seniorityYears = dto.seniorityYears
        enc.seniorityMonths = dto.seniorityMonths
        enc.seniorityWeeks = dto.seniorityWeeks
        enc.antecedentesJSON = dto.antecedentesJSON
        enc.ishihara = dto.ishihara
        enc.campimetry = dto.campimetry
        enc.vaOdSc = dto.vaOdSc
        enc.vaOsSc = dto.vaOsSc
        enc.vaOuSc = dto.vaOuSc
        enc.vaOdCc = dto.vaOdCc
        enc.vaOsCc = dto.vaOsCc
        enc.vaOuCc = dto.vaOuCc
        enc.nearVaOdSc = dto.nearVaOdSc
        enc.nearVaOsSc = dto.nearVaOsSc
        enc.nearVaOuSc = dto.nearVaOuSc
        enc.nearVaOdCc = dto.nearVaOdCc
        enc.nearVaOsCc = dto.nearVaOsCc
        enc.nearVaOuCc = dto.nearVaOuCc
        enc.rxOdSph = dto.rxOdSph
        enc.rxOdCyl = dto.rxOdCyl
        enc.rxOdAxis = dto.rxOdAxis
        enc.rxOdAdd = dto.rxOdAdd
        enc.rxOsSph = dto.rxOsSph
        enc.rxOsCyl = dto.rxOsCyl
        enc.rxOsAxis = dto.rxOsAxis
        enc.rxOsAdd = dto.rxOsAdd
        enc.dip = dto.dip
        enc.lensType = dto.lensType
        enc.usage = dto.usage
        enc.followUpDate = dto.followUpDate
        enc.payStatus = dto.payStatus
        enc.payTotal = dto.payTotal
        enc.payMethod = dto.payMethod
        enc.payReference = dto.payReference
        enc.payDiscount = dto.payDiscount
        enc.payNotes = dto.payNotes
        enc.payDeposit = dto.payDeposit
        enc.lensCost = dto.lensCost
        enc.diagnostico = dto.diagnostico
        enc.optometristName = dto.optometristName
        enc.signatureVideoFileName = dto.signatureVideoFileName
        enc.isGuarantee = dto.isGuarantee
        enc.guaranteeReason = dto.guaranteeReason
    }
}

// MARK: - EncounterDTO init from Encounter

private extension EncounterDTO {
    init(from enc: Encounter) {
        self.id = enc.id
        self.createdAt = enc.createdAt
        self.updatedAt = enc.updatedAt
        self.completedAt = enc.completedAt
        self.patient = enc.patient.map { PatientDTO(from: $0) }
        self.companyName = enc.companyName
        self.branch = enc.branch
        self.employeeNumber = enc.employeeNumber
        self.department = enc.department
        self.directBoss = enc.directBoss
        self.shift = enc.shift
        self.entryTime = enc.entryTime
        self.exitTime = enc.exitTime
        self.officePhone = enc.officePhone
        self.extensionNumber = enc.extensionNumber
        self.companyEmail = enc.companyEmail
        self.seniorityYears = enc.seniorityYears
        self.seniorityMonths = enc.seniorityMonths
        self.seniorityWeeks = enc.seniorityWeeks
        self.antecedentesJSON = enc.antecedentesJSON
        self.ishihara = enc.ishihara
        self.campimetry = enc.campimetry
        self.vaOdSc = enc.vaOdSc
        self.vaOsSc = enc.vaOsSc
        self.vaOuSc = enc.vaOuSc
        self.vaOdCc = enc.vaOdCc
        self.vaOsCc = enc.vaOsCc
        self.vaOuCc = enc.vaOuCc
        self.nearVaOdSc = enc.nearVaOdSc
        self.nearVaOsSc = enc.nearVaOsSc
        self.nearVaOuSc = enc.nearVaOuSc
        self.nearVaOdCc = enc.nearVaOdCc
        self.nearVaOsCc = enc.nearVaOsCc
        self.nearVaOuCc = enc.nearVaOuCc
        self.rxOdSph = enc.rxOdSph
        self.rxOdCyl = enc.rxOdCyl
        self.rxOdAxis = enc.rxOdAxis
        self.rxOdAdd = enc.rxOdAdd
        self.rxOsSph = enc.rxOsSph
        self.rxOsCyl = enc.rxOsCyl
        self.rxOsAxis = enc.rxOsAxis
        self.rxOsAdd = enc.rxOsAdd
        self.dip = enc.dip
        self.lensType = enc.lensType
        self.usage = enc.usage
        self.followUpDate = enc.followUpDate
        self.payStatus = enc.payStatus
        self.payTotal = enc.payTotal
        self.payMethod = enc.payMethod
        self.payReference = enc.payReference
        self.payDiscount = enc.payDiscount
        self.payNotes = enc.payNotes
        self.payDeposit = enc.payDeposit
        self.lensCost = enc.lensCost
        self.diagnostico = enc.diagnostico
        self.optometristName = enc.optometristName
        self.signatureVideoFileName = enc.signatureVideoFileName
        self.isGuarantee = enc.isGuarantee
        self.guaranteeReason = enc.guaranteeReason
    }
}

private extension PatientDTO {
    init(from p: Patient) {
        self.id = p.id
        self.createdAt = p.createdAt
        self.updatedAt = p.updatedAt
        self.firstName = p.firstName
        self.lastName = p.lastName
        self.dob = p.dob
        self.sex = p.sex
        self.homePhone = p.homePhone
        self.cellPhone = p.cellPhone
        self.personalEmail = p.personalEmail
        self.externalPatientNumber = p.externalPatientNumber
    }
}
