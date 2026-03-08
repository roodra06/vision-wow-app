//
//  FaceShapeAnalyzer.swift
//  VisionWow
//
//  Análisis de forma de rostro usando Vision (on-device, sin internet).
//  Detecta landmarks faciales y clasifica el tipo de rostro para
//  recomendar armazones compatibles.
//

import Vision
import UIKit
import CoreGraphics

// MARK: - Face Shape

enum FaceShape: String, CaseIterable {
    case oval      = "Ovalado"
    case round     = "Redondo"
    case square    = "Cuadrado"
    case heart     = "Trapezoidal"
    case diamond   = "Romboidal"
    case oblong    = "Alargado"
    case triangle  = "Triangular"

    var emoji: String {
        switch self {
        case .oval:     return "⬭"
        case .round:    return "⬤"
        case .square:   return "⬛"
        case .heart:    return "◁"
        case .diamond:  return "◇"
        case .oblong:   return "▭"
        case .triangle: return "▽"
        }
    }

    var description: String {
        switch self {
        case .oval:
            return "Rostro equilibrado con pómulos ligeramente más anchos que frente y mandíbula. Proporciones ideales: el largo supera al ancho en proporción armónica. Tipo de rostro más versátil en óptica."
        case .round:
            return "Ancho y largo muy similares, con mejillas llenas y línea de mandíbula suave y redondeada. La frente y la mandíbula tienen anchuras parecidas sin ángulos marcados."
        case .square:
            return "Mandíbula fuerte con ángulo marcado. Frente, pómulos y mandíbula de anchuras similares, dando proporciones robustas y simétricas. Línea de mandíbula bien definida."
        case .heart:
            return "Frente amplia que se va estrechando progresivamente hacia la mandíbula y mentón fino. El ancho máximo se localiza en la zona frontal o temporal del cráneo."
        case .diamond:
            return "Zona de pómulos y mejillas notablemente más ancha que frente y mandíbula. El punto más prominente del rostro es la zona media, creando un perfil angular y definido."
        case .oblong:
            return "Rostro alargado con longitud considerablemente mayor al ancho. Frente, pómulos y mandíbula mantienen proporciones similares a lo largo del eje vertical."
        case .triangle:
            return "Mandíbula más ancha que la frente. El ancho del rostro aumenta de arriba hacia abajo, con una base sólida y frente más estrecha."
        }
    }

    var compatibilityLabel: String {
        switch self {
        case .oval:     return "Compatibilidad universal"
        case .round:    return "Armazones que alargan"
        case .square:   return "Armazones que suavizan"
        case .heart:    return "Equilibrio en la parte baja"
        case .diamond:  return "Armazones que equilibran"
        case .oblong:   return "Armazones que ensanchan"
        case .triangle: return "Armazones que elevan"
        }
    }

    // MARK: - Recommended frames

