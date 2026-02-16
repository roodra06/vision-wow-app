//
//  AddPatientScreen.swift
//  VisionWow
//
//  Created by Rodrigo Marcos on 27/12/25.
//

import SwiftUI
import SwiftData

struct AddPatientScreen: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let companyId: UUID
    @Query(sort: \Company.createdAt, order: .reverse) private var companies: [Company]

    private var company: Company? { companies.first(where: { $0.id == companyId }) }

    var body: some View {
        ZStack {
            BrandColors.backgroundGradient.ignoresSafeArea()

            VStack(spacing: 14) {
                BrandHeader(title: "Agregar paciente", subtitle: company?.name ?? "Empresa")

                SectionCard(title: "Paciente", subtitle: "Pantalla pendiente de implementar.") {
                    Text("Aquí crearás el formulario del paciente (Encounter).")
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                Spacer()

                HStack(spacing: 12) {
                    SecondaryButton(title: "Volver") { dismiss() }

                    PrimaryButton(title: "Crear (demo)") {
                        // Aquí es donde crearías Encounter y lo asignas a company
                        // Ejemplo:
                        // let e = Encounter(...)
                        // e.company = company
                        // modelContext.insert(e)
                        // try? modelContext.save()
                        dismiss()
                    }
                }
            }
            .padding(16)
        }
        .navigationBarTitleDisplayMode(.inline)
    }
}
