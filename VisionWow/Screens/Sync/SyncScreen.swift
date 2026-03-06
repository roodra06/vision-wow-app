//
//  SyncScreen.swift
//  VisionWow
//
//  Pantalla de sincronización exclusiva por AirDrop.
//  Enviar: genera .vwsync y abre share sheet (AirDrop destacado).
//  Recibir: iOS abre el app automáticamente → FlowPickerScreen detecta la URL
//           → abre esta pantalla con el archivo ya procesado.
//

import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct SyncScreen: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(AppSyncState.self) private var syncState

    @Query private var allEncounters: [Encounter]

    // Export
    @State private var exportURL: URL?
    @State private var showShareSheet = false

    // Import result (cuando viene de AirDrop al abrir la pantalla)
    @State private var importResult: ExportImportService.ImportResult?
    @State private var showImportResult = false
    @State private var importSourceDevice: String = ""

    // Estado general
    @State private var isWorking = false
    @State private var workingMessage: String = ""
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            ZStack {
                BrandColors.backgroundGradient.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 28) {
                        headerSection
                        exportSection
                        howToReceiveSection
                        Spacer(minLength: 40)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 8)
                }
            }
            .navigationTitle("Sincronizar iPads")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cerrar") { dismiss() }
                        .foregroundStyle(BrandColors.primary)
                }
            }
            .sheet(isPresented: $showShareSheet, onDismiss: cleanupTempFile) {
                if let url = exportURL {
                    ShareSheet(items: [url])
                }
            }
            .sheet(isPresented: $showImportResult) {
                if let res = importResult {
                    ImportResultSheet(result: res, sourceDevice: importSourceDevice) {
                        showImportResult = false
                    }
                }
            }
            .alert("Error al importar", isPresented: .constant(errorMessage != nil), actions: {
                Button("OK") { errorMessage = nil }
            }, message: {
                Text(errorMessage ?? "")
            })
            .onAppear {
                // Procesar archivo recibido por AirDrop (si viene de FlowPickerScreen)
                if let url = syncState.incomingURL {
                    processIncomingFile(url: url)
                    syncState.incomingURL = nil
                }
            }
        }
    }

    // MARK: - Sections

    private var headerSection: some View {
        VStack(spacing: 10) {
            Image(systemName: "airplayaudio")
                .font(.system(size: 52))
                .foregroundStyle(BrandColors.strokeGradient)

            Text("Sincronizar por AirDrop")
                .font(.system(size: 19, weight: .semibold))
                .foregroundStyle(BrandColors.secondary)
                .multilineTextAlignment(.center)

            Text("Exporta los datos de este iPad y envíalos por AirDrop al iPad destino. El iPad receptor actualizará su base de datos automáticamente al aceptar el archivo.")
                .font(.system(size: 14))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 12)
    }

    private var exportSection: some View {
        SyncCard(
            icon: "square.and.arrow.up",
            title: "Exportar este iPad",
            subtitle: "\(allEncounters.count) expediente\(allEncounters.count == 1 ? "" : "s") · fotos y firmas incluidas"
        ) {
            Button(action: performExport) {
                HStack(spacing: 8) {
                    if isWorking {
                        ProgressView().tint(.white)
                        Text(workingMessage)
                            .fontWeight(.semibold)
                    } else {
                        Image(systemName: "arrow.up.circle.fill")
                        Text("Enviar por AirDrop")
                            .fontWeight(.semibold)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(isWorking || allEncounters.isEmpty ? Color.gray : BrandColors.primary)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .disabled(isWorking || allEncounters.isEmpty)

            if allEncounters.isEmpty {
                Text("No hay expedientes para exportar.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var howToReceiveSection: some View {
        SyncCard(
            icon: "square.and.arrow.down",
            title: "Cómo recibir datos",
            subtitle: "El iPad receptor se actualiza solo"
        ) {
            VStack(alignment: .leading, spacing: 10) {
                HowToStep(number: "1", text: "En el iPad origen, toca \"Enviar por AirDrop\"")
                HowToStep(number: "2", text: "Selecciona este iPad en el panel de AirDrop")
                HowToStep(number: "3", text: "Acepta el archivo en este iPad")
                HowToStep(number: "4", text: "VisionWow importa automáticamente los expedientes")
            }

            Text("Los expedientes duplicados se omiten. Fotos, firmas y datos de empresa se sincronizan completos.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.top, 4)
        }
    }

    // MARK: - Actions

    private func performExport() {
        workingMessage = "Preparando archivo…"
        isWorking = true
        Task {
            do {
                let data = try ExportImportService.export(encounters: allEncounters)
                let fileName = makeFileName()
                let tmpURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
                try data.write(to: tmpURL)
                await MainActor.run {
                    exportURL = tmpURL
                    showShareSheet = true
                    isWorking = false
                    workingMessage = ""
                }
            } catch {
                await MainActor.run {
                    errorMessage = "No se pudo exportar: \(error.localizedDescription)"
                    isWorking = false
                    workingMessage = ""
                }
            }
        }
    }

    private func processIncomingFile(url: URL) {
        workingMessage = "Importando expedientes…"
        isWorking = true
        Task {
            do {
                let data = try Data(contentsOf: url)
                // Extraer nombre del dispositivo origen del nombre del archivo
                let fileName = url.deletingPathExtension().lastPathComponent
                let deviceHint = fileName.components(separatedBy: "_").dropLast(2).joined(separator: " ")
                let res = try await MainActor.run {
                    try ExportImportService.importPackage(data: data, modelContext: modelContext)
                }
                await MainActor.run {
                    importSourceDevice = deviceHint
                    importResult = res
                    showImportResult = true
                    isWorking = false
                    workingMessage = ""
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Error al importar: \(error.localizedDescription)"
                    isWorking = false
                    workingMessage = ""
                }
            }
        }
    }

    private func cleanupTempFile() {
        if let url = exportURL {
            try? FileManager.default.removeItem(at: url)
            exportURL = nil
        }
    }

    // MARK: - Filename

    private func makeFileName() -> String {
        // Intentar usar el nombre de la empresa principal
        let names = Set(allEncounters.compactMap { $0.company?.name })
        let companyPart: String
        if names.count == 1, let name = names.first {
            companyPart = name
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .replacingOccurrences(of: " ", with: "_")
                .filter { $0.isLetter || $0.isNumber || $0 == "_" }
                .trimmingCharacters(in: CharacterSet(charactersIn: "_"))
        } else {
            companyPart = "VisionWow"
        }

        let df = DateFormatter()
        df.dateFormat = "yyyyMMdd"
        let dateStr = df.string(from: Date())
        let uniqueKey = String(UUID().uuidString.prefix(6).uppercased())
        return "\(companyPart)_\(dateStr)_\(uniqueKey).vwsync"
    }
}

// MARK: - HowToStep helper

private struct HowToStep: View {
    let number: String
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Text(number)
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 20, height: 20)
                .background(BrandColors.primary)
                .clipShape(Circle())

            Text(text)
                .font(.system(size: 13))
                .foregroundStyle(BrandColors.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

// MARK: - SyncCard helper

private struct SyncCard<Content: View>: View {
    let icon: String
    let title: String
    let subtitle: String
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(BrandColors.primary)
                    .frame(width: 36, height: 36)
                    .background(BrandColors.primary.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 8))

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(BrandColors.secondary)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            content()
        }
        .padding(20)
        .background(BrandColors.cardFill)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: BrandColors.secondary.opacity(0.10), radius: 8, x: 0, y: 4)
    }
}

// MARK: - ImportResultSheet

private struct ImportResultSheet: View {
    let result: ExportImportService.ImportResult
    let sourceDevice: String
    let onDismiss: () -> Void

    private var hasChanges: Bool { result.inserted > 0 || result.updated > 0 }

    var body: some View {
        NavigationStack {
            ZStack {
                BrandColors.backgroundGradient.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {

                        // Icono y título
                        VStack(spacing: 10) {
                            Image(systemName: hasChanges ? "checkmark.circle.fill" : "arrow.triangle.2.circlepath")
                                .font(.system(size: 60))
                                .foregroundStyle(hasChanges ? Color.green : BrandColors.primary)

                            Text(hasChanges ? "¡Sincronización exitosa!" : "Todo al día")
                                .font(.system(size: 22, weight: .bold, design: .rounded))
                                .foregroundStyle(BrandColors.secondary)

                            if !sourceDevice.isEmpty {
                                Text("Archivo: \(sourceDevice)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(.top, 8)

                        // Totales
                        HStack(spacing: 0) {
                            StatBadge(value: result.inserted, label: "Nuevos", color: .green)
                            Divider().frame(height: 40)
                            StatBadge(value: result.updated, label: "Actualizados", color: BrandColors.primary)
                            Divider().frame(height: 40)
                            StatBadge(value: result.skipped, label: "Sin cambios", color: .secondary)
                        }
                        .background(BrandColors.cardFill)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .shadow(color: BrandColors.secondary.opacity(0.08), radius: 6, x: 0, y: 3)

                        // Desglose por empresa
                        if !result.sortedCompanies.isEmpty {
                            VStack(alignment: .leading, spacing: 0) {
                                Text("DETALLE POR EMPRESA")
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundStyle(.secondary)
                                    .padding(.bottom, 8)
                                    .padding(.horizontal, 4)

                                VStack(spacing: 0) {
                                    ForEach(result.sortedCompanies, id: \.name) { co in
                                        CompanyResultRow(company: co)
                                        if co.name != result.sortedCompanies.last?.name {
                                            Divider().padding(.leading, 16)
                                        }
                                    }
                                }
                                .background(BrandColors.cardFill)
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                                .shadow(color: BrandColors.secondary.opacity(0.08), radius: 6, x: 0, y: 3)
                            }
                        }

                        // Errores (si hay)
                        if !result.errors.isEmpty {
                            VStack(alignment: .leading, spacing: 6) {
                                Label("Errores (\(result.errors.count))", systemImage: "exclamationmark.triangle.fill")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundStyle(.orange)

                                ForEach(result.errors.prefix(5), id: \.self) { err in
                                    Text("• \(err)")
                                        .font(.system(size: 11))
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .padding(14)
                            .background(Color.orange.opacity(0.08))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }

                        Button(action: onDismiss) {
                            Text("Cerrar")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(BrandColors.primary)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .padding(.top, 4)
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 32)
                }
            }
            .navigationTitle("Resultado")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

private struct StatBadge: View {
    let value: Int
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 2) {
            Text("\(value)")
                .font(.system(size: 26, weight: .bold, design: .rounded))
                .foregroundStyle(value > 0 ? color : Color.secondary)
            Text(label)
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
    }
}

private struct CompanyResultRow: View {
    let company: ExportImportService.CompanyResult

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(company.name)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(BrandColors.secondary)
                HStack(spacing: 10) {
                    if company.inserted > 0 {
                        Label("\(company.inserted) nuevo\(company.inserted > 1 ? "s" : "")", systemImage: "plus.circle.fill")
                            .font(.caption)
                            .foregroundStyle(.green)
                    }
                    if company.updated > 0 {
                        Label("\(company.updated) actualizado\(company.updated > 1 ? "s" : "")", systemImage: "arrow.clockwise.circle.fill")
                            .font(.caption)
                            .foregroundStyle(BrandColors.primary)
                    }
                }
            }
            Spacer()
            Text("\(company.inserted + company.updated)")
                .font(.system(size: 17, weight: .bold, design: .rounded))
                .foregroundStyle(BrandColors.secondary.opacity(0.6))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

// MARK: - UTType extension

extension UTType {
    static let vwsync = UTType(exportedAs: "com.visionwow.vwsync")
}

// MARK: - ShareSheet (UIActivityViewController wrapper)

private struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