    var recommendedFrames: [FrameSuggestion] {
        switch self {
        case .oval:
            return [
                FrameSuggestion(name: "Rectangulares", icon: "rectangle", reason: "Añaden estructura y contraste a tus proporciones naturales perfectas.", compatibility: .perfect),
                FrameSuggestion(name: "Aviador", icon: "shield.lefthalf.filled", reason: "Destacan tus proporciones equilibradas con un estilo clásico.", compatibility: .perfect),
                FrameSuggestion(name: "Cuadrados", icon: "square", reason: "El contraste angular aporta elegancia y carácter.", compatibility: .good),
            ]
        case .round:
            return [
                FrameSuggestion(name: "Rectangulares", icon: "rectangle", reason: "Alargan el rostro visualmente y añaden definición a la mandíbula suave.", compatibility: .perfect),
                FrameSuggestion(name: "Cuadrados", icon: "square", reason: "Las esquinas angulares contrastan con las curvas del rostro.", compatibility: .perfect),
                FrameSuggestion(name: "Geométricos", icon: "hexagon", reason: "Las formas angulares rompen la redondez y dan estructura moderna.", compatibility: .good),
            ]
        case .square:
            return [
                FrameSuggestion(name: "Ovalados", icon: "oval", reason: "Las curvas suavizan los ángulos fuertes de la mandíbula y frente.", compatibility: .perfect),
                FrameSuggestion(name: "Redondos", icon: "circle", reason: "El contraste redondeado equilibra la angularidad natural.", compatibility: .perfect),
                FrameSuggestion(name: "Rimless / Sin aro", icon: "rectangle.dashed", reason: "Minimizan el marco y dan ligereza visual al rostro.", compatibility: .good),
            ]
        case .heart:
            return [
                FrameSuggestion(name: "Cat Eye / Mariposa", icon: "flame", reason: "Amplían la parte inferior visual para equilibrar la frente ancha.", compatibility: .perfect),
                FrameSuggestion(name: "Ovalados ligeros", icon: "oval", reason: "Marco ligero que no agrega volumen donde ya hay amplitud.", compatibility: .perfect),
                FrameSuggestion(name: "Gruesos en la parte baja", icon: "rectangle.bottomhalf.inset.filled", reason: "Equilibran la mandíbula más estrecha añadiendo peso visual inferior.", compatibility: .good),
            ]
        case .diamond:
            return [
                FrameSuggestion(name: "Ovalados", icon: "oval", reason: "Suavizan los pómulos prominentes y equilibran frente y mentón.", compatibility: .perfect),
                FrameSuggestion(name: "Cat Eye", icon: "flame", reason: "Añaden anchura en la parte superior para equilibrar los pómulos.", compatibility: .perfect),
                FrameSuggestion(name: "Rimless", icon: "rectangle.dashed", reason: "Minimizan el marco para no competir con los pómulos.", compatibility: .good),
            ]
        case .oblong:
            return [
                FrameSuggestion(name: "Redondos grandes", icon: "circle", reason: "Añaden anchura visual y acortan la percepción del rostro.", compatibility: .perfect),
                FrameSuggestion(name: "Oversized / Anchos", icon: "rectangle", reason: "Cubren más área y crean la ilusión de más ancho que largo.", compatibility: .perfect),
                FrameSuggestion(name: "Con patillas decorativas", icon: "eyeglasses", reason: "Las patillas anchas añaden volumen lateral que equilibra el largo.", compatibility: .good),
            ]
        case .triangle:
            return [
                FrameSuggestion(name: "Anchos en la parte alta", icon: "rectangle.tophalf.inset.filled", reason: "Contrastan con la mandíbula ancha y equilibran el rostro.", compatibility: .perfect),
                FrameSuggestion(name: "Cat Eye", icon: "flame", reason: "Dirigen la atención hacia arriba y equilibran la base ancha.", compatibility: .perfect),
                FrameSuggestion(name: "Semi-rimless superior", icon: "rectangle.tophalf.filled", reason: "Añaden definición arriba para contrarrestar la mandíbula fuerte.", compatibility: .good),
            ]
        }
    }

    var framesToAvoid: [String] {
        switch self {
        case .oval:     return ["Muy pequeños (pierden proporción)"]
        case .round:    return ["Redondos (acentúan la redondez)", "Ovalados muy pequeños"]
        case .square:   return ["Rectangulares angulares (exageran la dureza)", "Cuadrados exactos"]
        case .heart:    return ["Decorativos en la parte alta", "Cuadrados muy altos"]
        case .diamond:  return ["Rectangulares estrechos", "Cuadrados pequeños"]
        case .oblong:   return ["Pequeños y estrechos (alargan más)", "Rectangulares muy altos"]
        case .triangle: return ["Anchos en la parte baja", "Sin aro inferior"]
        }
    }
}

// MARK: - Frame Suggestion

struct FrameSuggestion: Identifiable {
    let id = UUID()
    let name: String
    let icon: String
    let reason: String
    let compatibility: Compatibility

