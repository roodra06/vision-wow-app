//
//  LiveFaceCameraView.swift
//  VisionWow
//
//  Cámara frontal con detección facial en tiempo real.
//  Muestra: óvalo guía, cuadro de detección animado, instrucciones
//  contextuales y botón de captura que se habilita solo cuando el
//  rostro está bien posicionado.
//

import AVFoundation
import Vision
import UIKit
import SwiftUI

// MARK: - SwiftUI wrapper

struct LiveFaceCameraView: UIViewControllerRepresentable {
    let onCapture: (UIImage) -> Void
    let onDismiss: () -> Void

    func makeUIViewController(context: Context) -> FaceCameraViewController {
        FaceCameraViewController(onCapture: onCapture, onDismiss: onDismiss)
    }
    func updateUIViewController(_ uiViewController: FaceCameraViewController, context: Context) {}
}

// MARK: - Camera view controller

final class FaceCameraViewController: UIViewController {

    // MARK: Callbacks
    let onCapture: (UIImage) -> Void
    let onDismiss:  () -> Void

    // MARK: AVFoundation
    private let session        = AVCaptureSession()
    private var previewLayer   : AVCaptureVideoPreviewLayer!
    private let photoOutput    = AVCapturePhotoOutput()
    private let videoOutput    = AVCaptureVideoDataOutput()
    private let sessionQ       = DispatchQueue(label: "vw.camera", qos: .userInitiated)
    private let detectionQ     = DispatchQueue(label: "vw.face",   qos: .userInitiated)

    // MARK: Detection throttle
    private var lastDetectTime: CFTimeInterval = 0
    private let detectInterval: CFTimeInterval = 0.10  // ~10 fps

    // MARK: Layer overlays
    private let dimLayer      = CAShapeLayer()
    private let ovalLayer     = CAShapeLayer()
    private let faceBoxLayer  = CAShapeLayer()

    // MARK: UI views
    private let statusPill     = LiveStatusPill()
    private let tipCard        = LiveTipCard()
    private let captureBtn     = LiveCaptureButton()
    private let dismissBtn     = UIButton(type: .system)
    private let countdownView  = CountdownRingView()

    // MARK: Haptics
    private let haptic      = UIImpactFeedbackGenerator(style: .medium)
    private let tickHaptic  = UIImpactFeedbackGenerator(style: .light)

    // MARK: State
    private var faceReady         = false
    private var captureInProgress = false
    private var lastReadyTime: CFTimeInterval = 0
    private var countdownTimer:  Timer?
    private var countdownSeconds = 3

    // MARK: Init
    init(onCapture: @escaping (UIImage) -> Void, onDismiss: @escaping () -> Void) {
        self.onCapture = onCapture
        self.onDismiss = onDismiss
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) { fatalError() }

