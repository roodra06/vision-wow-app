//
//  PatientsList.swift
//  VisionWow
//
//  Created by Rodrigo Marcos on 27/12/25.
//

import SwiftUI
import SwiftData

struct PatientsList: View {
    @Bindable var company: Company

    var body: some View {
        if company.encounters.isEmpty {
            VStack(spacing: 8) {
                Text("No hay pacientes aún.")
                    .font(.headline)
                Text("Agrega un paciente para comenzar la captura.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, minHeight: 240)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color(uiColor: .secondarySystemBackground))
            )
        } else {
            ScrollView {
                VStack(spacing: 12) {
                    ForEach(company.encounters.sorted(by: { $0.createdAt > $1.createdAt })) { e in
                        NavigationLink {
                            FlowCoordinator(encounter: e)
                        } label: {
                            patientCard(e)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.bottom, 8)
            }
        }
    }

    private func patientCard(_ e: Encounter) -> some View {
        let name = e.patientFullName.trimmingCharacters(in: .whitespacesAndNewlines)
        let status = (e.completedAt == nil) ? "En progreso" : "Finalizado"

        return VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(name.isEmpty ? "Paciente sin nombre" : name)
                    .font(.headline)
                    .foregroundStyle(.primary)
                Spacer()
                Text(status)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(e.completedAt == nil ? BrandColors.secondary : BrandColors.primary)
            }

            Text("Creado: \(e.createdAt.formatted(date: .abbreviated, time: .shortened))")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color(uiColor: .secondarySystemBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.black.opacity(0.08), lineWidth: 1)
        )
    }
}
