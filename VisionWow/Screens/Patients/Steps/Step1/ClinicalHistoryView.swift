//
//  ClinicalHistoryView.swift
//  VisionWow
//
//  Created by Rodrigo Marcos on 27/12/25.
//

import SwiftUI
import UIKit

struct ClinicalHistoryView: View {
    @Bindable var encounter: Encounter
    let errors: [String: String]

    // Paso 1/4
    private let stepIndex = 1
    private let totalSteps = 4

    // Cámara
    @State private var showCamera = false
    @State private var showCameraError = false

    // Antigüedad (solo un campo)
    private enum SeniorityUnit: String, CaseIterable, Identifiable {
        case years = "Años"
        case months = "Meses"
        case weeks = "Semanas"

        var id: String { rawValue }

        var icon: String {
            switch self {
            case .years:  return "calendar"
            case .months: return "calendar.badge.clock"
            case .weeks:  return "calendar.day.timeline.left"
            }
        }
    }

    @State private var seniorityUnit: SeniorityUnit = .years
    @State private var seniorityValueText: String = ""

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
            hydrateSeniorityUIFromModel()
        }
        .sheet(isPresented: $showCamera) {
            CameraCaptureView(
                isPresented: $showCamera,
                onImage: { img in
                    persistProfileImage(img)
                },
                onError: {
                    showCameraError = true
                }
            )
            .ignoresSafeArea()
        }
        .alert("No se pudo abrir la cámara", isPresented: $showCameraError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Verifica permisos de cámara en Ajustes y que el dispositivo tenga cámara disponible.")
        }
    }

    // MARK: - Header

    private var headerCard: some View {
        VStack(spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                profileAvatar

                VStack(alignment: .leading, spacing: 8) {
                    // Nuevo paciente + nombre (placeholder hasta que exista el campo en Encounter)
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 6) {
                            Image(systemName: "person.text.rectangle")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(BrandColors.accent)

                            Text("Nuevo paciente")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.secondary)
                        }

                        // TODO: cuando tengas el nombre real en Encounter, sustituye aquí:
                        // Text(encounter.patientFullName.isEmpty ? "Sin nombre" : encounter.patientFullName)
                        Text("Sin nombre")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundStyle(.primary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.85)
                    }

                    // Empresa
                    HStack(spacing: 8) {
                        Image(systemName: "building.2.fill")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(BrandColors.accent)

                        Text(encounter.companyName.isEmpty ? "Empresa" : encounter.companyName)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }

                    // ID
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

            // Progreso
            VStack(spacing: 6) {
                HStack {
                    Text("Paso \(stepIndex) de \(totalSteps)")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                    Spacer()
                }

                ProgressPillBar(progress: CGFloat(stepIndex) / CGFloat(totalSteps), height: 10)
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
        ZStack(alignment: .bottomTrailing) {
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

            Button {
                if UIImagePickerController.isSourceTypeAvailable(.camera) {
                    showCamera = true
                } else {
                    showCameraError = true
                }
            } label: {
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.92))
                        .frame(width: 26, height: 26)
                        .overlay(
                            Circle().stroke(BrandColors.accent.opacity(0.22), lineWidth: 1)
                        )
                        .shadow(color: .black.opacity(0.10), radius: 6, x: 0, y: 3)

                    Image(systemName: "camera.fill")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(BrandColors.secondary)
                }
            }
            .buttonStyle(.plain)
            .offset(x: 2, y: 2)
            .accessibilityLabel(Text("Tomar foto de perfil"))
        }
    }

    private var patientIdText: String {
        let raw = String(describing: encounter.id)
        return "ID: \(raw.prefix(8))"
    }

    // MARK: - Form Card

    private var formCard: some View {
        VStack(spacing: 16) {

            sectionHeader(icon: "clock.arrow.circlepath", title: "Antigüedad")

            VStack(spacing: 10) {
                Picker("", selection: $seniorityUnit) {
                    ForEach(SeniorityUnit.allCases) { unit in
                        Text(unit.rawValue).tag(unit)
                    }
                }
                .pickerStyle(.segmented)
                .onChange(of: seniorityUnit) { _, _ in
                    // Cambiar unidad limpia el valor y el modelo
                    seniorityValueText = ""
                    encounter.seniorityYears = nil
                    encounter.seniorityMonths = nil
                    encounter.seniorityWeeks = nil
                }

                FieldRow("Valor", required: true, error: seniorityErrorMessage) {
                    iconNumberField(
                        systemName: seniorityUnit.icon,
                        placeholder: "0",
                        text: $seniorityValueText,
                        isError: seniorityHasError
                    )
                    .onChange(of: seniorityValueText) { _, newValue in
                        applySeniorityValue(newValue)
                    }
                }
            }

            sectionHeader(icon: "person.badge.shield.checkmark", title: "Condición laboral")

            VStack(spacing: 10) {
                Toggle(isOn: plantaBinding) {
                    Label("Personal de planta", systemImage: "checkmark.seal.fill")
                        .font(.system(size: 14, weight: .medium))
                }
                .toggleStyle(SwitchToggleStyle(tint: BrandColors.primary))

                Toggle(isOn: eventualBinding) {
                    Label("Personal eventual", systemImage: "clock.fill")
                        .font(.system(size: 14, weight: .medium))
                }
                .toggleStyle(SwitchToggleStyle(tint: BrandColors.accent))
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color.black.opacity(0.03))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(BrandColors.accent.opacity(0.14), lineWidth: 1)
                    )
            )

            Divider().opacity(0.35)

            sectionHeader(icon: "building.2.crop.circle", title: "Datos laborales")

            HStack(spacing: 12) {
                FieldRow("Nombre de la empresa", required: true, error: errors["companyName"]) {
                    iconTextField(
                        systemName: "building.2.fill",
                        placeholder: "",
                        text: $encounter.companyName,
                        isError: errors["companyName"] != nil
                    )
                }

                FieldRow("Sucursal", required: true, error: errors["branch"]) {
                    iconTextField(
                        systemName: "mappin.and.ellipse",
                        placeholder: "",
                        text: $encounter.branch,
                        isError: errors["branch"] != nil
                    )
                }
            }

            HStack(spacing: 12) {
                FieldRow("Número de empleado (opcional)") {
                    iconTextField(
                        systemName: "number.circle",
                        placeholder: "",
                        text: Binding(
                            get: { encounter.employeeNumber ?? "" },
                            set: { encounter.employeeNumber = $0.isEmpty ? nil : $0 }
                        ),
                        isError: false
                    )
                    .keyboardType(.numberPad)
                }

                FieldRow("Departamento", required: true, error: errors["department"]) {
                    iconTextField(
                        systemName: "briefcase.fill",
                        placeholder: "",
                        text: $encounter.department,
                        isError: errors["department"] != nil
                    )
                }
            }

            HStack(spacing: 12) {
                FieldRow("Jefe inmediato", required: true, error: errors["directBoss"]) {
                    iconTextField(
                        systemName: "person.2.fill",
                        placeholder: "",
                        text: $encounter.directBoss,
                        isError: errors["directBoss"] != nil
                    )
                }

                FieldRow("Turno", required: true, error: errors["shift"]) {
                    shiftPickerField(
                        selection: $encounter.shift,
                        placeholder: "Selecciona…",
                        isError: errors["shift"] != nil
                    )
                }
            }

            sectionHeader(icon: "clock.badge.checkmark", title: "Horarios")

            HStack(spacing: 12) {
                FieldRow("Entrada (opcional)") {
                    TimePickerField(
                        placeholder: "HH:mm",
                        value: Binding(get: { encounter.entryTime }, set: { encounter.entryTime = $0 })
                    )
                }

                FieldRow("Salida (opcional)") {
                    TimePickerField(
                        placeholder: "HH:mm",
                        value: Binding(get: { encounter.exitTime }, set: { encounter.exitTime = $0 })
                    )
                }
            }

            Divider().opacity(0.35)

            sectionHeader(icon: "envelope.badge", title: "Contacto corporativo")

            HStack(spacing: 12) {
                FieldRow("Teléfono oficina (opcional)") {
                    iconTextField(
                        systemName: "phone.fill",
                        placeholder: "",
                        text: Binding(
                            get: { encounter.officePhone ?? "" },
                            set: { encounter.officePhone = $0.isEmpty ? nil : $0 }
                        ),
                        isError: false
                    )
                    .keyboardType(.phonePad)
                }

                FieldRow("Extensión (opcional)") {
                    iconTextField(
                        systemName: "square.split.2x1.fill",
                        placeholder: "",
                        text: Binding(
                            get: { encounter.extensionNumber ?? "" },
                            set: { encounter.extensionNumber = $0.isEmpty ? nil : $0 }
                        ),
                        isError: false
                    )
                    .keyboardType(.numberPad)
                }
            }

            FieldRow("Correo de la empresa", required: true, error: errors["companyEmail"]) {
                iconTextField(
                    systemName: "envelope.fill",
                    placeholder: "nombre@empresa.com",
                    text: $encounter.companyEmail,
                    isError: errors["companyEmail"] != nil
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

    // MARK: - Exclusividad Planta / Eventual

    private var plantaBinding: Binding<Bool> {
        Binding(
            get: { encounter.isPlanta },
            set: { newValue in
                encounter.isPlanta = newValue
                if newValue { encounter.isEventual = false }
            }
        )
    }

    private var eventualBinding: Binding<Bool> {
        Binding(
            get: { encounter.isEventual },
            set: { newValue in
                encounter.isEventual = newValue
                if newValue { encounter.isPlanta = false }
            }
        )
    }

    // MARK: - Foto persistente

    private var profileUIImage: UIImage? {
        guard let data = encounter.profileImageData else { return nil }
        return UIImage(data: data)
    }

    private func persistProfileImage(_ img: UIImage) {
        // JPEG ligero para no inflar la BD
        encounter.profileImageData = img.jpegData(compressionQuality: 0.82)
    }

    // MARK: - Antigüedad: UI <-> modelo

    private func hydrateSeniorityUIFromModel() {
        if let y = encounter.seniorityYears, y > 0 {
            seniorityUnit = .years
            seniorityValueText = String(y)
        } else if let m = encounter.seniorityMonths, m > 0 {
            seniorityUnit = .months
            seniorityValueText = String(m)
        } else if let w = encounter.seniorityWeeks, w > 0 {
            seniorityUnit = .weeks
            seniorityValueText = String(w)
        } else {
            seniorityUnit = .years
            seniorityValueText = ""
        }
    }

    private func applySeniorityValue(_ raw: String) {
        encounter.seniorityYears = nil
        encounter.seniorityMonths = nil
        encounter.seniorityWeeks = nil

        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, let value = Int(trimmed) else { return }

        switch seniorityUnit {
        case .years:
            encounter.seniorityYears = value
        case .months:
            encounter.seniorityMonths = value
        case .weeks:
            encounter.seniorityWeeks = value
        }
    }

    private var seniorityHasError: Bool {
        errors["seniorityYears"] != nil || errors["seniorityMonths"] != nil || errors["seniorityWeeks"] != nil
    }

    private var seniorityErrorMessage: String? {
        errors["seniorityYears"] ?? errors["seniorityMonths"] ?? errors["seniorityWeeks"]
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

    private func iconNumberField(
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
                .keyboardType(.numberPad)
                .visionTextField(isError: isError)
        }
    }

    // ✅ Turno: Picker(menu) SIN texto azul encimado (Picker invisible + UI propia)
    private func shiftPickerField(
        selection: Binding<String>,
        placeholder: String,
        isError: Bool
    ) -> some View {

        ZStack {
            // 1) Picker real pero invisible (para evitar el texto azul)
            Picker("", selection: selection) {
                Text(placeholder).tag("")
                ForEach(ShiftOption.allCases) { opt in
                    Text(opt.rawValue).tag(opt.rawValue)
                }
            }
            .pickerStyle(.menu)
            .labelsHidden()
            .opacity(0.02) // ✅ evita que se vea el label azul
            .frame(maxWidth: .infinity, alignment: .leading)

            // 2) Input visible (bonito)
            HStack(spacing: 10) {
                Image(systemName: "clock.arrow.2.circlepath")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.secondary)

                Text(selection.wrappedValue.isEmpty ? placeholder : selection.wrappedValue)
                    .foregroundStyle(selection.wrappedValue.isEmpty ? .secondary : .primary)
                    .lineLimit(1)

                Spacer()

                Image(systemName: "chevron.down")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(Color.black.opacity(0.04))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(isError ? BrandColors.danger.opacity(0.90) : BrandColors.accent.opacity(0.12), lineWidth: 1)
            )
            .allowsHitTesting(false) // ✅ el tap llega al Picker invisible
        }
        .contentShape(Rectangle())
    }


//
// MARK: - Progress Bar
//
struct ProgressPillBar: View {
    let progress: CGFloat
    var height: CGFloat = 10

    @State private var animatedProgress: CGFloat = 0

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(Color.black.opacity(0.06))
                Capsule()
                    .fill(BrandColors.strokeGradient)
                    .frame(width: max(0, min(geo.size.width, geo.size.width * animatedProgress)))
            }
            .frame(height: height)
            .onAppear {
                withAnimation(.easeInOut(duration: 0.45)) {
                    animatedProgress = progress
                }
            }
            .onChange(of: progress) { _, newValue in
                withAnimation(.easeInOut(duration: 0.45)) {
                    animatedProgress = newValue
                }
            }
        }
        .frame(height: height)
    }
}

