//
//  ToastBanner.swift
//  VisionWow
//
//  Created by Rodrigo Marcos on 27/12/25.
//
import SwiftUI

struct ToastBanner: View {
    let text: String

    @State private var shakeOffset: CGFloat = 0
    @State private var iconPulse = false

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.red)
                .scaleEffect(iconPulse ? 1.20 : 1.0)
                .animation(.spring(response: 0.22, dampingFraction: 0.45).delay(0.30), value: iconPulse)
            Text(text)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.red)
            Spacer()
        }
        .padding(12)
        .background(Color.red.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color.red.opacity(0.25), lineWidth: 1)
        )
        .offset(x: shakeOffset)
        .onAppear {
            iconPulse = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) { iconPulse = false }
            shake()
        }
    }

    private func shake() {
        let offsets: [(CGFloat, Double)] = [
            (-9, 0.00), (9, 0.07), (-7, 0.14), (7, 0.21),
            (-4, 0.28), (4, 0.35), (0, 0.42)
        ]
        for (offset, delay) in offsets {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                withAnimation(.easeInOut(duration: 0.07)) { shakeOffset = offset }
            }
        }
    }
}

