//
//  FaceAnalysisSheet.swift
//  VisionWow
//
//  Analizador de forma de rostro.
//  Flujo: guía → cámara con detección en tiempo real → análisis → resultado detallado
//

import SwiftUI
import UIKit

struct FaceAnalysisSheet: View {
    @Environment(\.dismiss) private var dismiss

    /// Callback opcional: notifica al padre cuando el análisis termina con éxito
    var onResult: ((FaceShape) -> Void)?

    @State private var viewState: ViewState = .guide
    @State private var capturedImage: UIImage?
    @State private var showCamera = false
    @State private var analysisResult: (shape: FaceShape, measurements: FaceMeasurements)?
    @State private var analysisError: String?

    enum ViewState { case guide, analyzing, result, error }

    var body: some View {
        NavigationStack {
            ZStack {
                BrandColors.backgroundGradient.ignoresSafeArea()

                switch viewState {
                case .guide:     guideView
                case .analyzing: analyzingView
                case .result:    resultView
                case .error:     errorView
                }
            }
            .navigationTitle("Analizador de Rostro")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cerrar") { dismiss() }
                        .foregroundStyle(BrandColors.primary)
                }
                if viewState == .result {
                    ToolbarItem(placement: .primaryAction) {
                        Button("Nueva foto") {
                            withAnimation { viewState = .guide }
                        }
                        .foregroundStyle(BrandColors.primary)
                    }
                }
            }
            .fullScreenCover(isPresented: $showCamera) {
                LiveFaceCameraView(
                    onCapture: { image in
                        capturedImage = image
                        showCamera = false
                        runAnalysis(on: image)
                    },
                    onDismiss: { showCamera = false }
                )
                .ignoresSafeArea()
            }
        }
    }

    // MARK: - Guide

    private var guideView: some View {
        ScrollView {
            VStack(spacing: 28) {
                // Hero
                VStack(spacing: 12) {
                    Image(systemName: "faceid")
                        .font(.system(size: 64))
                        .foregroundStyle(BrandColors.strokeGradient)

                    Text("Análisis de Rostro")
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundStyle(BrandColors.secondary)

                    Text("Toma una foto del rostro del paciente. El sistema detectará la forma de su cara y recomendará los armazones más compatibles.")
                        .font(.system(size: 14))
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 8)
                }
                .padding(.top, 8)

                // Tips
                VStack(alignment: .leading, spacing: 14) {
                    Text("Para mejores resultados:")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(BrandColors.secondary)

                    TipRow(icon: "sun.max.fill",          color: .yellow,           text: "Buena iluminación, sin sombras duras")
                    TipRow(icon: "face.smiling",          color: BrandColors.primary, text: "Rostro de frente, mirada al lente")
                    TipRow(icon: "person.crop.rectangle", color: .green,            text: "Rostro ocupando la mayor parte del óvalo")
                    TipRow(icon: "wand.and.stars",        color: .purple,           text: "Sin cabello tapando frente ni mandíbula")
                    TipRow(icon: "lightbulb.fill",        color: .orange,           text: "La cámara guiará el posicionamiento en tiempo real")
                }
                .padding(18)
                .background(BrandColors.cardFill)
                .clipShape(RoundedRectangle(cornerRadius: 16))

                Button(action: { showCamera = true }) {
                    HStack(spacing: 10) {
                        Image(systemName: "camera.fill")
                        Text("Iniciar análisis")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(BrandColors.primary)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }

                Text("El análisis es 100% en el dispositivo. No se envían datos a ningún servidor.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
    }

    // MARK: - Analyzing

    private var analyzingView: some View {
        VStack(spacing: 24) {
            if let img = capturedImage {
                Image(uiImage: img)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 170, height: 170)
                    .clipShape(RoundedRectangle(cornerRadius: 22))
                    .overlay(
                        RoundedRectangle(cornerRadius: 22)
                            .stroke(BrandColors.strokeGradient, lineWidth: 3)
                    )
                    .shadow(color: BrandColors.secondary.opacity(0.18), radius: 12, x: 0, y: 6)
            }

            VStack(spacing: 10) {
                ProgressView()
                    .scaleEffect(1.4)
                    .tint(BrandColors.primary)

                Text("Analizando rostro…")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(BrandColors.secondary)

                Text("Detectando proporciones, forma y características faciales")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
            }
        }
    }

    // MARK: - Result

    private var resultView: some View {
        ScrollView {
            if let res = analysisResult {
                VStack(spacing: 20) {

                    // ── Foto capturada + resumen de forma
                    if let img = capturedImage {
                        CapturedFaceCard(image: img, shape: res.shape)
                    } else {
                        FaceShapeCard(shape: res.shape)
                    }

                    // ── Características detectadas
                    TraitsCard(measurements: res.measurements)

                    // ── Mediciones detalladas
                    DetailedMeasurementsCard(measurements: res.measurements)

                    // ── Armazones recomendados
                    VStack(alignment: .leading, spacing: 12) {
                        ScannerSectionHeader(
                            icon: "checkmark.seal.fill", color: .green,
                            title: "Armazones recomendados",
                            subtitle: res.shape.compatibilityLabel)
                        ForEach(res.shape.recommendedFrames) { frame in
                            FrameCard(suggestion: frame)
                        }
                    }

                    // ── Armazones a evitar
                    VStack(alignment: .leading, spacing: 10) {
                        ScannerSectionHeader(
                            icon: "xmark.circle.fill", color: .orange,
                            title: "Mejor evitar",
                            subtitle: "No son ideales para este tipo de rostro")
                        VStack(alignment: .leading, spacing: 6) {
                            ForEach(res.shape.framesToAvoid, id: \.self) { item in
                                HStack(spacing: 8) {
                                    Image(systemName: "xmark.circle")
                                        .foregroundStyle(.orange)
                                        .font(.caption)
                                    Text(item)
                                        .font(.system(size: 13))
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                        .padding(14)
                        .background(Color.orange.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }

                    Color.clear.frame(height: 8)
                }
                .padding(.horizontal, 20)
                .padding(.top, 4)
                .padding(.bottom, 32)
            }
        }
    }

    // MARK: - Error

    private var errorView: some View {
        VStack(spacing: 24) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 52))
                .foregroundStyle(.orange)

            VStack(spacing: 8) {
                Text("No se pudo analizar")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(BrandColors.secondary)

                Text(analysisError ?? "Error desconocido.")
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
            }

            Button(action: { withAnimation { viewState = .guide } }) {
                Label("Intentar de nuevo", systemImage: "arrow.clockwise")
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(BrandColors.primary)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .padding(.horizontal, 40)
            }
        }
    }

    // MARK: - Analysis trigger

    private func runAnalysis(on image: UIImage) {
        withAnimation { viewState = .analyzing }
        Task {
            do {
                let result = try await FaceShapeAnalyzer.analyze(image: image)
                await MainActor.run {
                    analysisResult = result
                    withAnimation { viewState = .result }
                    onResult?(result.shape)
                }
            } catch {
                await MainActor.run {
                    analysisError = error.localizedDescription
                    withAnimation { viewState = .error }
                }
            }
        }
    }
}

// MARK: - CapturedFaceCard

private struct CapturedFaceCard: View {
    let image: UIImage
    let shape: FaceShape

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(width: 110, height: 132)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(BrandColors.strokeGradient, lineWidth: 2.5)
                )

            VStack(alignment: .leading, spacing: 8) {
                Text(shape.emoji)
                    .font(.system(size: 40))

                Text("Rostro \(shape.rawValue)")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundStyle(BrandColors.secondary)

                Text(shape.compatibilityLabel)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(BrandColors.primary)
                    .clipShape(Capsule())

                Text(shape.description)
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .lineLimit(5)
            }

            Spacer(minLength: 0)
        }
        .padding(16)
        .background(BrandColors.cardFill)
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .shadow(color: BrandColors.secondary.opacity(0.10), radius: 8, x: 0, y: 4)
    }
}

