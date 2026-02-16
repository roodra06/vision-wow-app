//
//  StepProgress.swift
//  VisionWow
//
//  Created by Rodrigo Marcos on 27/12/25.
//
import SwiftUI

struct StepProgress: View {
    let step: Int
    let total: Int

    var progress: CGFloat {
        guard total > 0 else { return 0 }
        return CGFloat(step) / CGFloat(total)
    }

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(Color.black.opacity(0.10)).frame(height: 8)
                Capsule()
                    .fill(LinearGradient(colors: [BrandColors.primary, BrandColors.secondary], startPoint: .leading, endPoint: .trailing))
                    .frame(width: geo.size.width * progress, height: 8)
            }
        }
        .frame(height: 8)
    }
}

