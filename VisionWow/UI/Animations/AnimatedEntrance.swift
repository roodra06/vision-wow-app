//
//  AnimatedEntrance.swift
//  VisionWow
//

import SwiftUI

/// Fade in + slide-up entrance animation.
/// Attach `.entrance(delay:)` to any view for a staggered appear effect.
struct AnimatedEntrance: ViewModifier {
    let delay: Double
    @State private var appeared = false

    func body(content: Content) -> some View {
        content
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 20)
            .onAppear {
                withAnimation(.spring(response: 0.50, dampingFraction: 0.82).delay(delay)) {
                    appeared = true
                }
            }
    }
}

extension View {
    /// Fade + slide-up entrance animation with optional stagger delay (seconds).
    func entrance(delay: Double = 0) -> some View {
        modifier(AnimatedEntrance(delay: delay))
    }
}

/// Press scale animation for interactive elements.
struct BounceButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.easeInOut(duration: 0.11), value: configuration.isPressed)
    }
}
