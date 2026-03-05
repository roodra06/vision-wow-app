//
//  ShareService.swift
//  VisionWow
//
//  Created by Rodrigo Marcos on 27/12/25.
//

import UIKit

// Proveedor explícito de PDF que evita LaunchServices.
// UIActivityViewController usará este objeto para obtener los datos del archivo
// con el UTI correcto sin necesidad de resolver la ruta en la sandbox.
private final class PDFActivityItem: NSObject, UIActivityItemSource {
    let data: Data
    let fileName: String

    init(data: Data, fileName: String) {
        self.data = data
        self.fileName = fileName
    }

    func activityViewControllerPlaceholderItem(_ activityViewController: UIActivityViewController) -> Any {
        return data
    }

    func activityViewController(_ activityViewController: UIActivityViewController,
                                itemForActivityType activityType: UIActivity.ActivityType?) -> Any? {
        return data
    }

    func activityViewController(_ activityViewController: UIActivityViewController,
                                dataTypeIdentifierForActivityType activityType: UIActivity.ActivityType?) -> String {
        return "com.adobe.pdf"
    }

    func activityViewController(_ activityViewController: UIActivityViewController,
                                subjectForActivityType activityType: UIActivity.ActivityType?) -> String {
        return fileName
    }

    func activityViewController(_ activityViewController: UIActivityViewController,
                                filenameForActivityType activityType: UIActivity.ActivityType?) -> String {
        return fileName
    }
}

enum ShareService {
    static func sharePDF(data: Data, fileName: String) {
        print("[ShareService] sharePDF — fileName: \(fileName), bytes: \(data.count)")
        guard let top = topMostVC() else {
            print("[ShareService] ❌ No se encontró topMostVC")
            return
        }
        print("[ShareService] topMostVC: \(type(of: top))")

        // Escribe el PDF en un archivo temporal que WhatsApp puede leer directamente,
        // sin depender de LaunchServices para resolver rutas del sandbox.
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        do {
            try data.write(to: tempURL, options: .atomic)
            print("[ShareService] ✅ Temp file escrito: \(tempURL.path)")
        } catch {
            print("[ShareService] ❌ Error escribiendo temp file: \(error)")
            return
        }

        let provider = NSItemProvider()
        provider.suggestedName = String(fileName.dropLast(4)) // sin .pdf
        provider.registerFileRepresentation(
            forTypeIdentifier: "com.adobe.pdf",
            fileOptions: [],
            visibility: .all
        ) { completion in
            print("[ShareService] NSItemProvider — entregando archivo a la app receptora")
            completion(tempURL, false, nil)
            return nil
        }

        let vc = UIActivityViewController(activityItems: [provider], applicationActivities: nil)
        print("[ShareService] UIActivityViewController creado")

        if let popover = vc.popoverPresentationController {
            popover.sourceView = top.view
            popover.sourceRect = CGRect(x: top.view.bounds.midX, y: top.view.bounds.midY, width: 0, height: 0)
            popover.permittedArrowDirections = []
        }
        top.present(vc, animated: true)
        print("[ShareService] UIActivityViewController presentado")
    }

    static func share(items: [Any]) {
        guard let top = topMostVC() else { return }
        let vc = UIActivityViewController(activityItems: items, applicationActivities: nil)
        if let popover = vc.popoverPresentationController {
            popover.sourceView = top.view
            popover.sourceRect = CGRect(x: top.view.bounds.midX, y: top.view.bounds.midY, width: 0, height: 0)
            popover.permittedArrowDirections = []
        }
        top.present(vc, animated: true)
    }

    private static func topMostVC() -> UIViewController? {
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let root = scene.windows.first?.rootViewController else { return nil }
        var top = root
        while let presented = top.presentedViewController {
            top = presented
        }
        return top
    }
}
