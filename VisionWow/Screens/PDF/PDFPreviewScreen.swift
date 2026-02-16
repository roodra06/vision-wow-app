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
                            ShareService.share(items: [fileURL])
                        }
                    }
                }
        }
    }
}

