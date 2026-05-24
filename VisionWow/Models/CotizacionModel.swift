//
//  CotizacionModel.swift
//  VisionWow — Módulo de Cotizaciones
//

import Foundation

// MARK: - Paquetes

enum Paquete: String, CaseIterable, Codable {
    case esencial       = "Esencial"
    case plus           = "Plus"
    case wowCorporativo = "Wow Corporativo"
    case servicioDiario = "Servicio Diario"
    case personalizado  = "Personalizado"

    var precio: Double {
        switch self {
        case .esencial:       return 150
        case .plus:           return 750
        case .wowCorporativo: return 1_500
        case .servicioDiario: return 2_500   // tarifa plana por DÍA, no por persona
        case .personalizado:  return 0       // calculado desde PaquetePersonalizado
        }
    }

    var descripcion: String {
        switch self {
        case .esencial:       return "Examen visual básico + reporte digital"
        case .plus:           return "Examen completo + lentes básicos + reporte"
        case .wowCorporativo: return "Examen premium + armazón + lentes + atención prioritaria"
        case .servicioDiario: return "Uso de material por día · Solo examen visual · Sin reporte a RH"
        case .personalizado:  return "Servicio configurado a la medida del cliente"
        }
    }

    var etiquetaCorta: String { rawValue }

    // MARK: - Desglose de componentes por persona

    /// Costo del examen visual por persona
    var costoExamen: Double {
        switch self {
        case .esencial, .plus, .wowCorporativo, .servicioDiario: return 150
        case .personalizado: return 0   // depende de la opción elegida
        }
    }

    /// Costo del armazón por persona
    var costoArmazon: Double {
        switch self {
        case .esencial:       return 0
        case .plus:           return 400
        case .wowCorporativo: return 850
        case .servicioDiario, .personalizado: return 0
        }
    }

    /// Costo de micas por persona
    var costoMicas: Double {
        switch self {
        case .esencial:       return 0
        case .plus:           return 200
        case .wowCorporativo: return 500
        case .servicioDiario, .personalizado: return 0
        }
    }
}

// MARK: - Paquete Personalizado (componentes à la carte)

/// Nivel de examen visual incluido en el paquete
enum OpcionExamen: String, CaseIterable, Codable {
    case basico   = "Examen Básico"
    case completo = "Examen Completo"
    case premium  = "Examen Premium"

    var precio: Double {
        switch self {
        case .basico:   return 150
        case .completo: return 750
        case .premium:  return 1_500
        }
    }

    var descripcion: String {
        switch self {
        case .basico:   return "Agudeza visual, refracción y reporte digital"
        case .completo: return "Examen integral, tonometría, fondo de ojo y reporte"
        case .premium:  return "Examen avanzado, análisis completo y atención prioritaria"
        }
    }
}

/// Tipo de armazón a incluir (ninguno = sin cargo)
enum OpcionArmazon: String, CaseIterable, Codable {
    case ninguno     = "Sin armazón"
    case blanco      = "Armazón Tipo Blanco"
    case rosa        = "Armazón Tipo Rosa"
    case morado      = "Armazón Tipo Morado"
    case moradoClip  = "Armazón con Clip Solar"

    var precio: Double {
        switch self {
        case .ninguno:    return 0
        case .blanco:     return 450
        case .rosa:       return 800
        case .morado:     return 1_200
        case .moradoClip: return 1_500
        }
    }

    var descripcion: String {
        switch self {
        case .ninguno:    return "No se incluye armazón en el paquete"
        case .blanco:     return "Armazón básico · Ligero y resistente"
        case .rosa:       return "Armazón estándar · Estilo moderno"
        case .morado:     return "Armazón premium · Acabado de calidad"
        case .moradoClip: return "Armazón premium · Clip solar magnético incluido"
        }
    }
}

