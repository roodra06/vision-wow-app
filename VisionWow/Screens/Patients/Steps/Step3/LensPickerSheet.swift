import SwiftUI

// MARK: - Mica shape (lente óptico real: rectangular con esquinas redondeadas y leve convexidad en top/bottom)
private struct LensShape: Shape {
    /// Radio de esquinas. Para lentes pequeñas usa ~22, para grandes ~32.
    var cornerRadius: CGFloat = 26
    /// Cuánto se bombean hacia afuera los bordes superior e inferior (0 = plano, 6 = convexo leve).
    var bow: CGFloat = 5

    func path(in rect: CGRect) -> Path {
        let cr = min(cornerRadius, rect.height / 2, rect.width / 2)
        var p = Path()

        // ── Arista superior: de top-left arc → quad → top-right arc
        p.move(to: CGPoint(x: rect.minX + cr, y: rect.minY))
        p.addQuadCurve(
            to:      CGPoint(x: rect.maxX - cr, y: rect.minY),
            control: CGPoint(x: rect.midX, y: rect.minY - bow)   // convexidad hacia arriba
        )
        // esquina superior derecha
        p.addArc(center: CGPoint(x: rect.maxX - cr, y: rect.minY + cr),
                 radius: cr, startAngle: .degrees(-90), endAngle: .degrees(0), clockwise: false)

        // ── Arista derecha (recta)
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - cr))

        // esquina inferior derecha
        p.addArc(center: CGPoint(x: rect.maxX - cr, y: rect.maxY - cr),
                 radius: cr, startAngle: .degrees(0), endAngle: .degrees(90), clockwise: false)

        // ── Arista inferior: quad convexo hacia abajo
        p.addQuadCurve(
            to:      CGPoint(x: rect.minX + cr, y: rect.maxY),
            control: CGPoint(x: rect.midX, y: rect.maxY + bow)   // convexidad hacia abajo
        )
        // esquina inferior izquierda
        p.addArc(center: CGPoint(x: rect.minX + cr, y: rect.maxY - cr),
                 radius: cr, startAngle: .degrees(90), endAngle: .degrees(180), clockwise: false)

        // ── Arista izquierda (recta)
        p.addLine(to: CGPoint(x: rect.minX, y: rect.minY + cr))

        // esquina superior izquierda
        p.addArc(center: CGPoint(x: rect.minX + cr, y: rect.minY + cr),
                 radius: cr, startAngle: .degrees(180), endAngle: .degrees(270), clockwise: false)

        p.closeSubpath()
        return p
    }
}

// MARK: - Enums

enum LensCategory: String, CaseIterable {
    case visionSencilla = "Visión Sencilla"
    case bifocales      = "Bifocales"
    case progresivas    = "Progresivas"
    case soloArmazon    = "Solo Armazón"

    var subtitle: String {
        switch self {
        case .visionSencilla: return "Corrige miopía, visión intermedia o hipermetropía"
        case .bifocales:      return "Dos zonas de visión: lejos y cerca en una sola mica"
        case .progresivas:    return "Corrige múltiples campos visuales: cercano, intermedio y distante"
        case .soloArmazon:    return "Micas Demo · Sin logo, grabado, graduación ni tratamientos"
        }
    }

    var assetImage: String {
        switch self {
        case .visionSencilla: return "mica-sencilla"
        case .bifocales:      return "mica-bifocal"
        case .progresivas:    return "progresivos"
        case .soloArmazon:    return "armazon"
        }
    }
}

enum FrameType: String, CaseIterable {
    case blanco         = "Tipo Blanco"
    case rosa           = "Tipo Rosa"
    case morado         = "Tipo Morado"
    case moradoConClip  = "Tipo Morado con Clip"
    case armazonDeMarca = "Armazón de Marca"

    var salePrice: Int {
        switch self {
        case .blanco:         return 450
        case .rosa:           return 800
        case .morado:         return 1200
        case .moradoConClip:  return 1500
        case .armazonDeMarca: return 0   // precio ingresado por usuario
        }
    }

    var costPrice: Int {
        switch self {
        case .blanco:         return 100
        case .rosa:           return 200
        case .morado:         return 300
        case .moradoConClip:  return 350
        case .armazonDeMarca: return 0   // costo ingresado por usuario
        }
    }

    var frameDescription: String {
        switch self {
        case .blanco:         return "Armazón básico · Ligero y resistente"
        case .rosa:           return "Armazón estándar · Estilo moderno"
        case .morado:         return "Armazón premium · Acabado de calidad"
        case .moradoConClip:  return "Armazón premium · Incluye clip solar magnético"
        case .armazonDeMarca: return "Ingresa la marca y precio de venta"
        }
    }
}

enum MicaType: String, CaseIterable {
    case transparente = "Transparente"
    case transitions  = "Transitions"
    case blue         = "Blue"

    var subtitle: String {
        switch self {
        case .transparente: return "Micas clásicas transparentes"
        case .transitions:  return "Micas inteligentes que reaccionan a la luz solar"
        case .blue:         return "Filtra la luz azul-violeta de pantallas y del sol"
        }
    }

    var assetImage: String {
        switch self {
        case .transparente: return "mica-transparente"
        case .transitions:  return "mica-transition"
        case .blue:         return "mica-blue"
        }
    }
}

