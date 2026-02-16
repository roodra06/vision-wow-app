//
//  FieldRow.swift
//  VisionWow
//
//  Created by Rodrigo Marcos on 27/12/25.
//

import SwiftUI

struct FieldRow<Content: View>: View {
    let label: String
    let required: Bool
    let error: String?
    @ViewBuilder let content: Content

    init(_ label: String, required: Bool = false, error: String? = nil, @ViewBuilder content: () -> Content) {
        self.label = label
        self.required = required
        self.error = error
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Text(label)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .minimumScaleFactor(0.95)

                if required {
                    Text("*")
                        .font(.subheadline.weight(.heavy))
                        .foregroundStyle(BrandColors.danger)
                        .accessibilityLabel("Campo obligatorio")
                }
            }

            content

            if let error, !error.isEmpty {
                HStack(alignment: .top, spacing: 6) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(BrandColors.danger)

                    Text(error)
                        .font(.caption)
                        .foregroundStyle(BrandColors.danger)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.top, 2)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .animation(.easeInOut(duration: 0.18), value: error ?? "")
    }
}
