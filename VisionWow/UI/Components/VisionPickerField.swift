import SwiftUI

// MARK: - Picker Kind

enum VisionPickerKind {
    case distantAcuity
    case nearAcuity
    case sph
    case cyl
    case add
    case generic
}

// MARK: - VisionPickerField

struct VisionPickerField: View {
    let icon: String
    let options: [String]
    @Binding var selection: String
    var isError: Bool = false
    var placeholder: String = "Seleccionar..."
    var kind: VisionPickerKind = .generic

    @State private var showSheet = false
    @State private var tempSelection: String = ""

    var body: some View {
        Button {
            tempSelection = options.contains(selection) ? selection : options[options.count / 2]
            showSheet = true
        } label: {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(selection.isEmpty ? Color.secondary : BrandColors.secondary)

                Text(selection.isEmpty ? placeholder : selection)
                    .font(.system(size: 15))
                    .foregroundStyle(selection.isEmpty ? Color.secondary.opacity(0.55) : Color.primary)
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Image(systemName: "chevron.up.chevron.down")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Color.secondary.opacity(0.5))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(Color.black.opacity(0.04))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(
                        isError
                            ? BrandColors.danger.opacity(0.9)
                            : (selection.isEmpty ? BrandColors.accent.opacity(0.12) : BrandColors.primary.opacity(0.30)),
                        lineWidth: isError || !selection.isEmpty ? 1.5 : 1
                    )
            )
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showSheet) {
            _WheelPickerSheet(
                options: options,
                kind: kind,
                tempSelection: $tempSelection,
                onConfirm: { chosen in
                    selection = chosen
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                }
            )
            .presentationDetents([.height(kind == .generic ? 300 : 420)])
            .presentationDragIndicator(.visible)
        }
    }
}

// MARK: - AxisPickerField

struct AxisPickerField: View {
    let icon: String
    @Binding var selection: String
    var isError: Bool = false

    private static let options: [String] = (0...180).map { "\($0)°" }

    @State private var showSheet = false
    @State private var tempSelection: String = ""

    var body: some View {
        Button {
            tempSelection = Self.options.contains(selection) ? selection : "0°"
            showSheet = true
        } label: {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(selection.isEmpty ? Color.secondary : BrandColors.secondary)

                Text(selection.isEmpty ? "Seleccionar..." : selection)
                    .font(.system(size: 15))
                    .foregroundStyle(selection.isEmpty ? Color.secondary.opacity(0.55) : Color.primary)
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, alignment: .leading)

                if let deg = axisValue {
                    _AxisMiniIndicator(degrees: Double(deg))
                        .frame(width: 22, height: 22)
                }

                Image(systemName: "chevron.up.chevron.down")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Color.secondary.opacity(0.5))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(Color.black.opacity(0.04))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(
                        isError
                            ? BrandColors.danger.opacity(0.9)
                            : (selection.isEmpty ? BrandColors.accent.opacity(0.12) : BrandColors.primary.opacity(0.30)),
                        lineWidth: isError || !selection.isEmpty ? 1.5 : 1
                    )
            )
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showSheet) {
            _AxisPickerSheet(
                tempSelection: $tempSelection,
                options: Self.options,
                onConfirm: { chosen in
                    selection = chosen
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                }
            )
            .presentationDetents([.height(460)])
            .presentationDragIndicator(.visible)
        }
    }

    private var axisValue: Int? {
        guard !selection.isEmpty else { return nil }
        return Int(selection.replacingOccurrences(of: "°", with: ""))
    }
}

// MARK: - Internal Sheets

private struct _WheelPickerSheet: View {
    let options: [String]
    let kind: VisionPickerKind
    @Binding var tempSelection: String
    let onConfirm: (String) -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            // Top bar
            HStack {
                Button("Cancelar") { dismiss() }
                    .font(.system(size: 16))
                    .foregroundStyle(.secondary)
                Spacer()
                Text(sheetTitle)
                    .font(.system(size: 15, weight: .semibold))
                Spacer()
                Button("Listo") {
                    onConfirm(tempSelection)
                    dismiss()
                }
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(BrandColors.primary)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)

