//
//  Company.swift
//  VisionWow
//
//  Created by Rodrigo Marcos on 27/12/25.
//
import Foundation
import SwiftData

@Model
final class Company {
    @Attribute(.unique) var id: UUID
    var name: String
    var serviceType: String
    var expectedPatients: Int?
    var createdAt: Date
    var updatedAt: Date

    @Relationship(deleteRule: .cascade)
    var encounters: [Encounter] = []

    init(name: String, serviceType: String, expectedPatients: Int? = nil) {
        self.id = UUID()
        self.name = name
        self.serviceType = serviceType
        self.expectedPatients = expectedPatients
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}