// MARK: - FaceShapeCard (fallback sin foto)

private struct FaceShapeCard: View {
    let shape: FaceShape

    var body: some View {
        VStack(spacing: 14) {
            HStack(spacing: 16) {
                Text(shape.emoji)
                    .font(.system(size: 52))

                VStack(alignment: .leading, spacing: 4) {
                    Text("Rostro \(shape.rawValue)")
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundStyle(BrandColors.secondary)

                    Text(shape.compatibilityLabel)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(BrandColors.primary)
                        .clipShape(Capsule())
                }
                Spacer()
            }
            Text(shape.description)
                .font(.system(size: 13))
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(18)
        .background(BrandColors.cardFill)
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .shadow(color: BrandColors.secondary.opacity(0.10), radius: 8, x: 0, y: 4)
    }
}

// MARK: - TraitsCard (características detectadas)

private struct TraitsCard: View {
    let measurements: FaceMeasurements

    private var traits: [(icon: String, color: Color, text: String)] {
        var list: [(String, Color, String)] = []

        // Proporción largo/ancho
        switch measurements.aspectRatio {
        case ..<0.72:  list.append(("ruler",        .purple,          "Rostro notablemente alargado"))
        case ..<0.82:  list.append(("ruler",        BrandColors.primary, "Rostro proporcionado y ligeramente alargado"))
        case 0.92...:  list.append(("circle.fill",  .orange,          "Rostro ancho y redondeado"))
        default:       list.append(("ruler",        .green,           "Proporciones ancho-alto muy equilibradas"))
        }

        // Frente vs mandíbula
        switch measurements.foreheadToJawRatio {
        case 1.18...: list.append(("triangle.fill", .pink,            "Frente notablemente más ancha que la mandíbula"))
        case 1.07...: list.append(("triangle",      BrandColors.primary, "Frente ligeramente más ancha que la mandíbula"))
        case ..<0.88: list.append(("triangle.fill", .orange,          "Mandíbula más ancha que la frente"))
        default:      list.append(("equal.circle",  .green,           "Frente y mandíbula de anchuras similares"))
        }

        // Mentón
        switch measurements.chinSharpness {
        case 0.55...: list.append(("drop.fill",                  BrandColors.primary, "Mentón fino y bien definido"))
        case 0.35...: list.append(("drop",                       .teal,              "Mentón moderadamente definido"))
        default:      list.append(("rectangle.roundedtop.fill",  .secondary,         "Mentón ancho y redondeado"))
        }

        // Prominencia de mejillas
        switch measurements.cheekProminence {
        case 1.10...: list.append(("diamond.fill", .indigo,          "Zona media del rostro muy prominente"))
        case 1.04...: list.append(("diamond",      BrandColors.secondary, "Zona de mejillas bien marcada"))
        case ..<0.94: list.append(("heart.fill",   .pink,            "Zona superior más amplia que la mandíbula"))
        default:      list.append(("hexagon",      .green,           "Anchura facial equilibrada en toda la altura"))
        }

        return list
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Características detectadas", systemImage: "magnifyingglass.circle.fill")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(BrandColors.secondary)

            VStack(alignment: .leading, spacing: 8) {
                ForEach(traits.indices, id: \.self) { i in
                    HStack(spacing: 10) {
                        Image(systemName: traits[i].icon)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(traits[i].color)
                            .frame(width: 20)
                        Text(traits[i].text)
                            .font(.system(size: 13))
                            .foregroundStyle(BrandColors.secondary)
                    }
                }
            }
        }
        .padding(16)
        .background(BrandColors.cardFill)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: BrandColors.secondary.opacity(0.08), radius: 6, x: 0, y: 3)
    }
}

