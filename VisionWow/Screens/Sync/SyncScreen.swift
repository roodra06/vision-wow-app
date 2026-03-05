//
//  SyncScreen.swift
//  VisionWow
//
//  Pantalla para exportar/importar datos entre iPads (.vwsync JSON).
//  Cómo usarlo:
//    1. iPad A: "Exportar" → comparte el .vwsync por AirDrop / Mail / Files
//    2. iPad B: "Importar" → selecciona el .vwsync recibido → los datos se fusionan
//

import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct SyncScreen: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @Query private var allEncounters: [Encounter]

    // Export
    @State private var exportURL: URL?
    @State private var showShareSheet = false

    // Import
    @State private var showFilePicker = false
    @State private var importResult: ExportImportService.ImportResult?
    @State private var showImportResult = false

    // Estado general
    @State private var isWorking = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            ZStack {
                BrandColors.backgroundGradient.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 28) {
                        headerSection
                        exportSection
                        importSection
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
            .fileImporter(
                isPresented: $showFilePicker,
                allowedContentTypes: [.vwsync],
                allowsMultipleSelection: false
            ) { result in
                handleFileImport(result: result)
            }
            .alert("Importación completada", isPresented: $showImportResult, presenting: importResult) { _ in
                Button("OK") {}
            } message: { res in
                Text(importResultMessage(res))
            }
            .alert("Error", isPresented: .constant(errorMessage != nil), actions: {
                Button("OK") { errorMessage = nil }
            }, message: {
                Text(errorMessage ?? "")
            })
        }
    }

    // MARK: - Sections

    private var headerSection: some View {
        VStack(spacing: 10) {
            Image(systemName: "arrow.triangle.2.circlepath.icloud")
                .font(.system(size: 52))
                .foregroundStyle(BrandColors.strokeGradient)

            Text("Combina datos de múltiples iPads")
                .font(.system(size: 17, weight: .medium))
                .foregroundStyle(BrandColors.secondary)
                .multilineTextAlignment(.center)

            Text("Exporta los datos de este iPad y luego importalos en el iPad principal para generar un reporte unificado.")
                .font(.system(size: 14))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 12)
    }

    private var exportSection: some View {
        SyncCard(
            icon: "square.and.arrow.up",
            title: "Exportar datos",
            subtitle: "\(allEncounters.count) expediente\(allEncounters.count == 1 ? "" : "s") en este iPad"
        ) {
            Button(action: performExport) {
                HStack(spacing: 8) {
                    if isWorking {
                        ProgressView().tint(.white)
                    } else {
                        Image(systemName: "square.and.arrow.up.fill")
                    }
                    Text("Exportar y compartir")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(BrandColors.primary)
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

    private var importSection: some View {
        SyncCard(
            icon: "square.and.arrow.down",
            title: "Importar datos",
            subtitle: "Carga un archivo .vwsync recibido de otro iPad"
        ) {
            Button(action: { showFilePicker = true }) {
                HStack(spacing: 8) {
                    Image(systemName: "square.and.arrow.down.fill")
                    Text("Seleccionar archivo .vwsync")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(BrandColors.secondary)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .disabled(isWorking)

            Text("Los expedientes duplicados se omiten. Los datos más recientes prevalecen.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Actions

    private func performExport() {
        isWorking = true
        Task {
            do {
                let data = try ExportImportService.export(encounters: allEncounters)
                let fileName = "VisionWow_\(deviceShortName())_\(dateTag()).vwsync"
                let tmpURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
                try data.write(to: tmpURL)
                await MainActor.run {
                    exportURL = tmpURL
                    showShareSheet = true
                    isWorking = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = "No se pudo exportar: \(error.localizedDescription)"
                    isWorking = false
                }
            }
        }
    }

    private func handleFileImport(result: Result<[URL], Error>) {
        switch result {
        case .failure(let err):
            errorMessage = "Error al seleccionar archivo: \(err.localizedDescription)"
        case .success(let urls):
            guard let url = urls.first else { return }
            isWorking = true
            Task {
                do {
                    let accessed = url.startAccessingSecurityScopedResource()
                    defer { if accessed { url.stopAccessingSecurityScopedResource() } }
                    let data = try Data(contentsOf: url)
                    let res = try await MainActor.run {
                        try ExportImportService.importPackage(data: data, modelContext: modelContext)
                    }
                    await MainActor.run {
                        importResult = res
                        showImportResult = true
                        isWorking = false
                    }
                } catch {
                    await MainActor.run {
                        errorMessage = "Error al importar: \(error.localizedDescription)"
                        isWorking = false
                    }
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

    private func importResultMessage(_ res: ExportImportService.ImportResult) -> String {
        var msg = "Nuevos: \(res.inserted) · Actualizados: \(res.updated) · Omitidos: \(res.skipped)"
        if !res.errors.isEmpty {
            msg += "\n\nErrores (\(res.errors.count)):\n" + res.errors.prefix(3).joined(separator: "\n")
        }
        return msg
    }

    private func deviceShortName() -> String {
        UIDevice.current.name
            .replacingOccurrences(of: " ", with: "_")
            .filter { $0.isLetter || $0.isNumber || $0 == "_" }
    }

    private func dateTag() -> String {
        let f = DateFormatter()
        f.dateFormat = "yyyyMMdd_HHmm"
        return f.string(from: Date())
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
