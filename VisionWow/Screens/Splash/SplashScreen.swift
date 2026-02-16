import SwiftUI

struct SplashScreen: View {
    @State private var iconScale: CGFloat = 0.86
    @State private var iconOpacity: Double = 0.0
    @State private var glowOpacity: Double = 0.18
    @State private var ringScale: CGFloat = 0.92
    @State private var ringOpacity: Double = 0.0

    var onFinished: () -> Void

    var body: some View {
        ZStack {
            BrandColors.backgroundGradient
                .ignoresSafeArea()

            // Halo grande detrás (se nota pero fino)
            Circle()
                .fill(BrandColors.primary.opacity(0.12))
                .frame(width: 320, height: 320)
                .blur(radius: 10)
                .opacity(glowOpacity)

            VStack(spacing: 14) {
                ZStack {
                    // Anillo exterior con gradiente
                    Circle()
                        .stroke(BrandColors.strokeGradient, lineWidth: 10)
                        .frame(width: 190, height: 190)
                        .scaleEffect(ringScale)
                        .opacity(ringOpacity)
                        .shadow(color: BrandColors.primary.opacity(0.22), radius: 18, x: 0, y: 10)

                    // Contenedor blanco para que el logo “truene”
                    Circle()
                        .fill(Color.white.opacity(0.92))
                        .frame(width: 168, height: 168)
                        .shadow(color: BrandColors.secondary.opacity(0.12), radius: 14, x: 0, y: 10)

                    // Logo redondeado
                    Image("visionwow_logo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 132, height: 132)
                        .clipShape(Circle())
                        .overlay(
                            Circle()
                                .stroke(Color.white.opacity(0.85), lineWidth: 2)
                        )
                        .scaleEffect(iconScale)
                        .opacity(iconOpacity)
                        .shadow(color: BrandColors.primary.opacity(0.22), radius: 16, x: 0, y: 10)
                }

                Text("Vision Wow")
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(BrandColors.secondary)
                    .opacity(iconOpacity)

                Text("Atención integral en salud visual")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .opacity(iconOpacity)
            }
            .padding()
        }
        .onAppear {
            runAnimations()
        }
    }

    private func runAnimations() {
        // 1) Entrada principal (suave y visible)
        withAnimation(.easeOut(duration: 0.65)) {
            iconOpacity = 1.0
            iconScale = 1.0
            ringOpacity = 1.0
            ringScale = 1.0
        }

        // 2) Pulso del glow (lento para que se aprecie)
        withAnimation(.easeInOut(duration: 1.1).repeatForever(autoreverses: true)) {
            glowOpacity = 0.42
        }

        // 3) Tiempo total del splash (se ve pro, no “flash”)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.85) {
            onFinished()
        }
    }
}
