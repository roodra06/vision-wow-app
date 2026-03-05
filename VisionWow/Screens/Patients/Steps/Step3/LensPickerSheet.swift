import SwiftUI

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

    private func advance() {
        switch step {
        case .category:
            // Siempre va primero al armazón
            step = .frameType

        case .frameType:
            guard let frame = selectedFrame else { return }
            if frame == .armazonDeMarca {
                step = .brandFrameDetails
            } else if selectedCategory == .soloArmazon {
                step = .detail
            } else {
                step = .micaType
            }

        case .brandFrameDetails:
            if selectedCategory == .soloArmazon {
                step = .detail
            } else {
                step = .micaType
            }

        case .micaType:
            step = selectedMica == .transitions ? .transitionColor : .thickness

        case .transitionColor:
            step = .thickness

        case .thickness:
            step = .detail

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
                LinearGradient(
                    colors: [
                        BrandColors.primary.opacity(0.06),
                        BrandColors.accent.opacity(0.04),
                        Color.white
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
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
                    .background(Color.white.opacity(0.95))
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
            ForEach(LensCategory.allCases, id: \.self) { cat in
                OptionCard(
                    assetImage: cat.assetImage,
                    title: cat.rawValue,
                    subtitle: cat.subtitle,
                    isSelected: selectedCategory == cat
                ) {
                    selectedCategory = cat
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
                    .fill(Color.white)
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
                .background(Color.black.opacity(0.04))
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
    }

    private var micaTypeStep: some View {
        // Referencia: precio transparente delgado como base ("Incluido")
        let cat = selectedCategory ?? .visionSencilla
        let baseRef = micaBasePrice(category: cat, mica: .transparente)
        return VStack(spacing: 12) {
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
                    selectedMica = mica
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
                    selectedColor = color
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
                    .fill(Color.white)
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
                    .fill(isSelected ? BrandColors.primary.opacity(0.06) : Color.white)
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
        .buttonStyle(.plain)
        .animation(.easeOut(duration: 0.18), value: isSelected)
    }
}
