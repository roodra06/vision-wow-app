//
//  SignatureCanvasView.swift
//  VisionWow
//

import SwiftUI
import PencilKit

struct SignatureCanvasView: UIViewRepresentable {
    @Binding var canvasView: PKCanvasView
    var onDrawingChanged: (() -> Void)?

    func makeUIView(context: Context) -> PKCanvasView {
        canvasView.drawingPolicy = .anyInput
        canvasView.tool = PKInkingTool(.pen, color: .black, width: 3)
        canvasView.backgroundColor = .clear
        canvasView.isOpaque = false
        canvasView.delegate = context.coordinator
        return canvasView
    }

    func updateUIView(_ uiView: PKCanvasView, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onDrawingChanged: onDrawingChanged)
    }

    final class Coordinator: NSObject, PKCanvasViewDelegate {
        let onDrawingChanged: (() -> Void)?
        init(onDrawingChanged: (() -> Void)?) {
            self.onDrawingChanged = onDrawingChanged
        }
        func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) {
            onDrawingChanged?()
        }
    }
}

extension PKCanvasView {
    func exportPNG() -> Data? {
        let bounds = drawing.bounds.isEmpty
            ? CGRect(x: 0, y: 0, width: frame.width, height: frame.height)
            : drawing.bounds.insetBy(dx: -10, dy: -10)
        let scale = window?.windowScene?.screen.scale ?? 3.0
        let image = drawing.image(from: bounds, scale: scale)
        return image.pngData()
    }
}
