//
//  TestsView.swift
//  VisionWow
//
//  Created by Rodrigo Marcos on 27/12/25.
//
import SwiftUI

struct TestsView: View {
    @Bindable var encounter: Encounter
    let errors: [String: String]

    var body: some View {
        SectionCard(title: "Pruebas", subtitle: "Se capturan junto con Resultados del Examen Visual.") {
            VStack(spacing: 12) {
                HStack(spacing: 12) {
                    FieldRow("Ishihara", required: true, error: errors["ishihara"]) {
                        TextField("", text: $encounter.ishihara).textFieldStyle(.roundedBorder)
                    }
                    FieldRow("Campimetría", required: true, error: errors["campimetry"]) {
                        TextField("", text: $encounter.campimetry).textFieldStyle(.roundedBorder)
                    }
                }
            }
        }
    }
}