enum TransitionColor: String, CaseIterable {
    case blue      = "Blue"
    case amber     = "Amber"
    case rubi      = "Rubí"
    case esmeralda = "Esmeralda"

    var assetImage: String {
        switch self {
        case .blue:      return "transition-blue"
        case .amber:     return "transition-amber"
        case .rubi:      return "transition-rubi"
        case .esmeralda: return "transition-esmeralda"
        }
    }
}

enum LensThickness: String, CaseIterable {
    case delgado = "Delgado"
    case grueso  = "Grueso"

    var subtitle: String {
        switch self {
        case .delgado: return "Menor peso · Mejor apariencia estética · Índice alto"
        case .grueso:  return "Mayor resistencia · Ideal para prescripciones bajas"
        }
    }
}

enum LensWizardStep {
    case category
    case frameType
    case brandFrameDetails   // solo cuando se elige Armazón de Marca
    case micaType
    case transitionColor
    case thickness
    case detail
}

// MARK: - Price Tables

// MARK: - Precio base de mica por categoría + tipo + grosor
// Modifica estos valores para ajustar tu lista de precios.
// Los Transitions tienen precio diferente por color: blue/amber = precio base, rubi/esmeralda = +$200.
private func micaPrice(
    category: LensCategory,
    mica: MicaType,
    color: TransitionColor?,
    thickness: LensThickness
) -> Int {
    let colorSurcharge: Int = (color == .rubi || color == .esmeralda) ? 200 : 0

    switch (category, mica, thickness) {
    // ── Visión Sencilla ──────────────────────────────────────────
    case (.visionSencilla, .transparente, .delgado): return 850
    case (.visionSencilla, .transparente, .grueso):  return 650
    case (.visionSencilla, .blue, .delgado):         return 1200
    case (.visionSencilla, .blue, .grueso):          return 950
    case (.visionSencilla, .transitions, .delgado):  return 1800 + colorSurcharge
    case (.visionSencilla, .transitions, .grueso):   return 1500 + colorSurcharge

    // ── Bifocales ────────────────────────────────────────────────
    case (.bifocales, .transparente, .delgado): return 1400
    case (.bifocales, .transparente, .grueso):  return 1100
    case (.bifocales, .blue, .delgado):         return 1900
    case (.bifocales, .blue, .grueso):          return 1500
    case (.bifocales, .transitions, .delgado):  return 2800 + colorSurcharge
    case (.bifocales, .transitions, .grueso):   return 2300 + colorSurcharge

    // ── Progresivas ──────────────────────────────────────────────
    case (.progresivas, .transparente, .delgado): return 2400
    case (.progresivas, .transparente, .grueso):  return 1900
    case (.progresivas, .blue, .delgado):         return 2900
    case (.progresivas, .blue, .grueso):          return 2400
    case (.progresivas, .transitions, .delgado):  return 3800 + colorSurcharge
    case (.progresivas, .transitions, .grueso):   return 3200 + colorSurcharge

    default: return 0
    }
}

// Precio base de mica sin grosor (para mostrar referencia en la card de tipo de mica).
// Usa grosor delgado como referencia "desde".
private func micaBasePrice(category: LensCategory, mica: MicaType) -> Int {
    micaPrice(category: category, mica: mica, color: nil, thickness: .delgado)
}

// Diferencia de precio entre mica delgada y gruesa (para mostrar en la card de grosor).
private func thicknessDelta(category: LensCategory, mica: MicaType, color: TransitionColor?) -> (delgado: Int, grueso: Int) {
    let d = micaPrice(category: category, mica: mica, color: color, thickness: .delgado)
    let g = micaPrice(category: category, mica: mica, color: color, thickness: .grueso)
    return (d, g)
}

private func formattedPrice(_ value: Int) -> String {
    let formatter = NumberFormatter()
    formatter.numberStyle = .decimal
    formatter.groupingSeparator = ","
    return "$\(formatter.string(from: NSNumber(value: value)) ?? "\(value)") MXN"
}

/// Badge que aparece en cada card: "Incluido" si no hay cargo extra, "+$X,XXX" si hay incremento.
/// `base` = precio de la opción más barata/base, `current` = precio de esta opción.
private func priceBadge(base: Int, current: Int) -> String {
    if base == 0 { return formattedPrice(current) }
    let delta = current - base
    if delta <= 0 { return "Incluido" }
    let formatter = NumberFormatter()
    formatter.numberStyle = .decimal
    formatter.groupingSeparator = ","
    let str = formatter.string(from: NSNumber(value: delta)) ?? "\(delta)"
    return "+$\(str)"
}

/// True si el badge indica que no hay costo extra (muestra en gris, no en acento).
private func isIncluded(base: Int, current: Int) -> Bool {
    current <= base || base == 0
}

// MARK: - Sheet

struct LensPickerSheet: View {
    @Binding var lensType: String
    @Binding var lensCost: String
    var onDismiss: () -> Void

    @State private var step: LensWizardStep = .category
    @State private var isGoingForward = true
    @State private var selectedCategory: LensCategory? = nil
    @State private var selectedFrame: FrameType? = nil
    @State private var selectedMica: MicaType? = nil
    @State private var selectedColor: TransitionColor? = nil
    @State private var selectedThickness: LensThickness? = nil

