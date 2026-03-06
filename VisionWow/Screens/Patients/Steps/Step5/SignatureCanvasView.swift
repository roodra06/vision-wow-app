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

    func updateUIView(_ uiView: PKCanvasView, context: Context) {
        // Mantener el delegate sincronizado ante rebuilds de SwiftUI
        uiView.delegate = context.coordinator

        // FIX: El UIScrollView padre retiene el primer toque por defecto
        // (delaysContentTouches = true), lo que hace que el primer trazo no
        // se registre en PKCanvasView. Deshabilitarlo permite que el canvas
        // reciba el toque inmediatamente desde el primer trazo.
        uiView.parentScrollView()?.delaysContentTouches = false
    }

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

// MARK: - UIView hierarchy helper

private extension UIView {
    /// Recorre la jerarquía hacia arriba buscando el primer UIScrollView padre.
    func parentScrollView() -> UIScrollView? {
        var current: UIView? = superview
        while let view = current {
            if let sv = view as? UIScrollView { return sv }
            current = view.superview
        }
        return nil
    }
}

// MARK: - PKCanvasView export

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
