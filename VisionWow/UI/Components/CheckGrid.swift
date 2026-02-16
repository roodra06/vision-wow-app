//
//  CheckGrid.swift
//  VisionWow
//
//  Created by Rodrigo Marcos on 27/12/25.
//
import SwiftUI

struct CheckGrid: View {
    let items: [String]
    let isOn: (String) -> Bool
    let toggle: (String) -> Void

    private let columns = [
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10)
    ]

    var body: some View {
        LazyVGrid(columns: columns, spacing: 10) {
            ForEach(items, id: \.self) { item in
                Button {
                    toggle(item)
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: isOn(item) ? "checkmark.circle.fill" : "circle")
                            .foregroundStyle(isOn(item) ? BrandColors.secondary : .secondary)
                        Text(item)
                            .foregroundStyle(Color(.label))
                            .font(.system(size: 14, weight: .medium))
                            .lineLimit(2)
                        Spacer(minLength: 0)
                    }
                    .padding(12)
                    .background(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(Color.black.opacity(0.08), lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }
}

