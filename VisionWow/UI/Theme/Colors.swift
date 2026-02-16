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
    // Mantener "danger" rosado/berry para no romper la identidad visual.
    static let danger    = Color(hex: 0xD62F6B) // berry (cercano a primary pero más "alerta")
    static let warning   = Color(hex: 0xC07A2C) // ámbar cálido (neutro, no compite con el magenta)
    static let success   = Color(hex: 0x2E8B6C) // verde/teal elegante (contraste saludable)
    static let info      = Color(hex: 0x4A64D8) // azul sobrio (para mensajes informativos)

    // Fondos
    static let backgroundTop    = primary.opacity(0.18)
    static let backgroundMid    = accent.opacity(0.14)
    static let backgroundBottom = Color.white

    static var backgroundGradient: LinearGradient {
        LinearGradient(
            colors: [backgroundTop, backgroundMid, backgroundBottom],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static var cardGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color.white.opacity(0.92),
                soft.opacity(0.35)
            ],
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
