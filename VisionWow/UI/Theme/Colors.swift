//
//  Colors.swift
//  VisionWow
//
//  Created by Rodrigo Marcos on 27/12/25.
//

import SwiftUI

enum BrandColors {
    // Base (del logo)
    static let primary   = Color(hex: 0xE7387F) // magenta
    static let secondary = Color(hex: 0x763976) // morado profundo
    static let accent    = Color(hex: 0xB673AD) // lavanda
    static let soft      = Color(hex: 0xEAD0E0) // rosa/lavanda muy suave
    static let rose      = Color(hex: 0xDB5F91) // rosa medio

    // Semánticos (UI)
    static let danger    = Color(hex: 0xD62F6B) // berry
    static let warning   = Color(hex: 0xC07A2C) // ámbar cálido
    static let success   = Color(hex: 0x2E8B6C) // verde/teal
    static let info      = Color(hex: 0x4A64D8) // azul sobrio

    // MARK: - Fondos adaptativos (UIColor dynamicProvider → responde al modo del iPad automáticamente)

    /// Fondo base: blanco en light · morado muy oscuro (#1A0A2E) en dark
    static let backgroundBottom = Color(uiColor: UIColor(dynamicProvider: { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.102, green: 0.039, blue: 0.180, alpha: 1) // #1A0A2E morado oscuro
            : .systemBackground
    }))

    /// Color de card: blanco en light · mauve oscuro (#251240) en dark
    static let cardFill = Color(uiColor: UIColor(dynamicProvider: { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.145, green: 0.071, blue: 0.251, alpha: 1) // #251240 mauve
            : .systemBackground
    }))

    /// Overlay de card con borde: white.opacity(.92) light · mauve.opacity(.94) dark
    static let cardFillOverlay = Color(uiColor: UIColor(dynamicProvider: { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.180, green: 0.090, blue: 0.290, alpha: 0.94)
            : UIColor.white.withAlphaComponent(0.92)
    }))

    /// Fondo de formularios y campos: gris muy suave light · morado semi-oscuro dark
    static let fieldBackground = Color(uiColor: UIColor(dynamicProvider: { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.20, green: 0.10, blue: 0.32, alpha: 1)
            : UIColor.black.withAlphaComponent(0.04)
    }))

    // MARK: - Gradientes

    /// Gradiente de fondo principal (adapta a light/dark)
    static var backgroundGradient: LinearGradient {
        LinearGradient(
            colors: [
                primary.opacity(0.26),   // top: magenta suave
                accent.opacity(0.18),    // mid: lavanda
                backgroundBottom         // bottom: blanco (light) / morado oscuro (dark)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static var cardGradient: LinearGradient {
        LinearGradient(
            colors: [cardFill.opacity(0.92), soft.opacity(0.22)],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    static var strokeGradient: LinearGradient {
        LinearGradient(
            colors: [primary, accent, secondary.opacity(0.90)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

// MARK: - Color Hex helper
extension Color {
    init(hex: UInt, alpha: Double = 1.0) {
        let r = Double((hex >> 16) & 0xFF) / 255.0
        let g = Double((hex >> 8) & 0xFF) / 255.0
        let b = Double(hex & 0xFF) / 255.0
        self.init(.sRGB, red: r, green: g, blue: b, opacity: alpha)
    }
}
