//
//  AntecedentsStep2Screen.swift
//  VisionWow
//
//  Created by Rodrigo Marcos on 27/12/25.
//

import SwiftUI
import UIKit

struct AntecedentsStep2Screen: View {
    @Bindable var encounter: Encounter

    @State private var model: Antecedents = .defaults()

    // Paso 3/4 (tus steps: 1 Historia, 2 Datos, 3 Antecedentes, 4 Examen)
    private let stepIndex = 3
    private let totalSteps = 4

    private var patientIdText: String {
        let raw = String(describing: encounter.id)
        return "ID: \(raw.prefix(8))"
    }

    private var fullNameText: String {
        let first = encounter.firstName.trimmingCharacters(in: .whitespacesAndNewlines)
        let last  = encounter.lastName.trimmingCharacters(in: .whitespacesAndNewlines)
        let combined = [first, last].filter { !$0.isEmpty }.joined(separator: " ")
        return combined.isEmpty ? "Sin nombre" : combined
    }

    private var profileUIImage: UIImage? {
        guard let data = encounter.profileImageData else { return nil }
        return UIImage(data: data)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                headerCard
                antecedentsCard
            }
            .padding(.horizontal, 16)
            .padding(.top, 14)
            .padding(.bottom, 28)
        }
        .onAppear {
            loadFromEncounter()
        }
        .onChange(of: model) { _, newValue in
            saveToEncounter(newValue)
        }
    }

    // MARK: - Header

    private var headerCard: some View {
        VStack(spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                avatar

                VStack(alignment: .leading, spacing: 8) {
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 6) {
                            Image(systemName: "checklist")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(BrandColors.accent)

                            Text("Antecedentes")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.secondary)
                        }

                        Text(fullNameText)
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundStyle(.primary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.85)
                    }

                    HStack(spacing: 8) {
                        Image(systemName: "building.2.fill")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(BrandColors.accent)

                        Text(encounter.companyName.isEmpty ? "Empresa" : encounter.companyName)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }

                    HStack(spacing: 8) {
                        Image(systemName: "number")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(BrandColors.accent)

                        Text(patientIdText)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }

                Spacer(minLength: 0)
            }

            VStack(spacing: 6) {
                HStack {
                    Text("Paso \(stepIndex) de \(totalSteps)")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                    Spacer()
                }

                // Usa el ProgressPillBar existente en tu proyecto
                ProgressPillBar(
                    progress: CGFloat(stepIndex) / CGFloat(totalSteps),
                    height: 10
                )
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.white.opacity(0.72))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(BrandColors.accent.opacity(0.16), lineWidth: 1)
                )
                .shadow(color: BrandColors.secondary.opacity(0.06), radius: 14, x: 0, y: 8)
        )
    }

    private var avatar: some View {
        ZStack {
            Circle()
                .fill(BrandColors.primary.opacity(0.12))
                .frame(width: 76, height: 76)

            Circle()
                .stroke(BrandColors.strokeGradient, lineWidth: 3)
                .frame(width: 76, height: 76)

            if let img = profileUIImage {
                Image(uiImage: img)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 70, height: 70)
                    .clipShape(Circle())
            } else {
                Image(systemName: "person.fill")
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundStyle(BrandColors.secondary.opacity(0.85))
            }
        }
        .accessibilityLabel(Text("Foto de perfil del paciente"))
    }

    // MARK: - Card

    private var antecedentsCard: some View {
        VStack(spacing: 12) {
            sectionHeader(icon: "checklist", title: "Selecciona los checks que apliquen")

            VStack(spacing: 14) {
                Accordion(title: "Antecedentes", initiallyOpen: true) {
                    sectionGrid(
                        items: Array(model.antecedentes.keys).sorted(),
                        get: { model.antecedentes[$0] ?? false },
                        set: { model.antecedentes[$0] = $1 }
                    )
                    otherField(isOn: model.antecedentes["Otra"] ?? false, text: $model.antecedentesOther)
                }

                Accordion(title: "Síntomas") {
                    sectionGrid(
                        items: Array(model.sintomas.keys).sorted(),
                        get: { model.sintomas[$0] ?? false },
                        set: { model.sintomas[$0] = $1 }
                    )
                    otherField(isOn: model.sintomas["Otra"] ?? false, text: $model.sintomasOther)
                }

                Accordion(title: "Cirugías") {
                    sectionGrid(
                        items: Array(model.cirugias.keys).sorted(),
                        get: { model.cirugias[$0] ?? false },
                        set: { model.cirugias[$0] = $1 }
                    )
                    otherField(isOn: model.cirugias["Otra"] ?? false, text: $model.cirugiasOther)
                }

                Accordion(title: "Conjuntivitis") {
                    sectionGrid(
                        items: Array(model.conjuntivitis.keys).sorted(),
                        get: { model.conjuntivitis[$0] ?? false },
                        set: { model.conjuntivitis[$0] = $1 }
                    )
                    otherField(isOn: model.conjuntivitis["Otra"] ?? false, text: $model.conjuntivitisOther)
                }

                Accordion(title: "Computadora") {
                    sectionGrid(
                        items: Array(model.computadora.keys).sorted(),
                        get: { model.computadora[$0] ?? false },
                        set: { model.computadora[$0] = $1 }
                    )
                    otherField(isOn: model.computadora["Otra"] ?? false, text: $model.computadoraOther)
                }

                Accordion(title: "Anexos") {
                    sectionGrid(
                        items: Array(model.anexos.keys).sorted(),
                        get: { model.anexos[$0] ?? false },
                        set: { model.anexos[$0] = $1 }
                    )
                    otherField(isOn: model.anexos["Otra"] ?? false, text: $model.anexosOther)
                }

                Accordion(title: "Salud") {
                    sectionGrid(
                        items: Array(model.salud.keys).sorted(),
                        get: { model.salud[$0] ?? false },
                        set: { model.salud[$0] = $1 }
                    )
                    otherField(isOn: model.salud["Otra"] ?? false, text: $model.saludOther)
                }

                Accordion(title: "Salud ocular") {
                    sectionGrid(
                        items: Array(model.saludOcular.keys).sorted(),
                        get: { model.saludOcular[$0] ?? false },
                        set: { model.saludOcular[$0] = $1 }
                    )
                    otherField(isOn: model.saludOcular["Otra"] ?? false, text: $model.saludOcularOther)
                }

                Accordion(title: "Consultas") {
                    sectionGrid(
                        items: Array(model.consultas.keys).sorted(),
                        get: { model.consultas[$0] ?? false },
                        set: { model.consultas[$0] = $1 }
                    )
                    otherField(isOn: model.consultas["Otra"] ?? false, text: $model.consultasOther)
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.white.opacity(0.82))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(BrandColors.accent.opacity(0.16), lineWidth: 1)
                )
                .shadow(color: BrandColors.secondary.opacity(0.06), radius: 14, x: 0, y: 8)
        )
    }

    private func sectionHeader(icon: String, title: String) -> some View {
        HStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(BrandColors.primary.opacity(0.10))
                    .frame(width: 28, height: 28)

                Image(systemName: icon)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(BrandColors.secondary.opacity(0.9))
            }

            Text(title)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(BrandColors.secondary)

            Spacer()
        }
        .padding(.top, 2)
    }

    // MARK: - Helpers

    private func sectionGrid(
        items: [String],
        get: @escaping (String) -> Bool,
        set: @escaping (String, Bool) -> Void
    ) -> some View {
        CheckGrid(
            items: items,
            isOn: { get($0) },
            toggle: { key in
                let newValue = !get(key)
                set(key, newValue)
            }
        )
        .padding(.vertical, 6)
    }

    @ViewBuilder
    private func otherField(isOn: Bool, text: Binding<String>) -> some View {
        if isOn {
            FieldRow("Especifica (Otra)") {
                TextField("Describe…", text: text)
                    .visionTextField()
            }
        }
    }

    private func loadFromEncounter() {
        if let data = encounter.antecedentesJSON.data(using: .utf8),
           let decoded = try? JSONDecoder().decode(Antecedents.self, from: data) {
            model = decoded
        } else {
            model = .defaults()
        }
    }

    private func saveToEncounter(_ newValue: Antecedents) {
        if let data = try? JSONEncoder().encode(newValue),
           let s = String(data: data, encoding: .utf8) {
            encounter.antecedentesJSON = s
        }
    }
}
