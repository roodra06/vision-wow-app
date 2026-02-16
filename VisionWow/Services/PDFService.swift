//
//  PDFService.swift
//  VisionWow
//
//  Created by Rodrigo Marcos on 27/12/25.
//

import UIKit

enum PDFService {
    struct Output {
        let url: URL
        let data: Data
        let fileName: String
    }

    static func generate(encounter: Encounter) throws -> Output {
        guard let logo = UIImage(named: "visionwow_logo") else {
            throw NSError(domain: "PDFService", code: 1, userInfo: [NSLocalizedDescriptionKey: "No se encontró el logo en Assets.xcassets (visionwow_logo)."])
        }

        let data = PDFRenderer.render(encounter: encounter, logo: logo)

        let fileName = "VisionWow_\(safe(encounter.firstName))_\(safe(encounter.lastName))_\(DateUtils.formatStamp()).pdf"
        let url = try saveToDocuments(data: data, fileName: fileName)

        return Output(url: url, data: data, fileName: fileName)
    }

    private static func safe(_ s: String) -> String {
        let trimmed = s.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty { return "Paciente" }
        return trimmed.replacingOccurrences(of: " ", with: "_")
    }

    private static func saveToDocuments(data: Data, fileName: String) throws -> URL {
        let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let folder = dir.appendingPathComponent("VisionWow", isDirectory: true)
        if !FileManager.default.fileExists(atPath: folder.path) {
            try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        }
        let url = folder.appendingPathComponent(fileName)
        try data.write(to: url, options: .atomic)
        return url
    }
}
