//
//  CircleIconButton.swift
//  VisionWow
//
//  Created by Rodrigo Marcos on 27/12/25.
//
import SwiftUI

struct CircleIconButton: View {
    let systemName: String
    let fill: Color
    let stroke: Color
    let iconColor: Color

    var body: some View {
        ZStack {
            Circle()
                .fill(fill)
                .overlay(
                    Circle().stroke(stroke, lineWidth: 1)
                )
                .frame(width: 36, height: 36)

            Image(systemName: systemName)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(iconColor)
        }
        .contentShape(Circle())
        .accessibilityLabel(Text(systemName))
    }
}

