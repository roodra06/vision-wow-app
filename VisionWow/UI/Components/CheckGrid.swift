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
                _CheckCell(
                    label: item,
                    isOn: isOn(item),
                    toggle: { toggle(item) }
                )
            }
        }
    }
}

private struct _CheckCell: View {
    let label: String
    let isOn: Bool
    let toggle: () -> Void

    @State private var bouncing = false

    var body: some View {
        Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            bouncing = true
            toggle()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) { bouncing = false }
        } label: {
            HStack(spacing: 10) {
                ZStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(BrandColors.secondary)
                        .scaleEffect(isOn ? 1.0 : 0.01)
                        .opacity(isOn ? 1 : 0)

                    Image(systemName: "circle")
                        .foregroundStyle(Color.secondary.opacity(0.5))
                        .scaleEffect(isOn ? 0.01 : 1.0)
                        .opacity(isOn ? 0 : 1)
                }
                .font(.system(size: 18, weight: .semibold))
                .scaleEffect(bouncing ? 1.35 : 1.0)
                .animation(.spring(response: 0.25, dampingFraction: 0.50), value: bouncing)
                .animation(.spring(response: 0.28, dampingFraction: 0.60), value: isOn)

                Text(label)
                    .foregroundStyle(isOn ? BrandColors.secondary : Color(.label))
                    .font(.system(size: 14, weight: isOn ? .semibold : .medium))
                    .lineLimit(2)
                    .animation(.easeInOut(duration: 0.18), value: isOn)

                Spacer(minLength: 0)
            }
            .padding(12)
            .background(
                isOn ? BrandColors.primary.opacity(0.07) : Color.white
            )
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(
                        isOn ? BrandColors.primary.opacity(0.35) : Color.black.opacity(0.08),
                        lineWidth: isOn ? 1.5 : 1
                    )
            )
            .animation(.spring(response: 0.30, dampingFraction: 0.75), value: isOn)
        }
        .buttonStyle(.plain)
    }
}