            Divider()

            // Animated clinical preview
            if kind != .generic {
                VisionPickerPreview(kind: kind, value: tempSelection)
                    .padding(.horizontal, 24)
                    .padding(.top, 14)
                    .padding(.bottom, 6)
            }

            Picker("", selection: $tempSelection) {
                ForEach(options, id: \.self) { opt in
                    Text(opt)
                        .font(.system(size: 20, weight: .regular))
                        .tag(opt)
                }
            }
            .pickerStyle(.wheel)
            .frame(maxWidth: .infinity)
            .onChange(of: tempSelection) {
                UISelectionFeedbackGenerator().selectionChanged()
            }
        }
        .onAppear {
            if !options.contains(tempSelection) {
                tempSelection = options[options.count / 2]
            }
        }
    }

    private var sheetTitle: String {
        switch kind {
        case .distantAcuity: return "Agudeza lejana"
        case .nearAcuity:    return "Agudeza cercana"
        case .sph:           return "Esfera (SPH)"
        case .cyl:           return "Cilindro (CYL)"
        case .add:           return "Adición (ADD)"
        case .generic:       return "Seleccionar valor"
        }
    }
}

private struct _AxisPickerSheet: View {
    @Binding var tempSelection: String
    let options: [String]
    let onConfirm: (String) -> Void

    @Environment(\.dismiss) private var dismiss

    private var axisDeg: Double {
        Double(tempSelection.replacingOccurrences(of: "°", with: "")) ?? 90
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button("Cancelar") { dismiss() }
                    .font(.system(size: 16))
                    .foregroundStyle(.secondary)
                Spacer()
                Text("Eje (AXIS)")
                    .font(.system(size: 15, weight: .semibold))
                Spacer()
                Button("Listo") {
                    onConfirm(tempSelection)
                    dismiss()
                }
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(BrandColors.primary)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)

            Divider()

            // Axis preview
            _AxisLargeIndicator(degrees: axisDeg, label: tempSelection)
                .padding(.top, 16)
                .padding(.bottom, 8)

            Picker("", selection: $tempSelection) {
                ForEach(options, id: \.self) { opt in
                    Text(opt)
                        .font(.system(size: 20, weight: .regular))
                        .tag(opt)
                }
            }
            .pickerStyle(.wheel)
            .frame(maxWidth: .infinity)
            .onChange(of: tempSelection) {
                UISelectionFeedbackGenerator().selectionChanged()
            }
        }
        .onAppear {
            if !options.contains(tempSelection) { tempSelection = "0°" }
        }
    }
}

// MARK: - Clinical Preview Router

private struct VisionPickerPreview: View {
    let kind: VisionPickerKind
    let value: String

    var body: some View {
        Group {
            switch kind {
            case .distantAcuity: _DistantAcuityPreview(value: value)
            case .nearAcuity:    _NearAcuityPreview(value: value)
            case .sph:           _SPHPreview(value: value)
            case .cyl:           _CYLPreview(value: value)
            case .add:           _ADDPreview(value: value)
            case .generic:       EmptyView()
            }
        }
    }
}

// MARK: - Distant Acuity Preview

private struct _DistantAcuityPreview: View {
    let value: String

    private var denominator: Double {
        let parts = value.split(separator: "/")
        guard parts.count == 2, let d = Double(parts[1]) else { return 20 }
        return d
    }

    private var letterScale: CGFloat {
        let s = denominator / 20.0
        return min(max(CGFloat(s) * 0.42, 0.22), 2.0)
    }

    private var blurAmount: CGFloat {
        CGFloat(max(0.0, (denominator - 20.0) / 35.0))
    }

    private var acuityColor: Color {
        if denominator <= 20 { return BrandColors.success }
        if denominator <= 40 { return BrandColors.warning }
        return BrandColors.danger
    }

