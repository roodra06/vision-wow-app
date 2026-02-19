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

        // ✅ Incluye TODOS los @Model aquí
        let schema = Schema([
            Company.self,
            Patient.self,
            Encounter.self
        ])

        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false
        )

        do {
            return try ModelContainer(
                for: schema,
                configurations: [configuration]
            )
        } catch {
            print("SwiftData: error cargando store:", error)

            #if DEBUG
            // ✅ Solo en desarrollo: borrar store y recrear
            do {
                try VisionWowApp.deleteSwiftDataStoreFiles()
                return try ModelContainer(
                    for: schema,
                    configurations: [configuration]
                )
            } catch {
                fatalError("No se pudo recrear ModelContainer en DEBUG: \(error)")
            }
            #else
            // ❌ En producción jamás borres expedientes automáticamente
            fatalError("""
            Error crítico cargando base de datos.
            Se requiere migración o revisión del modelo.
            Error: \(error)
            """)
            #endif
        }
    }()

    var body: some Scene {
        WindowGroup {
            RootView()
                .preferredColorScheme(.light)
                .modelContainer(container)
        }
    }

    // MARK: - DEBUG ONLY STORE RESET

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
                print("SwiftData: store eliminado en DEBUG ->", name)
            }
        }
    }
}