    // Armazón de Marca
    @State private var brandName: String = ""
    @State private var brandSalePrice: String = ""
    @State private var brandCostPrice: String = ""

    @Environment(\.dismiss) private var dismiss

    // MARK: - Step metadata

    private var stepTitle: String {
        switch step {
        case .category:          return "Tipo de lente"
        case .frameType:         return "Tipo de armazón"
        case .brandFrameDetails: return "Datos del armazón"
        case .micaType:          return "Tipo de mica"
        case .transitionColor:   return "Color Transitions"
        case .thickness:         return "Grosor de mica"
        case .detail:            return "Resumen del pedido"
        }
    }

    private var stepSubtitle: String {
        switch step {
        case .category:          return "Selecciona la categoría que necesita el paciente"
        case .frameType:         return "Elige el armazón para el paciente"
        case .brandFrameDetails: return "Ingresa la marca, precio de venta y costo del armazón"
        case .micaType:          return "Elige el tipo de tratamiento para las micas"
        case .transitionColor:   return "Selecciona el color de tu mica Transitions"
        case .thickness:         return "Define el grosor de la mica"
        case .detail:            return "Verifica el desglose antes de confirmar"
        }
    }

    // MARK: - Navigation

    private var canGoBack: Bool { step != .category }

    private func goBack() {
        isGoingForward = false
        withAnimation(.easeInOut(duration: 0.26)) {
            switch step {
            case .frameType:
                step = .category
            case .brandFrameDetails:
                step = .frameType
            case .micaType:
                step = selectedFrame == .armazonDeMarca ? .brandFrameDetails : .frameType
            case .transitionColor:
                step = .micaType
            case .thickness:
                step = selectedMica == .transitions ? .transitionColor : .micaType
            case .detail:
                if selectedCategory == .soloArmazon {
                    step = selectedFrame == .armazonDeMarca ? .brandFrameDetails : .frameType
                } else {
                    step = .thickness
                }
            default: break
            }
        }
    }

    private func advance() {
        isGoingForward = true
        switch step {
        case .category:
            withAnimation(.easeInOut(duration: 0.26)) { step = .frameType }

        case .frameType:
            guard let frame = selectedFrame else { return }
            withAnimation(.easeInOut(duration: 0.26)) {
                if frame == .armazonDeMarca {
                    step = .brandFrameDetails
                } else if selectedCategory == .soloArmazon {
                    step = .detail
                } else {
                    step = .micaType
                }
            }

        case .brandFrameDetails:
            withAnimation(.easeInOut(duration: 0.26)) {
                step = selectedCategory == .soloArmazon ? .detail : .micaType
            }

        case .micaType:
            withAnimation(.easeInOut(duration: 0.26)) {
                step = selectedMica == .transitions ? .transitionColor : .thickness
            }

        case .transitionColor:
            withAnimation(.easeInOut(duration: 0.26)) { step = .thickness }

        case .thickness:
            withAnimation(.easeInOut(duration: 0.26)) { step = .detail }

        case .detail:
            confirmSelection()
        }
    }

    private var nextEnabled: Bool {
        switch step {
        case .category:          return selectedCategory != nil
        case .frameType:         return selectedFrame != nil
        case .brandFrameDetails:
            return !brandName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                && !brandSalePrice.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        case .micaType:          return selectedMica != nil
        case .transitionColor:   return selectedColor != nil
        case .thickness:         return selectedThickness != nil
        case .detail:            return true
        }
    }

    private var nextLabel: String {
        step == .detail ? "Confirmar" : "Siguiente"
    }

    // MARK: - Result builder

    private var currentFrameSalePrice: Int {
        guard let frame = selectedFrame else { return 0 }
        if frame == .armazonDeMarca { return Int(brandSalePrice) ?? 0 }
        return frame.salePrice
    }

    private var currentFrameCostPrice: Int {
        guard let frame = selectedFrame else { return 0 }
        if frame == .armazonDeMarca { return Int(brandCostPrice) ?? 0 }
        return frame.costPrice
    }

    private var currentMicaPrice: Int {
        guard let cat = selectedCategory, let mica = selectedMica, let thick = selectedThickness else { return 0 }
        return micaPrice(category: cat, mica: mica, color: selectedColor, thickness: thick)
    }

    private var totalSalePrice: Int { currentFrameSalePrice + currentMicaPrice }

    private func confirmSelection() {
        guard let cat = selectedCategory, let frame = selectedFrame else { return }

        var frameName: String
        if frame == .armazonDeMarca {
            frameName = "Armazón de Marca · \(brandName)"
        } else {
            frameName = frame.rawValue
        }

        var result: String
        if cat == .soloArmazon {
            result = "Solo Armazón · \(frameName) · \(formattedPrice(currentFrameSalePrice))"
        } else if let mica = selectedMica, let thick = selectedThickness {
            let colorStr = selectedColor.map { " \($0.rawValue)" } ?? ""
            let micaLabel = mica == .transitions ? "Transitions\(colorStr)" : mica.rawValue
            result = "\(cat.rawValue) · \(frameName) · \(micaLabel) · \(thick.rawValue) · \(formattedPrice(totalSalePrice))"
        } else {
            return
        }

        lensType = result
        lensCost = "\(currentFrameCostPrice)"
        dismiss()
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                BrandColors.backgroundGradient
                .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        Text(stepSubtitle)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 20)
                            .padding(.top, 4)

