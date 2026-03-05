//
//  OpticaPatientsScreen.swift
//  VisionWow
//

import SwiftUI
import SwiftData
import Foundation

struct OpticaPatientsScreen: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @Query(sort: \Encounter.createdAt, order: .reverse) private var encounters: [Encounter]

    // Buscador
    @State private var searchText: String = ""

    // 🔴 Eliminación con doble confirmación
    @State private var selectedEncounterForDelete: Encounter? = nil
    @State private var showDeleteConfirm1 = false
    @State private var showDeleteConfirm2 = false
    @State private var deleteError: String? = nil

    private var opticaCompany: Company {
        WalkInCompanyStore.ensure(modelContext: modelContext)
    }

    private var opticaEncounters: [Encounter] {
        encounters.filter { $0.company?.name == WalkInCompanyStore.name }
    }

    // Pacientes únicos que coinciden con el buscador (para historial)
    private var filteredPatients: [(patient: Patient, latestEncounter: Encounter)] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !query.isEmpty else { return [] }
        var seen = Set<UUID>()
        var result: [(patient: Patient, latestEncounter: Encounter)] = []
        for enc in opticaEncounters {
            guard let pat = enc.patient else { continue }
            guard !seen.contains(pat.id) else { continue }
            let name = [pat.firstName, pat.lastName]
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
                .joined(separator: " ")
                .lowercased()
            if name.contains(query) {
                seen.insert(pat.id)
                result.append((patient: pat, latestEncounter: enc))
            }
        }
        return result.sorted { a, b in
            let nameA = a.patient.firstName + a.patient.lastName
            let nameB = b.patient.firstName + b.patient.lastName
            return nameA < nameB
        }
    }

    private var isSearching: Bool {
        !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        NavigationStack {
            ZStack {
                BrandColors.backgroundGradient.ignoresSafeArea()

                // Bokeh / dots sutiles
                Circle()
                    .fill(BrandColors.primary.opacity(0.10))
                    .frame(width: 240, height: 240)
                    .blur(radius: 2)
                    .offset(x: 150, y: -290)

                Circle()
                    .fill(BrandColors.accent.opacity(0.10))
                    .frame(width: 170, height: 170)
                    .blur(radius: 2)
                    .offset(x: -165, y: -130)

                Circle()
                    .fill(BrandColors.secondary.opacity(0.08))
                    .frame(width: 280, height: 280)
                    .blur(radius: 8)
                    .offset(x: -140, y: 300)

                VStack(spacing: 12) {

                    Text("Pacientes · Óptica")
                        .font(.system(size: 30, weight: .semibold, design: .rounded))
                        .foregroundStyle(BrandColors.secondary)
                        .padding(.top, 6)
                        .entrance(delay: 0.05)

                    // ─── Buscador ───
                    searchField
                        .padding(.horizontal, 16)
                        .entrance(delay: 0.10)

                    // ─── Resultados de búsqueda ───
                    if isSearching {
                        if filteredPatients.isEmpty {
                            VStack(spacing: 6) {
                                Image(systemName: "magnifyingglass")
                                    .font(.system(size: 28))
                                    .foregroundStyle(.secondary)
                                Text("Sin resultados para \"\(searchText)\"")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.top, 10)
                        } else {
                            ScrollView {
                                LazyVStack(spacing: 10) {
                                    ForEach(filteredPatients, id: \.patient.id) { item in
                                        NavigationLink {
                                            PatientHistoryScreen(patient: item.patient, opticaCompany: opticaCompany)
                                        } label: {
                                            searchResultCard(item: item)
                                                .contentShape(Rectangle())
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                                .padding(.top, 4)
                                .padding(.horizontal, 16)
                            }
                        }

                    // ─── Lista regular (flujo original) ───
                    } else if opticaEncounters.isEmpty {
                        VStack(spacing: 8) {
                            Text("Aún no hay pacientes externos.")
                                .foregroundStyle(.secondary)
                            Text("Agrega tu primer paciente para iniciar su historial.")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.top, 10)
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 10) {
                                ForEach(Array(opticaEncounters.enumerated()), id: \.element.id) { index, e in
                                    NavigationLink {
                                        EditEncounterWizardScreen(company: opticaCompany, encounter: e)
                                    } label: {
                                        opticaPatientCard(encounter: e)
                                            .contentShape(Rectangle())
                                    }
                                    .buttonStyle(.plain)
                                    .entrance(delay: 0.10 + Double(index) * 0.06)
                                }
                            }
                            .padding(.top, 10)
                            .padding(.horizontal, 16)
                        }
                    }

                    Spacer()

                    // CTA Reporte de ventas (óptica, con filtro de fechas)
                    NavigationLink {
                        ReportAuthGate {
                            SalesReportScreen(
                                companyName: WalkInCompanyStore.name,
                                encounters: opticaEncounters,
                                showDateFilter: true
                            )
                        }
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: "chart.bar.doc.horizontal")
                                .font(.system(size: 16, weight: .semibold))
                            Text("Reporte de ventas")
                                .font(.system(size: 16, weight: .semibold))
                        }
                        .foregroundStyle(BrandColors.secondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .padding(.horizontal, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(Color.white.opacity(0.88))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                                        .stroke(BrandColors.secondary.opacity(0.20), lineWidth: 1)
                                )
                        )
                        .shadow(color: BrandColors.secondary.opacity(0.08), radius: 10, x: 0, y: 6)
                    }
                    .buttonStyle(.plain)
                    .frame(maxWidth: 340)
                    .padding(.horizontal, 16)
                    .entrance(delay: 0.20)

                    // CTA Agregar paciente
                    NavigationLink {
                        NewEncounterWizardScreen(company: opticaCompany)
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: "person.badge.plus")
                                .font(.system(size: 16, weight: .semibold))
                            Text("Agregar paciente")
                                .font(.system(size: 16, weight: .semibold))
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .padding(.horizontal, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(BrandColors.primary)
                        )
                        .shadow(color: BrandColors.primary.opacity(0.22), radius: 10, x: 0, y: 6)
                    }
                    .buttonStyle(.plain)
                    .frame(maxWidth: 340)
                    .padding(.horizontal, 16)
                    .entrance(delay: 0.26)

                    SecondaryButton(title: "Volver") {
                        dismiss()
                    }
                    .frame(maxWidth: 340)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 18)
                    .entrance(delay: 0.32)
                }
                .padding(.top, 14)
            }
            .onAppear {
                _ = WalkInCompanyStore.ensure(modelContext: modelContext)
            }
            .navigationBarTitleDisplayMode(.inline)

            // Error al eliminar
            .alert("No se pudo eliminar", isPresented: Binding(
                get: { deleteError != nil },
                set: { if !$0 { deleteError = nil } }
            )) {
                Button("Aceptar", role: .cancel) { deleteError = nil }
            } message: {
                Text(deleteError ?? "")
            }

            // 🔴 ALERTS DE ELIMINACIÓN
            .alert("Eliminar paciente", isPresented: $showDeleteConfirm1) {
                Button("Cancelar", role: .cancel) { selectedEncounterForDelete = nil }
                Button("Continuar", role: .destructive) { showDeleteConfirm2 = true }
            } message: {
                Text("Vas a eliminar este paciente. Esta acción no se puede deshacer.")
            }
            .alert("Confirmación final", isPresented: $showDeleteConfirm2) {
                Button("Cancelar", role: .cancel) { selectedEncounterForDelete = nil }
                Button("Eliminar definitivamente", role: .destructive) {
                    if let e = selectedEncounterForDelete {
                        deleteEncounter(e)
                    }
                    selectedEncounterForDelete = nil
                }
            } message: {
                Text("¿Eliminar definitivamente este paciente?")
            }
        }
    }

    // MARK: - Search Field

    private var searchField: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(.secondary)

            TextField("Buscar paciente por nombre...", text: $searchText)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.words)

            if !searchText.isEmpty {
                Button {
                    searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 15))
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(Color.white.opacity(0.82))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(BrandColors.accent.opacity(0.2), lineWidth: 1)
        )
        .shadow(color: BrandColors.secondary.opacity(0.06), radius: 8, x: 0, y: 4)
    }

    // MARK: - Search Result Card

    private func searchResultCard(item: (patient: Patient, latestEncounter: Encounter)) -> some View {
        let pat = item.patient
        let enc = item.latestEncounter
        return HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(BrandColors.primary.opacity(0.12))
                    .frame(width: 44, height: 44)
                if let data = pat.profileImageData, let img = UIImage(data: data) {
                    Image(uiImage: img)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 40, height: 40)
                        .clipShape(Circle())
                } else {
                    Image(systemName: "person.fill")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(BrandColors.secondary.opacity(0.8))
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                let fullName = [pat.firstName, pat.lastName]
                    .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                    .filter { !$0.isEmpty }
                    .joined(separator: " ")
                Text(fullName.isEmpty ? "Paciente" : fullName)
                    .font(.headline)
                    .foregroundStyle(.primary)
                    .lineLimit(1)

                let visits = pat.encounters.filter { $0.company?.name == WalkInCompanyStore.name }.count
                Label("\(visits) visita\(visits == 1 ? "" : "s") · Última: \(DateUtils.formatShort(enc.createdAt))",
                      systemImage: "clock.fill")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(BrandColors.accent.opacity(0.6))
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.white.opacity(0.86))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(BrandColors.primary.opacity(0.18), lineWidth: 1)
                )
                .shadow(color: BrandColors.secondary.opacity(0.07), radius: 14, x: 0, y: 8)
        )
    }

    // MARK: - Card

    private func opticaPatientCard(encounter: Encounter) -> some View {
        HStack(spacing: 12) {
            // Avatar
            ZStack {
                Circle()
                    .fill(BrandColors.accent.opacity(0.12))
                    .frame(width: 44, height: 44)

                Image(systemName: "person.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(BrandColors.secondary.opacity(0.85))
            }

            VStack(alignment: .leading, spacing: 6) {
                Text(encounter.displayName)
                    .font(.headline)
                    .foregroundStyle(.primary)
                    .lineLimit(1)

                HStack(spacing: 10) {
                    Label(
                        "Creado: \(encounter.createdAt.formatted(date: .numeric, time: .shortened))",
                        systemImage: "calendar"
                    )
                    .font(.caption)
                    .foregroundStyle(.secondary)

                    Spacer(minLength: 0)

                    let phone = (encounter.patient?.cellPhone ?? "")
                        .trimmingCharacters(in: .whitespacesAndNewlines)

                    if !phone.isEmpty {
                        Label(phone, systemImage: "phone.fill")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                HStack(spacing: 10) {
                    Label(encounter.paymentSummary, systemImage: encounter.paymentIconName)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(encounter.paymentColor)
                        .lineLimit(1)

                    Spacer(minLength: 0)
                }
            }

            Spacer(minLength: 8)

            // 🔴 Botón eliminar
            Button {
                selectedEncounterForDelete = encounter
                showDeleteConfirm1 = true
            } label: {
                CircleIconButton(
                    systemName: "trash",
                    fill: BrandColors.danger.opacity(0.12),
                    stroke: BrandColors.danger.opacity(0.30),
                    iconColor: BrandColors.danger
                )
            }
            .buttonStyle(.plain)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.white.opacity(0.86))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(BrandColors.accent.opacity(0.16), lineWidth: 1)
                )
                .shadow(color: BrandColors.secondary.opacity(0.07), radius: 14, x: 0, y: 8)
        )
        .contentShape(Rectangle())
    }

    // MARK: - Actions

    private func deleteEncounter(_ e: Encounter) {
        modelContext.delete(e)
        do {
            try modelContext.save()
        } catch {
            deleteError = "No se pudo eliminar el paciente. Inténtalo de nuevo.\n\n\(error.localizedDescription)"
        }
    }
}
