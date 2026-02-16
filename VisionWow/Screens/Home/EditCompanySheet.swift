//
//  EditCompanySheet.swift
//  VisionWow
//
//  Created by Rodrigo Marcos on 27/12/25.
//

import SwiftUI
import SwiftData

struct EditCompanySheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let companyId: UUID

    @Query(sort: \Company.createdAt, order: .reverse) private var companies: [Company]
    private var company: Company? { companies.first(where: { $0.id == companyId }) }

    @State private var name: String = ""
    @State private var serviceType: ServiceType? = nil
    @State private var expectedPatientsText: String = ""

    @State private var errors: [String: String] = [:]
    @State private var saveError: String?

    var body: some View {
        NavigationStack {
            ZStack {
                BrandColors.backgroundGradient.ignoresSafeArea()

                VStack(spacing: 14) {
                    BrandHeader(title: "Editar empresa", subtitle: "Actualiza los datos de la empresa.")

                    SectionCard(title: "Datos de la empresa", subtitle: "Edita y guarda cambios.") {
                        VStack(spacing: 12) {
                            FieldRow("Nombre de la empresa", required: true, error: errors["name"]) {
                                TextField("", text: $name)
                                    .textInputAutocapitalization(.words)
                                    .visionTextField(isError: errors["name"] != nil)
                            }

                            FieldRow("Tipo de servicio", required: true, error: errors["serviceType"]) {
                                Menu {
                                    ForEach(ServiceType.allCases) { option in
                                        Button {
                                            serviceType = option
                                        } label: {
                                            HStack {
                                                Text(option.rawValue)
                                                Spacer()
                                                if serviceType == option { Image(systemName: "checkmark") }
                                            }
                                        }
                                    }
                                } label: {
                                    HStack(spacing: 10) {
                                        Text(serviceType?.rawValue ?? "Selecciona una opción")
                                            .foregroundStyle(serviceType == nil ? .secondary : .primary)
                                        Spacer()
                                        Image(systemName: "chevron.down")
                                            .font(.footnote.weight(.semibold))
                                            .foregroundStyle(.secondary)
                                    }
                                    .visionControl(isError: errors["serviceType"] != nil)
                                    .contentShape(Rectangle())
                                }
                            }

                            FieldRow("Número de pacientes a revisar (opcional)", error: errors["expectedPatients"]) {
                                TextField("Ej. 50", text: $expectedPatientsText)
                                    .keyboardType(.numberPad)
                                    .visionTextField(isError: errors["expectedPatients"] != nil)
                            }
                        }
                    }

                    if let saveError, !saveError.isEmpty {
                        ValidationSummary(title: "No se pudo guardar", items: [saveError])
                    }

                    Spacer()

                    HStack(spacing: 12) {
                        SecondaryButton(title: "Cancelar") { dismiss() }

                        PrimaryButton(title: "Guardar cambios") {
                            save()
                        }
                    }
                }
                .padding(16)
            }
            .navigationBarTitleDisplayMode(.inline)
        }
        .onAppear { preload() }
    }

    private func preload() {
        guard let company else { return }
        name = company.name
        serviceType = ServiceType(rawValue: company.serviceType)
        if let exp = company.expectedPatients {
            expectedPatientsText = String(exp)
        } else {
            expectedPatientsText = ""
        }
    }

    private func validate() -> [String: String] {
        var e: [String: String] = [:]

        if name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            e["name"] = "Campo obligatorio."
        }
        if serviceType == nil {
            e["serviceType"] = "Campo obligatorio."
        }

        let trimmed = expectedPatientsText.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty, Int(trimmed) == nil {
            e["expectedPatients"] = "Debe ser un número válido."
        }

        return e
    }

    private func save() {
        saveError = nil
        errors = validate()
        guard errors.isEmpty else { return }
        guard let company else {
            saveError = "Empresa no encontrada."
            return
        }

        let trimmedExpected = expectedPatientsText.trimmingCharacters(in: .whitespacesAndNewlines)
        let expected = trimmedExpected.isEmpty ? nil : Int(trimmedExpected)

        company.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        company.serviceType = serviceType?.rawValue ?? ""
        company.expectedPatients = expected
        company.updatedAt = Date()

        do {
            try modelContext.save()
            dismiss()
        } catch {
            print("ERROR saving company edits:", error)
            saveError = error.localizedDescription
        }
    }
}