    var body: some View {
        HStack(spacing: 16) {
            // Optotype "E"
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.black.opacity(0.04))
                    .frame(width: 80, height: 80)

                Text("E")
                    .font(.system(size: 48, weight: .heavy, design: .monospaced))
                    .foregroundStyle(BrandColors.secondary.opacity(0.85))
                    .scaleEffect(letterScale)
                    .blur(radius: blurAmount)
                    .animation(.spring(response: 0.3, dampingFraction: 0.72), value: letterScale)
                    .animation(.spring(response: 0.3, dampingFraction: 0.72), value: blurAmount)
            }

            VStack(alignment: .leading, spacing: 8) {
                // Acuity bar
                VStack(alignment: .leading, spacing: 4) {
                    Text("Agudeza")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.secondary)

                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(Color.secondary.opacity(0.12))
                                .frame(height: 8)
                            // 20/200 = worst → 0%, 20/10 = best → 100%
                            let pct = CGFloat(1.0 - (denominator - 10) / 190.0)
                            Capsule()
                                .fill(acuityColor.opacity(0.8))
                                .frame(width: geo.size.width * min(max(pct, 0), 1), height: 8)
                                .animation(.spring(response: 0.35), value: pct)
                        }
                    }
                    .frame(height: 8)
                }

                // Status label
                HStack(spacing: 6) {
                    Circle()
                        .fill(acuityColor)
                        .frame(width: 8, height: 8)
                    Text(acuityLabel)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(acuityColor)
                }
                .animation(.easeInOut(duration: 0.2), value: value)

                Text(value)
                    .font(.system(size: 22, weight: .bold, design: .monospaced))
                    .foregroundStyle(BrandColors.secondary)
                    .contentTransition(.numericText())
            }
            Spacer()
        }
        .frame(height: 90)
    }

    private var acuityLabel: String {
        if denominator <= 15 { return "Visión superior" }
        if denominator <= 20 { return "Visión normal" }
        if denominator <= 40 { return "Visión reducida" }
        if denominator <= 70 { return "Visión baja" }
        return "Visión muy baja"
    }
}

// MARK: - Near Acuity Preview

private struct _NearAcuityPreview: View {
    let value: String

    private var meters: Double {
        Double(value.replacingOccurrences(of: "m", with: "")) ?? 1.0
    }

    var body: some View {
        HStack(spacing: 0) {
            // Eye
            VStack(spacing: 4) {
                Image(systemName: "eye.fill")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(BrandColors.primary.opacity(0.8))
                Text("Ojo")
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundStyle(.secondary)
            }

            // Distance ruler
            GeometryReader { geo in
                ZStack {
                    // Track
                    Capsule()
                        .fill(Color.secondary.opacity(0.12))
                        .frame(height: 6)

                    // Tick marks
                    HStack(spacing: 0) {
                        ForEach(0..<8, id: \.self) { i in
                            Spacer()
                            if i < 7 {
                                Rectangle()
                                    .fill(Color.secondary.opacity(0.25))
                                    .frame(width: 1, height: 12)
                            }
                        }
                    }

                    // Filled track
                    HStack {
                        Capsule()
                            .fill(BrandColors.primary.opacity(0.55))
                            .frame(width: geo.size.width * CGFloat(meters / 2.0), height: 6)
                            .animation(.spring(response: 0.35, dampingFraction: 0.68), value: meters)
                        Spacer(minLength: 0)
                    }

                    // Draggable dot
                    HStack {
                        Circle()
                            .fill(BrandColors.primary)
                            .frame(width: 18, height: 18)
                            .shadow(color: BrandColors.primary.opacity(0.35), radius: 4, y: 2)
                            .overlay(
                                Text(value)
                                    .font(.system(size: 7, weight: .bold))
                                    .foregroundStyle(.white)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.5)
                                    .padding(2)
                            )
                            .offset(x: geo.size.width * CGFloat(meters / 2.0) - 9)
                            .animation(.spring(response: 0.35, dampingFraction: 0.68), value: meters)
                        Spacer(minLength: 0)
                    }
                }
                .frame(maxHeight: .infinity, alignment: .center)
            }
            .frame(height: 36)
            .padding(.horizontal, 12)

            // Book
            VStack(spacing: 4) {
                Image(systemName: "text.book.closed.fill")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(BrandColors.secondary.opacity(0.75))
                Text("Lectura")
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 4)
        .frame(height: 70)
    }
}

