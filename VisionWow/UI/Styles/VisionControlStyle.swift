//
//  VisionControlStyle.swift
//  VisionWow
//
//  Created by Rodrigo Marcos on 27/12/25.
//

import SwiftUI

struct VisionControlStyle: ViewModifier {
    var isError: Bool = false

    func body(content: Content) -> some View {
        content
            .padding(.horizontal, 12)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color(uiColor: .secondarySystemBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(isError ? BrandColors.danger : Color.primary.opacity(0.12), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 2)
            .foregroundStyle(.primary)
            .tint(BrandColors.primary)
    }
}

extension View {
    func visionControl(isError: Bool = false) -> some View {
        modifier(VisionControlStyle(isError: isError))
    }
}
