//
//  PersonalDataView.swift
//  VisionWow
//
//  Created by Rodrigo Marcos on 27/12/25.
//

import SwiftUI
import UIKit

struct PersonalDataView: View {
    @Bindable var encounter: Encounter
    let errors: [String: String]

    var stepNumber: Int = 2
    var totalSteps: Int = 4

    // ✅ Edad calculada y forzada a refrescar
    @State private var ageDisplay: String = ""

    // ✅ Control de selección de sexo (para dialog)
    @State private var showSexDialog = false

    private var patientIdText: String {
        let raw = String(describing: encounter.id)
        return "ID: \(raw.prefix(8))"
    }

    private var fullNameText: String {
        let first = (encounter.patient?.firstName ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        let last  = (encounter.patient?.lastName ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        let combined = [first, last].filter { !$0.isEmpty }.joined(separator: " ")
        return combined.isEmpty ? "Sin nombre" : combined
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                headerCard
                formCard
            }
            .padding(.horizontal, 16)
            .padding(.top, 14)
            .padding(.bottom, 28)
        }
        .onAppear {
            // Evita nil para que los bindings funcionen
            if encounter.patient == nil { encounter.patient = Patient() }
            recomputeAge()
        }
        // ✅ Si cambia DOB, recalcula SIEMPRE
        .onChange(of: encounter.patient?.dob) { _, _ in
            recomputeAge()
        }
    }

    // MARK: - Header

    private var headerCard: some View {
        VStack(spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                profileAvatar

                VStack(alignment: .leading, spacing: 8) {
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 6) {
                            Image(systemName: "person.text.rectangle")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(BrandColors.accent)

                            Text("Nuevo paciente")
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
                    Text("Paso \(stepNumber) de \(totalSteps)")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                    Spacer()
                }

                ProgressPillBar(
                    progress: CGFloat(stepNumber) / CGFloat(totalSteps),
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

    private var profileAvatar: some View {
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

    private var profileUIImage: UIImage? {
        guard let data = encounter.patient?.profileImageData else { return nil }
        return UIImage(data: data)
    }

    // MARK: - Bindings (Patient)

    private var firstNameBinding: Binding<String> {
        Binding(
            get: { encounter.patient?.firstName ?? "" },
            set: { newValue in
                if encounter.patient == nil { encounter.patient = Patient() }
                encounter.patient?.firstName = newValue
            }
        )
    }

    private var lastNameBinding: Binding<String> {
        Binding(
            get: { encounter.patient?.lastName ?? "" },
            set: { newValue in
                if encounter.patient == nil { encounter.patient = Patient() }
                encounter.patient?.lastName = newValue
            }
        )
    }

    private var dobBinding: Binding<Date> {
        Binding(
            get: { encounter.patient?.dob ?? defaultDOB },
            set: { newValue in
                if encounter.patient == nil { encounter.patient = Patient() }
                encounter.patient?.dob = newValue
            }
        )
    }

    private var sexBinding: Binding<String> {
        Binding(
            get: { encounter.patient?.sex ?? "" },
            set: { newValue in
                if encounter.patient == nil { encounter.patient = Patient() }
                encounter.patient?.sex = newValue
            }
        )
    }

    private var homePhoneBinding: Binding<String> {
        Binding(
            get: { encounter.patient?.homePhone ?? "" },
            set: { newValue in
                if encounter.patient == nil { encounter.patient = Patient() }
                encounter.patient?.homePhone = newValue.isEmpty ? nil : newValue
            }
        )
    }

    private var cellPhoneBinding: Binding<String> {
        Binding(
            get: { encounter.patient?.cellPhone ?? "" },
            set: { newValue in
                if encounter.patient == nil { encounter.patient = Patient() }
                encounter.patient?.cellPhone = newValue
            }
        )
    }

    private var personalEmailBinding: Binding<String> {
        Binding(
            get: { encounter.patient?.personalEmail ?? "" },
            set: { newValue in
                if encounter.patient == nil { encounter.patient = Patient() }
                encounter.patient?.personalEmail = newValue
            }
        )
    }

    // MARK: - Form

    private var formCard: some View {
        VStack(spacing: 16) {
            sectionHeader(icon: "person.fill", title: "Identidad")

            HStack(spacing: 12) {
                FieldRow("Nombre", required: true, error: errors["firstName"]) {
                    iconTextField(
                        systemName: "person.fill",
                        placeholder: "",
                        text: firstNameBinding,
                        isError: errors["firstName"] != nil
                    )
                }

                FieldRow("Apellidos", required: true, error: errors["lastName"]) {
                    iconTextField(
                        systemName: "person.2.fill",
                        placeholder: "",
                        text: lastNameBinding,
                        isError: errors["lastName"] != nil
                    )
                }
            }

            sectionHeader(icon: "calendar", title: "Nacimiento")

            HStack(spacing: 12) {
                FieldRow("Fecha de nacimiento", required: true, error: errors["dob"]) {
                    SpanishDateField(
                        selection: dobBinding,
                        isError: errors["dob"] != nil
                    )
                }

                FieldRow("Edad (automática)") {
                    HStack(spacing: 10) {
                        Image(systemName: "number.circle.fill")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(.secondary)

                        Text(ageDisplay.isEmpty ? "—" : ageDisplay)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(.primary)

                        Spacer()
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(Color.black.opacity(0.04))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(BrandColors.accent.opacity(0.12), lineWidth: 1)
                    )
                }

                FieldRow("Sexo", required: true, error: errors["sex"]) {
                    SexPickerField(
                        selection: sexBinding,
                        placeholder: "Selecciona…",
                        isError: errors["sex"] != nil,
                        showDialog: $showSexDialog
                    )
                }
            }

            Divider().opacity(0.35)

            sectionHeader(icon: "phone.fill", title: "Contacto")

            HStack(spacing: 12) {
                FieldRow("Teléfono de casa (opcional)") {
                    iconTextField(
                        systemName: "phone.fill",
                        placeholder: "",
                        text: homePhoneBinding,
                        isError: false
                    )
                    .keyboardType(.phonePad)
                }

                FieldRow("Teléfono celular", required: true, error: errors["cellPhone"]) {
                    iconTextField(
                        systemName: "iphone",
                        placeholder: "",
                        text: cellPhoneBinding,
                        isError: errors["cellPhone"] != nil
                    )
                    .keyboardType(.phonePad)
                }
            }

            FieldRow("Correo personal", required: true, error: errors["personalEmail"]) {
                iconTextField(
                    systemName: "envelope.fill",
                    placeholder: "correo@personal.com",
                    text: personalEmailBinding,
                    isError: errors["personalEmail"] != nil
                )
                .keyboardType(.emailAddress)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
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

    // MARK: - Age logic

    private var defaultDOB: Date {
        // Default: 18 años atrás para evitar Date() que confunde UI
        Calendar.current.date(byAdding: .year, value: -18, to: Date()) ?? Date()
    }

    private func recomputeAge() {
        guard let dob = encounter.patient?.dob else {
            ageDisplay = ""
            return
        }
        let age = DateUtils.age(from: dob)
        ageDisplay = "\(age)"
    }

    // MARK: - UI helpers

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

    private func iconTextField(
        systemName: String,
        placeholder: String,
        text: Binding<String>,
        isError: Bool
    ) -> some View {
        HStack(spacing: 10) {
            Image(systemName: systemName)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.secondary)

            TextField(placeholder, text: text)
                .visionTextField(isError: isError)
        }
    }
}

// MARK: - SpanishDateField (rueda grande e intuitiva día/mes/año)
private struct SpanishDateField: View {
    @Binding var selection: Date
    let isError: Bool

    @State private var showSheet = false

    var body: some View {
        Button {
            showSheet = true
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "calendar")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.secondary)

                Text(formattedSpanishDate(selection))
                    .foregroundStyle(.primary)
                    .lineLimit(1)

                Spacer()

                Image(systemName: "chevron.down")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .opacity(0.7)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity, minHeight: 44)
            .background(Color.black.opacity(0.04))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(isError ? BrandColors.danger.opacity(0.90) : BrandColors.accent.opacity(0.12), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showSheet) {
            NavigationStack {
                VStack(alignment: .leading, spacing: 14) {
                    Text("Selecciona día, mes y año")
                        .font(.headline)
                        .foregroundStyle(.primary)

                    Text("Fecha de nacimiento")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    // ✅ Grande e intuitivo: ruedas (día/mes/año)
                    DatePicker(
                        "",
                        selection: $selection,
                        in: allowedRange,
                        displayedComponents: .date
                    )
                    .datePickerStyle(.wheel)
                    .labelsHidden()
                    .environment(\.locale, Locale(identifier: "es_MX"))
                    .frame(maxWidth: .infinity)
                    .frame(height: 260) // ✅ más grande
                    .clipped()
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(Color.black.opacity(0.04))
                    )

                    Spacer()
                }
                .padding(16)
                .navigationTitle("Nacimiento")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancelar") { showSheet = false }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Listo") { showSheet = false }
                            .fontWeight(.semibold)
                    }
                }
            }
            .presentationDetents([.large]) // ✅ se ve grande de verdad
        }
    }