                        Group {
                            switch step {
                            case .category:          categoryStep
                            case .frameType:         frameTypeStep
                            case .brandFrameDetails: brandFrameDetailsStep
                            case .micaType:          micaTypeStep
                            case .transitionColor:   transitionColorStep
                            case .thickness:         thicknessStep
                            case .detail:            detailStep
                            }
                        }
                        .id(step)
                        .transition(
                            isGoingForward
                            ? .asymmetric(
                                insertion: .move(edge: .trailing).combined(with: .opacity),
                                removal: .move(edge: .leading).combined(with: .opacity)
                              )
                            : .asymmetric(
                                insertion: .move(edge: .leading).combined(with: .opacity),
                                removal: .move(edge: .trailing).combined(with: .opacity)
                              )
                        )
                        .padding(.horizontal, 20)

                        Color.clear.frame(height: 90)
                    }
                    .padding(.top, 8)
                }

                // Bottom buttons
                VStack(spacing: 0) {
                    Divider()
                    HStack(spacing: 12) {
                        if canGoBack {
                            Button(action: goBack) {
                                HStack(spacing: 6) {
                                    Image(systemName: "chevron.left")
                                        .font(.system(size: 14, weight: .semibold))
                                    Text("Atrás")
                                        .font(.system(size: 15, weight: .semibold))
                                }
                                .foregroundStyle(BrandColors.secondary)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 14)
                                .background(
                                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                                        .fill(BrandColors.soft.opacity(0.7))
                                )
                            }
                        }

                        PrimaryButton(title: nextLabel) {
                            advance()
                        }
                        .disabled(!nextEnabled)
                        .opacity(nextEnabled ? 1 : 0.45)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 14)
                    .background(BrandColors.cardFill.opacity(0.97))
                }
            }
            .navigationTitle(stepTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { dismiss() }
                        .foregroundStyle(BrandColors.secondary)
                }
            }
        }
        .presentationDetents([.fraction(1.0)])
        .presentationDragIndicator(.visible)
    }

    // MARK: - Step Views

    private var categoryStep: some View {
        VStack(spacing: 12) {
            // Preview animado de la categoría seleccionada
            if let cat = selectedCategory {
                LensCategoryPreview(category: cat)
                    .id(cat)
                    .transition(.opacity.combined(with: .scale(scale: 0.96)))
            }

            ForEach(LensCategory.allCases, id: \.self) { cat in
                OptionCard(
                    assetImage: cat.assetImage,
                    title: cat.rawValue,
                    subtitle: cat.subtitle,
                    isSelected: selectedCategory == cat
                ) {
                    withAnimation(.spring(response: 0.38, dampingFraction: 0.80)) {
                        selectedCategory = cat
                    }
                    selectedFrame = nil
                    selectedMica = nil
                    selectedColor = nil
                    selectedThickness = nil
                }
            }
        }
    }

    private var frameTypeStep: some View {
        VStack(spacing: 12) {
            ForEach(FrameType.allCases, id: \.self) { frame in
                OptionCard(
                    assetImage: "armazon",
                    title: frame.rawValue,
                    subtitle: frame.frameDescription,
                    badge: frame == .armazonDeMarca ? nil : formattedPrice(frame.salePrice),
                    isSelected: selectedFrame == frame
                ) {
                    selectedFrame = frame
                    if frame != .armazonDeMarca {
                        brandName = ""
                        brandSalePrice = ""
                        brandCostPrice = ""
                    }
                }
            }
        }
    }

    private var brandFrameDetailsStep: some View {
        VStack(spacing: 16) {
            VStack(spacing: 12) {
                brandField(label: "Marca del armazón", placeholder: "Ej. Ray-Ban, Oakley…",
                           text: $brandName, keyboardType: .default)
                Divider().opacity(0.4)
                brandField(label: "Precio de venta", placeholder: "0.00",
                           text: $brandSalePrice, keyboardType: .decimalPad)
                Divider().opacity(0.4)
                brandField(label: "Costo (precio de stock)", placeholder: "0.00 (opcional)",
                           text: $brandCostPrice, keyboardType: .decimalPad)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(BrandColors.cardFill)
                    .shadow(color: BrandColors.secondary.opacity(0.08), radius: 10, x: 0, y: 4)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(BrandColors.accent.opacity(0.18), lineWidth: 1)
            )
        }
    }

    private func brandField(label: String, placeholder: String,
                            text: Binding<String>, keyboardType: UIKeyboardType) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            TextField(placeholder, text: text)
                .keyboardType(keyboardType)
                .font(.system(size: 15))
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(BrandColors.fieldBackground)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
    }

    private var micaTypeStep: some View {
        // Referencia: precio transparente delgado como base ("Incluido")
        let cat = selectedCategory ?? .visionSencilla
        let baseRef = micaBasePrice(category: cat, mica: .transparente)
        return VStack(spacing: 12) {
            LensAnimatedPreview(
                mica: selectedMica ?? .transparente,
                transitionColor: selectedColor
            )
            .id(selectedMica)

            ForEach(MicaType.allCases, id: \.self) { mica in
                let price = micaBasePrice(category: cat, mica: mica)
                let badge = priceBadge(base: baseRef, current: price)
                let neutral = isIncluded(base: baseRef, current: price)
                OptionCard(
                    assetImage: mica.assetImage,
                    title: mica.rawValue,
                    subtitle: mica.subtitle,
                    badge: badge,
                    badgeIsNeutral: neutral,
                    isSelected: selectedMica == mica
                ) {
                    withAnimation(.spring(response: 0.42, dampingFraction: 0.78)) {
                        selectedMica = mica
                    }
                    selectedColor = nil
                    selectedThickness = nil
                }
            }
        }
    }

    private var transitionColorStep: some View {
        // Blue y Amber son el precio base; Rubí y Esmeralda tienen +$200
        let cat = selectedCategory ?? .visionSencilla
        let baseRef = micaPrice(category: cat, mica: .transitions, color: .blue, thickness: .delgado)
        return VStack(spacing: 12) {
            LensAnimatedPreview(
                mica: .transitions,
                transitionColor: selectedColor ?? .blue
            )
            .id(selectedColor)

            ForEach(TransitionColor.allCases, id: \.self) { color in
                let price = micaPrice(category: cat, mica: .transitions, color: color, thickness: .delgado)
                let badge = priceBadge(base: baseRef, current: price)
                let neutral = isIncluded(base: baseRef, current: price)
                OptionCard(
                    assetImage: color.assetImage,
                    title: color.rawValue,
                    subtitle: "",
                    badge: badge,
                    badgeIsNeutral: neutral,
                    isSelected: selectedColor == color
                ) {
                    withAnimation(.spring(response: 0.42, dampingFraction: 0.78)) {
                        selectedColor = color
                    }
                }
            }
        }
    }

    private var thicknessStep: some View {
        let cat = selectedCategory ?? .visionSencilla
        let mica = selectedMica ?? .transparente
        let prices = thicknessDelta(category: cat, mica: mica, color: selectedColor)
        let baseRef = min(prices.delgado, prices.grueso)   // el menor es "Incluido"
        return VStack(spacing: 12) {
            ForEach(LensThickness.allCases, id: \.self) { thick in
                let price = thick == .delgado ? prices.delgado : prices.grueso
                let badge = priceBadge(base: baseRef, current: price)
                let neutral = isIncluded(base: baseRef, current: price)
                OptionCard(
                    assetImage: "grosor-micas",
                    title: thick.rawValue,
                    subtitle: thick.subtitle,
                    badge: badge,
                    badgeIsNeutral: neutral,
                    isSelected: selectedThickness == thick
                ) {
                    selectedThickness = thick
                }
            }
        }
    }

    // MARK: - Detail Step (desglose)

    private var detailStep: some View {
        VStack(spacing: 16) {
            VStack(spacing: 0) {
                // Categoría
                detailRow(label: "Categoría", value: selectedCategory?.rawValue ?? "—")
                Divider().opacity(0.5)

                // Armazón
                if let frame = selectedFrame {
                    let frameName = frame == .armazonDeMarca
                        ? "Armazón de Marca · \(brandName)"
                        : frame.rawValue
                    detailRow(label: "Armazón", value: frameName)
                    Divider().opacity(0.5)
                    detailRow(label: "Precio armazón",
                              value: formattedPrice(currentFrameSalePrice),
                              bold: false)
                    Divider().opacity(0.5)
                    if currentFrameCostPrice > 0 {
                        detailRow(label: "Costo armazón",
                                  value: formattedPrice(currentFrameCostPrice),
                                  secondary: true)
                        Divider().opacity(0.5)
                    }
                }

                // Mica (si aplica)
                if selectedCategory != .soloArmazon, let mica = selectedMica, let thick = selectedThickness {
                    let colorStr = selectedColor.map { " \($0.rawValue)" } ?? ""
                    let micaLabel = mica == .transitions ? "Transitions\(colorStr) · \(thick.rawValue)" : "\(mica.rawValue) · \(thick.rawValue)"
                    detailRow(label: "Mica", value: micaLabel)
                    Divider().opacity(0.5)
                    detailRow(label: "Precio mica",
                              value: formattedPrice(currentMicaPrice),
                              bold: false)
                    Divider().opacity(0.5)
                }

                // Total
                detailRow(label: "Total de venta",
                          value: formattedPrice(totalSalePrice),
                          bold: true, accent: true)
            }
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(BrandColors.cardFill)
                    .shadow(color: BrandColors.secondary.opacity(0.08), radius: 10, x: 0, y: 4)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(BrandColors.accent.opacity(0.18), lineWidth: 1)
            )

            Text("Los precios son estimados y pueden variar según la prescripción del paciente.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 8)
        }
    }

    private func detailRow(label: String, value: String,
                           bold: Bool = false, accent: Bool = false, secondary: Bool = false) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 14))
                .foregroundStyle(secondary ? Color.secondary.opacity(0.7) : .secondary)
            Spacer()
            Text(value)
                .font(.system(size: 14, weight: bold ? .bold : .medium))
                .foregroundStyle(accent ? BrandColors.primary : secondary ? Color.secondary.opacity(0.7) : .primary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 13)
    }
}

