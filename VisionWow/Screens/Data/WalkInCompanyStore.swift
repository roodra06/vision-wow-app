//
//  WalkInCompanyStore.swift
//  VisionWow
//

import Foundation
import SwiftData

enum WalkInCompanyStore {
    static let name = "Óptica · Pacientes externos"
    static let defaultServiceType = "Essencial"

    static func ensure(modelContext: ModelContext) -> Company {
        let descriptor = FetchDescriptor<Company>()
        let companies = (try? modelContext.fetch(descriptor)) ?? []

        if let existing = companies.first(where: { $0.name == name }) {
            return existing
        }

        let company = Company(
            name: name,
            serviceType: defaultServiceType,
            expectedPatients: nil
        )

        modelContext.insert(company)
        do { try modelContext.save() }
        catch { print("ERROR creating WalkIn company:", error) }

        return company
    }
}

