//
//  ProgressPillBar.swift
//  VisionWow
//
//  Created by Rodrigo Marcos on 28/12/25.
//
import SwiftUI

struct ProgressPillBar: View {
    let progress: CGFloat
    var height: CGFloat = 10

    @State private var animatedProgress: CGFloat = 0

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(Color.black.opacity(0.06))
                Capsule()
                    .fill(BrandColors.strokeGradient)
                    .frame(width: max(0, min(geo.size.width, geo.size.width * animatedProgress)))
            }
            .frame(height: height)
            .onAppear {
                withAnimation(.easeInOut(duration: 0.45)) {
                    animatedProgress = progress
                }
            }
            .onChange(of: progress) { _, newValue in
                withAnimation(.easeInOut(duration: 0.45)) {
                    animatedProgress = newValue
                }
            }
        }
        .frame(height: height)
    }
}

