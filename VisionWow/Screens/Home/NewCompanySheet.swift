//
//  NewCompanySheet.swift
//  VisionWow
//
//  Created by Rodrigo Marcos on 27/12/25.
//

import SwiftUI
import SwiftData

enum ServiceType: String, CaseIterable, Identifiable {
    case essencial = "Essencial"
    case plus = "Plus"
    case corporative = "Corporative"

    var id: String { rawValue }
}

struct NewCompanySheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    var onCreated: (UUID) -> Void

    @State private var name: String = ""
    @State private var serviceType: ServiceType? = nil
    @State private var expectedPatientsText: String = ""

    @State private var errors: [String: String] = [:]
    @State private var saveError: String? = nil
    @State private var isSaving = false

    private enum FocusField: Hashable {
        case name
        case expectedPatients
    }

    @FocusState private var focus: FocusField?

    var body: some View {
        NavigationStack {
            ZStack {
                BrandColors.backgroundGradient.ignoresSafeArea()

                VStack(spacing: 14) {
                    BrandHeader(title: "Nueva empresa", subtitle: "Registra la empresa para asignar pacientes.")

                    SectionCard(title: "Datos de la empresa", subtitle: "Campos obligatorios marcados.") {
                        VStack(spacing: 12) {
                            FieldRow("Nombre de la empresa", required: true, error: errors["name"]) {
                                TextField("", text: $name)
                                    .textInputAutocapitalization(.words)
                                    .autocorrectionDisabled(false)
                                    .visionTextField(isError: errors["name"] != nil)
                                    .focused($focus, equals: .name)
                                    .submitLabel(.next)
                                    .onSubmit {
                                        // Como el "Tipo de servicio" es menú, brincamos al siguiente campo
                                        focus = .expectedPatients
                                    }
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
                                                if serviceType == option {
                                                    Image(systemName: "checkmark")
                                                }
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
                                    .focused($focus, equals: .expectedPatients)
                            }
                        }
                    }

                    if let saveError, !saveError.isEmpty {
                        ValidationSummary(title: "No se pudo guardar", items: [saveError])
                    }

                    Spacer()

                    HStack(spacing: 12) {
                        SecondaryButton(title: "Cancelar") {
                            dismiss()
                        }

                        PrimaryButton(title: isSaving ? "Guardando..." : "Guardar") {
                            save()
                        }
                        .disabled(isSaving)
                    }
                }
                .padding(16)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                // Botón "Listo" para cerrar teclado (especialmente en numberPad)
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Listo") { focus = nil }
                }
            }
        }
        .onAppear {
            // Evita el warning del teclado iniciando el foco de forma controlada
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                focus = .name
            }
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

        let trimmedExpected = expectedPatientsText.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedExpected.isEmpty, Int(trimmedExpected) == nil {
            e["expectedPatients"] = "Debe ser un número válido."
        }

        return e
    }

    private func save() {
        focus = nil
        saveError = nil
        errors = validate()
        guard errors.isEmpty else { return }

        isSaving = true
        defer { isSaving = false }

        let trimmedExpected = expectedPatientsText.trimmingCharacters(in: .whitespacesAndNewlines)
        let expected = trimmedExpected.isEmpty ? nil : Int(trimmedExpected)

        let company = Company(
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            serviceType: serviceType?.rawValue ?? "",
            expectedPatients: expected
        )

        do {
            modelContext.insert(company)
            try modelContext.save()

            // Navega de forma segura tras guardar y cerrar teclado
            let createdId = company.id
            DispatchQueue.main.async {
                onCreated(createdId)
                dismiss()
            }
        } catch {
            // Esto te mostrará el error real (y evitará “solo un icono” sin texto)
            let msg = error.localizedDescription
            print("ERROR save company:", error)
            saveError = msg.isEmpty ? "Error desconocido al guardar." : msg
        }
    }
}