// MARK: - DetailedMeasurementsCard

private struct DetailedMeasurementsCard: View {
    let measurements: FaceMeasurements

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label("Proporciones medidas", systemImage: "ruler")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(BrandColors.secondary)

            DetailMeasBar(
                label: "Proporción ancho / alto",
                value: measurements.aspectRatio,
                minLabel: "Alargado", maxLabel: "Muy ancho",
                range: 0.58...1.10,
                interpretation: aspectRatioLabel(measurements.aspectRatio))

            DetailMeasBar(
                label: "Frente vs mandíbula",
                value: measurements.foreheadToJawRatio,
                minLabel: "Mandíbula amplia", maxLabel: "Frente amplia",
                range: 0.70...1.40,
                interpretation: foreheadJawLabel(measurements.foreheadToJawRatio))

            DetailMeasBar(
                label: "Prominencia de mejillas",
                value: measurements.cheekProminence,
                minLabel: "Plano", maxLabel: "Muy prominente",
                range: 0.85...1.25,
                interpretation: cheekLabel(measurements.cheekProminence))

            DetailMeasBar(
                label: "Definición del mentón",
                value: measurements.chinSharpness,
                minLabel: "Mentón ancho", maxLabel: "Mentón fino",
                range: 0.0...0.80,
                interpretation: chinLabel(measurements.chinSharpness))
        }
        .padding(16)
        .background(BrandColors.cardFill)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: BrandColors.secondary.opacity(0.08), radius: 6, x: 0, y: 3)
    }

    private func aspectRatioLabel(_ v: Double) -> String {
        if v < 0.72 { return "Muy alargado" }
        if v < 0.82 { return "Alargado" }
        if v < 0.90 { return "Equilibrado" }
        return "Ancho"
    }

    private func foreheadJawLabel(_ v: Double) -> String {
        if v < 0.88 { return "Mandíbula prominente" }
        if v < 1.06 { return "Equilibrado" }
        if v < 1.18 { return "Frente amplia" }
        return "Frente muy amplia"
    }

    private func cheekLabel(_ v: Double) -> String {
        if v < 0.94 { return "Frente más ancha" }
        if v < 1.03 { return "Equilibrado" }
        if v < 1.10 { return "Mejillas marcadas" }
        return "Muy prominente"
    }

    private func chinLabel(_ v: Double) -> String {
        if v < 0.20 { return "Mentón ancho" }
        if v < 0.38 { return "Mentón moderado" }
        if v < 0.55 { return "Definido" }
        return "Muy fino"
    }
}

