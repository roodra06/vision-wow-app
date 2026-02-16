//
//  Accordion.swift
//  VisionWow
//
//  Created by Rodrigo Marcos on 27/12/25.
//

import SwiftUI

struct Accordion<Content: View>: View {
    let title: String
    @State private var isOpen: Bool = false
    @ViewBuilder var content: Content

    init(title: String, initiallyOpen: Bool = false, @ViewBuilder content: () -> Content) {
        self.title = title
        self._isOpen = State(initialValue: initiallyOpen)
        self.content = content()
    }

    var body: some View {
        VStack(spacing: 10) {
            Button {
                withAnimation(.easeInOut(duration: 0.20)) {
                    isOpen.toggle()
                }
            } label: {
                HStack(spacing: 10) {

                    // Icono sutil
                    ZStack {
                        Circle()
                            .fill(BrandColors.primary.opacity(0.10))
                            .frame(width: 26, height: 26)

                        Image(systemName: "list.bullet.rectangle")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(BrandColors.secondary.opacity(0.90))
                    }

                    // ✅ Texto ahora visible (NO gradient)
                    Text(title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(BrandColors.secondary) // ✅ aquí el cambio clave
                        .lineLimit(1)

                    Spacer()

                    Image(systemName: isOpen ? "chevron.up" : "chevron.down")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(BrandColors.secondary.opacity(0.65))
                }
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(Color.white.opacity(0.70))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .stroke(BrandColors.accent.opacity(0.14), lineWidth: 1)
                        )
                )
            }
            .buttonStyle(.plain)

            if isOpen {
                content
                    .padding(.horizontal, 4)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }
}