/// Tipo de micas y tratamiento a incluir (ninguno = sin cargo)
enum OpcionMicas: String, CaseIterable, Codable {
    case ninguna              = "Sin micas"
    case sencillaTransparente = "V. Sencilla Transparente"
    case sencillaBlue         = "V. Sencilla Blue-Ray"
    case sencillaTransitions  = "V. Sencilla Transitions"
    case bifocalesTransparente = "Bifocales Transparentes"
    case bifocalesBlue        = "Bifocales Blue-Ray"
    case bifocalesTransitions = "Bifocales Transitions"
    case progresivasTransparente = "Progresivas Transparentes"
    case progresivasBlue      = "Progresivas Blue-Ray"
    case progresivasTransitions = "Progresivas Transitions"

    var precio: Double {
        switch self {
        case .ninguna:                return 0
        case .sencillaTransparente:   return 850
        case .sencillaBlue:           return 1_200
        case .sencillaTransitions:    return 1_800
        case .bifocalesTransparente:  return 1_400
        case .bifocalesBlue:          return 1_900
        case .bifocalesTransitions:   return 2_800
        case .progresivasTransparente: return 2_400
        case .progresivasBlue:        return 2_900
        case .progresivasTransitions: return 3_800
        }
    }

    var descripcion: String {
        switch self {
        case .ninguna:                return "No se incluyen micas en el paquete"
        case .sencillaTransparente:   return "CR-39 · Micas clásicas · Visión lejana o cercana"
        case .sencillaBlue:           return "Filtro anti luz azul-violeta de pantallas y LED"
        case .sencillaTransitions:    return "Se oscurecen automáticamente con la luz solar"
        case .bifocalesTransparente:  return "Dos zonas de visión: lejos y cerca en una mica"
        case .bifocalesBlue:          return "Bifocal con filtro anti luz azul"
        case .bifocalesTransitions:   return "Bifocal que reacciona a la luz solar"
        case .progresivasTransparente: return "Corrección multifocal: lejos, intermedio y cerca"
        case .progresivasBlue:        return "Progresiva con filtro anti luz azul"
        case .progresivasTransitions: return "Progresiva que reacciona a la luz solar"
        }
    }

    /// Categoría para agrupar en la UI
    var categoria: String {
        switch self {
        case .ninguna:                                           return "Sin micas"
        case .sencillaTransparente, .sencillaBlue,
             .sencillaTransitions:                              return "Visión Sencilla"
        case .bifocalesTransparente, .bifocalesBlue,
             .bifocalesTransitions:                             return "Bifocales"
        case .progresivasTransparente, .progresivasBlue,
             .progresivasTransitions:                           return "Progresivas"
        }
    }
}

// MARK: - Micas con tratamientos combinables

enum BaseMica: String, CaseIterable, Codable {
    case ninguna    = "Sin micas"
    case sencilla   = "Visión Sencilla"
    case bifocal    = "Bifocal"
    case progresiva = "Progresiva"

    var precioBase: Double {
        switch self {
        case .ninguna:    return 0
        case .sencilla:   return 850
        case .bifocal:    return 1_400
        case .progresiva: return 2_400
        }
    }

    var descripcion: String {
        switch self {
        case .ninguna:    return "No se incluyen micas"
        case .sencilla:   return "Corrección monofocal · lejos o cerca"
        case .bifocal:    return "Dos zonas de visión: lejos y cerca"
        case .progresiva: return "Corrección multifocal: lejos, intermedio y cerca"
        }
    }
}

enum TratamientoMica: String, CaseIterable, Codable {
    case blueRay = "Blue-Ray"
    case foto    = "Fotosensible"

    func precioExtra(para base: BaseMica) -> Double {
        switch (self, base) {
        case (.blueRay, .sencilla):   return 350
        case (.blueRay, .bifocal):    return 500
        case (.blueRay, .progresiva): return 500
        case (.foto,    .sencilla):   return 950
        case (.foto,    .bifocal):    return 1_400
        case (.foto,    .progresiva): return 1_400
        default:                      return 0
        }
    }