// MARK: - SPH Preview

private struct _SPHPreview: View {
    let value: String

    private var sph: Double {
        Double(value) ?? 0
    }

    // bow: positive = biconvex, negative = biconcave, 0 = flat circle
    private var bow: CGFloat {
        CGFloat(sph / 15.0) // normalized -1..+1
    }

    var body: some View {
        HStack(spacing: 20) {
            // Lens cross-section
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.black.opacity(0.04))
                    .frame(width: 80, height: 80)

                // Lens shape
                _LensShape(bow: bow)
                    .fill(BrandColors.primary.opacity(0.12))
                    .frame(width: 52, height: 52)
                    .animation(.spring(response: 0.3, dampingFraction: 0.72), value: bow)

                _LensShape(bow: bow)
                    .stroke(BrandColors.primary.opacity(0.7), lineWidth: 1.8)
                    .frame(width: 52, height: 52)
                    .animation(.spring(response: 0.3, dampingFraction: 0.72), value: bow)

                // Light rays (arrows)
                _LightRays(sph: sph)
                    .frame(width: 80, height: 80)
                    .animation(.spring(response: 0.3), value: sph)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text(sph >= 0 ? "Hipermetropía" : "Miopía")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .animation(.easeInOut(duration: 0.2), value: sph >= 0)

                Text(value)
                    .font(.system(size: 26, weight: .bold, design: .monospaced))
                    .foregroundStyle(sph == 0 ? Color.secondary : (sph > 0 ? BrandColors.primary : BrandColors.secondary))
                    .contentTransition(.numericText())

                Text(sph == 0 ? "Sin corrección esférica" : (sph > 0 ? "Lente convergente +" : "Lente divergente"))
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                    .animation(.easeInOut(duration: 0.2), value: sph)
            }
            Spacer()
        }
        .frame(height: 90)
    }
}

// Custom lens cross-section shape
private struct _LensShape: Shape {
    var bow: CGFloat // -1 = max concave, +1 = max convex

    var animatableData: CGFloat {
        get { bow }
        set { bow = newValue }
    }

    func path(in rect: CGRect) -> Path {
        var p = Path()
        let cx = rect.midX
        let cy = rect.midY
        let r = min(rect.width, rect.height) / 2
        let bowing = bow * r * 0.85

        // Left point → right point with top arc
        p.move(to: CGPoint(x: cx - r, y: cy))
        p.addQuadCurve(
            to: CGPoint(x: cx + r, y: cy),
            control: CGPoint(x: cx, y: cy - r - bowing)
        )
        // Right → left with bottom arc (mirrored)
        p.addQuadCurve(
            to: CGPoint(x: cx - r, y: cy),
            control: CGPoint(x: cx, y: cy + r + bowing)
        )
        p.closeSubpath()
        return p
    }
}

// Light ray arrows around the lens
private struct _LightRays: View {
    let sph: Double

    var body: some View {
        GeometryReader { geo in
            let cx = geo.size.width / 2
            let cy = geo.size.height / 2
            let converge = sph > 0 // positive = converging rays

            // Draw 3 horizontal ray lines
            ForEach([0.28, 0.5, 0.72], id: \.self) { frac in
                let y = geo.size.height * frac
                let offset = (frac - 0.5) * (converge ? 1 : -1) * CGFloat(min(abs(sph) / 15.0, 1.0)) * 12

                // Incoming ray (left side)
                Path { p in
                    p.move(to: CGPoint(x: 0, y: y))
                    p.addLine(to: CGPoint(x: cx - 28, y: y))
                }
                .stroke(BrandColors.accent.opacity(0.5), style: StrokeStyle(lineWidth: 1.2, dash: [3, 2]))

                // Outgoing ray (right side, angled for convergence/divergence)
                Path { p in
                    p.move(to: CGPoint(x: cx + 28, y: y))
                    p.addLine(to: CGPoint(x: geo.size.width, y: y + offset))
                }
                .stroke(BrandColors.accent.opacity(0.5), style: StrokeStyle(lineWidth: 1.2, dash: [3, 2]))
            }
        }
    }
}