    // MARK: Lifecycle
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask { .landscape }
    override var preferredInterfaceOrientationForPresentation: UIInterfaceOrientation { .landscapeRight }
    override var preferredStatusBarStyle: UIStatusBarStyle { .lightContent }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        checkPermission()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer?.frame = view.bounds
        refreshGuideLayers()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        sessionQ.async { self.session.startRunning() }
        haptic.prepare()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        sessionQ.async { self.session.stopRunning() }
    }

    // MARK: Permission

    private func checkPermission() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:       setupSession()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] ok in
                DispatchQueue.main.async { ok ? self?.setupSession() : self?.showNoPermission() }
            }
        default: showNoPermission()
        }
    }

    private func showNoPermission() {
        let lbl = UILabel()
        lbl.text = "Se necesita acceso a la cámara.\nAbre Ajustes › VisionWow › Cámara."
        lbl.textColor = .white
        lbl.font = .systemFont(ofSize: 16, weight: .medium)
        lbl.textAlignment = .center
        lbl.numberOfLines = 0
        lbl.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(lbl)
        NSLayoutConstraint.activate([
            lbl.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            lbl.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            lbl.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 32),
            lbl.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -32),
        ])
        buildDismissButton()
    }

    // MARK: Session setup

    private func setupSession() {
        session.beginConfiguration()
        session.sessionPreset = .photo

        guard
            let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front),
            let input  = try? AVCaptureDeviceInput(device: device)
        else { session.commitConfiguration(); return }

        if session.canAddInput(input)       { session.addInput(input) }
        if session.canAddOutput(photoOutput) { session.addOutput(photoOutput) }

        videoOutput.setSampleBufferDelegate(self, queue: detectionQ)
        videoOutput.alwaysDiscardsLateVideoFrames = true
        if session.canAddOutput(videoOutput) { session.addOutput(videoOutput) }

        session.commitConfiguration()
        DispatchQueue.main.async { self.buildUI() }
    }

    // MARK: UI construction

    private func buildUI() {
        // Preview
        previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.videoGravity = .resizeAspectFill
        previewLayer.frame = view.bounds
        // Fix orientation for landscape — critical for layerRectConverted correctness
        if let conn = previewLayer.connection, conn.isVideoOrientationSupported {
            conn.videoOrientation = .landscapeRight
        }
        view.layer.addSublayer(previewLayer)

        // Guide overlays (dim + oval + face box)
        dimLayer.fillRule = .evenOdd
        dimLayer.fillColor = UIColor.black.withAlphaComponent(0.45).cgColor
        view.layer.addSublayer(dimLayer)

        ovalLayer.fillColor  = UIColor.clear.cgColor
        ovalLayer.strokeColor = UIColor.white.withAlphaComponent(0.85).cgColor
        ovalLayer.lineWidth  = 2.5
        ovalLayer.lineDashPattern = [12, 6]
        view.layer.addSublayer(ovalLayer)

        faceBoxLayer.fillColor   = UIColor.clear.cgColor
        faceBoxLayer.strokeColor = UIColor.systemGreen.cgColor
        faceBoxLayer.lineWidth   = 2.5
        faceBoxLayer.cornerRadius = 12
        faceBoxLayer.isHidden    = true
        view.layer.addSublayer(faceBoxLayer)

        refreshGuideLayers()

        // Status pill — top center
        statusPill.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(statusPill)

        // Tip card — above capture button
        tipCard.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tipCard)

        // Capture button
        captureBtn.translatesAutoresizingMaskIntoConstraints = false
        captureBtn.addTarget(self, action: #selector(capture), for: .touchUpInside)
        view.addSubview(captureBtn)

        buildDismissButton()

        // Countdown ring — centered over the oval
        countdownView.translatesAutoresizingMaskIntoConstraints = false
        countdownView.isHidden = true
        view.addSubview(countdownView)

        NSLayoutConstraint.activate([
            statusPill.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 52),
            statusPill.centerXAnchor.constraint(equalTo: view.centerXAnchor),

            captureBtn.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -36),
            captureBtn.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            captureBtn.widthAnchor.constraint(equalToConstant: 80),
            captureBtn.heightAnchor.constraint(equalToConstant: 80),

            tipCard.bottomAnchor.constraint(equalTo: captureBtn.topAnchor, constant: -22),
            tipCard.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            tipCard.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 28),
            tipCard.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -28),

            countdownView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            countdownView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            countdownView.widthAnchor.constraint(equalToConstant: 110),
            countdownView.heightAnchor.constraint(equalToConstant: 110),
        ])

        tickHaptic.prepare()
        applyStatus(.searching)
    }

    private func buildDismissButton() {
        let cfg = UIImage.SymbolConfiguration(pointSize: 16, weight: .semibold)
        dismissBtn.setImage(UIImage(systemName: "xmark", withConfiguration: cfg), for: .normal)
        dismissBtn.tintColor = .white
        dismissBtn.backgroundColor = UIColor.black.withAlphaComponent(0.45)
        dismissBtn.layer.cornerRadius = 22
        dismissBtn.translatesAutoresizingMaskIntoConstraints = false
        dismissBtn.addTarget(self, action: #selector(dismiss_), for: .touchUpInside)
        view.addSubview(dismissBtn)
        NSLayoutConstraint.activate([
            dismissBtn.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            dismissBtn.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10),
            dismissBtn.widthAnchor.constraint(equalToConstant: 44),
            dismissBtn.heightAnchor.constraint(equalToConstant: 44),
        ])
    }

    // MARK: Guide layers

    private func ovalGuideRect() -> CGRect {
        // In landscape the screen is short vertically — base oval on height
        let h = min(view.bounds.height * 0.82, 300.0)
        let w = h * 0.78   // face oval: slightly wider than tall
        return CGRect(
            x: (view.bounds.width  - w) / 2,
            y: (view.bounds.height - h) / 2,
            width: w, height: h
        )
    }

    private func refreshGuideLayers() {
        guard view.bounds != .zero else { return }
        let oval = ovalGuideRect()
        let ovalPath = UIBezierPath(ovalIn: oval)

        // Dim with transparent cutout
        let screen = UIBezierPath(rect: view.bounds)
        screen.append(ovalPath)
        dimLayer.path  = screen.cgPath
        dimLayer.frame = view.bounds

        // Oval border
        ovalLayer.path = ovalPath.cgPath
    }

    // MARK: Status model

    enum FaceStatus {
        case searching
        case noFace
        case tooSmall
        case tooLarge
        case offCenter(String)
        case ready
    }

    private func applyStatus(_ s: FaceStatus, faceRect: CGRect? = nil) {
        // While a capture is in progress, freeze the UI so the button stays live
        guard !captureInProgress else { return }

        let wasReady = faceReady

        switch s {
        case .searching:
            // Debounce: keep button enabled for 1.5 s after last ready frame
            if CACurrentMediaTime() - lastReadyTime < 1.5 { return }
            faceReady = false
            cancelCountdown()
            hideFaceBox()
            statusPill.set(text: "🔍  Buscando rostro...", color: .systemGray)
            tipCard.set(icon: "faceid",
                        primary: "Coloca el rostro en el óvalo",
                        secondary: "Mira directamente a la cámara")

        case .noFace:
            if CACurrentMediaTime() - lastReadyTime < 1.5 { return }
            faceReady = false
            cancelCountdown()
            hideFaceBox()
            statusPill.set(text: "⚠️  Sin rostro detectado", color: .systemOrange)
            tipCard.set(icon: "exclamationmark.triangle.fill",
                        primary: "No se detecta ningún rostro",
                        secondary: "Asegúrate de tener buena iluminación")

        case .tooSmall:
            if CACurrentMediaTime() - lastReadyTime < 1.5 { return }
            faceReady = false
            cancelCountdown()
            showFaceBox(faceRect, ready: false)
            statusPill.set(text: "↗  Acércate más", color: .systemOrange)
            tipCard.set(icon: "arrow.up.left.and.arrow.down.right",
                        primary: "Acércate a la cámara",
                        secondary: "El rostro debe llenar el óvalo guía")

        case .tooLarge:
            if CACurrentMediaTime() - lastReadyTime < 1.5 { return }
            faceReady = false
            cancelCountdown()
            showFaceBox(faceRect, ready: false)
            statusPill.set(text: "↙  Aléjate un poco", color: .systemOrange)
            tipCard.set(icon: "arrow.down.right.and.arrow.up.left",
                        primary: "Aléjate de la cámara",
                        secondary: "El rostro excede el óvalo guía")

        case .offCenter(let direction):
            if CACurrentMediaTime() - lastReadyTime < 1.5 { return }
            faceReady = false
            cancelCountdown()
            showFaceBox(faceRect, ready: false)
            statusPill.set(text: "↔  Centra el rostro", color: .systemOrange)
            tipCard.set(icon: "arrow.left.arrow.right",
                        primary: "Mueve el rostro \(direction)",
                        secondary: "Mantén el rostro centrado en el óvalo")

        case .ready:
            lastReadyTime = CACurrentMediaTime()
            showFaceBox(faceRect, ready: true)
            statusPill.set(text: "✓  Mantén el rostro quieto…", color: .systemGreen)
            tipCard.set(icon: "timer",
                        primary: "Foto automática en 3 segundos",
                        secondary: "O toca el botón para capturar ahora")
            if !wasReady {
                faceReady = true
                haptic.impactOccurred()
                startCountdown()
            }
            return   // don't touch captureBtn here; countdown manages it
        }

        captureBtn.setReady(faceReady)
    }

    // MARK: - Countdown

    private func startCountdown() {
        countdownTimer?.invalidate()
        countdownSeconds = 3
        countdownView.set(seconds: countdownSeconds)
        countdownView.isHidden = false
        captureBtn.setReady(true)

        countdownTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self else { return }
            self.countdownSeconds -= 1
            if self.countdownSeconds <= 0 {
                self.cancelCountdown()
                self.capture()
            } else {
                self.countdownView.set(seconds: self.countdownSeconds)
                self.tickHaptic.impactOccurred()
            }
        }
    }

    private func cancelCountdown() {
        countdownTimer?.invalidate()
        countdownTimer = nil
        countdownView.isHidden = true
        countdownSeconds = 3
    }

    private func hideFaceBox() {
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        faceBoxLayer.isHidden = true
        CATransaction.commit()
    }

    private func showFaceBox(_ rect: CGRect?, ready: Bool) {
        guard let r = rect else { hideFaceBox(); return }
        CATransaction.begin()
        CATransaction.setAnimationDuration(0.1)
        faceBoxLayer.isHidden = false
        faceBoxLayer.path = UIBezierPath(roundedRect: r, cornerRadius: 12).cgPath
        faceBoxLayer.strokeColor = (ready ? UIColor.systemGreen : UIColor.systemOrange).cgColor
        CATransaction.commit()
    }

    // MARK: Actions

    @objc private func capture() {
        guard !captureInProgress else { return }
        cancelCountdown()
        captureInProgress = true          // freeze detection UI immediately
        captureBtn.setReady(false)        // visual feedback: button dims
        haptic.impactOccurred()

        sessionQ.async { [weak self] in
            guard let self else { return }
            let settings = AVCapturePhotoSettings(
                format: [AVVideoCodecKey: AVVideoCodecType.jpeg]
            )
            self.photoOutput.capturePhoto(with: settings, delegate: self)
        }
    }

    @objc private func dismiss_() {
        cancelCountdown()
        onDismiss()
    }
}

