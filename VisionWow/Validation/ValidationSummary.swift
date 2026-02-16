//
//  ValidationSummary.swift
//  VisionWow
//
//  Created by Rodrigo Marcos on 27/12/25.
//
import SwiftUI

struct ValidationSummary: View {
    var title: String
    var items: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(BrandColors.danger)

            VStack(alignment: .leading, spacing: 6) {
                ForEach(items, id: \.self) { it in
                    Text("• \(it)")
                        .font(.footnote)
                        .foregroundStyle(.primary)
                }
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(BrandColors.danger.opacity(0.10))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(BrandColors.danger.opacity(0.30), lineWidth: 1)
        )
    }
}

    
