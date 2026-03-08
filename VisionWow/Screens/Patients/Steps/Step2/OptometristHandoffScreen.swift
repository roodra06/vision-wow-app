import SwiftUI

struct OptometristHandoffScreen: View {
    @Bindable var encounter: Encounter
    let onContinueToAntecedents: () -> Void

    @State private var showOptometristModal = false
    @State private var localOptometristName: String = ""
    @State private var animate = false
    @State private var showUnlockConfirm = false
    @State private var showFaceAnalysis = false
    @State private var detectedFaceShape: FaceShape?

    private var isLocked: Bool {
        !(encounter.optometristName ?? "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .isEmpty
    }

    var body: some View {
        ZStack {
            BrandColors.backgroundGradient.ignoresSafeArea()

            VStack(spacing: 32) {
                Spacer()

                if isLocked {
                    lockedCard
                } else {
                    mainCard
                }

                Spacer()

                if isLocked {
                    lockedContinueButton
                } else {
                    continueButton
                }
            }
            .padding(.horizontal, 20)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.6)) {
                animate = true
            }
        }
        .alert("¿Cambiar optometrista?", isPresented: $showUnlockConfirm) {
            Button("Cambiar nombre", role: .destructive) {
                localOptometristName = (encounter.optometristName ?? "")
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                encounter.optometristName = nil
                showOptometristModal = true
            }
            Button("Cancelar", role: .cancel) {}
        } message: {
            Text("El optometrista \"\(encounter.optometristName ?? "")\" ya fue asignado. ¿Deseas corregir el nombre?")
        }
        .sheet(isPresented: $showOptometristModal) {
            OptometristNameModal(
                name: $localOptometristName,
                onConfirm: {
                    let cleaned = localOptometristName.trimmingCharacters(in: .whitespacesAndNewlines)
                    encounter.optometristName = cleaned.isEmpty ? nil : cleaned

                    showOptometristModal = false
                    onContinueToAntecedents()
                }
            )
            .presentationDetents([PresentationDetent.medium])
        }
        .sheet(isPresented: $showFaceAnalysis) {
            FaceAnalysisSheet {
                detectedFaceShape = $0
            }
        }
    }

    // MARK: - Locked Card

    private var lockedCard: some View {
        VStack(spacing: 28) {
            ZStack {
                Circle()
                    .fill(BrandColors.primary.opacity(0.15))
                    .frame(width: 120, height: 120)
                    .scaleEffect(animate ? 1 : 0.85)

                Circle()
                    .stroke(BrandColors.strokeGradient, lineWidth: 4)
                    .frame(width: 120, height: 120)

                Image(systemName: "lock.fill")
                    .font(.system(size: 44, weight: .semibold))
                    .foregroundStyle(BrandColors.primary)
            }

            VStack(spacing: 14) {
                Text("Optometrista asignado")
                    .font(.system(size: 26, weight: .bold))
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.center)

                Text(encounter.optometristName ?? "")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(BrandColors.secondary)
                    .multilineTextAlignment(.center)

                Divider().padding(.vertical, 4)

                HStack(spacing: 10) {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 18))
                        .foregroundStyle(BrandColors.accent)

                    Text("El optometrista ya fue registrado.")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.secondary)
                }

                Button {
                    showUnlockConfirm = true
                } label: {
                    Label("Corregir nombre", systemImage: "pencil.circle")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(BrandColors.primary)
                }
                .buttonStyle(.plain)
                .padding(.top, 2)
            }
        }
        .padding(28)
        .background(
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .fill(Color.white.opacity(0.90))
                .overlay(
                    RoundedRectangle(cornerRadius: 26, style: .continuous)
                        .stroke(BrandColors.accent.opacity(0.18), lineWidth: 1)
                )
                .shadow(color: BrandColors.secondary.opacity(0.12), radius: 25, x: 0, y: 15)
        )
        .opacity(animate ? 1 : 0)
        .offset(y: animate ? 0 : 20)
    }

    private var lockedContinueButton: some View {
        Button {
            onContinueToAntecedents()
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "arrow.right.circle.fill")
                    .font(.system(size: 20, weight: .semibold))

                Text("Continuar")
                    .font(.system(size: 18, weight: .bold))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .foregroundStyle(.white)
            .background(
                LinearGradient(
                    colors: [BrandColors.primary, BrandColors.secondary],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .shadow(color: BrandColors.secondary.opacity(0.25), radius: 20, x: 0, y: 12)
        }
        .padding(.bottom, 24)
    }

    // MARK: - Main Card

    private var mainCard: some View {
        VStack(spacing: 28) {
            ZStack {
                Circle()
                    .fill(BrandColors.primary.opacity(0.15))
                    .frame(width: 120, height: 120)
                    .scaleEffect(animate ? 1 : 0.85)

                Circle()
                    .stroke(BrandColors.strokeGradient, lineWidth: 4)
                    .frame(width: 120, height: 120)

                ProgressView()
                    .scaleEffect(1.6)
            }

            VStack(spacing: 14) {
                Text("Aguarda un momento…")
                    .font(.system(size: 26, weight: .bold))
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.center)

                Text("Un optometrista certificado está por atender tu valoración visual.")
                    .font(.system(size: 17, weight: .medium))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.horizontal, 6)

                Divider().padding(.vertical, 6)

                HStack(spacing: 10) {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 18))
                        .foregroundStyle(BrandColors.accent)

                    Text("Tus datos fueron registrados correctamente.")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.secondary)
                }

                Divider().padding(.vertical, 4)

                // ── Analizador de rostro mientras esperas ──
                if let shape = detectedFaceShape {
                    faceAnalysisDoneCard(shape: shape)
                } else {
                    faceAnalysisInviteCard
                }
            }
        }
        .padding(28)
        .background(
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .fill(Color.white.opacity(0.90))
                .overlay(
                    RoundedRectangle(cornerRadius: 26, style: .continuous)
                        .stroke(BrandColors.accent.opacity(0.18), lineWidth: 1)
                )
                .shadow(color: BrandColors.secondary.opacity(0.12), radius: 25, x: 0, y: 15)
        )
        .opacity(animate ? 1 : 0)
        .offset(y: animate ? 0 : 20)
    }

    // MARK: - Face Analysis Invite

    private var faceAnalysisInviteCard: some View {
        Button { showFaceAnalysis = true } label: {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(BrandColors.primary.opacity(0.12))
                        .frame(width: 46, height: 46)
                    Image(systemName: "faceid")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(BrandColors.primary)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text("Mientras esperas…")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(BrandColors.secondary)
                    Text("Descubre qué armazón favorece\nla forma de tu rostro")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer()

                Image(systemName: "chevron.right.circle.fill")
                    .font(.system(size: 22))
                    .foregroundStyle(BrandColors.primary.opacity(0.7))
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(BrandColors.primary.opacity(0.07))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(BrandColors.primary.opacity(0.22), lineWidth: 1.5)
                    )
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Face Analysis Result Mini-card

    private func faceAnalysisDoneCard(shape: FaceShape) -> some View {
        Button { showFaceAnalysis = true } label: {
            HStack(spacing: 14) {
                Text(shape.emoji)
                    .font(.system(size: 34))

                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 6) {
                        Text("Rostro \(shape.rawValue)")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(BrandColors.secondary)
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 13))
                            .foregroundStyle(.green)
                    }
                    Text(shape.recommendedFrames.prefix(2).map(\.name).joined(separator: " · "))
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                Spacer()

                Text("Ver más")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(BrandColors.primary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(BrandColors.primary.opacity(0.10))
                    .clipShape(Capsule())
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color.green.opacity(0.06))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(Color.green.opacity(0.25), lineWidth: 1.5)
                    )
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Button

    private var continueButton: some View {
        Button {
            localOptometristName = (encounter.optometristName ?? "")
                .trimmingCharacters(in: .whitespacesAndNewlines)
            showOptometristModal = true
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "arrow.right.circle.fill")
                    .font(.system(size: 20, weight: .semibold))

                Text("Continuar")
                    .font(.system(size: 18, weight: .bold))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .foregroundStyle(.white)
            .background(
                LinearGradient(
                    colors: [BrandColors.primary, BrandColors.secondary],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .shadow(color: BrandColors.secondary.opacity(0.25), radius: 20, x: 0, y: 12)
        }
        .padding(.bottom, 24)
    }
}