// MARK: - Option Card

private struct OptionCard: View {
    var assetImage: String? = nil
    var icon: String = ""
    let title: String
    let subtitle: String
    var badge: String? = nil
    /// true = badge se muestra en gris ("Incluido"), false = badge en acento ("+$XXX")
    var badgeIsNeutral: Bool = true
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(isSelected ? BrandColors.primary.opacity(0.15) : BrandColors.soft.opacity(0.4))
                        .frame(width: 74, height: 74)
                    if let name = assetImage {
                        Image(name)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 74, height: 74)
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .stroke(isSelected ? BrandColors.primary.opacity(0.5) : Color.clear, lineWidth: 2)
                            )
                    } else {
                        Image(systemName: icon)
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundStyle(isSelected ? .white : BrandColors.secondary)
                    }
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(isSelected ? BrandColors.primary : .primary)
                    if !subtitle.isEmpty {
                        Text(subtitle)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                    }
                }

                Spacer(minLength: 0)

                if let badge = badge {
                    Text(badge)
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(badgeIsNeutral ? Color.secondary : BrandColors.accent)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(badgeIsNeutral
                                      ? Color.secondary.opacity(0.10)
                                      : BrandColors.accent.opacity(0.12))
                        )
                }

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 20))
                    .foregroundStyle(isSelected ? BrandColors.primary : Color.secondary.opacity(0.4))
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(isSelected ? BrandColors.primary.opacity(0.12) : BrandColors.cardFill)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(
                        isSelected ? BrandColors.primary.opacity(0.55) : BrandColors.accent.opacity(0.20),
                        lineWidth: isSelected ? 1.5 : 1
                    )
            )
            .shadow(color: BrandColors.secondary.opacity(isSelected ? 0.10 : 0.04), radius: 8, x: 0, y: 3)
        }
        .buttonStyle(BounceButtonStyle())
        .animation(.easeOut(duration: 0.18), value: isSelected)
    }
}

