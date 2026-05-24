//
//  CotizacionStorage.swift
//  VisionWow — Módulo de Cotizaciones
//
//  Persiste el historial de cotizaciones usando UserDefaults + Codable.
//  No requiere CoreData ni librerías externas.
//

import Foundation
import Combine

final class CotizacionStorage: ObservableObject {

    /// Instancia compartida (singleton)
    static let shared = CotizacionStorage()

    // Claves de UserDefaults
    private let claveLista  = "vw_cotizaciones_lista"
    private let claveFolio  = "vw_cotizaciones_ultimo_numero"

    /// Lista reactiva de cotizaciones — más reciente primero
    @Published private(set) var cotizaciones: [Cotizacion] = []

    private init() {
        cargar()
    }

    // MARK: - Folio automático

    /// Devuelve el siguiente folio disponible en formato COT-YYYY-NNN
    /// (NO incrementa el contador — eso se hace al guardar)
    func siguienteFolio() -> String {
        let año     = Calendar.current.component(.year, from: Date())
        let ultimo  = UserDefaults.standard.integer(forKey: claveFolio)
        return String(format: "COT-%d-%03d", año, ultimo + 1)
    }

    // MARK: - Guardar

    /// Registra una nueva cotización e incrementa el contador de folio
    func guardar(_ cotizacion: Cotizacion) {
        // Incrementar el contador ANTES de guardar
        let numeroActual = UserDefaults.standard.integer(forKey: claveFolio)
        UserDefaults.standard.set(numeroActual + 1, forKey: claveFolio)

        // Insertar al inicio para que la más reciente aparezca primero
        cotizaciones.insert(cotizacion, at: 0)
        persistir()
    }

    // MARK: - Actualizar

    /// Reemplaza una cotización existente por su ID (modo edición)
    func actualizar(_ cotizacion: Cotizacion) {
        guard let idx = cotizaciones.firstIndex(where: { $0.id == cotizacion.id }) else { return }
        cotizaciones[idx] = cotizacion
        persistir()
    }

    // MARK: - Eliminar

    /// Elimina una cotización del historial por su ID
    func eliminar(id: UUID) {
        cotizaciones.removeAll { $0.id == id }
        persistir()
    }

    // MARK: - Persistencia interna

    private func persistir() {
        guard let data = try? JSONEncoder().encode(cotizaciones) else { return }
        UserDefaults.standard.set(data, forKey: claveLista)
    }

    private func cargar() {
        guard
            let data  = UserDefaults.standard.data(forKey: claveLista),
            let lista = try? JSONDecoder().decode([Cotizacion].self, from: data)
        else { return }
        cotizaciones = lista
    }
}
