//
//  SignaturePadView.swift
//  VisionWow — Lienzo de firma digital del ejecutivo
//
//  Usa PencilKit (PKCanvasView) — mismo stack que SignatureStepScreen.
//

import SwiftUI
import PencilKit

struct SignaturePadView: View {
    @Binding var signatureData: Data?

    @State private var canvas      = PKCanvasView()
    @State private var hasDrawing  = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {

            // Canvas de firma
            ZStack {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color.white)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(BrandColors.primary.opacity(0.35), lineWidth: 1.5)
                    )
                    .shadow(color: BrandColors.secondary.opacity(0.06), radius: 8, x: 0, y: 4)

                SignatureCanvasView(canvasView: $canvas) {
                    hasDrawing = !canvas.drawing.strokes.isEmpty
                    signatureData = canvas.exportPNG()
                }
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

                // Placeholder
                if !hasDrawing {
                    VStack(spacing: 6) {
                        Image(systemName: "signature")
                            .font(.system(size: 22))
                            .foregroundStyle(BrandColors.primary.opacity(0.3))
                        Text("Dibuja tu firma aquí")
                            .font(.system(size: 13))
                            .foregroundStyle(.secondary.opacity(0.7))
                    }
                    .allowsHitTesting(false)
                }

                // Línea guía inferior
                VStack {
                    Spacer()
                    Rectangle()
                        .fill(BrandColors.primary.opacity(0.18))
                        .frame(height: 1)
                        .padding(.horizontal, 24)
                        .padding(.bottom, 30)
                }
                .allowsHitTesting(false)
            }
            .frame(height: 160)

            // Botón limpiar — solo visible cuando hay trazos
            if hasDrawing {
                Button {
                    canvas.drawing = PKDrawing()
                    hasDrawing     = false
                    signatureData  = nil
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "trash")
                            .font(.system(size: 12, weight: .semibold))
                        Text("Limpiar firma")
                            .font(.system(size: 13, weight: .medium))
                    }
                    .foregroundStyle(BrandColors.danger)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(BrandColors.danger.opacity(0.08))
                            .overlay(
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .stroke(BrandColors.danger.opacity(0.25), lineWidth: 1)
                            )
                    )
                }
                .buttonStyle(.plain)
                .transition(.opacity.combined(with: .scale(scale: 0.9)))
                .animation(.easeInOut(duration: 0.2), value: hasDrawing)
            }
        }
    }
}