// MARK: - Modal Premium
private struct OptometristNameModal: View {
    @Binding var name: String
    let onConfirm: () -> Void

    @Environment(\.dismiss) private var dismiss
    @FocusState private var focused: Bool
    @State private var animate = false

    var body: some View {
        ZStack {
            BrandColors.backgroundGradient
                .ignoresSafeArea()

            VStack {
                Spacer()

                modalCard

                Spacer()
            }
            .padding(.horizontal, 24)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.4)) {
                animate = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                focused = true
            }
        }
    }

    private var modalCard: some View {
        VStack(spacing: 24) {

            // Header
            VStack(spacing: 8) {
                Text("Asignar Optometrista")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(.primary)

                Text("Ingresa el nombre del profesional que continuará la atención.")
                    .font(.system(size: 15))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            // Campo
            VStack(alignment: .leading, spacing: 8) {
                Text("Nombre completo")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.secondary)

                HStack(spacing: 10) {
                    Image(systemName: "stethoscope")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(BrandColors.secondary)

                    TextField("Ej. Lic. Ana Pérez", text: $name)
                        .textInputAutocapitalization(.words)
                        .autocorrectionDisabled()
                        .focused($focused)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 14)
                .background(Color.black.opacity(0.04))
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(BrandColors.accent.opacity(0.20), lineWidth: 1)
                )
            }

            // Botones
            VStack(spacing: 12) {

                Button {
                    onConfirm()
                } label: {
                    Text("Continuar")
                        .font(.system(size: 17, weight: .bold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .foregroundStyle(.white)
                        .background(
                            LinearGradient(
                                colors: [BrandColors.primary, BrandColors.secondary],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
                .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .opacity(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.6 : 1)

                Button("Cancelar") {
                    dismiss()
                }
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(.secondary)
            }
        }
        .padding(28)
        .background(
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .fill(Color.white.opacity(0.95))
                .overlay(
                    RoundedRectangle(cornerRadius: 26, style: .continuous)
                        .stroke(BrandColors.accent.opacity(0.15), lineWidth: 1)
                )
                .shadow(color: BrandColors.secondary.opacity(0.15),
                        radius: 30, x: 0, y: 20)
        )
        .scaleEffect(animate ? 1 : 0.95)
        .opacity(animate ? 1 : 0)
    }
}

