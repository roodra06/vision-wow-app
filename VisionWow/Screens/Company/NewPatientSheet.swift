//
//  NewPatientSheet.swift
//  VisionWow
//
//  Created by Rodrigo Marcos on 27/12/25.
//
import SwiftUI
import SwiftData

struct NewPatientSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @Bindable var company: Company

    var body: some View {
        NavigationStack {
            ZStack {
                BrandColors.backgroundGradient.ignoresSafeArea()

                VStack(spacing: 16) {
                    BrandHeader(title: "Nuevo paciente", subtitle: company.name)

                    Text("Se creará un paciente vacío y podrás capturar el examen.")
                        .foregroundStyle(.secondary)

                    PrimaryButton(title: "Crear paciente") {
                        create()
                    }

                    Spacer()
                }
                .padding(16)
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cerrar") { dismiss() }
                }
            }
        }
    }

    private func create() {
        let e = Encounter()
        e.company = company
        e.companyName = company.name // opcional: autollenar
        modelContext.insert(e)
        try? modelContext.save()
        dismiss()
    }
}
