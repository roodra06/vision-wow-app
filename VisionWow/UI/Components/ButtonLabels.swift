//
//  ButtonLabels.swift
//  VisionWow
//
//  Created by Rodrigo Marcos on 12/01/26.
//
import SwiftUI

struct PrimaryButtonLabel: View {
    let title: String
    var body: some View {
        Text(title)
            .font(.headline)
            .foregroundStyle(Color.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(BrandColors.primary)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

struct SecondaryButtonLabel: View {
    let title: String
    var body: some View {
        Text(title)
            .font(.headline)
            .foregroundStyle(BrandColors.secondary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(Color.white.opacity(0.75))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(BrandColors.accent.opacity(0.25), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