    enum Compatibility {
        case perfect, good
        var label: String { self == .perfect ? "Ideal" : "Muy bueno" }
        var color: String { self == .perfect ? "green" : "blue" }
    }
}

// MARK: - Measurements

struct FaceMeasurements {
    /// Ancho real / alto real del bounding box de la cara
    let aspectRatio: Double
    /// Ancho de frente / ancho de mandíbula
    let foreheadToJawRatio: Double
    /// Punto más ancho del contorno / ancho del bounding box
    let cheekProminence: Double
    /// Qué tan estrecho es el mentón (0 = ancho, 1 = puntiagudo)
    let chinSharpness: Double
}

// MARK: - Analyzer

enum FaceShapeAnalyzer {

    enum AnalysisError: LocalizedError {
        case invalidImage, noFaceDetected, insufficientLandmarks

        var errorDescription: String? {
            switch self {
            case .invalidImage:
                return "La imagen no es válida."
            case .noFaceDetected:
                return "No se detectó un rostro. Asegúrate de que el rostro esté de frente, bien iluminado y que ocupe la mayor parte de la foto."
            case .insufficientLandmarks:
                return "No se pudieron detectar suficientes puntos del rostro. Intenta con mejor iluminación y de frente."
            }
        }
    }

    static func analyze(image: UIImage) async throws -> (shape: FaceShape, measurements: FaceMeasurements) {
        guard let cgImage = image.cgImage else { throw AnalysisError.invalidImage }

        let imageW = CGFloat(cgImage.width)
        let imageH = CGFloat(cgImage.height)
        let orientation = CGImagePropertyOrientation(image.imageOrientation)

        return try await withCheckedThrowingContinuation { continuation in
            let request = VNDetectFaceLandmarksRequest { req, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }
                guard let results = req.results as? [VNFaceObservation],
                      let face = results.first,
                      let landmarks = face.landmarks else {
                    continuation.resume(throwing: AnalysisError.noFaceDetected)
                    return
                }

                do {
                    let m = try extractMeasurements(from: landmarks,
                                                    bbox: face.boundingBox,
                                                    imageW: imageW,
                                                    imageH: imageH)
                    let shape = classify(m)
                    continuation.resume(returning: (shape, m))
                } catch {
                    continuation.resume(throwing: error)
                }
            }

            let handler = VNImageRequestHandler(cgImage: cgImage, orientation: orientation, options: [:])
            do { try handler.perform([request]) }
            catch { continuation.resume(throwing: error) }
        }
    }

    // MARK: - Extract measurements

    private static func extractMeasurements(
        from landmarks: VNFaceLandmarks2D,
        bbox: CGRect,
        imageW: CGFloat,
        imageH: CGFloat
    ) throws -> FaceMeasurements {

        // ── 1. Aspect ratio from real pixel bounding box
        let realW = bbox.width  * imageW
        let realH = bbox.height * imageH
        guard realH > 0 else { throw AnalysisError.insufficientLandmarks }
        let aspectRatio = Double(realW / realH)

        // ── 2. Face contour (17 pts: left temple → chin bottom → right temple)
        guard let contour = landmarks.faceContour?.normalizedPoints,
              contour.count >= 13 else {
            throw AnalysisError.insufficientLandmarks
        }
        let n = contour.count

        // Temple width (top of contour = widest structural reference)
        let templeWidth = abs(contour[n - 1].x - contour[0].x)

        // Jaw width: AVERAGE of 3 symmetric pairs in the 25–40% zone of the contour.
        // Single-point measurements are noisy; averaging stabilises the result.
        // For 17 pts: this covers approximately indices 4, 5, 6 on each side.
        let jawStart  = n / 4
        let jawCount  = max(1, n / 5)
        var jawSum: CGFloat = 0
        for k in 0 ..< jawCount {
            let lo = jawStart + k
            let hi = n - 1 - lo
            guard lo < hi else { break }
            jawSum += abs(contour[hi].x - contour[lo].x)
        }
        let jawWidth = jawSum / CGFloat(jawCount)

        // Max horizontal span across all symmetric pairs
        var maxSpan: CGFloat = templeWidth
        for i in 0 ..< (n / 2) {
            let span = abs(contour[n - 1 - i].x - contour[i].x)
            if span > maxSpan { maxSpan = span }
        }

        // Chin width: average of ±2 points around the midpoint
        let mid = n / 2
        var chinSum: CGFloat = 0
        var chinCount = 0
        for off in [-2, -1, 0, 1, 2] {
            let lo = mid - abs(off), hi = mid + abs(off)
            guard lo >= 0, hi < n, lo != hi else { continue }
            chinSum += abs(contour[hi].x - contour[lo].x)
            chinCount += 1
        }
        let chinWidth = chinCount > 0 ? chinSum / CGFloat(chinCount) : 0

        // Pre-chin width: halfway between jaw zone and chin, gives the taper rate
        let preChinIdx  = jawStart + jawCount
        let preChinHi   = n - 1 - preChinIdx
        let preChinWidth: CGFloat = preChinIdx < preChinHi
            ? abs(contour[preChinHi].x - contour[preChinIdx].x)
            : jawWidth

        // ── 3. Forehead width: blend eyebrow-based and temple-based estimates
        var foreheadWidth: CGFloat = templeWidth
        if let lb = landmarks.leftEyebrow?.normalizedPoints,
           let rb = landmarks.rightEyebrow?.normalizedPoints,
           !lb.isEmpty, !rb.isEmpty {
            let lx = lb.map(\.x).min() ?? lb[0].x
            let rx = rb.map(\.x).max() ?? rb[0].x
            let browSpan = abs(rx - lx)
            if browSpan > 0.05 {
                // Eyebrows cover ~80% of the forehead width; blend with temple for stability
                let browEst = browSpan * 1.22
                foreheadWidth = browEst * 0.55 + templeWidth * 0.45
            }
        }

        // ── 4. Chin sharpness: combines absolute narrowness + rate of taper
        // - rawSharpness: how much narrower chin is than the jaw
        // - taperRate:    how quickly the jaw narrows from pre-chin to chin
        let rawSharpness = jawWidth > 0
            ? max(0.0, 1.0 - Double(chinWidth / jawWidth)) : 0.5
        let taperRate    = preChinWidth > 0
            ? max(0.0, 1.0 - Double(chinWidth / preChinWidth)) : 0.5
        let chinSharpness = min(1.0, rawSharpness * 0.55 + taperRate * 0.45)

        // ── 5. Final ratios
        let foreheadToJaw  = jawWidth > 0       ? Double(foreheadWidth / jawWidth)  : 1.0
        let cheekProminence = foreheadWidth > 0 ? Double(maxSpan / foreheadWidth)   : 1.0

        return FaceMeasurements(
            aspectRatio: aspectRatio,
            foreheadToJawRatio: foreheadToJaw,
            cheekProminence: cheekProminence,
            chinSharpness: chinSharpness
        )
    }

    // MARK: - Gaussian similarity

    /// Bell curve: returns 1.0 at `center`, decays symmetrically with `sigma`.
    private static func gauss(_ value: Double, center: Double, sigma: Double) -> Double {
        let x = (value - center) / sigma
        return exp(-0.5 * x * x)
    }

    // MARK: - Classify (scoring system)

    private static func classify(_ m: FaceMeasurements) -> FaceShape {

        var scores = [FaceShape: Double]()

        // ── ALARGADO: rostro claramente más alto que ancho
        scores[.oblong] =
            gauss(m.aspectRatio,        center: 0.65, sigma: 0.10) * 4.5

        // ── REDONDO: cara casi tan ancha como larga, mandíbula y mentón suaves
        scores[.round] =
            gauss(m.aspectRatio,        center: 0.94, sigma: 0.10) * 2.5 +
            gauss(m.foreheadToJawRatio, center: 0.98, sigma: 0.14) * 2.0 +
            gauss(m.chinSharpness,      center: 0.10, sigma: 0.14) * 2.5 +
            gauss(m.cheekProminence,    center: 0.97, sigma: 0.10) * 1.0

        // ── CUADRADO: frente y mandíbula similares, mentón moderado/ancho
        scores[.square] =
            gauss(m.aspectRatio,        center: 0.88, sigma: 0.10) * 1.5 +
            gauss(m.foreheadToJawRatio, center: 0.98, sigma: 0.12) * 2.5 +
            gauss(m.chinSharpness,      center: 0.22, sigma: 0.14) * 2.5 +
            gauss(m.cheekProminence,    center: 0.97, sigma: 0.10) * 1.0

        // ── TRAPEZOIDAL: frente claramente más ancha que mandíbula, mentón fino
        scores[.heart] =
            gauss(m.foreheadToJawRatio, center: 1.28, sigma: 0.16) * 4.0 +
            gauss(m.chinSharpness,      center: 0.62, sigma: 0.20) * 3.0 +
            gauss(m.cheekProminence,    center: 0.90, sigma: 0.14) * 1.5

        // ── ROMBOIDAL: pómulos/mejillas más anchos que frente y mandíbula
        scores[.diamond] =
            gauss(m.cheekProminence,    center: 1.14, sigma: 0.12) * 4.0 +
            gauss(m.foreheadToJawRatio, center: 1.00, sigma: 0.14) * 1.5 +
            gauss(m.chinSharpness,      center: 0.50, sigma: 0.18) * 2.0

        // ── TRIANGULAR: mandíbula más ancha que la frente
        scores[.triangle] =
            gauss(m.foreheadToJawRatio, center: 0.78, sigma: 0.13) * 4.0 +
            gauss(m.cheekProminence,    center: 1.12, sigma: 0.12) * 2.5 +
            gauss(m.chinSharpness,      center: 0.15, sigma: 0.16) * 1.5

        // ── OVALADO: proporciones armónicas, estrechamiento suave hacia el mentón
        scores[.oval] =
            gauss(m.aspectRatio,        center: 0.79, sigma: 0.10) * 1.5 +
            gauss(m.foreheadToJawRatio, center: 1.10, sigma: 0.15) * 2.5 +
            gauss(m.chinSharpness,      center: 0.40, sigma: 0.18) * 2.0 +
            gauss(m.cheekProminence,    center: 1.01, sigma: 0.10) * 1.5

#if DEBUG
        let ranked = scores.sorted { $0.value > $1.value }
        print("""
        [FaceShape] aspect=\(String(format:"%.3f",m.aspectRatio)) \
        f2j=\(String(format:"%.3f",m.foreheadToJawRatio)) \
        cheek=\(String(format:"%.3f",m.cheekProminence)) \
        chin=\(String(format:"%.3f",m.chinSharpness))
        [FaceShape] \(ranked.map{"\($0.key.rawValue):\(String(format:"%.2f",$0.value))"}.joined(separator:" "))
        """)
#endif

        return scores.max(by: { $0.value < $1.value })?.key ?? .oval
    }
}

// MARK: - UIImage.Orientation → CGImagePropertyOrientation

extension CGImagePropertyOrientation {
    init(_ uiOrientation: UIImage.Orientation) {
        switch uiOrientation {
        case .up:            self = .up
        case .down:          self = .down
        case .left:          self = .left
        case .right:         self = .right
        case .upMirrored:    self = .upMirrored
        case .downMirrored:  self = .downMirrored
        case .leftMirrored:  self = .leftMirrored
        case .rightMirrored: self = .rightMirrored
        @unknown default:    self = .up
        }
    }
}