// MARK: - Video data delegate

extension FaceCameraViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput,
                       didOutput sampleBuffer: CMSampleBuffer,
                       from connection: AVCaptureConnection) {
        let now = CACurrentMediaTime()
        guard now - lastDetectTime > detectInterval else { return }
        lastDetectTime = now

        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }

        let req = VNDetectFaceRectanglesRequest { [weak self] request, _ in
            guard let self else { return }
            let obs = (request.results as? [VNFaceObservation])?.first
            DispatchQueue.main.async { self.handleFaceObservation(obs) }
        }

        // Front camera in landscape: upMirrored (buffer is upright + mirrored)
        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer,
                                            orientation: .upMirrored,
                                            options: [:])
        try? handler.perform([req])
    }
}

// MARK: - Face observation → UI update

extension FaceCameraViewController {
    private func handleFaceObservation(_ obs: VNFaceObservation?) {
        guard let obs else {
            applyStatus(.noFace)
            return
        }

        // Convert Vision bbox (origin bottom-left, normalized) to preview layer coords.
        // .upMirrored orientation already bakes in the mirror, so only flip Y.
        let bbox = obs.boundingBox
        let meta = CGRect(
            x:      bbox.minX,
            y:      1.0 - bbox.maxY,   // flip Y (Vision bottom-left → UIKit top-left)
            width:  bbox.width,
            height: bbox.height
        )
        let layerRect = previewLayer.layerRectConverted(fromMetadataOutputRect: meta)

        // ── Size check
        let faceArea   = layerRect.width  * layerRect.height
        let screenArea = view.bounds.width * view.bounds.height
        let ratio      = faceArea / screenArea

        if ratio < 0.025 { applyStatus(.tooSmall,  faceRect: layerRect); return }
        if ratio > 0.65  { applyStatus(.tooLarge,  faceRect: layerRect); return }

        // ── Centering check relative to oval guide
        let oval  = ovalGuideRect()
        let tolX  = oval.width  * 0.22
        let tolY  = oval.height * 0.22
        let dX    = layerRect.midX - oval.midX
        let dY    = layerRect.midY - oval.midY

        if abs(dX) > tolX {
            let dir = dX < 0 ? "hacia la derecha" : "hacia la izquierda"
            applyStatus(.offCenter(dir), faceRect: layerRect)
            return
        }
        if abs(dY) > tolY {
            let dir = dY < 0 ? "hacia abajo" : "hacia arriba"
            applyStatus(.offCenter(dir), faceRect: layerRect)
            return
        }

        applyStatus(.ready, faceRect: layerRect)
    }
}

