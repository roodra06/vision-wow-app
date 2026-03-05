//
//  SignatureStepScreen.swift
//  VisionWow
//

import SwiftUI
import PencilKit
import AVFoundation

struct SignatureStepScreen: View {
    @Bindable var encounter: Encounter
    let onFinish: () -> Void

    // Fases
    @State private var phase: Phase = .patient
    @State private var patientCanvas = PKCanvasView()
    @State private var optometristCanvas = PKCanvasView()
    @State private var patientHasDrawing = false
    @State private var optometristHasDrawing = false

    // Cámara
    @State private var recorder = FrontCameraRecorder()
    @State private var isRecording = false
    @State private var cameraAuthDenied = false
    @State private var pdfError: String? = nil
    @State private var shareURL: URL? = nil

    enum Phase { case patient, optometrist, complete }

    // ─── Resumen de cobro ───
    private var totalText: String {
        let t = encounter.payTotal.trimmingCharacters(in: .whitespacesAndNewlines)
        return t.isEmpty ? "—" : "$\(t) MXN"
    }
    private var methodText: String {
        encounter.payMethod.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            ? "—" : encounter.payMethod
    }
    private var lensText: String {
        encounter.lensType.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            ? "—" : encounter.lensType
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {

                // Garantía badge
                if encounter.isGuarantee {
                    guaranteeBadge
                }

                if phase == .complete {
                    completionCard
                    completionButtons
                } else {
                    // Header de paso
                    stepHeader

                    // Resumen de cobro (solo en fase paciente)
                    if phase == .patient {
                        summaryCard
                    }

                    // Canvas de firma
                    signatureCard

                    // Botones de acción
                    actionButtons
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 14)
            .padding(.bottom, 28)
        }
        .alert("Error al generar PDF", isPresented: Binding(
            get: { pdfError != nil },
            set: { if !$0 { pdfError = nil } }
        )) {
            Button("Aceptar", role: .cancel) { pdfError = nil }
        } message: {
            Text(pdfError ?? "")
        }
        .sheet(item: Binding(
            get: { shareURL.map { SignatureShareItem(url: $0) } },
            set: { if $0 == nil { shareURL = nil } }
        )) { item in
            SignaturePDFShareSheet(url: item.url)
        }
        .alert("Cámara no disponible", isPresented: $cameraAuthDenied) {
            Button("Abrir Ajustes") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            Button("Continuar sin cámara", role: .cancel) {}
        } message: {
            Text("El acceso a la cámara fue denegado. Puedes habilitarlo en Ajustes → VisionWow → Cámara. La firma se capturará sin video de respaldo.")
        }
        .onAppear {
            // Ambas firmas presentes → completado directo
            if encounter.patientSignatureData != nil && encounter.optometristSignatureData != nil {
                phase = .complete
                return
            }
            // Solo firma del paciente → ir directo a fase optometrista
            if encounter.patientSignatureData != nil {
                phase = .optometrist
                return
            }
            // Fase paciente: iniciar cámara con verificación de permiso
            startCameraIfPermitted()
        }
        .onDisappear {
            if phase != .complete {
                recorder.stopSession()
            }
        }
    }

    // MARK: - Guarantee Badge

    private var guaranteeBadge: some View {
        HStack(spacing: 8) {
            Image(systemName: "shield.checkmark.fill")
                .font(.system(size: 14, weight: .semibold))
            Text("GARANTÍA")
                .font(.system(size: 13, weight: .bold))
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 14)
        .padding(.vertical, 6)
        .background(BrandColors.danger)
        .clipShape(Capsule())
    }

    // MARK: - Step Header

