//
//  AntecedentsCodec.swift
//  VisionWow
//
//  Created by Rodrigo Marcos on 19/02/26.
//

import Foundation

enum AntecedentsCodec {

    // MARK: - Decode

    static func decode(from json: String) -> Antecedents? {
        let trimmed = json.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        guard let data = trimmed.data(using: .utf8) else { return nil }

        do {
            return try JSONDecoder().decode(Antecedents.self, from: data)
        } catch {
            // Si quieres ver fallos de decode:
            // print("AntecedentsCodec.decode error:", error, "json:", trimmed.prefix(200))
            return nil
        }
    }

    // MARK: - Sections

    static func allSections(_ a: Antecedents) -> [[String: Bool]] {
        [
            a.antecedentes,
            a.sintomas,
            a.cirugias,
            a.conjuntivitis,
            a.computadora,
            a.anexos,
            a.salud,
            a.saludOcular,
            a.consultas
        ]
    }

    // MARK: - Enabled Keys

    /// Regresa TODAS las llaves que están en true en cualquier sección.
    /// (Opcional: excluimos "Otra" porque suele ser genérica; si la quieres contar, cambia `excludeOtra` a false.)
    static func enabledKeys(_ a: Antecedents, excludeOtra: Bool = true) -> Set<String> {
        var set = Set<String>()

        for section in allSections(a) {
            for (key, isOn) in section where isOn {
                if excludeOtra, key.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() == "otra" {
                    continue
                }
                set.insert(key)
            }
        }
        return set
    }

    /// Retorna true si esa key está en true en CUALQUIER sección.
    static func hasKeyEnabled(_ a: Antecedents, key: String) -> Bool {
        let k = key.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !k.isEmpty else { return false }

        for section in allSections(a) {
            if section[k] == true { return true }
        }
        return false
    }
}