private struct DetailMeasBar: View {
    let label: String
    let value: Double
    let minLabel: String
    let maxLabel: String
    let range: ClosedRange<Double>
    let interpretation: String

    private var progress: Double {
        let clamped = max(range.lowerBound, min(range.upperBound, value))
        return (clamped - range.lowerBound) / (range.upperBound - range.lowerBound)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(label)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.secondary)
                Spacer()
                Text(interpretation)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(BrandColors.primary)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 2)
                    .background(BrandColors.primary.opacity(0.10))
                    .clipShape(Capsule())
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.secondary.opacity(0.15))
                        .frame(height: 8)

                    RoundedRectangle(cornerRadius: 4)
                        .fill(BrandColors.strokeGradient)
                        .frame(width: geo.size.width * progress, height: 8)
                        .animation(.easeOut(duration: 0.7), value: progress)

                    Circle()
                        .fill(BrandColors.primary)
                        .frame(width: 14, height: 14)
                        .offset(x: geo.size.width * progress - 7)
                        .animation(.easeOut(duration: 0.7), value: progress)
                }
            }
            .frame(height: 14)

            HStack {
                Text(minLabel).font(.system(size: 9)).foregroundStyle(.secondary)
                Spacer()
                Text(String(format: "%.2f", value))
                    .font(.system(size: 9, weight: .medium, design: .monospaced))
                    .foregroundStyle(.secondary.opacity(0.6))
                Spacer()
                Text(maxLabel).font(.system(size: 9)).foregroundStyle(.secondary)
            }
        }
    }
}

// MARK: - FrameCard

private struct FrameCard: View {
    let suggestion: FrameSuggestion

    private var accentColor: Color {
        suggestion.compatibility == .perfect ? .green : BrandColors.primary
    }

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(accentColor.opacity(0.12))
                    .frame(width: 44, height: 44)
                Image(systemName: suggestion.icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(accentColor)
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(suggestion.name)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(BrandColors.secondary)
                    Spacer()
                    Text(suggestion.compatibility.label)
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(accentColor)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(accentColor.opacity(0.12))
                        .clipShape(Capsule())
                }
                Text(suggestion.reason)
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(14)
        .background(BrandColors.cardFill)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(accentColor.opacity(0.20), lineWidth: 1)
        )
    }
}

// MARK: - Helpers

private struct ScannerSectionHeader: View {
    let icon: String
    let color: Color
    let title: String
    let subtitle: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .foregroundStyle(color)
                .font(.system(size: 16, weight: .semibold))
            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(BrandColors.secondary)
                Text(subtitle)
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }
        }
    }
}

private struct TipRow: View {
    let icon: String
    let color: Color
    let text: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(color)
                .font(.system(size: 16))
                .frame(width: 24)
            Text(text)
                .font(.system(size: 13))
                .foregroundStyle(BrandColors.secondary)
        }
    }
}
