//
//  HomeScreen.swift
//  VisionWow
//
//  Created by Rodrigo Marcos on 27/12/25.
//
import SwiftUI
import SwiftData

struct HomeScreen: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Encounter.updatedAt, order: .reverse) private var encounters: [Encounter]

    @State private var search: String = ""

    private var filtered: [Encounter] {
        if search.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return encounters
        }
        let term = search.lowercased()
        return encounters.filter { e in
            let full = "\(e.firstName) \(e.lastName)".lowercased()
            let comp = e.companyName.lowercased()
            return full.contains(term) || comp.contains(term) || e.id.uuidString.lowercased().contains(term)
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                BrandColors.backgroundGradient.ignoresSafeArea()

                VStack(spacing: 16) {
                    header
                    listCard
                    Spacer(minLength: 0)
                }
                .padding(16)
            }
            .navigationBarHidden(true)
        }
    }

    private var header: some View {
        SectionCard(title: "Vision Wow • Registros", subtitle: "Crea y administra evaluaciones.") {
            HStack(spacing: 12) {
                TextField("Buscar por nombre, empresa o ID…", text: $search)
                    .textFieldStyle(.roundedBorder)

                Button {
                    let e = NewEncounterFactory.make()
                    modelContext.insert(e)
                    try? modelContext.save()
                } label: {
                    Text("Nuevo")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(
                            LinearGradient(colors: [BrandColors.primary, BrandColors.secondary], startPoint: .leading, endPoint: .trailing)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
            }
        }
    }

    private var listCard: some View {
        SectionCard(title: "Listado", subtitle: filtered.isEmpty ? "No hay registros aún." : "\(filtered.count) registro(s)") {
            if filtered.isEmpty {
                Text("Crea un registro con el botón “Nuevo”.")
                    .foregroundStyle(.secondary)
                    .font(.system(size: 14))
            } else {
                VStack(spacing: 0) {
                    ForEach(filtered) { e in
                        NavigationLink {
                            FlowCoordinator(encounter: e)
                        } label: {
                            row(e)
                        }
                        .buttonStyle(.plain)

                        Divider().opacity(0.2)
                    }
                }
            }
        }
    }

    private func row(_ e: Encounter) -> some View {
        let name = "\(e.firstName) \(e.lastName)".trimmingCharacters(in: .whitespacesAndNewlines)
        return HStack {
            VStack(alignment: .leading, spacing: 3) {
                Text(name.isEmpty ? "Sin nombre" : name)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Color(.label))
                Text("\(e.companyName.isEmpty ? "Sin empresa" : e.companyName) • ID: \(e.id)")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Text(DateUtils.formatShort(e.updatedAt))
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 10)
    }
}

