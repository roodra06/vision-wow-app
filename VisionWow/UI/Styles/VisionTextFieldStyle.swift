//
//  VisionTextFieldStyle.swift
//  VisionWow
//
//  Created by Rodrigo Marcos on 27/12/25.
//

import SwiftUI

struct VisionTextFieldStyle: ViewModifier {
    var isError: Bool = false

    func body(content: Content) -> some View {
        content
            .textInputAutocapitalization(.sentences)
            .autocorrectionDisabled()
            .padding(.horizontal, 12)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color(uiColor: .secondarySystemBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(borderColor, lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 2)
            .foregroundStyle(.primary)     // Importante: no forzar .black (Dark Mode)
            .tint(BrandColors.primary)
            .accessibilityHint(isError ? "Contiene un error" : "")
    }

    private var borderColor: Color {
        isError ? BrandColors.danger : Color.primary.opacity(0.12)
    }
}

extension View {
    func visionTextField(isError: Bool = false) -> some View {
        modifier(VisionTextFieldStyle(isError: isError))
    }
}
