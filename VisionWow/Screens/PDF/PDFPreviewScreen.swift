//
//  PDFPreviewScreen.swift
//  VisionWow
//
//  Created by Rodrigo Marcos on 27/12/25.
//
import SwiftUI

struct PDFPreviewScreen: View {
    let fileURL: URL

    var body: some View {
        NavigationStack {
            PDFKitView(url: fileURL)
                .navigationTitle("PDF")
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Compartir") {
                            print("[Compartir] Botón tapped — fileURL: \(fileURL.lastPathComponent)")
                            guard let data = try? Data(contentsOf: fileURL) else {
                                print("[Compartir] ❌ No se pudo leer el archivo")
                                return
                            }
                            print("[Compartir] ✅ Archivo leído — \(data.count) bytes")
                            ShareService.sharePDF(data: data, fileName: fileURL.lastPathComponent)
                        }
                    }
                }
        }
    }
}