    var descripcion: String {
        switch self {
        case .blueRay: return "Filtro anti luz azul-violeta de pantallas y LED"
        case .foto:    return "Se oscurecen automáticamente con la luz solar"
        }
    }
}

// MARK: - Día de campaña con horario propio

struct DiaServicio: Codable {
    var fecha: Date
    var horarioInicio: Date
    var horarioFin: Date
}

// MARK: - Paquete Personalizado

struct PaquetePersonalizado: Codable {
    // Examen siempre incluido a $150 — no es configurable
    var armazon:           OpcionArmazon   = .ninguno
    var baseMica:          BaseMica        = .ninguna
    var tratamientosMica:  [TratamientoMica] = []

    var precioMicas: Double {
        guard baseMica != .ninguna else { return 0 }
        return baseMica.precioBase + tratamientosMica.reduce(0) { $0 + $1.precioExtra(para: baseMica) }
    }

    var descripcionMicas: String {
        guard baseMica != .ninguna else { return "Sin micas" }
        var partes = [baseMica.rawValue]
        partes.append(contentsOf: tratamientosMica.map { $0.rawValue })
        return partes.joined(separator: " + ")
    }

    var precioUnitario: Double {
        150 + armazon.precio + precioMicas   // examen visual siempre $150
    }

    /// Descripción corta para PDF y resumen
    var descripcionCompleta: String {
        var partes = ["Examen Visual Completo $150"]
        if armazon != .ninguno { partes.append(armazon.rawValue) }
        if baseMica != .ninguna { partes.append(descripcionMicas) }
        return partes.joined(separator: " + ")
    }
}

// MARK: - Método de pago

enum MetodoPago: String, CaseIterable, Codable {
    case transferencia = "Transferencia bancaria"
    case efectivo      = "Efectivo"
    case tarjeta       = "Tarjeta"
}

// MARK: - Cotización

struct Cotizacion: Codable, Identifiable {
    var id: UUID       = UUID()
    var folio: String
    var fechaEmision: Date = Date()
    var fechaVigencia: Date

    // Datos del servicio
    var cliente: Cliente
    var paquete: Paquete
    var numeroColaboradores: Int

    // Descuentos e IVA
    var codigoPromo: String  // "ABRIL2026" aplica 10%
    var aplicarIVA:  Bool    // emitir factura — suma IVA 16%

    // Campos operativos
    var fechaCampana:      Date        // fecha propuesta del servicio (primer día)
    var fechasAdicionales: [Date] = [] // fechas de días extra cuando el servicio abarca varios días
    var horarioInicio:     Date    // hora de inicio del servicio
    var horarioFin:        Date    // hora de fin del servicio
    var lugarSede:         String  // nombre del lugar o sede
    var direccionServicio: String  // dirección completa del lugar
    var observaciones:     String  // notas adicionales

    // Forma de pago
    var metodoPago: MetodoPago

    // Componentes del paquete personalizado (solo cuando paquete == .personalizado)
    var componentesPersonalizados: PaquetePersonalizado?

    // Ejecutivo que genera la cotización
    var nombreEjecutivo: String   // nombre de quien cotiza
    var cargoEjecutivo:  String   // cargo dentro de Vission Wow
    var firmaEjecutivo:  Data?    // PNG de su firma digital

    // Firma del cliente (se captura al aceptar la cotización)
    var firmaCliente:    Data?    // PNG de la firma del cliente

    // Optometristas y días adicionales de campaña
    var optometristasExtras: Int = 0       // extras más allá del cálculo automático
    var diasAdicionales: [DiaServicio] = [] // días 2, 3, … cada uno con su propio horario
    var pagoPorDia: Bool = false            // SD: opción de cobrar día a día en lugar de 50/50

    // MARK: - Helpers de pago

    var esEfectivo: Bool { metodoPago == .efectivo }

    // MARK: - Cálculos de jornada y optometristas (R5)