//
// MARK: - TimePickerField (HH:mm en String?)
//
struct TimePickerField: View {
    let placeholder: String
    @Binding var value: String?

    @State private var date: Date = Date()
    @State private var hasValue: Bool = false

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "clock")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.secondary)

            DatePicker(
                "",
                selection: Binding(
                    get: { date },
                    set: { newDate in
                        date = newDate
                        hasValue = true
                        value = formatTime(newDate)
                    }
                ),
                displayedComponents: [.hourAndMinute]
            )
            .labelsHidden()
            .datePickerStyle(.compact)

            Spacer()

            if hasValue || (value != nil && !(value ?? "").isEmpty) {
                Button {
                    hasValue = false
                    value = nil
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary.opacity(0.7))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(Color.black.opacity(0.04))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(BrandColors.accent.opacity(0.12), lineWidth: 1)
        )
        .onAppear {
            if let v = value, let parsed = parseTime(v) {
                date = parsed
                hasValue = true
            }
        }
        .onChange(of: value) { _, newValue in
            if let v = newValue, let parsed = parseTime(v) {
                date = parsed
                hasValue = true
            }
        }
    }

    private func formatTime(_ date: Date) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "es_MX")
        f.dateFormat = "HH:mm"
        return f.string(from: date)
    }

    private func parseTime(_ string: String) -> Date? {
        let f = DateFormatter()
        f.locale = Locale(identifier: "es_MX")
        f.dateFormat = "HH:mm"
        guard let t = f.date(from: string) else { return nil }

        let cal = Calendar.current
        let comps = cal.dateComponents([.hour, .minute], from: t)
        return cal.date(bySettingHour: comps.hour ?? 0, minute: comps.minute ?? 0, second: 0, of: Date())
    }
}

//
// MARK: - Cámara: solo cámara, captura en modal
//
struct CameraCaptureView: UIViewControllerRepresentable {
    @Binding var isPresented: Bool
    let onImage: (UIImage) -> Void
    let onError: () -> Void

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.cameraCaptureMode = .photo
        picker.allowsEditing = false
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    final class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: CameraCaptureView

        init(parent: CameraCaptureView) {
            self.parent = parent
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.isPresented = false
        }

        func imagePickerController(_ picker: UIImagePickerController,
                                   didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            defer { parent.isPresented = false }

            if let img = info[.originalImage] as? UIImage {
                parent.onImage(img)
            } else {
                parent.onError()
            }
        }
    }
}
}