// MARK: - Photo delegate

extension FaceCameraViewController: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput,
                     didFinishProcessingPhoto photo: AVCapturePhoto,
                     error: Error?) {
        if error != nil {
            // Allow retry on failure
            DispatchQueue.main.async { [weak self] in
                self?.captureInProgress = false
                self?.captureBtn.setReady(true)
            }
            return
        }
        guard let data  = photo.fileDataRepresentation(),
              let raw   = UIImage(data: data) else { return }
        onCapture(raw.normalizedOrientation())
    }
}

// MARK: - UIImage orientation fix

private extension UIImage {
    /// Redraws the image so its orientation is always .up, fixing the 90° rotation
    /// that can appear when the front camera captures in landscape.
    /// Always redraws (no early-out on .up) because AVCapturePhotoOutput sometimes
    /// embeds .up in EXIF while leaving the pixel data in portrait layout.
    func normalizedOrientation() -> UIImage {
        let fmt = UIGraphicsImageRendererFormat()
        fmt.scale = scale
        let renderer = UIGraphicsImageRenderer(size: size, format: fmt)
        return renderer.image { _ in
            draw(in: CGRect(origin: .zero, size: size))
        }
    }
}

// MARK: - LiveStatusPill

final class LiveStatusPill: UIView {
    private let label = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        layer.cornerRadius = 18
        clipsToBounds = true
        backgroundColor = UIColor.black.withAlphaComponent(0.55)

