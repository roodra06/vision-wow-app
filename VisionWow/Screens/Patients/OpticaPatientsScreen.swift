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

    // 🔴 Eliminación con doble confirmación
    @State private var selectedEncounterForDelete: Encounter? = nil
    @State private var showDeleteConfirm1 = false
    @State private var showDeleteConfirm2 = false

    private var opticaCompany: Company {
        WalkInCompanyStore.ensure(modelContext: modelContext)
    }

    private var opticaEncounters: [Encounter] {
        encounters.filter { $0.company?.name == WalkInCompanyStore.name }
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

                    if opticaEncounters.isEmpty {
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
                                ForEach(opticaEncounters) { e in
                                    NavigationLink {
                                        // ✅ Editar paciente
                                        EditEncounterWizardScreen(company: opticaCompany, encounter: e)
                                    } label: {
                                        opticaPatientCard(encounter: e)
                                            .contentShape(Rectangle())
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.top, 10)
                            .padding(.horizontal, 16)
                        }
                    }

                    Spacer()

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

                    SecondaryButton(title: "Volver") {
                        dismiss()
                    }
                    .frame(maxWidth: 340)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 18)
                }
                .padding(.top, 14)
            }
            .onAppear {
                _ = WalkInCompanyStore.ensure(modelContext: modelContext)
            }
            .navigationBarTitleDisplayMode(.inline)

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
                Text(patientDisplayName(encounter))
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
                    Label(paymentSummary(encounter), systemImage: paymentIcon(encounter))
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(paymentColor(encounter))
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

    // MARK: - Helpers

    private func patientDisplayName(_ e: Encounter) -> String {
        let first = (e.patient?.firstName ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        let last  = (e.patient?.lastName ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        let full = [first, last].filter { !$0.isEmpty }.joined(separator: " ")
        return full.isEmpty ? "Paciente" : full
    }

    private func paymentSummary(_ e: Encounter) -> String {
        let status = e.payStatus.trimmingCharacters(in: .whitespacesAndNewlines)
        let total  = e.payTotal.trimmingCharacters(in: .whitespacesAndNewlines)

        if status.isEmpty && total.isEmpty { return "Sin compra" }
        if !status.isEmpty && !total.isEmpty { return "\(status) • $\(total)" }
        if !status.isEmpty { return status }
        return "Total • $\(total)"
    }

    private func paymentIcon(_ e: Encounter) -> String {
        let status = e.payStatus.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if status.contains("pag") { return "checkmark.seal.fill" }
        if status.contains("pend") { return "clock.fill" }
        if status.contains("cort") { return "gift.fill" }

        let total = e.payTotal.trimmingCharacters(in: .whitespacesAndNewlines)
        return total.isEmpty ? "cart.badge.minus" : "cart.fill"
    }

    private func paymentColor(_ e: Encounter) -> Color {
        let status = e.payStatus.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if status.contains("pag") { return BrandColors.success }
        if status.contains("pend") { return BrandColors.warning }
        if status.contains("cort") { return BrandColors.info }

        let total = e.payTotal.trimmingCharacters(in: .whitespacesAndNewlines)
        return total.isEmpty ? .secondary : BrandColors.secondary
    }

    // MARK: - Actions

    private func deleteEncounter(_ e: Encounter) {
        modelContext.delete(e)
        do {
            try modelContext.save()
        } catch {
            print("ERROR deleting encounter:", error)
        }
    }
}
