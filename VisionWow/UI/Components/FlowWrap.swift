//
//  FlowWrap.swift
//  VisionWow
//
//  Created by Rodrigo Marcos on 19/02/26.
//
import SwiftUI

struct FlowWrap<Data: RandomAccessCollection, Content: View>: View where Data.Element: Hashable {
    let data: Data
    let spacing: CGFloat
    let content: (Data.Element) -> Content

    init(_ data: Data, spacing: CGFloat = 8, @ViewBuilder content: @escaping (Data.Element) -> Content) {
        self.data = data
        self.spacing = spacing
        self.content = content
    }

    var body: some View {
        GeometryReader { geo in
            self.generateContent(in: geo)
        }
        .frame(minHeight: 10) // se ajusta automáticamente con PreferenceKey
    }

    private func generateContent(in geo: GeometryProxy) -> some View {
        var x: CGFloat = 0
        var y: CGFloat = 0

        return ZStack(alignment: .topLeading) {
            ForEach(Array(data), id: \.self) { item in
                content(item)
                    .padding(.trailing, spacing)
                    .padding(.bottom, spacing)
                    .alignmentGuide(.leading, computeValue: { d in
                        if x + d.width > geo.size.width {
                            x = 0
                            y -= d.height + spacing
                        }
                        let result = x
                        x += d.width + spacing
                        return -result
                    })
                    .alignmentGuide(.top, computeValue: { _ in
                        return y
                    })
            }
        }
        .frame(width: geo.size.width, alignment: .topLeading)
    }
}