        label.font = .systemFont(ofSize: 14, weight: .semibold)
        label.textColor = .white
        label.translatesAutoresizingMaskIntoConstraints = false
        addSubview(label)
        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: topAnchor, constant: 9),
            label.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -9),
            label.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            label.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
        ])
    }
    required init?(coder: NSCoder) { fatalError() }

    func set(text: String, color: UIColor) {
        label.text = text
        UIView.animate(withDuration: 0.2) {
            self.backgroundColor = color.withAlphaComponent(0.80)
        }
    }
}

// MARK: - LiveTipCard

final class LiveTipCard: UIView {
    private let icon      = UIImageView()
    private let primary   = UILabel()
    private let secondary = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = UIColor.black.withAlphaComponent(0.60)
        layer.cornerRadius = 18
        clipsToBounds = true

        icon.tintColor = .white
        icon.contentMode = .scaleAspectFit
        icon.setContentHuggingPriority(.required, for: .horizontal)

        primary.font = .systemFont(ofSize: 15, weight: .semibold)
        primary.textColor = .white
        primary.textAlignment = .center
        primary.numberOfLines = 1

        secondary.font = .systemFont(ofSize: 12, weight: .regular)
        secondary.textColor = UIColor.white.withAlphaComponent(0.75)
        secondary.textAlignment = .center
        secondary.numberOfLines = 1

        let textStack = UIStackView(arrangedSubviews: [primary, secondary])
        textStack.axis = .vertical
        textStack.spacing = 2

        let row = UIStackView(arrangedSubviews: [icon, textStack])
        row.axis = .horizontal
        row.spacing = 10
        row.alignment = .center
        row.translatesAutoresizingMaskIntoConstraints = false
        addSubview(row)

        NSLayoutConstraint.activate([
            row.topAnchor.constraint(equalTo: topAnchor, constant: 12),
            row.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -12),
            row.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            row.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            icon.widthAnchor.constraint(equalToConstant: 24),
            icon.heightAnchor.constraint(equalToConstant: 24),
        ])
    }
    required init?(coder: NSCoder) { fatalError() }

    func set(icon name: String, primary p: String, secondary s: String) {
        let cfg = UIImage.SymbolConfiguration(pointSize: 18, weight: .semibold)
        icon.image = UIImage(systemName: name, withConfiguration: cfg)
        UIView.transition(with: self, duration: 0.2, options: .transitionCrossDissolve) {
            self.primary.text   = p
            self.secondary.text = s
        }
    }
}

// MARK: - LiveCaptureButton

final class LiveCaptureButton: UIControl {
    private let ring = UIView()
    private let disk = UIView()

    override init(frame: CGRect) {
        super.init(frame: frame)

        ring.layer.borderColor = UIColor.white.withAlphaComponent(0.55).cgColor
        ring.layer.borderWidth = 3
        ring.layer.cornerRadius = 40
        ring.translatesAutoresizingMaskIntoConstraints = false
        addSubview(ring)

        disk.backgroundColor = .white
        disk.layer.cornerRadius = 31
        disk.translatesAutoresizingMaskIntoConstraints = false
        addSubview(disk)

        NSLayoutConstraint.activate([
            ring.centerXAnchor.constraint(equalTo: centerXAnchor),
            ring.centerYAnchor.constraint(equalTo: centerYAnchor),
            ring.widthAnchor.constraint(equalToConstant: 80),
            ring.heightAnchor.constraint(equalToConstant: 80),
            disk.centerXAnchor.constraint(equalTo: centerXAnchor),
            disk.centerYAnchor.constraint(equalTo: centerYAnchor),
            disk.widthAnchor.constraint(equalToConstant: 62),
            disk.heightAnchor.constraint(equalToConstant: 62),
        ])

        alpha = 0.30
        isUserInteractionEnabled = false
    }
    required init?(coder: NSCoder) { fatalError() }