// MARK: - CYL Preview

private struct _CYLPreview: View {
    let value: String

    private var cylMag: Double {
        abs(Double(value) ?? 0) // 0..12
    }

    // 0 → circle, 12 → very elongated oval
    private var widthFactor: CGFloat {
        CGFloat(1.0 + cylMag / 8.0) // 1.0 to 2.5
    }

    private var heightFactor: CGFloat {
        1.0 / widthFactor
    }

    var body: some View {
        HStack(spacing: 20) {
            // Eye with pupil
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.black.opacity(0.04))
                    .frame(width: 80, height: 80)

                // Sclera (white of eye)
                Ellipse()
                    .fill(Color.white)
                    .frame(width: 68, height: 44)
                    .shadow(color: .black.opacity(0.06), radius: 3)

                // Iris
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [BrandColors.primary.opacity(0.5), BrandColors.secondary.opacity(0.7)],
                            center: .center, startRadius: 0, endRadius: 16
                        )
                    )
                    .frame(width: 32, height: 32)

                // Pupil — elongates with CYL
                Ellipse()
                    .fill(Color.black.opacity(0.85))
                    .frame(
                        width: 14 * widthFactor,
                        height: 14 * heightFactor
                    )
                    .animation(.spring(response: 0.3, dampingFraction: 0.72), value: widthFactor)

                // Eyelids
                Ellipse()
                    .stroke(BrandColors.secondary.opacity(0.35), lineWidth: 1.5)
                    .frame(width: 68, height: 44)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Astigmatismo")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)

                Text(value)
                    .font(.system(size: 26, weight: .bold, design: .monospaced))
                    .foregroundStyle(cylMag == 0 ? Color.secondary : BrandColors.secondary)
                    .contentTransition(.numericText())

                Text(cylMag == 0 ? "Sin astigmatismo" : cylMag <= 2 ? "Astigmatismo leve" : cylMag <= 4 ? "Moderado" : "Severo")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                    .animation(.easeInOut(duration: 0.2), value: cylMag)
            }
            Spacer()
        }
        .frame(height: 90)
    }
}

// MARK: - ADD Preview

private struct _ADDPreview: View {
    let value: String

    private var addValue: Double {
        Double(value.replacingOccurrences(of: "+", with: "")) ?? 0
    }

    private var ringCount: Int {
        max(1, Int(addValue / 0.75)) // 1 ring at +0.75, up to 4 at +3.00
    }

    var body: some View {
        HStack(spacing: 20) {
            // Magnifying glass with rings
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.black.opacity(0.04))
                    .frame(width: 80, height: 80)

                // Concentric rings
                ForEach(0..<4, id: \.self) { i in
                    let size = CGFloat(20 + i * 12)
                    Circle()
                        .stroke(
                            BrandColors.primary.opacity(i < ringCount ? 0.7 - Double(i) * 0.12 : 0.08),
                            lineWidth: i < ringCount ? 2.0 : 1.0
                        )
                        .frame(width: size, height: size)
                        .animation(.spring(response: 0.35, dampingFraction: 0.7).delay(Double(i) * 0.04), value: ringCount)
                }

                // Center dot
                Circle()
                    .fill(BrandColors.primary.opacity(0.8))
                    .frame(width: 8, height: 8)

                // Magnifier handle
                Rectangle()
                    .fill(BrandColors.secondary.opacity(0.5))
                    .frame(width: 3, height: 14)
                    .cornerRadius(2)
                    .rotationEffect(.degrees(45))
                    .offset(x: 20, y: 20)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Adición (presbicia)")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)

                Text(value)
                    .font(.system(size: 26, weight: .bold, design: .monospaced))
                    .foregroundStyle(BrandColors.primary)
                    .contentTransition(.numericText())

                Text(addValue <= 1.0 ? "Presbicia inicial" : addValue <= 2.0 ? "Presbicia moderada" : "Presbicia avanzada")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                    .animation(.easeInOut(duration: 0.2), value: addValue)
            }
            Spacer()
        }
        .frame(height: 90)
    }
}