    // ✅ Rango razonable (evita fechas futuras)
    private var allowedRange: ClosedRange<Date> {
        let cal = Calendar.current
        let min = cal.date(from: DateComponents(year: 1900, month: 1, day: 1)) ?? Date.distantPast
        let max = Date() // hoy
        return min...max
    }

    private func formattedSpanishDate(_ date: Date) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "es_MX")
        f.dateStyle = .long
        f.timeStyle = .none
        return f.string(from: date)
    }
}

// MARK: - SexPickerField (botón 100% tocable + opciones ocupan todo)
private struct SexPickerField: View {
    @Binding var selection: String
    let placeholder: String
    let isError: Bool
    @Binding var showDialog: Bool

    var body: some View {
        Button {
            showDialog = true
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "figure.dress.line.vertical.figure")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.secondary)

                Text(selection.isEmpty ? placeholder : selection)
                    .foregroundStyle(selection.isEmpty ? .secondary : .primary)
                    .lineLimit(1)

                Spacer()

                Image(systemName: "chevron.down")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity, minHeight: 44)
            .background(Color.black.opacity(0.04))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(isError ? BrandColors.danger.opacity(0.90) : BrandColors.accent.opacity(0.12), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .confirmationDialog("Selecciona sexo", isPresented: $showDialog, titleVisibility: .visible) {
            ForEach(SexOption.allCases) { opt in
                Button(opt.rawValue) { selection = opt.rawValue }
            }

            if !selection.isEmpty {
                Button("Limpiar selección", role: .destructive) { selection = "" }
            }

            Button("Cancelar", role: .cancel) {}
        }
    }
}