    func setReady(_ ready: Bool) {
        isUserInteractionEnabled = ready
        UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 0.5) {
            self.alpha = ready ? 1.0 : 0.30
            self.disk.backgroundColor = ready ? .white : .gray
            self.transform = ready ? .identity : CGAffineTransform(scaleX: 0.92, y: 0.92)
        }
    }

    override var isHighlighted: Bool {
        didSet {
            UIView.animate(withDuration: 0.1) {
                self.transform = self.isHighlighted
                    ? CGAffineTransform(scaleX: 0.90, y: 0.90) : .identity
            }
        }
    }
}

// MARK: - CountdownRingView

final class CountdownRingView: UIView {
    private let numberLabel  = UILabel()
    private let ringLayer    = CAShapeLayer()
    private let trackLayer   = CAShapeLayer()

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear

        // Background track ring
        trackLayer.fillColor   = UIColor.clear.cgColor
        trackLayer.strokeColor = UIColor.white.withAlphaComponent(0.25).cgColor
        trackLayer.lineWidth   = 6
        trackLayer.lineCap     = .round
        layer.addSublayer(trackLayer)

        // Animated progress ring
        ringLayer.fillColor   = UIColor.clear.cgColor
        ringLayer.strokeColor = UIColor.systemGreen.cgColor
        ringLayer.lineWidth   = 6
        ringLayer.lineCap     = .round
        ringLayer.strokeEnd   = 1.0
        // Start from top (−π/2)
        ringLayer.transform   = CATransform3DMakeRotation(-.pi / 2, 0, 0, 1)
        layer.addSublayer(ringLayer)

        // Number
        numberLabel.font = UIFont.systemFont(ofSize: 52, weight: .bold, width: .compressed)
        numberLabel.textColor = .white
        numberLabel.textAlignment = .center
        numberLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(numberLabel)
        NSLayoutConstraint.activate([
            numberLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            numberLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
        ])

        // Blurred background circle
        let blur = UIVisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterialDark))
        blur.layer.cornerRadius = 55
        blur.clipsToBounds = true
        blur.translatesAutoresizingMaskIntoConstraints = false
        insertSubview(blur, at: 0)
        NSLayoutConstraint.activate([
            blur.leadingAnchor.constraint(equalTo: leadingAnchor),
            blur.trailingAnchor.constraint(equalTo: trailingAnchor),
            blur.topAnchor.constraint(equalTo: topAnchor),
            blur.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
    }
    required init?(coder: NSCoder) { fatalError() }

    override func layoutSubviews() {
        super.layoutSubviews()
        let center = CGPoint(x: bounds.midX, y: bounds.midY)
        let radius = (min(bounds.width, bounds.height) - 6) / 2
        let path   = UIBezierPath(arcCenter: center, radius: radius,
                                  startAngle: 0, endAngle: .pi * 2, clockwise: true)
        trackLayer.path = path.cgPath
        ringLayer.path  = path.cgPath
    }

    /// Update displayed number and animate the ring sweeping from full → empty over 1 second.
    func set(seconds: Int) {
        numberLabel.text = "\(seconds)"

        // Scale pop animation on the number
        let pop = CAKeyframeAnimation(keyPath: "transform.scale")
        pop.values   = [1.0, 1.35, 1.0]
        pop.keyTimes = [0, 0.3, 1]
        pop.duration = 0.35
        numberLabel.layer.add(pop, forKey: "pop")

        // Sweep the ring from full (1.0) to empty (0.0) over 1 second
        let sweep = CABasicAnimation(keyPath: "strokeEnd")
        sweep.fromValue = 1.0
        sweep.toValue   = 0.0
        sweep.duration  = 1.0
        sweep.fillMode  = .forwards
        sweep.isRemovedOnCompletion = false
        ringLayer.removeAnimation(forKey: "sweep")
        ringLayer.add(sweep, forKey: "sweep")

        // Color: green → orange → red
        let color: UIColor = seconds == 3 ? .systemGreen : seconds == 2 ? .systemOrange : .systemRed
        ringLayer.strokeColor = color.cgColor
    }
}
