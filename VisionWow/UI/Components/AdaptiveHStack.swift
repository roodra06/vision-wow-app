//
//  AdaptiveHStack.swift
//  VisionWow
//
//  Created by Rodrigo Marcos on 27/12/25.
//
import SwiftUI

struct AdaptiveHStack<Content: View>: View {
    let columns: Int
    let spacing: CGFloat
    @ViewBuilder let content: () -> Content

    init(columns: Int, spacing: CGFloat = 12, @ViewBuilder content: @escaping () -> Content) {
        self.columns = max(1, columns)
        self.spacing = spacing
        self.content = content
    }

    var body: some View {
        ViewThatFits(in: .horizontal) {
            // Intento 1: layout en columnas (si cabe)
            HStack(alignment: .top, spacing: spacing) { content() }

            // Fallback: si no cabe, apila
            VStack(alignment: .leading, spacing: spacing) { content() }
        }
    }
}