// MARK: - Axis Indicators

private struct _AxisMiniIndicator: View {
    var degrees: Double

    var body: some View {
        ZStack {
            Circle()
                .stroke(BrandColors.accent.opacity(0.3), lineWidth: 1.2)
            Capsule()
                .fill(BrandColors.primary.opacity(0.85))
                .frame(width: 1.5, height: 14)
                .rotationEffect(.degrees(degrees))
        }
    }
}

private struct _AxisLargeIndicator: View {
    let degrees: Double
    let label: String

    // 4 quadrant arcs to give the full circle context
    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                // Outer ring
                Circle()
                    .stroke(BrandColors.accent.opacity(0.18), lineWidth: 2)
                    .frame(width: 120, height: 120)

                // Degree marks
                ForEach([0, 45, 90, 135], id: \.self) { deg in
                    Capsule()
                        .fill(Color.secondary.opacity(0.2))
                        .frame(width: 1, height: 10)
                        .offset(y: -55)
                        .rotationEffect(.degrees(Double(deg)))
                }

                // 0°, 90°, 180° labels
                ForEach([(0.0, CGPoint(x: 0, y: -50)),
                         (90.0, CGPoint(x: 50, y: 0)),
                         (180.0, CGPoint(x: 0, y: 50))], id: \.0) { item in
                    Text("\(Int(item.0))°")
                        .font(.system(size: 8, weight: .semibold, design: .monospaced))
                        .foregroundStyle(Color.secondary.opacity(0.5))
                        .offset(x: item.1.x, y: item.1.y)
                }

                // Inner fill
                Circle()
                    .fill(BrandColors.primary.opacity(0.05))
                    .frame(width: 96, height: 96)

                // The axis needle (with spring animation)
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [BrandColors.primary, BrandColors.secondary],
                            startPoint: .top, endPoint: .bottom
                        )
                    )
                    .frame(width: 3, height: 80)
                    .shadow(color: BrandColors.primary.opacity(0.4), radius: 4)
                    .rotationEffect(.degrees(degrees))
                    .animation(.spring(response: 0.28, dampingFraction: 0.62), value: degrees)

                // Center knob
                Circle()
                    .fill(BrandColors.primary)
                    .frame(width: 10, height: 10)
                    .shadow(color: BrandColors.primary.opacity(0.5), radius: 3)

                // Value badge
                Text(label)
                    .font(.system(size: 13, weight: .bold, design: .monospaced))
                    .foregroundStyle(BrandColors.primary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(BrandColors.primary.opacity(0.10))
                    .clipShape(Capsule())
                    .offset(y: 70)
            }
            .frame(width: 120, height: 150)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Option generators

enum VisionOptions {

    static let distantAcuity: [String] = [
        "20/200", "20/100", "20/70", "20/50", "20/40",
        "20/30", "20/25", "20/20", "20/15", "20/13", "20/10"
    ]

    static let nearAcuity: [String] = [
        "0.5m", "0.75m", "1m", "1.25m", "1.50m", "1.75m", "2.00m"
    ]

    static let sph: [String] = stride(from: -15.0, through: 15.0, by: 0.25).map { val in
        let sign = val >= 0 ? "+" : ""
        return String(format: "\(sign)%.2f", val)
    }

    static let cyl: [String] = stride(from: -12.0, through: 0.0, by: 0.25).map { val in
        let sign = val >= 0 ? "+" : ""
        return String(format: "\(sign)%.2f", val)
    }

    static let add: [String] = ["—"] + stride(from: 0.75, through: 3.0, by: 0.25).map { val in
        String(format: "+%.2f", val)
    }
}

