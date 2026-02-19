//
//  ReportComputer.swift
//  VisionWow
//
//  Created by Rodrigo Marcos on 19/02/26.
//

import Foundation

// MARK: - ReportSummary

struct ReportSummary {

    struct BucketCount: Identifiable, Hashable {
        let id = UUID()
        let label: String
        let count: Int
    }

    let totalEncounters: Int

    // Compra
    let boughtCount: Int
    let notBoughtCount: Int
    let buyRatePercent: Int

    // Antecedentes (lo que marcaron los pacientes)
    let antecedentCountsAll: [String: Int]
    let topAntecedents: [(String, Int)]
    let antecedentCountsSelectedFilterKeys: [String: Int]

    // Dioptrías
    let diopterDistribution: [BucketCount]
}

// MARK: - ReportComputer

enum ReportComputer {

    static func didBuy(_ e: Encounter) -> Bool {
        let status = e.payStatus.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let total  = e.payTotal.trimmingCharacters(in: .whitespacesAndNewlines)

        if status.contains("pag") { return true }
        if !total.isEmpty, total != "0" { return true }
        return false
    }

    static func computeSummary(
        company: Company,
        encounters: [Encounter],
        selectedAntecedentKeys: [String]
    ) -> ReportSummary {

        let total = encounters.count
        let bought = encounters.filter(didBuy).count
        let notBought = max(0, total - bought)
        let rate = total == 0 ? 0 : Int(round((Double(bought) / Double(total)) * 100.0))

        var allCounts: [String: Int] = [:]

        var selectedCounts: [String: Int] = [:]
        if !selectedAntecedentKeys.isEmpty {
            selectedAntecedentKeys.forEach { selectedCounts[$0] = 0 }
        }

        for e in encounters {
            guard let a = AntecedentsCodec.decode(from: e.antecedentesJSON) else { continue }

            // ✅ Todas las llaves activadas por paciente
            let enabled = AntecedentsCodec.enabledKeys(a)
            for key in enabled {
                allCounts[key, default: 0] += 1
            }

            // ✅ Conteo de llaves seleccionadas como filtro (si aplica)
            if !selectedAntecedentKeys.isEmpty {
                for key in selectedAntecedentKeys where enabled.contains(key) {
                    selectedCounts[key, default: 0] += 1
                }
            }
        }

        let top = allCounts
            .sorted { $0.value > $1.value }
            .prefix(10)
            .map { ($0.key, $0.value) }

        let dist = computeDiopterDistribution(encounters: encounters)

        return ReportSummary(
            totalEncounters: total,
            boughtCount: bought,
            notBoughtCount: notBought,
            buyRatePercent: rate,
            antecedentCountsAll: allCounts,
            topAntecedents: top,
            antecedentCountsSelectedFilterKeys: selectedCounts,
            diopterDistribution: dist
        )
    }

    // MARK: - Diopters

    static func computeDiopterDistribution(encounters: [Encounter]) -> [ReportSummary.BucketCount] {

        let buckets: [(label: String, test: (Double) -> Bool)] = [
            ("Buena (0 a ±0.50)", { abs($0) <= 0.50 }),
            ("Leve (±0.50 a ±1.50)", { abs($0) > 0.50 && abs($0) <= 1.50 }),
            ("Media (±1.50 a ±3.00)", { abs($0) > 1.50 && abs($0) <= 3.00 }),
            ("Alta (±3.00 a ±6.00)", { abs($0) > 3.00 && abs($0) <= 6.00 }),
            ("Muy alta (>6.00)", { abs($0) > 6.00 })
        ]

        var counts = Array(repeating: 0, count: buckets.count)

        for e in encounters {
            let od = parseDouble(e.rxOdSph)
            let os = parseDouble(e.rxOsSph)

            guard let value = worstAbs(od, os) else { continue }

            for (i, b) in buckets.enumerated() {
                if b.test(value) {
                    counts[i] += 1
                    break
                }
            }
        }

        return zip(buckets, counts).map { ReportSummary.BucketCount(label: $0.0.label, count: $0.1) }
    }

    private static func worstAbs(_ a: Double?, _ b: Double?) -> Double? {
        switch (a, b) {
        case (nil, nil): return nil
        case (let x?, nil): return x
        case (nil, let y?): return y
        case (let x?, let y?):
            return abs(x) >= abs(y) ? x : y
        }
    }

    static func parseDouble(_ s: String) -> Double? {
        let trimmed = s.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty { return nil }
        let normalized = trimmed.replacingOccurrences(of: ",", with: ".")
        return Double(normalized)
    }
}
