//
//  VisionWowApp.swift
//  VisionWow
//
//  Created by Rodrigo Marcos on 27/12/25.
//

import SwiftUI
import SwiftData

@main
struct VisionWowApp: App {

    private let container: ModelContainer = {
        let schema = Schema([Company.self, Encounter.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [config])
        } catch {
            // Si falla por cambios de modelo (muy común en desarrollo),
            // borramos el store local y lo recreamos.
            print("SwiftData: error cargando store, intentando recuperación:", error)

            do {
                try VisionWowApp.deleteSwiftDataStoreFiles()
                return try ModelContainer(for: schema, configurations: [config])
            } catch {
                fatalError("No se pudo crear ModelContainer ni con recuperación: \(error)")
            }
        }
    }()

    var body: some Scene {
        WindowGroup {
            RootView()
                .preferredColorScheme(.light)
                .modelContainer(container) // INYECCIÓN GLOBAL
        }
    }

    /// Borra el store local de SwiftData (solo para desarrollo)
    private static func deleteSwiftDataStoreFiles() throws {
        let fm = FileManager.default
        let appSupport = try fm.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )

        let items = try fm.contentsOfDirectory(
            at: appSupport,
            includingPropertiesForKeys: nil
        )

        for url in items {
            let name = url.lastPathComponent
            if name.hasSuffix(".sqlite")
                || name.hasSuffix(".sqlite-wal")
                || name.hasSuffix(".sqlite-shm")
                || name.contains("store")
            {
                try? fm.removeItem(at: url)
            }
        }
    }
}