// MARK: - Lens Animated Preview

private struct LensAnimatedPreview: View {
    let mica: MicaType
    let transitionColor: TransitionColor?

    // Dimensiones de la mica (forma lente óptica)
    private let lensW: CGFloat = 150
    private let lensH: CGFloat = 92

    @State private var shimmerX: CGFloat = -160
    @State private var blueGlow: CGFloat = 0.18
    // 0 = interior (claro) · 100 = exterior (oscuro)
    @State private var transitionValue: Double = 0

    private var isOutdoor: Bool { transitionValue >= 50 }

    var body: some View {
        VStack(spacing: 12) {

            // ── Mica en forma de lente ──────────────────────────────
            ZStack {
                // Base fill
                LensShape()
                    .fill(baseFill)

                // Overlay de oscurecimiento para Transitions (opacidad = 0…1)
                if mica == .transitions {
                    LensShape()
                        .fill(
                            RadialGradient(
                                colors: [transitionTint.opacity(0.85), transitionTint.opacity(0.45)],
                                center: UnitPoint(x: 0.3, y: 0.25),
                                startRadius: 4, endRadius: 60
                            )
                        )
                        .opacity(transitionValue / 100)
                        .animation(.easeInOut(duration: 0.18), value: transitionValue)
                }

                // Brillo especular (esquina superior izquierda)
                Ellipse()
                    .fill(Color.white.opacity(0.55))
                    .frame(width: 36, height: 16)
                    .offset(x: -30, y: -22)
                    .blur(radius: 3)

                // Borde de la mica
                LensShape()
                    .stroke(lensBorderColor, lineWidth: 2)
                    .animation(.easeInOut(duration: 0.18), value: transitionValue)

                // Transparente: shimmer sweep
                if mica == .transparente {
                    LinearGradient(
                        stops: [
                            .init(color: .clear,               location: 0.35),
                            .init(color: .white.opacity(0.75), location: 0.48),
                            .init(color: .white.opacity(0.92), location: 0.50),
                            .init(color: .white.opacity(0.75), location: 0.52),
                            .init(color: .clear,               location: 0.65)
                        ],
                        startPoint: .leading, endPoint: .trailing
                    )
                    .frame(width: lensW * 1.4, height: lensH * 1.4)
                    .rotationEffect(.degrees(20))
                    .offset(x: shimmerX)
                }

                // Blue: glow pulsante
                if mica == .blue {
                    LensShape()
                        .stroke(Color(red: 0.35, green: 0.65, blue: 1.0).opacity(blueGlow), lineWidth: 10)
                        .blur(radius: 5)
                }
            }
            .frame(width: lensW, height: lensH)
            .clipShape(LensShape())
            .shadow(color: lensBorderColor.opacity(0.35), radius: 12, x: 0, y: 5)

            // ── Slider de oscurecimiento (solo Transitions) ─────────
            if mica == .transitions {
                transitionSlider
                    .padding(.horizontal, 8)
                    .padding(.top, 2)
            }

            // ── Caption ────────────────────────────────────────────
            Text(previewCaption)
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 12)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(BrandColors.cardFill.opacity(0.88))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(BrandColors.accent.opacity(0.22), lineWidth: 1)
                )
        )
        .shadow(color: BrandColors.secondary.opacity(0.07), radius: 12, x: 0, y: 5)
        .onAppear { startAnimations() }
    }

    // MARK: - Slider control

    private var transitionSlider: some View {
        VStack(spacing: 6) {
            // Etiquetas extremos
            HStack {
                Label("Interior", systemImage: "moon.fill")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(BrandColors.secondary)
                Spacer()
                Text("\(Int(transitionValue))")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundStyle(BrandColors.accent)
                Spacer()
                Label("Exterior", systemImage: "sun.max.fill")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.orange)
            }

            // Barra degradada claro → tint de la mica
            ZStack {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.90),
                                transitionTint.opacity(0.95)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(height: 12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .stroke(transitionTint.opacity(0.30), lineWidth: 1)
                    )

                Slider(value: $transitionValue, in: 0...100, step: 1)
                    .tint(transitionTint)
            }

            // Estado legible
            Text(transitionValue < 15  ? "Interior · Clara" :
                 transitionValue < 45  ? "Semiosccura"      :
                 transitionValue < 75  ? "Oscureciendo"     : "Exterior · Oscura")
                .font(.caption2)
                .foregroundStyle(.secondary)
                .animation(.none, value: transitionValue)
        }
    }

    // MARK: - Computed

    private var baseFill: some ShapeStyle {
        RadialGradient(
            colors: [
                lensTint.opacity(mica == .transparente ? 0.18 : 0.55),
                Color(white: 0.96).opacity(0.85)
            ],
            center: UnitPoint(x: 0.3, y: 0.25),
            startRadius: 4, endRadius: 60
        )
    }

    private var lensTint: Color {
        switch mica {
        case .transparente: return Color.white
        case .blue:         return Color(red: 0.55, green: 0.78, blue: 1.0)
        case .transitions:  return transitionTint
        }
    }

    private var transitionTint: Color {
        switch transitionColor {
        case .blue:      return Color(red: 0.35, green: 0.60, blue: 0.95)
        case .amber:     return Color(red: 0.90, green: 0.68, blue: 0.20)
        case .rubi:      return Color(red: 0.85, green: 0.22, blue: 0.32)
        case .esmeralda: return Color(red: 0.18, green: 0.72, blue: 0.48)
        case nil:        return Color(red: 0.35, green: 0.60, blue: 0.95)
        }
    }

    private var lensBorderColor: Color {
        switch mica {
        case .transparente: return BrandColors.accent.opacity(0.35)
        case .blue:         return Color(red: 0.35, green: 0.65, blue: 1.0).opacity(0.50)
        case .transitions:
            let pct = transitionValue / 100
            return transitionTint.opacity(0.30 + pct * 0.35)
        }
    }

    private var previewCaption: String {
        switch mica {
        case .transparente: return "Mica clásica · Sin tratamiento de color"
        case .blue:         return "Filtra hasta el 40% de luz azul-violeta"
        case .transitions:  return "Desliza para simular la reacción al sol"
        }
    }

    // MARK: - Animations

    private func startAnimations() {
        if mica == .transparente {
            shimmerX = -160
            withAnimation(.linear(duration: 1.8).repeatForever(autoreverses: false)) {
                shimmerX = 160
            }
        }
        if mica == .blue {
            withAnimation(.easeInOut(duration: 1.3).repeatForever(autoreverses: true)) {
                blueGlow = 0.52
            }
        }
    }
}

