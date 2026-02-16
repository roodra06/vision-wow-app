//
//  RootView.swift
//  VisionWow
//
//  Created by Rodrigo Marcos on 27/12/25.
//
//
//  RootView.swift
//  VisionWow
//

import SwiftUI

struct RootView: View {
    @State private var showSplash = true

    var body: some View {
        ZStack {
            if showSplash {
                SplashScreen {
                    withAnimation(.easeInOut(duration: 0.35)) {
                        showSplash = false
                    }
                }
                .transition(.opacity.combined(with: .scale(scale: 1.02)))
            } else {
                FlowPickerScreen()
                    .transition(.opacity)
            }
        }
    }
}


