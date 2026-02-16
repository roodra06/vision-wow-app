//
//  CompanyDetailScreen.swift
//  VisionWow
//
//  Created by Rodrigo Marcos on 27/12/25.
//

import SwiftUI
import SwiftData
import Foundation

struct CompanyDetailScreen: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let companyId: UUID

    @Query(sort: \Company.createdAt, order: .reverse) private var companies: [Company]
    private var company: Company? { companies.first(where: { $0.id == companyId }) }

    @State private var showEdit = false

    // Empresa: doble confirmación
    @State private var showDeleteConfirm1 = false
    @State private var showDeleteConfirm2 = false

    // Paciente: eliminación / doble confirmación
    @State private var selectedEncounterForDelete: Encounter? = nil
    @State private var showDeleteEncounterConfirm1 = false
    @State private var showDeleteEncounterConfirm2 = false

    var body: some View {
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

            if let company {
                GeometryReader { geo in
                    VStack(spacing: 12) {
                        heroHeader(company: company, height: geo.size.height * 0.48)

                        patientsSection(company: company)
                            .padding(.horizontal, 16)

                        Spacer(minLength: 0)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                }
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Menu {
                            Button("Editar") { showEdit = true }
                            Button(role: .destructive) { showDeleteConfirm1 = true } label: {
                                Text("Eliminar empresa")
                            }
                        } label: {
                            Image(systemName: "ellipsis.circle")
                        }
                    }
                }
                .sheet(isPresented: $showEdit) {
                    EditCompanySheet(companyId: company.id)
                }

                // Empresa alerts
                .alert("Eliminar empresa", isPresented: $showDeleteConfirm1) {
                    Button("Cancelar", role: .cancel) {}
                    Button("Continuar", role: .destructive) { showDeleteConfirm2 = true }
                } message: {
                    Text("Vas a eliminar esta empresa. Esto también eliminará sus pacientes asociados.")
                }
                .alert("Confirmación final", isPresented: $showDeleteConfirm2) {
                    Button("Cancelar", role: .cancel) {}
                    Button("Eliminar definitivamente", role: .destructive) {
                        deleteCompany(company)
                    }
                } message: {
                    Text("Esta acción no se puede deshacer. ¿Deseas eliminar definitivamente la empresa?")
                }

                // Paciente alerts
                .alert("Eliminar paciente", isPresented: $showDeleteEncounterConfirm1) {
                    Button("Cancelar", role: .cancel) { selectedEncounterForDelete = nil }
                    Button("Continuar", role: .destructive) { showDeleteEncounterConfirm2 = true }
                } message: {
                    Text("Vas a eliminar este paciente. Esta acción no se puede deshacer.")
                }
                .alert("Confirmación final", isPresented: $showDeleteEncounterConfirm2) {
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

            } else {
                VStack(spacing: 8) {
                    Text("Empresa no encontrada.")
                        .font(.headline)
                    Text(companyId.uuidString.prefix(8))
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                .padding(16)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Hero Header

    private func heroHeader(company: Company, height: CGFloat) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(BrandColors.cardGradient)
                .overlay(
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .stroke(BrandColors.accent.opacity(0.20), lineWidth: 1)
                )
                .shadow(color: BrandColors.secondary.opacity(0.08), radius: 22, x: 0, y: 12)

            VStack(spacing: 12) {
                // Avatar iniciales centrado y grande
                ZStack {
                    Circle()
                        .fill(BrandColors.primary.opacity(0.12))
                        .frame(width: 176, height: 176)
                        .blur(radius: 1)

                    Circle()
                        .stroke(BrandColors.strokeGradient, lineWidth: 10)
                        .frame(width: 156, height: 156)
                        .shadow(color: BrandColors.primary.opacity(0.18), radius: 14, x: 0, y: 10)

                    Text(initials(from: company.name))
                        .font(.system(size: 48, weight: .semibold, design: .rounded))
                        .foregroundStyle(BrandColors.secondary)
                }
                .padding(.top, 6)

                VStack(spacing: 6) {
                    Text(company.name)
                        .font(.system(size: 28, weight: .semibold, design: .rounded))
                        .foregroundStyle(.primary)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .padding(.horizontal, 14)

                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(BrandColors.accent)

                        Text(company.serviceType.isEmpty ? "Plan" : company.serviceType)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }

                // CTA: Agregar paciente
                NavigationLink {
                    NewEncounterWizardScreen(company: company)
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
                .frame(maxWidth: 360)
                .padding(.top, 2)

                Spacer(minLength: 0)
            }
            .padding(18)
        }
        .frame(height: height)
        .padding(.horizontal, 16)
        .padding(.top, 12)
    }

    // MARK: - Pacientes

    private func patientsSection(company: Company) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Pacientes")
                    .font(.headline)
                    .foregroundStyle(.primary)

                Spacer()

                Text("Registros asociados")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            if company.encounters.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Aún no hay pacientes registrados.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(Color.white.opacity(0.78))
                        .overlay(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .stroke(BrandColors.accent.opacity(0.16), lineWidth: 1)
                        )
                )
            } else {
                VStack(spacing: 10) {
                    ForEach(company.encounters) { e in
                        NavigationLink {
                            // ✅ Tap en toda la card: editar
                            EditEncounterWizardScreen(company: company, encounter: e)
                        } label: {
                            patientCard(company: company, encounter: e)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    // MARK: - Card (Paciente)

    private func patientCard(company: Company, encounter: Encounter) -> some View {
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
                // Título: nombre del paciente
                Text(patientDisplayName(encounter))
                    .font(.headline)
                    .foregroundStyle(.primary)
                    .lineLimit(1)

                // Fecha + teléfono
                HStack(spacing: 10) {
                    Label(
                        "Creado: \(encounter.createdAt.formatted(date: .numeric, time: .shortened))",
                        systemImage: "calendar"
                    )
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)

                    Spacer(minLength: 0)

                    let phone = (encounter.patient?.cellPhone ?? "")
                        .trimmingCharacters(in: .whitespacesAndNewlines)

                    if !phone.isEmpty {
                        Label(phone, systemImage: "phone.fill")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }

                // Pago / compra
                HStack(spacing: 10) {
                    Label(paymentSummary(encounter), systemImage: paymentIcon(encounter))
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(paymentColor(encounter))
                        .lineLimit(1)

                    Spacer(minLength: 0)
                }
            }

            Spacer(minLength: 8)

            // Eliminar (danger) — el edit lo hace el tap a toda la card
            Button {
                selectedEncounterForDelete = encounter
                showDeleteEncounterConfirm1 = true
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

    // MARK: - Helpers (nombre/pago)

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

    private func initials(from name: String) -> String {
        let parts = name
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .split(separator: " ")
            .prefix(2)
        let initials = parts.compactMap { $0.first }.map { String($0) }.joined()
        return initials.isEmpty ? "VW" : initials.uppercased()
    }

    // MARK: - Actions

    private func deleteCompany(_ company: Company) {
        modelContext.delete(company)
        do {
            try modelContext.save()
            dismiss()
        } catch {
            print("ERROR deleting company:", error)
        }
    }

    private func deleteEncounter(_ e: Encounter) {
        modelContext.delete(e)
        do {
            try modelContext.save()
        } catch {
            print("ERROR deleting encounter:", error)
        }
    }
}