// MARK: - Lens Category Animated Preview

private struct LensCategoryPreview: View {
    let category: LensCategory

    private let lensW: CGFloat = 150
    private let lensH: CGFloat = 92

    // Visión Sencilla — punto focal pulsante
    @State private var focusPulse: CGFloat = 1.0
    @State private var focusGlow: CGFloat  = 0.40

    // Bifocales — brillo de la línea divisoria
    @State private var lineGlow: CGFloat   = 0.30

    // Progresivas — scanner de zona
    @State private var scanOffset: CGFloat = -30
    @State private var scanOpacity: Double = 0.0

    // Solo Armazón — giro del gradiente de borde
    @State private var borderPhase: CGFloat = 0

    var body: some View {
        VStack(spacing: 10) {
            ZStack {
                lensContent
            }
            .frame(width: lensW, height: lensH)
            .clipShape(LensShape())
            .shadow(color: BrandColors.accent.opacity(0.25), radius: 12, x: 0, y: 5)
            .overlay(LensShape().stroke(BrandColors.accent.opacity(0.35), lineWidth: 2))

            Text(caption)
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 12)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(BrandColors.cardFill.opacity(0.88))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(BrandColors.accent.opacity(0.22), lineWidth: 1)
                )
        )
        .shadow(color: BrandColors.secondary.opacity(0.07), radius: 12, x: 0, y: 5)
        .onAppear { startAnimations() }
    }

    // MARK: - Content per category

    @ViewBuilder
    private var lensContent: some View {
        switch category {

        // ── Visión Sencilla ── base clara + punto focal pulsante central
        case .visionSencilla:
            // base
            LensShape().fill(
                RadialGradient(
                    colors: [Color(red: 0.88, green: 0.95, blue: 1.0).opacity(0.85),
                             Color.white.opacity(0.50)],
                    center: .center, startRadius: 0, endRadius: 60
                )
            )
            // anillo de glow
            Circle()
                .stroke(BrandColors.accent.opacity(focusGlow), lineWidth: 10)
                .frame(width: 38 * focusPulse, height: 38 * focusPulse)
                .blur(radius: 4)
            // punto central
            Circle()
                .fill(BrandColors.primary.opacity(0.75))
                .frame(width: 8, height: 8)
                .scaleEffect(focusPulse)
            // cruz sutil
            Rectangle().fill(BrandColors.accent.opacity(0.20)).frame(width: 28, height: 1)
            Rectangle().fill(BrandColors.accent.opacity(0.20)).frame(width: 1, height: 18)

        // ── Bifocales ── dos zonas + línea divisoria animada
        case .bifocales:
            // zona superior (lejos) — azul muy suave
            Rectangle()
                .fill(Color(red: 0.80, green: 0.92, blue: 1.0).opacity(0.55))
                .frame(height: lensH / 2)
                .offset(y: -lensH / 4)
            // zona inferior (cerca) — rosa muy suave
            Rectangle()
                .fill(BrandColors.soft.opacity(0.55))
                .frame(height: lensH / 2)
                .offset(y: lensH / 4)
            // línea divisoria
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [BrandColors.primary.opacity(lineGlow),
                                 BrandColors.accent.opacity(lineGlow * 0.8),
                                 BrandColors.primary.opacity(lineGlow)],
                        startPoint: .leading, endPoint: .trailing
                    )
                )
                .frame(height: 2)
            // etiquetas de zona
            VStack {
                Text("L").font(.system(size: 9, weight: .bold)).foregroundStyle(Color(red: 0.35, green: 0.60, blue: 0.90).opacity(0.65))
                Spacer()
                Text("C").font(.system(size: 9, weight: .bold)).foregroundStyle(BrandColors.primary.opacity(0.55))
            }
            .padding(.vertical, 6)

        // ── Progresivas ── 3 zonas con scanner
        case .progresivas:
            // Fondo de 3 zonas
            LensShape().fill(
                LinearGradient(
                    colors: [
                        Color(red: 0.76, green: 0.90, blue: 1.0).opacity(0.80),  // lejos  (azul)
                        Color(red: 0.88, green: 0.80, blue: 1.0).opacity(0.65),  // intermedio (lila)
                        BrandColors.soft.opacity(0.75)                            // cerca  (rosa)
                    ],
                    startPoint: .top, endPoint: .bottom
                )
            )
            // scanner horizontal animado
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [.clear, Color.white.opacity(0.70), .clear],
                        startPoint: .leading, endPoint: .trailing
                    )
                )
                .frame(height: 14)
                .offset(y: scanOffset)
                .opacity(scanOpacity)
            // etiquetas de zona
            VStack {
                Text("∞").font(.system(size: 9, weight: .semibold)).foregroundStyle(Color(red: 0.30, green: 0.55, blue: 0.85).opacity(0.70))
                Spacer()
                Text("60°").font(.system(size: 9, weight: .semibold)).foregroundStyle(Color(red: 0.55, green: 0.35, blue: 0.85).opacity(0.60))
                Spacer()
                Text("↙").font(.system(size: 9, weight: .semibold)).foregroundStyle(BrandColors.primary.opacity(0.60))
            }
            .padding(.vertical, 6)

        // ── Solo Armazón ── solo el contorno
        case .soloArmazon:
            // interior transparente con reflejo
            LensShape().fill(Color(red: 0.96, green: 0.92, blue: 0.98).opacity(0.30))
            // contorno con glow
            LensShape()
                .stroke(BrandColors.secondary.opacity(0.55 + 0.2 * borderPhase), lineWidth: 5)
                .blur(radius: 2)
            LensShape()
                .stroke(BrandColors.strokeGradient, lineWidth: 3)
            // texto
            Text("Armazón")
                .font(.system(size: 9, weight: .bold))
                .foregroundStyle(BrandColors.secondary.opacity(0.60))
        }
    }

    // MARK: - Captions

    private var caption: String {
        switch category {
        case .visionSencilla: return "Un solo punto focal · Lejos o cerca"
        case .bifocales:      return "Zona superior (lejos) + zona inferior (cerca)"
        case .progresivas:    return "Transición suave · Lejos → Intermedio → Cerca"
        case .soloArmazon:    return "Solo el armazón · Sin mica graduada"
        }
    }

    // MARK: - Animations

    private func startAnimations() {
        switch category {
        case .visionSencilla:
            withAnimation(.easeInOut(duration: 1.1).repeatForever(autoreverses: true)) {
                focusPulse = 1.30
                focusGlow  = 0.72
            }

        case .bifocales:
            withAnimation(.easeInOut(duration: 1.4).repeatForever(autoreverses: true)) {
                lineGlow = 0.80
            }

        case .progresivas:
            scanOffset  = -lensH / 2 + 10
            scanOpacity = 0.0
            withAnimation(.linear(duration: 2.2).repeatForever(autoreverses: false)) {
                scanOffset  = lensH / 2 - 10
                scanOpacity = 0.85
            }

        case .soloArmazon:
            withAnimation(.easeInOut(duration: 1.8).repeatForever(autoreverses: true)) {
                borderPhase = 1.0
            }
        }
    }
}