    /// Minutos totales de la jornada, con tope de 8 horas (480 min)
    var minutosJornada: Int {
        let mins = Int(horarioFin.timeIntervalSince(horarioInicio) / 60)
        return max(1, min(mins, 480))
    }

    /// ¿La jornada configurada supera el límite de 8 horas?
    var jornadaExcede8Horas: Bool {
        Int(horarioFin.timeIntervalSince(horarioInicio) / 60) > 480
    }

    /// Exámenes que puede hacer un optometrista en la jornada
    /// (restamos 60 min de comida; 1 examen cada 20 min)
    var examenesPerOptometristaPorDia: Int {
        let minutosEfectivos = max(1, minutosJornada - 60)
        return max(1, minutosEfectivos / 20)
    }

    /// Optometristas incluidos gratis: 1 por cada 30 colaboradores, mínimo 1.
    /// Aplica igual para todos los paquetes, incluyendo Servicio Diario.
    var optometristasGratis: Int {
        max(1, Int(ceil(Double(numeroColaboradores) / 30.0)))
    }

    /// Total de optometristas asignados al servicio
    var totalOptometristasAsignados: Int {
        optometristasGratis + optometristasExtras
    }

    /// Días necesarios con la configuración actual
    var diasNecesariosCalculados: Int {
        let examenesXDia = totalOptometristasAsignados * examenesPerOptometristaPorDia
        return Int(ceil(Double(numeroColaboradores) / Double(max(1, examenesXDia))))
    }

    /// Costo extra por optometristas adicionales
    /// (para Servicio Diario los extras ya están incluidos en el subtotal → 0)
    var costoOptometristasExtras: Double {
        if paquete == .servicioDiario { return 0 }
        return Double(optometristasExtras) * 2_500
    }

    // MARK: - Cálculos automáticos

    var subtotal: Double {
        if paquete == .servicioDiario {
            // días necesarios × total optometristas por día × $2,500
            return Double(diasNecesariosCalculados) * Double(totalOptometristasAsignados) * 2_500
        }
        if paquete == .personalizado, let custom = componentesPersonalizados {
            return Double(numeroColaboradores) * custom.precioUnitario
        }
        return Double(numeroColaboradores) * paquete.precio
    }

    /// Precio por colaborador (útil para mostrar en UI y PDF)
    var precioPorColaborador: Double {
        if paquete == .servicioDiario { return 0 }
        if paquete == .personalizado, let custom = componentesPersonalizados {
            return custom.precioUnitario
        }
        return paquete.precio
    }

    var descuentoPromoAplicado: Bool {
        codigoPromo.trimmingCharacters(in: .whitespaces).uppercased() == "ABRIL2026"
    }

    var montoDescuentoPromo: Double {
        descuentoPromoAplicado ? subtotal * 0.10 : 0
    }

    var totalAntesIVA: Double {
        subtotal - montoDescuentoPromo
    }

    /// IVA 16% sobre bienes (armazón + micas) y servicios facturables, nunca en efectivo
    var montoIVA: Double {
        guard aplicarIVA && !esEfectivo else { return 0 }
        let costoA: Double
        let costoM: Double
        if paquete == .personalizado, let custom = componentesPersonalizados {
            costoA = custom.armazon.precio
            costoM = custom.precioMicas
        } else {
            costoA = paquete.costoArmazon
            costoM = paquete.costoMicas
        }
        let bienes = (costoA + costoM) * Double(numeroColaboradores)
        // Para Servicio Diario el costo diario también lleva IVA al facturar
        let servicioBase: Double = paquete == .servicioDiario ? subtotal : 0
        return (bienes + servicioBase + costoOptometristasExtras) * 0.16
    }

    /// ISR retención 10% sobre servicios profesionales, nunca en efectivo
    var montoISRRetencion: Double {
        guard !esEfectivo else { return 0 }
        let costoE: Double = paquete == .personalizado ? 150 : paquete.costoExamen
        let baseExamen = costoE * Double(numeroColaboradores)
        // Para Servicio Diario la base es el costo diario completo
        let baseServicio: Double = paquete == .servicioDiario ? subtotal : 0
        return (baseExamen + baseServicio + costoOptometristasExtras) * 0.10
    }

