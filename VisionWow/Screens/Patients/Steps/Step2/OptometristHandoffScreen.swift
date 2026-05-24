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
            Button("Cambiar", role: .destructive) {
                localOptometristName = (encounter.optometristName ?? "")
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                encounter.optometristName = nil
                showOptometristModal = true
            }
            Button("Cancelar", role: .cancel) {}
        } message: {
            Text("\"\(encounter.optometristName ?? "")\" ya está asignado. ¿Deseas seleccionar otro?")
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
            .presentationDetents([.height(380), .medium])
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

                Divider().padding(.vertical, 4)

                // ── Analizador de rostro (siempre visible) ──
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

// MARK: - Catálogo de optometristas registrados

struct OptometristEntry: Identifiable {
    let id = UUID()
    let name: String
    let cedula: String
    let initials: String
}

private let registeredOptometrists: [OptometristEntry] = [
    OptometristEntry(
        name: "Wendy Yemely Mazariego González",
        cedula: "14168592",
        initials: "WM"
    )
    // Agrega más optometristas aquí
]

// MARK: - Modal Picker de Optometrista

private struct OptometristNameModal: View {
    @Binding var name: String
    let onConfirm: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var selected: OptometristEntry? = nil
    @State private var animate = false

    var body: some View {
        ZStack {
            BrandColors.backgroundGradient.ignoresSafeArea()

            VStack(spacing: 0) {
                // Título
                VStack(spacing: 6) {
                    Text("¿Quién atiende?")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(.primary)
                    Text("Selecciona al optometrista que realizará la consulta")
                        .font(.system(size: 14))
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 32)
                .padding(.bottom, 24)
                .padding(.horizontal, 24)

                // Lista de optometristas
                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(registeredOptometrists) { opt in
                            optometristCard(opt)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 24)
                }

                // Botón Cancelar
                Button("Cancelar") { dismiss() }
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(.secondary)
                    .padding(.bottom, 28)
            }
        }
        .onAppear {
            // Pre-seleccionar si ya había un nombre guardado
            if let match = registeredOptometrists.first(where: {
                $0.name.lowercased() == name.lowercased()
            }) {
                selected = match
            }
            withAnimation(.easeOut(duration: 0.35)) { animate = true }
        }
    }

    @ViewBuilder
    private func optometristCard(_ opt: OptometristEntry) -> some View {
        let isSelected = selected?.id == opt.id

        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                selected = opt
            }
            name = opt.name
            // Pequeño delay para que se vea la selección antes de cerrar
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) {
                onConfirm()
            }
        } label: {
            HStack(spacing: 16) {
                // Avatar con iniciales
                ZStack {
                    Circle()
                        .fill(
                            isSelected
                                ? LinearGradient(colors: [BrandColors.primary, BrandColors.secondary],
                                                 startPoint: .topLeading, endPoint: .bottomTrailing)
                                : LinearGradient(colors: [BrandColors.primary.opacity(0.12),
                                                           BrandColors.secondary.opacity(0.08)],
                                                 startPoint: .topLeading, endPoint: .bottomTrailing)
                        )
                        .frame(width: 52, height: 52)

                    Text(opt.initials)
                        .font(.system(size: 17, weight: .bold))
                        .foregroundStyle(isSelected ? .white : BrandColors.primary)
                }

                // Nombre + cédula
                VStack(alignment: .leading, spacing: 4) {
                    Text(opt.name)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.primary)
                        .multilineTextAlignment(.leading)

                    HStack(spacing: 5) {
                        Image(systemName: "stethoscope")
                            .font(.system(size: 11))
                            .foregroundStyle(BrandColors.accent)
                        Text("Céd. Prof. \(opt.cedula)")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(BrandColors.accent)
                    }
                }

                Spacer()

                // Check de selección
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 22))
                    .foregroundStyle(isSelected ? BrandColors.primary : Color.secondary.opacity(0.3))
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(isSelected
                          ? BrandColors.primary.opacity(0.07)
                          : Color.white.opacity(0.90))
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(
                                isSelected ? BrandColors.primary.opacity(0.40) : Color.clear,
                                lineWidth: 1.5
                            )
                    )
                    .shadow(color: isSelected
                            ? BrandColors.primary.opacity(0.12)
                            : Color.black.opacity(0.05),
                            radius: isSelected ? 12 : 6, x: 0, y: 4)
            )
        }
        .buttonStyle(.plain)
        .scaleEffect(animate ? 1 : 0.95)
        .opacity(animate ? 1 : 0)
    }
}