    private var stepHeader: some View {
        VStack(spacing: 6) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(phase == .patient ? "Firma del Paciente" : "Firma del Optometrista")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(BrandColors.secondary)
                    Text(phase == .patient
                         ? "El paciente acepta los servicios y montos indicados."
                         : "El optometrista confirma el servicio prestado.")
                        .font(.system(size: 14))
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: phase == .patient ? "person.fill" : "stethoscope")
                    .font(.system(size: 28))
                    .foregroundStyle(BrandColors.primary.opacity(0.7))
            }

            ProgressPillBar(
                progress: phase == .patient ? 0.33 : 0.66,
                height: 8
            )
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.white.opacity(0.72))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(BrandColors.accent.opacity(0.16), lineWidth: 1)
                )
                .shadow(color: BrandColors.secondary.opacity(0.06), radius: 14, x: 0, y: 8)
        )
    }

    // MARK: - Summary Card

    private var summaryCard: some View {
        VStack(spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "doc.text.fill")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(BrandColors.accent)
                Text("Resumen del servicio")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(BrandColors.secondary)
                Spacer()
            }

            Divider()

            summaryRow(icon: "creditcard.fill", label: "Total", value: totalText)
            summaryRow(icon: "creditcard.and.123", label: "Método", value: methodText)
            summaryRow(icon: "eyeglasses", label: "Lentes", value: lensText)

            if encounter.isGuarantee, let reason = encounter.guaranteeReason, !reason.isEmpty {
                summaryRow(icon: "shield.checkmark", label: "Garantía", value: reason)
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.white.opacity(0.82))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(BrandColors.accent.opacity(0.16), lineWidth: 1)
                )
                .shadow(color: BrandColors.secondary.opacity(0.06), radius: 14, x: 0, y: 8)
        )
    }

    private func summaryRow(icon: String, label: String, value: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(BrandColors.accent)
                .frame(width: 20)
            Text(label)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.primary)
                .lineLimit(2)
                .multilineTextAlignment(.trailing)
        }
    }

    // MARK: - Signature Card

    private var signatureCard: some View {
        VStack(spacing: 10) {
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "signature")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(BrandColors.accent)
                    Text("Firma aquí")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(BrandColors.secondary)
                }
                Spacer()

                // Cámara pequeña solo en fase paciente
                if phase == .patient {
                    cameraOverlay
                }
            }

            ZStack {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color.white)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(BrandColors.accent.opacity(0.3), lineWidth: 1.5)
                    )

                if phase == .patient {
                    SignatureCanvasView(canvasView: $patientCanvas) {
                        patientHasDrawing = !patientCanvas.drawing.strokes.isEmpty
                    }
                } else {
                    SignatureCanvasView(canvasView: $optometristCanvas) {
                        optometristHasDrawing = !optometristCanvas.drawing.strokes.isEmpty
                    }
                }
            }
            .frame(height: 200)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.white.opacity(0.82))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(BrandColors.accent.opacity(0.16), lineWidth: 1)
                )
                .shadow(color: BrandColors.secondary.opacity(0.06), radius: 14, x: 0, y: 8)
        )
    }

    private var cameraOverlay: some View {
        ZStack(alignment: .topTrailing) {
            FrontCameraPreviewView(session: recorder.session)
                .frame(width: 90, height: 70)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(isRecording ? BrandColors.danger : BrandColors.accent.opacity(0.4), lineWidth: 2)
                )

            if isRecording {
                Circle()
                    .fill(BrandColors.danger)
                    .frame(width: 10, height: 10)
                    .padding(4)
            }
        }
    }

    // MARK: - Action Buttons

    private var actionButtons: some View {
        VStack(spacing: 10) {
            if phase == .patient {
                // Limpiar
                Button {
                    patientCanvas.drawing = PKDrawing()
                    patientHasDrawing = false
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "trash")
                        Text("Limpiar")
                    }
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(BrandColors.danger)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(BrandColors.danger.opacity(0.08))
                            .overlay(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .stroke(BrandColors.danger.opacity(0.3), lineWidth: 1)
                            )
                    )
                }
                .buttonStyle(.plain)

                // Confirmar firma paciente
                Button {
                    confirmPatientSignature()
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                        Text("Confirmar firma del paciente")
                    }
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(patientHasDrawing ? BrandColors.primary : Color.gray.opacity(0.4))
                    )
                }
                .buttonStyle(.plain)
                .disabled(!patientHasDrawing)

            } else {
                // Limpiar (optometrista)
                Button {
                    optometristCanvas.drawing = PKDrawing()
                    optometristHasDrawing = false
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "trash")
                        Text("Limpiar")
                    }
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(BrandColors.danger)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(BrandColors.danger.opacity(0.08))
                            .overlay(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .stroke(BrandColors.danger.opacity(0.3), lineWidth: 1)
                            )
                    )
                }
                .buttonStyle(.plain)

                // Confirmar firma optometrista + Finalizar
                Button {
                    confirmOptometristSignatureAndFinish()
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.seal.fill")
                        Text("Confirmar y Finalizar")
                    }
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(optometristHasDrawing ? BrandColors.primary : Color.gray.opacity(0.4))
                    )
                }
                .buttonStyle(.plain)
                .disabled(!optometristHasDrawing)
            }
        }
    }

    // MARK: - Completion Card

    private var completionCard: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 48))
                .foregroundStyle(BrandColors.primary)

            Text("Firmas registradas")
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(BrandColors.secondary)

            Text("Ambas firmas han sido capturadas correctamente.\nGenera el PDF final con las firmas incluidas.")
                .font(.system(size: 14))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            ProgressPillBar(progress: 1.0, height: 8)
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.white.opacity(0.82))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(BrandColors.primary.opacity(0.2), lineWidth: 1.5)
                )
                .shadow(color: BrandColors.primary.opacity(0.08), radius: 14, x: 0, y: 8)
        )
    }

    private var completionButtons: some View {
        VStack(spacing: 10) {
            Button {
                generateAndSharePDF()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "square.and.arrow.up")
                    Text("Generar y Compartir PDF")
                }
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(BrandColors.primary)
                )
            }
            .buttonStyle(.plain)

            Button {
                onFinish()
            } label: {
                Text("Finalizar sin compartir")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Actions

    private func confirmPatientSignature() {
        encounter.patientSignatureData = patientCanvas.exportPNG()
        recorder.stopRecording()
        withAnimation {
            phase = .optometrist
        }
    }

    private func confirmOptometristSignatureAndFinish() {
        encounter.optometristSignatureData = optometristCanvas.exportPNG()
        recorder.stopSession()
        withAnimation {
            phase = .complete
        }
    }

    private func generateAndSharePDF() {
        do {
            let output = try PDFService.generate(encounter: encounter)
            shareURL = output.url
        } catch {
            pdfError = error.localizedDescription
        }
    }

    private func startCameraIfPermitted() {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        switch status {
        case .authorized:
            launchCamera()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    if granted { self.launchCamera() } else { self.cameraAuthDenied = true }
                }
            }
        case .denied, .restricted:
            cameraAuthDenied = true
        @unknown default:
            launchCamera()
        }
    }

    private func launchCamera() {
        recorder.onRecordingSaved = { fileName in
            encounter.signatureVideoFileName = fileName
        }
        recorder.startSession()
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            isRecording = true
            recorder.startRecording()
        }
    }
}

// MARK: - Share helpers

private struct SignatureShareItem: Identifiable {
    let id = UUID()
    let url: URL
}

private struct SignaturePDFShareSheet: UIViewControllerRepresentable {
    let url: URL
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: [url], applicationActivities: nil)
    }
    func updateUIViewController(_ vc: UIActivityViewController, context: Context) {}
}
