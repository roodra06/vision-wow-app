//
//  CompaniesHomeScreen.swift
//  VisionWow
//
//  Created by Rodrigo Marcos on 27/12/25.
//

import SwiftUI
import SwiftData

struct CompaniesHomeScreen: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Company.createdAt, order: .reverse) private var companies: [Company]

    @State private var showNewCompany = false
    @State private var navPath = NavigationPath()

    // Editar
    @State private var editingCompanyId: UUID? = nil

    // Eliminar (doble confirmación)
    @State private var deleteCandidate: Company? = nil
    @State private var showDeleteConfirm1 = false
    @State private var showDeleteConfirm2 = false

    // ✅ SOLO EMPRESAS VISIBLES (oculta la interna de Óptica)
    private var visibleCompanies: [Company] {
        companies.filter { $0.name != WalkInCompanyStore.name }
    }

    var body: some View {
        NavigationStack(path: $navPath) {
            GeometryReader { geo in
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

                    VStack(spacing: 14) {
                        heroHeader(height: geo.size.height * 0.48)

                        if visibleCompanies.isEmpty {
                            emptyState
                                .padding(.horizontal, 16)
                                .padding(.top, 6)
                        } else {
                            listState
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                }
            }
            .navigationDestination(for: UUID.self) { companyId in
                CompanyDetailScreen(companyId: companyId)
            }
            .sheet(isPresented: $showNewCompany) {
                NewCompanySheet { createdCompanyId in
                    showNewCompany = false
                    DispatchQueue.main.async {
                        navPath.append(createdCompanyId)
                    }
                }
            }
            .sheet(item: $editingCompanyId) { id in
                EditCompanySheet(companyId: id)
            }
            .alert("Eliminar empresa", isPresented: $showDeleteConfirm1) {
                Button("Cancelar", role: .cancel) { deleteCandidate = nil }
                Button("Continuar", role: .destructive) { showDeleteConfirm2 = true }
            } message: {
                Text("Vas a eliminar esta empresa. Esto también eliminará sus pacientes asociados.")
            }
            .alert("Confirmación final", isPresented: $showDeleteConfirm2) {
                Button("Cancelar", role: .cancel) { deleteCandidate = nil }
                Button("Eliminar definitivamente", role: .destructive) {
                    if let company = deleteCandidate {
                        deleteCompany(company)
                    }
                    deleteCandidate = nil
                }
            } message: {
                Text("Esta acción no se puede deshacer. ¿Deseas eliminar definitivamente la empresa?")
            }
        }
    }

    // MARK: - Hero Header

    private func heroHeader(height: CGFloat) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(BrandColors.cardGradient)
                .overlay(
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .stroke(BrandColors.accent.opacity(0.20), lineWidth: 1)
                )
                .shadow(color: BrandColors.secondary.opacity(0.08), radius: 22, x: 0, y: 12)

            VStack(spacing: 12) {

                // ✅ BOTÓN REGRESAR AL MENÚ PRINCIPAL
                HStack {
                    Button {
                        dismiss()
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "chevron.left")
                            Text("Volver")
                        }
                        .font(.subheadline)
                        .foregroundStyle(BrandColors.secondary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 7)
                        .background(
                            Capsule()
                                .fill(Color.white.opacity(0.75))
                        )
                    }

                    Spacer()
                }
                .padding(.top, 4)

                // Logo grande, redondeado
                ZStack {
                    Circle()
                        .fill(BrandColors.primary.opacity(0.10))
                        .frame(width: 170, height: 170)
                        .blur(radius: 1)

                    Circle()
                        .stroke(BrandColors.strokeGradient, lineWidth: 8)
                        .frame(width: 150, height: 150)
                        .shadow(color: BrandColors.primary.opacity(0.18), radius: 14, x: 0, y: 10)

                    Image("visionwow_logo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 112, height: 112)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color.white.opacity(0.85), lineWidth: 2))
                        .shadow(color: BrandColors.secondary.opacity(0.12), radius: 12, x: 0, y: 8)
                }
                .padding(.top, 2)

                VStack(spacing: 6) {
                    Text("Empresas")
                        .font(.system(size: 34, weight: .semibold, design: .rounded))
                        .foregroundStyle(BrandColors.secondary)

                    Text("Crea una empresa y luego agrega pacientes.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 18)
                }

                PrimaryButton(title: "Agregar empresa") {
                    showNewCompany = true
                }
                .frame(maxWidth: 340)
                .padding(.top, 4)

                Spacer(minLength: 0)
            }
            .padding(18)
        }
        .frame(height: height)
        .padding(.horizontal, 16)
        .padding(.top, 12)
    }

    // MARK: - Subviews

    private var emptyState: some View {
        VStack(spacing: 10) {
            Text("Aún no hay empresas registradas.")
                .font(.headline)
                .foregroundStyle(.primary)

            Text("Comienza agregando tu primera empresa para registrar pacientes.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 6)
        }
        .padding(18)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.white.opacity(0.70))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(BrandColors.accent.opacity(0.18), lineWidth: 1)
                )
        )
    }

    private var listState: some View {
        VStack(spacing: 10) {
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(visibleCompanies) { c in
                        Button {
                            navPath.append(c.id)
                        } label: {
                            CompanyCard(
                                company: c,
                                onEdit: { editingCompanyId = c.id },
                                onDelete: {
                                    deleteCandidate = c
                                    showDeleteConfirm1 = true
                                }
                            )
                        }
                        .buttonStyle(.plain)
                        .padding(.horizontal, 16)
                    }
                }
                .padding(.vertical, 10)
            }
        }
    }

    // MARK: - Actions

    private func deleteCompany(_ company: Company) {
        modelContext.delete(company)
        do { try modelContext.save() }
        catch { print("ERROR deleting company:", error) }
    }
}

extension UUID: Identifiable {
    public var id: UUID { self }
}