    var totalFinal: Double {
        totalAntesIVA + montoIVA + costoOptometristasExtras
    }

    // MARK: - Promociones automáticas (R4)

    /// +5 colaboradores → 1 par de lentes gratis para el contacto principal
    var promoBeneficiarioContacto: Bool { numeroColaboradores > 5 }

    /// ≥100 colaboradores → familiares directos reciben armazón + lentes gratis
    var promoBeneficiarioFamilia: Bool { numeroColaboradores >= 100 }

    // MARK: - Estructura de pagos
    // Servicio Diario: 50% inicial + 50% al iniciar labores
    // Otros paquetes:  5% apartar fecha / 65% al iniciar / 30% al finalizar

    var esServicioDiario: Bool { paquete == .servicioDiario }

    /// Primer pago: 5% (otros paquetes) ó 50% (Servicio Diario)
    var pagoApartarFecha: Double {
        esServicioDiario ? totalFinal * 0.50 : totalFinal * 0.05
    }

    /// Segundo pago: 65% al iniciar labores (otros) ó 50% al iniciar (Servicio Diario)
    var anticipo: Double {
        esServicioDiario ? totalFinal * 0.50 : totalFinal * 0.65
    }

    /// Tercer pago: 30% liquidación — solo aplica en paquetes distintos a Servicio Diario
    var liquidacion: Double {
        esServicioDiario ? 0 : totalFinal * 0.30
    }

    /// Costo por día para Servicio Diario (total ÷ días necesarios)
    var costoPorDia: Double {
        guard esServicioDiario, diasNecesariosCalculados > 0 else { return 0 }
        return totalFinal / Double(diasNecesariosCalculados)
    }

    // MARK: - Init

    init(folio: String,
         cliente: Cliente,
         paquete: Paquete,
         numeroColaboradores: Int,
         codigoPromo: String,
         aplicarIVA: Bool,
         fechaCampana: Date        = Date(),
         horarioInicio: Date       = Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: Date()) ?? Date(),
         horarioFin: Date          = Calendar.current.date(bySettingHour: 18, minute: 0, second: 0, of: Date()) ?? Date(),
         lugarSede: String         = "",
         direccionServicio: String = "",
         observaciones: String     = "",
         metodoPago: MetodoPago    = .transferencia,
         nombreEjecutivo: String   = "",
         cargoEjecutivo: String    = "",
         firmaEjecutivo: Data?              = nil,
         firmaCliente:   Data?              = nil,
         componentesPersonalizados: PaquetePersonalizado? = nil,
         optometristasExtras: Int  = 0,
         diasAdicionales: [DiaServicio] = []) {
        self.folio               = folio
        self.cliente             = cliente
        self.paquete             = paquete
        self.numeroColaboradores = max(10, numeroColaboradores)   // R6: mínimo 10
        self.codigoPromo         = codigoPromo
        self.aplicarIVA          = aplicarIVA
        self.fechaCampana        = fechaCampana
        self.horarioInicio       = horarioInicio
        self.horarioFin          = horarioFin
        self.lugarSede           = lugarSede
        self.direccionServicio   = direccionServicio
        self.observaciones       = observaciones
        self.metodoPago          = metodoPago
        self.nombreEjecutivo     = nombreEjecutivo
        self.cargoEjecutivo      = cargoEjecutivo
        self.firmaEjecutivo      = firmaEjecutivo
        self.firmaCliente               = firmaCliente
        self.componentesPersonalizados  = componentesPersonalizados
        self.optometristasExtras        = optometristasExtras
        self.diasAdicionales            = diasAdicionales
        self.fechaVigencia              = Calendar.current
            .date(byAdding: .day, value: 30, to: Date()) ?? Date()
    }
}
