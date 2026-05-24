//
//  NuevaCotizacionView.swift
//  VisionWow — Módulo de Cotizaciones
//

import SwiftUI
import Combine

// MARK: - ViewModel

final class NuevaCotizacionVM: ObservableObject {

    // Datos del cliente
    @Published var nombreContacto   = ""
    @Published var nombreEmpresa    = ""
    @Published var puesto           = ""
    @Published var telefono         = ""
    @Published var correo           = ""
    @Published var rfc              = ""
    @Published var domicilioFiscal  = ""

    // Paquete y colaboradores
    @Published var paqueteSeleccionado: Paquete = .esencial
    @Published var colaboradoresSlider: Double  = 10   // representa 10–200

    // Opciones del paquete personalizado
    // (examen siempre $150 — no configurable)
    @Published var opcionArmazon:            OpcionArmazon    = .ninguno
    @Published var baseMicaSeleccionada:     BaseMica         = .ninguna
    @Published var tratamientosMicaSel:      [TratamientoMica] = []

    // Datos operativos del servicio
    @Published var fechaCampana: Date      = Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date()
    @Published var horarioInicio: Date     = Calendar.current.date(bySettingHour: 9,  minute: 0, second: 0, of: Date()) ?? Date()
    @Published var horarioFin: Date        = Calendar.current.date(bySettingHour: 18, minute: 0, second: 0, of: Date()) ?? Date()
    @Published var lugarSede         = ""
    @Published var direccionServicio = ""
    @Published var observaciones     = ""

    // Descuentos, IVA y forma de pago
    @Published var codigoPromo            = ""
    @Published var aplicarIVA             = false
    @Published var metodoPago: MetodoPago = .transferencia {
        didSet {
            if metodoPago == .efectivo { aplicarIVA = false }
        }
    }

    // Ejecutivo
    @Published var nombreEjecutivo  = ""
    @Published var cargoEjecutivo   = ""
    @Published var firmaEjecutivo: Data? = nil

    // Optometristas extras (R5)
    @Published var optometristasExtras: Int = 0

    // Días adicionales de campaña (cada uno con su propio horario)
    @Published var diasAdicionales: [DiaServicio] = []

    // Servicio Diario: pagar día a día en lugar de 50/50
    @Published var pagoPorDia: Bool = false

    // MARK: - Derivados

    var colaboradores: Int {
        max(10, min(200, Int(colaboradoresSlider)))   // R6: mínimo 10, máximo 200
    }

    var esEfectivo: Bool { metodoPago == .efectivo }

    var precioMicasPersonalizado: Double {
        guard baseMicaSeleccionada != .ninguna else { return 0 }
        return baseMicaSeleccionada.precioBase
            + tratamientosMicaSel.reduce(0) { $0 + $1.precioExtra(para: baseMicaSeleccionada) }
    }

    var precioPorColaborador: Double {
        if paqueteSeleccionado == .personalizado {
            return 150 + opcionArmazon.precio + precioMicasPersonalizado
        }
        if paqueteSeleccionado == .servicioDiario { return 0 }
        return paqueteSeleccionado.precio
    }

    var subtotal: Double {
        if paqueteSeleccionado == .servicioDiario {
            return Double(diasNecesariosCalculados) * Double(totalOptometristasAsignados) * 2_500
        }
        return Double(colaboradores) * precioPorColaborador
    }

    var codigoPromoValido: Bool {
        codigoPromo.trimmingCharacters(in: .whitespaces).uppercased() == "ABRIL2026"
    }

    var montoDescuentoPromo: Double { codigoPromoValido ? subtotal * 0.10 : 0 }
    var totalAntesIVA:       Double { subtotal - montoDescuentoPromo }

    var montoIVA: Double {
        guard aplicarIVA && !esEfectivo else { return 0 }
        let costoA: Double = paqueteSeleccionado == .personalizado
            ? opcionArmazon.precio : paqueteSeleccionado.costoArmazon
        let costoM: Double = paqueteSeleccionado == .personalizado
            ? precioMicasPersonalizado : paqueteSeleccionado.costoMicas
        let bienes = (costoA + costoM) * Double(colaboradores)
        let servicioBase: Double = paqueteSeleccionado == .servicioDiario ? subtotal : 0
        return (bienes + servicioBase + costoOptometristasExtras) * 0.16
    }

    var montoISRRetencion: Double {
        guard !esEfectivo else { return 0 }
        let costoE: Double = paqueteSeleccionado == .personalizado ? 150 : paqueteSeleccionado.costoExamen
        let baseExamen = costoE * Double(colaboradores)
        let baseServicio: Double = paqueteSeleccionado == .servicioDiario ? subtotal : 0
        return (baseExamen + baseServicio + costoOptometristasExtras) * 0.10
    }

    // R5 — Optometristas
    var minutosJornada: Int {
        let mins = Int(horarioFin.timeIntervalSince(horarioInicio) / 60)
        return max(1, min(mins, 480))  // tope 8h
    }

    var examenesPerOptometristaPorDia: Int {
        let mins = max(1, minutosJornada - 60)
        return max(1, mins / 20)
    }

    var optometristasGratis: Int {
        max(1, Int(ceil(Double(colaboradores) / 30.0)))
    }

    var promoBeneficiarioFamilia: Bool { colaboradores >= 100 }

    var totalOptometristasAsignados: Int {
        optometristasGratis + optometristasExtras
    }

    var diasNecesariosCalculados: Int {
        let examenesXDia = totalOptometristasAsignados * examenesPerOptometristaPorDia
        return Int(ceil(Double(colaboradores) / Double(max(1, examenesXDia))))
    }

    var costoOptometristasExtras: Double {
        if paqueteSeleccionado == .servicioDiario { return 0 }
        return Double(optometristasExtras) * 2_500
    }

    var totalFinal: Double { totalAntesIVA + montoIVA + costoOptometristasExtras }

    var esServicioDiario: Bool { paqueteSeleccionado == .servicioDiario }

    var pagoApartarFecha: Double { esServicioDiario ? totalFinal * 0.50 : totalFinal * 0.05 }
    var anticipo:         Double { esServicioDiario ? totalFinal * 0.50 : totalFinal * 0.65 }
    var liquidacion:      Double { esServicioDiario ? 0                 : totalFinal * 0.30 }

    // R4 — Promociones automáticas
    var promoBeneficiarioContacto: Bool { colaboradores > 5 }

    // MARK: - Validación

    var telefonoValido: Bool { telefono.filter { $0.isNumber }.count == 10 }

    var correoValido: Bool {
        guard !correo.isEmpty else { return false }
        return correo.range(of: #"^[A-Za-z0-9._%+\-]+@[A-Za-z0-9.\-]+\.[A-Za-z]{2,}$"#,
                            options: .regularExpression) != nil
    }

    var formularioValido: Bool {
        !nombreContacto.trimmingCharacters(in: .whitespaces).isEmpty &&
        !nombreEmpresa.trimmingCharacters(in: .whitespaces).isEmpty &&
        telefonoValido && correoValido && colaboradores >= 10
    }

    // MARK: - Modo edición

    /// ID y folio originales — sólo en modo edición
    var cotizacionOriginalID: UUID? = nil
    var folioOriginal: String?      = nil

    var enModoEdicion: Bool { cotizacionOriginalID != nil }

    /// Pre-llena el VM con una cotización existente para editarla
    convenience init(editando cotizacion: Cotizacion) {
        self.init()
        cotizacionOriginalID = cotizacion.id
        folioOriginal        = cotizacion.folio
        // Cliente
        nombreContacto   = cotizacion.cliente.nombreContacto
        nombreEmpresa    = cotizacion.cliente.nombreEmpresa
        puesto           = cotizacion.cliente.puesto
        telefono         = cotizacion.cliente.telefono
        correo           = cotizacion.cliente.correo
        rfc              = cotizacion.cliente.rfc
        domicilioFiscal  = cotizacion.cliente.domicilioFiscal
        // Paquete y colaboradores
        paqueteSeleccionado   = cotizacion.paquete
        colaboradoresSlider   = Double(cotizacion.numeroColaboradores)
        // Operativos
        fechaCampana      = cotizacion.fechaCampana
        horarioInicio     = cotizacion.horarioInicio
        horarioFin        = cotizacion.horarioFin
        lugarSede         = cotizacion.lugarSede
        direccionServicio = cotizacion.direccionServicio
        observaciones     = cotizacion.observaciones
        // Descuentos y pago
        codigoPromo  = cotizacion.codigoPromo
        aplicarIVA   = cotizacion.aplicarIVA
        metodoPago   = cotizacion.metodoPago
        // Ejecutivo
        nombreEjecutivo = cotizacion.nombreEjecutivo
        cargoEjecutivo  = cotizacion.cargoEjecutivo
        firmaEjecutivo  = cotizacion.firmaEjecutivo
        // Paquete personalizado
        if let custom = cotizacion.componentesPersonalizados {
            opcionArmazon           = custom.armazon
            baseMicaSeleccionada    = custom.baseMica
            tratamientosMicaSel     = custom.tratamientosMica
        }
        // R5
        optometristasExtras = cotizacion.optometristasExtras
        diasAdicionales     = cotizacion.diasAdicionales
        pagoPorDia          = cotizacion.pagoPorDia
    }

    // MARK: - Construcción de modelos

    private func uc(_ s: String) -> String { s.trimmingCharacters(in: .whitespaces).uppercased() }

    func construirCliente() -> Cliente {
        Cliente(
            nombreContacto:  uc(nombreContacto),
            nombreEmpresa:   uc(nombreEmpresa),
            puesto:          uc(puesto),
            telefono:        telefono.filter { $0.isNumber },
            correo:          correo.trimmingCharacters(in: .whitespaces),
            rfc:             uc(rfc),
            domicilioFiscal: uc(domicilioFiscal)
        )
    }

    func construirCotizacion(folio: String, id: UUID? = nil) -> Cotizacion {
        let customPkg: PaquetePersonalizado? = paqueteSeleccionado == .personalizado
            ? PaquetePersonalizado(armazon: opcionArmazon,
                                   baseMica: baseMicaSeleccionada,
                                   tratamientosMica: tratamientosMicaSel)
            : nil
        var cot = Cotizacion(
            folio:               folio,
            cliente:             construirCliente(),
            paquete:             paqueteSeleccionado,
            numeroColaboradores: colaboradores,
            codigoPromo:         codigoPromo.trimmingCharacters(in: .whitespaces).uppercased(),
            aplicarIVA:          aplicarIVA,
            fechaCampana:        fechaCampana,
            horarioInicio:       horarioInicio,
            horarioFin:          horarioFin,
            lugarSede:           uc(lugarSede),
            direccionServicio:   uc(direccionServicio),
            observaciones:       uc(observaciones),
            metodoPago:          metodoPago,
            nombreEjecutivo:            uc(nombreEjecutivo),
            cargoEjecutivo:             uc(cargoEjecutivo),
            firmaEjecutivo:             firmaEjecutivo,
            componentesPersonalizados:  customPkg,
            optometristasExtras:        optometristasExtras,
            diasAdicionales:            diasAdicionales
        )
        cot.pagoPorDia = pagoPorDia
        if let id { cot.id = id }
        return cot
    }
}

// MARK: - Vista principal

struct NuevaCotizacionView: View {

    @StateObject private var vm: NuevaCotizacionVM
    @State private var mostrarResumen    = false
    @State private var mostrarAlertaIVA  = false
    @State private var mostrarAlerta8h   = false

    /// Crea una cotización nueva (sin parámetros) o abre una existente en modo edición
    init(editando cotizacion: Cotizacion? = nil) {
        if let cot = cotizacion {
            _vm = StateObject(wrappedValue: NuevaCotizacionVM(editando: cot))
        } else {
            _vm = StateObject(wrappedValue: NuevaCotizacionVM())
        }
    }

    private let mxn: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle           = .currency
        f.currencyCode          = "MXN"
        f.currencySymbol        = "$"
        f.maximumFractionDigits = 2
        return f
    }()

    private func fmt(_ v: Double) -> String { mxn.string(from: NSNumber(value: v)) ?? "$0.00" }

    var body: some View {
        ZStack {
            BrandColors.backgroundGradient.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 16) {
                    seccionCliente
                    seccionPaquete
                    seccionPaquetePersonalizado
                    seccionColaboradores
                    seccionOptometristas
                    seccionDatosServicio
                    seccionObservaciones
                    seccionDescuentos
                    seccionResumen
                    seccionEjecutivo
                    botonContinuar
                }
                .padding(16)
                .padding(.bottom, 32)
            }
        }
        .navigationTitle(vm.enModoEdicion ? "Editar Cotización" : "Nueva Cotización")
        .alert("Jornada máxima: 8 horas", isPresented: $mostrarAlerta8h) {
            Button("Entendido", role: .cancel) { }
        } message: {
            Text("El horario de atención no puede superar 8 horas por día. Se ha ajustado automáticamente al límite permitido.")
        }
        .navigationBarTitleDisplayMode(.inline)
        .alert("Emitir factura", isPresented: $mostrarAlertaIVA) {
            Button("Entendido", role: .cancel) { }
            Button("Cancelar factura", role: .destructive) { vm.aplicarIVA = false }
        } message: {
            Text("Al emitir factura se agrega el IVA del 16% al subtotal. El total aumentará en consecuencia.\n\nEsta acción requiere que el cliente proporcione sus datos fiscales.")
        }
        .navigationDestination(isPresented: $mostrarResumen) {
            let folio = vm.folioOriginal ?? CotizacionStorage.shared.siguienteFolio()
            let cot   = vm.construirCotizacion(folio: folio,
                                               id: vm.cotizacionOriginalID)
            ResumenCotizacionView(cotizacion: cot,
                                  yaGuardada: vm.enModoEdicion,
                                  modoEdicion: vm.enModoEdicion)
        }
    }

    // MARK: - Sección: Datos del cliente

    private var seccionCliente: some View {
        SectionCard(title: "Datos del Cliente", subtitle: "Empresa y contacto principal") {
            VStack(spacing: 12) {
                campoTexto("Nombre de la empresa *",
                           texto: $vm.nombreEmpresa,
                           placeholder: "Ej. Distribuidora Norte SA de CV")

                HStack(spacing: 12) {
                    campoTexto("Contacto *",
                               texto: $vm.nombreContacto,
                               placeholder: "Nombre completo")
                    campoTexto("Puesto / Cargo",
                               texto: $vm.puesto,
                               placeholder: "Ej. Gerente de RH")
                }

                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        campoTexto("Teléfono * (10 dígitos)",
                                   texto: $vm.telefono,
                                   placeholder: "5512345678",
                                   teclado: .phonePad)
                        if !vm.telefono.isEmpty && !vm.telefonoValido {
                            Text("10 dígitos requeridos")
                                .font(.system(size: 10))
                                .foregroundStyle(BrandColors.danger)
                        }
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        campoTexto("Correo electrónico *",
                                   texto: $vm.correo,
                                   placeholder: "contacto@empresa.com",
                                   teclado: .emailAddress)
                        if !vm.correo.isEmpty && !vm.correoValido {
                            Text("Formato inválido")
                                .font(.system(size: 10))
                                .foregroundStyle(BrandColors.danger)
                        }
                    }
                }

                HStack(spacing: 12) {
                    campoTexto("RFC (opcional)",
                               texto: $vm.rfc,
                               placeholder: "ABC123456789")
                    campoTexto("Domicilio fiscal (opcional)",
                               texto: $vm.domicilioFiscal,
                               placeholder: "Calle, colonia, ciudad")
                }
            }
        }
    }

    // MARK: - Sección: Paquete

    private var seccionPaquete: some View {
        SectionCard(title: "Paquete Cotizado", subtitle: "Selecciona el servicio a ofrecer") {
            VStack(spacing: 8) {
                ForEach(Paquete.allCases, id: \.self) { botonPaquete($0) }
            }
        }
    }

    private func botonPaquete(_ paquete: Paquete) -> some View {
        let sel = vm.paqueteSeleccionado == paquete
        return Button { vm.paqueteSeleccionado = paquete } label: {
            HStack {
                // Indicador de selección
                ZStack {
                    Circle()
                        .fill(sel ? Color.white : Color.gray.opacity(0.2))
                        .frame(width: 22, height: 22)
                    if sel {
                        Image(systemName: "checkmark")
                            .font(.system(size: 11, weight: .black))
                            .foregroundStyle(BrandColors.primary)
                    }
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(paquete.rawValue)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(sel ? .white : Color(.label))
                    Text(paquete.descripcion)
                        .font(.system(size: 12))
                        .foregroundStyle(sel ? .white.opacity(0.85) : .secondary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 0) {
                    if paquete == .personalizado {
                        Text(sel && vm.precioPorColaborador > 0
                             ? fmt(vm.precioPorColaborador)
                             : "A medida")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundStyle(sel ? .white : BrandColors.primary)
                        Text(sel && vm.precioPorColaborador > 0 ? "por colaborador" : "configura abajo")
                            .font(.system(size: 10))
                            .foregroundStyle(sel ? .white.opacity(0.75) : .secondary)
                    } else if paquete == .servicioDiario {
                        Text(fmt(paquete.precio))   // ya es $2,500
                            .font(.system(size: 15, weight: .bold))
                            .foregroundStyle(sel ? .white : BrandColors.primary)
                        Text("por día · 1 optometrista")
                            .font(.system(size: 10))
                            .foregroundStyle(sel ? .white.opacity(0.75) : .secondary)
                    } else {
                        Text(fmt(paquete.precio))
                            .font(.system(size: 15, weight: .bold))
                            .foregroundStyle(sel ? .white : BrandColors.primary)
                        Text("por colaborador")
                            .font(.system(size: 10))
                            .foregroundStyle(sel ? .white.opacity(0.75) : .secondary)
                    }
                }
            }
            .padding(14)
            .background(
                sel
                    ? LinearGradient(colors: [BrandColors.primary, BrandColors.secondary],
                                     startPoint: .leading, endPoint: .trailing)
                    : LinearGradient(colors: [BrandColors.fieldBackground, BrandColors.fieldBackground],
                                     startPoint: .leading, endPoint: .trailing)
            )
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(sel ? Color.clear : Color.gray.opacity(0.2), lineWidth: 1))
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.2), value: vm.paqueteSeleccionado)
    }

    // MARK: - Sección: Paquete Personalizado

    @ViewBuilder
    private var seccionPaquetePersonalizado: some View {
        if vm.paqueteSeleccionado == .personalizado {
            SectionCard(title: "Personaliza tu Paquete",
                        subtitle: "Elige exactamente lo que incluye el servicio") {
                VStack(spacing: 20) {

                    // ── Grupo 1: Examen Visual (fijo) ─────────────────────
                    grupoOpciones(
                        titulo: "Examen Visual",
                        icono: "eye.fill",
                        obligatorio: true
                    ) {
                        HStack(spacing: 12) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(BrandColors.primary)
                                .font(.system(size: 20))
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Examen Visual Completo")
                                    .font(.system(size: 14, weight: .semibold))
                                Text("Incluido siempre en el paquete")
                                    .font(.system(size: 12))
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Text(fmt(150))
                                .font(.system(size: 14, weight: .bold))
                                .foregroundStyle(BrandColors.primary)
                            Text("/persona")
                                .font(.system(size: 11))
                                .foregroundStyle(.secondary)
                        }
                        .padding(12)
                        .background(BrandColors.primary.opacity(0.06))
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    }

                    separadorGrupo

                    // ── Grupo 2: Armazón ─────────────────────────────────
                    grupoOpciones(
                        titulo: "Armazón",
                        icono: "eyeglasses",
                        obligatorio: false
                    ) {
                        ForEach(OpcionArmazon.allCases, id: \.self) { op in
                            opcionRow(
                                nombre: op.rawValue,
                                descripcion: op.descripcion,
                                precio: op.precio,
                                seleccionado: vm.opcionArmazon == op,
                                esGratis: op == .ninguno
                            ) { vm.opcionArmazon = op }
                        }
                    }

                    separadorGrupo

                    // ── Grupo 3: Micas — base + tratamientos combinables ──
                    grupoOpciones(
                        titulo: "Tipo de Micas",
                        icono: "sparkles",
                        obligatorio: false
                    ) {
                        // Selector de base
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Tipo de lente")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundStyle(.secondary)
                            ForEach(BaseMica.allCases, id: \.self) { base in
                                opcionRow(
                                    nombre: base.rawValue,
                                    descripcion: base.descripcion,
                                    precio: base.precioBase,
                                    seleccionado: vm.baseMicaSeleccionada == base,
                                    esGratis: base == .ninguna
                                ) { vm.baseMicaSeleccionada = base }
                            }
                        }

                        // Tratamientos adicionales (solo si hay base)
                        if vm.baseMicaSeleccionada != .ninguna {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("TRATAMIENTOS ADICIONALES")
                                    .font(.system(size: 10, weight: .semibold))
                                    .foregroundStyle(BrandColors.primary)
                                    .tracking(1)
                                    .padding(.top, 4)

                                ForEach(TratamientoMica.allCases, id: \.self) { trat in
                                    let seleccionado = vm.tratamientosMicaSel.contains(trat)
                                    let delta = trat.precioExtra(para: vm.baseMicaSeleccionada)
                                    Button {
                                        if seleccionado {
                                            vm.tratamientosMicaSel.removeAll { $0 == trat }
                                        } else {
                                            vm.tratamientosMicaSel.append(trat)
                                        }
                                    } label: {
                                        HStack(spacing: 12) {
                                            Image(systemName: seleccionado ? "checkmark.square.fill" : "square")
                                                .font(.system(size: 22))
                                                .foregroundStyle(seleccionado ? BrandColors.primary : Color.gray.opacity(0.5))
                                            VStack(alignment: .leading, spacing: 2) {
                                                Text(trat.rawValue)
                                                    .font(.system(size: 14, weight: .semibold))
                                                    .foregroundStyle(.primary)
                                                Text("Tratamiento adicional")
                                                    .font(.system(size: 12))
                                                    .foregroundStyle(.secondary)
                                            }
                                            Spacer()
                                            Text("+ \(fmt(delta))")
                                                .font(.system(size: 13, weight: .semibold))
                                                .foregroundStyle(BrandColors.primary)
                                        }
                                        .padding(12)
                                        .background(seleccionado ? BrandColors.primary.opacity(0.08) : Color.gray.opacity(0.04))
                                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                                .stroke(seleccionado ? BrandColors.primary.opacity(0.3) : Color.gray.opacity(0.15), lineWidth: 1)
                                        )
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }

                    separadorGrupo

                    // ── Resumen del paquete a medida ──────────────────────
                    VStack(spacing: 10) {
                        HStack {
                            Text("PRECIO POR COLABORADOR")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(.secondary)
                                .tracking(0.8)
                            Spacer()
                            Text(fmt(vm.precioPorColaborador))
                                .font(.system(size: 22, weight: .black))
                                .foregroundStyle(BrandColors.primary)
                        }

                        // Desglose de lo seleccionado
                        VStack(alignment: .leading, spacing: 4) {
                            filaDesglose("Examen", "Examen Visual Completo", 150)
                            if vm.opcionArmazon != .ninguno {
                                filaDesglose("Armazón", vm.opcionArmazon.rawValue, vm.opcionArmazon.precio)
                            }
                            if vm.baseMicaSeleccionada != .ninguna {
                                filaDesglose("Micas base", vm.baseMicaSeleccionada.rawValue, vm.baseMicaSeleccionada.precioBase)
                                ForEach(vm.tratamientosMicaSel, id: \.self) { trat in
                                    filaDesglose(trat.rawValue, "Tratamiento adicional", trat.precioExtra(para: vm.baseMicaSeleccionada))
                                }
                            }
                        }
                        .padding(12)
                        .background(BrandColors.primary.opacity(0.04))
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    }
                }
            }
            .transition(.opacity.combined(with: .move(edge: .top)))
            .animation(.easeInOut(duration: 0.25), value: vm.paqueteSeleccionado)
        }
    }

    // MARK: - Helpers del paquete personalizado

    @ViewBuilder
    private func grupoOpciones<Content: View>(
        titulo: String,
        icono: String,
        obligatorio: Bool,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: icono)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(BrandColors.primary)
                    .frame(width: 28, height: 28)
                    .background(BrandColors.primary.opacity(0.10))
                    .clipShape(RoundedRectangle(cornerRadius: 7, style: .continuous))

                Text(titulo)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(BrandColors.secondary)

                if obligatorio {
                    Text("Obligatorio")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3)
                        .background(BrandColors.primary)
                        .clipShape(Capsule())
                } else {
                    Text("Opcional")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3)
                        .background(Color.gray.opacity(0.12))
                        .clipShape(Capsule())
                }
                Spacer()
            }

            VStack(spacing: 4) {
                content()
            }
        }
    }

    private func opcionRow(nombre: String, descripcion: String,
                            precio: Double, seleccionado: Bool,
                            esGratis: Bool, onTap: @escaping () -> Void) -> some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Radio button
                ZStack {
                    Circle()
                        .stroke(seleccionado ? BrandColors.primary : Color.gray.opacity(0.35),
                                lineWidth: 1.5)
                        .frame(width: 20, height: 20)
                    if seleccionado {
                        Circle()
                            .fill(BrandColors.primary)
                            .frame(width: 11, height: 11)
                    }
                }

                // Nombre + descripción
                VStack(alignment: .leading, spacing: 2) {
                    Text(nombre)
                        .font(.system(size: 14, weight: seleccionado ? .semibold : .regular))
                        .foregroundStyle(seleccionado ? BrandColors.secondary : Color(.label))
                    Text(descripcion)
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer()

                // Precio
                Group {
                    if esGratis {
                        Text("—")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(.secondary)
                    } else {
                        Text(fmt(precio))
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(seleccionado ? BrandColors.primary : Color(.secondaryLabel))
                    }
                }
                .frame(minWidth: 72, alignment: .trailing)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(seleccionado ? BrandColors.primary.opacity(0.06) : Color.clear)
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(seleccionado ? BrandColors.primary.opacity(0.35) : Color.clear, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.15), value: seleccionado)
    }

    private var separadorGrupo: some View {
        HStack(spacing: 8) {
            Rectangle()
                .fill(BrandColors.primary.opacity(0.12))
                .frame(height: 1)
            Image(systemName: "plus.circle.fill")
                .font(.system(size: 12))
                .foregroundStyle(BrandColors.primary.opacity(0.4))
            Rectangle()
                .fill(BrandColors.primary.opacity(0.12))
                .frame(height: 1)
        }
    }

    private func filaDesglose(_ etiqueta: String, _ nombre: String, _ precio: Double) -> some View {
        HStack {
            Text(etiqueta)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.secondary)
                .frame(width: 52, alignment: .leading)
            Text(nombre)
                .font(.system(size: 11))
                .foregroundStyle(Color(.label))
            Spacer()
            Text(fmt(precio))
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(BrandColors.secondary)
        }
    }

    // MARK: - Sección: Colaboradores

    private var seccionColaboradores: some View {
        SectionCard(title: "Colaboradores", subtitle: "Mínimo 10 — Máximo 200") {
            VStack(spacing: 14) {

                // Número grande centrado
                Text("\(vm.colaboradores)")
                    .font(.system(size: 52, weight: .black))
                    .foregroundStyle(BrandColors.primary)
                    .frame(maxWidth: .infinity, alignment: .center)

                // Barra deslizante 10–200
                VStack(spacing: 4) {
                    Slider(value: $vm.colaboradoresSlider, in: 10...200, step: 1)
                        .tint(BrandColors.primary)
                    HStack {
                        Text("10").font(.system(size: 11)).foregroundStyle(.secondary)
                        Spacer()
                        Text("200").font(.system(size: 11)).foregroundStyle(.secondary)
                    }
                }

                // R4 — Banners de promociones automáticas
                if vm.promoBeneficiarioContacto {
                    promoBanner(
                        texto: "🎁 Beneficio incluido: 1 par de lentes completo GRATIS para el contacto principal",
                        color: BrandColors.success
                    )
                }
                if vm.promoBeneficiarioFamilia {
                    promoBanner(
                        texto: "👨‍👩‍👧‍👦 Beneficio Plus: Familiares directos (esposa e hijos c/ID oficial) reciben armazón + lentes GRATIS",
                        color: BrandColors.primary
                    )
                }
            }
        }
    }

    // MARK: - Sección: Optometristas (R5)

    @ViewBuilder
    private var seccionOptometristas: some View {
        SectionCard(title: "Optometristas", subtitle: "Asignación del equipo para el servicio") {
            VStack(spacing: 14) {

                // Info de optometristas gratis
                HStack(spacing: 10) {
                    Image(systemName: "person.badge.shield.checkmark.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(BrandColors.success)
                    Text("\(vm.optometristasGratis) optometrista\(vm.optometristasGratis == 1 ? "" : "s") incluido\(vm.optometristasGratis == 1 ? "" : "s") gratis (1 por cada 30 colaboradores)")
                        .font(.system(size: 13))
                        .foregroundStyle(Color(.label))
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(10)
                .background(BrandColors.success.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

                    // Duración estimada
                    HStack(spacing: 10) {
                        Image(systemName: "calendar.badge.clock")
                            .font(.system(size: 14))
                            .foregroundStyle(BrandColors.primary)
                        Text("Duración estimada: \(vm.diasNecesariosCalculados) día\(vm.diasNecesariosCalculados == 1 ? "" : "s") con \(vm.totalOptometristasAsignados) optometrista\(vm.totalOptometristasAsignados == 1 ? "" : "s")")
                            .font(.system(size: 13))
                            .foregroundStyle(Color(.label))
                    }
                    .padding(10)
                    .background(BrandColors.primary.opacity(0.06))
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

                    Divider().opacity(0.3)

                    // Stepper de optometristas adicionales
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Optometristas adicionales")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(.secondary)
                        HStack(spacing: 16) {
                            Button {
                                if vm.optometristasExtras > 0 {
                                    vm.optometristasExtras -= 1
                                }
                            } label: {
                                Image(systemName: "minus.circle.fill")
                                    .font(.system(size: 28))
                                    .foregroundStyle(vm.optometristasExtras > 0 ? BrandColors.primary : .gray)
                            }

                            Text("\(vm.optometristasExtras)")
                                .font(.system(size: 28, weight: .bold))
                                .foregroundStyle(BrandColors.secondary)
                                .frame(minWidth: 40, alignment: .center)
                                .multilineTextAlignment(.center)

                            Button {
                                vm.optometristasExtras += 1
                            } label: {
                                Image(systemName: "plus.circle.fill")
                                    .font(.system(size: 28))
                                    .foregroundStyle(BrandColors.primary)
                            }

                            Spacer()

                            if vm.optometristasExtras > 0 {
                                VStack(alignment: .trailing, spacing: 2) {
                                    Text(fmt(vm.costoOptometristasExtras))
                                        .font(.system(size: 16, weight: .bold))
                                        .foregroundStyle(BrandColors.primary)
                                    Text("costo adicional")
                                        .font(.system(size: 10))
                                        .foregroundStyle(.secondary)
                                }
                                .transition(.opacity.combined(with: .scale))
                                .animation(.easeInOut(duration: 0.2), value: vm.optometristasExtras)
                            }
                        }
                    }

                    // Advertencia de múltiples días
                    if vm.diasNecesariosCalculados > 1 {
                        HStack(spacing: 8) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.system(size: 13))
                                .foregroundStyle(BrandColors.warning)
                            Text("⚠️ El servicio requiere \(vm.diasNecesariosCalculados) días con la configuración actual")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(BrandColors.warning)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding(10)
                        .background(BrandColors.warning.opacity(0.10))
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    }
                }
            }
        }

    // MARK: - Sección: Datos del servicio

    private var seccionDatosServicio: some View {
        SectionCard(title: "Detalles del Servicio", subtitle: "Información operativa del evento") {
            VStack(spacing: 14) {

                // Para Servicio Diario: mostrar días calculados automáticamente
                if vm.paqueteSeleccionado == .servicioDiario {
                    HStack(spacing: 12) {
                        Image(systemName: "calendar.badge.clock")
                            .font(.system(size: 20))
                            .foregroundStyle(BrandColors.primary)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Días necesarios calculados")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(.secondary)
                            Text("\(vm.diasNecesariosCalculados) día\(vm.diasNecesariosCalculados == 1 ? "" : "s")")
                                .font(.system(size: 22, weight: .bold))
                                .foregroundStyle(BrandColors.secondary)
                        }
                        Spacer()
                        VStack(alignment: .trailing, spacing: 2) {
                            Text(fmt(vm.subtotal))
                                .font(.system(size: 16, weight: .bold))
                                .foregroundStyle(BrandColors.primary)
                            Text("subtotal")
                                .font(.system(size: 10))
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(12)
                    .background(BrandColors.primary.opacity(0.05))
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

                    Divider().opacity(0.3)
                }

                // Fecha de campaña — Día 1 siempre visible
                VStack(alignment: .leading, spacing: 4) {
                    Text("Fecha del servicio — Día 1")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.secondary)
                    CotizacionDatePicker(
                        titulo: "Día 1",
                        selection: $vm.fechaCampana,
                        componentes: .date,
                        icono: "calendar"
                    )
                }

                // Días adicionales: cada uno con su propia fecha y horario
                let diasRequeridos: Int = vm.diasNecesariosCalculados
                if diasRequeridos > 1 {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Fechas adicionales — \(diasRequeridos - 1) día\(diasRequeridos - 1 == 1 ? "" : "s") más")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(BrandColors.primary)

                        ForEach(1..<diasRequeridos, id: \.self) { idx in
                            let defaultFecha = Calendar.current.date(byAdding: .day, value: idx, to: vm.fechaCampana) ?? vm.fechaCampana
                            let defaultInicio = vm.horarioInicio
                            let defaultFin   = vm.horarioFin

                            // Asegurar que el array tiene el elemento
                            let _ = {
                                while vm.diasAdicionales.count < idx {
                                    vm.diasAdicionales.append(DiaServicio(
                                        fecha: Calendar.current.date(byAdding: .day, value: vm.diasAdicionales.count + 1, to: vm.fechaCampana) ?? defaultFecha,
                                        horarioInicio: defaultInicio,
                                        horarioFin: defaultFin
                                    ))
                                }
                            }()

                            VStack(alignment: .leading, spacing: 6) {
                                Text("Día \(idx + 1)")
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundStyle(BrandColors.secondary)

                                CotizacionDatePicker(
                                    titulo: "Fecha día \(idx + 1)",
                                    selection: Binding(
                                        get: { vm.diasAdicionales.count > idx - 1 ? vm.diasAdicionales[idx - 1].fecha : defaultFecha },
                                        set: { vm.diasAdicionales[idx - 1].fecha = $0 }
                                    ),
                                    componentes: .date,
                                    icono: "calendar.badge.plus"
                                )

                                HStack(spacing: 10) {
                                    CotizacionDatePicker(
                                        titulo: "Inicio",
                                        selection: Binding(
                                            get: { vm.diasAdicionales.count > idx - 1 ? vm.diasAdicionales[idx - 1].horarioInicio : defaultInicio },
                                            set: { vm.diasAdicionales[idx - 1].horarioInicio = $0 }
                                        ),
                                        componentes: .hourAndMinute,
                                        icono: "clock"
                                    )
                                    CotizacionDatePicker(
                                        titulo: "Fin",
                                        selection: Binding(
                                            get: { vm.diasAdicionales.count > idx - 1 ? vm.diasAdicionales[idx - 1].horarioFin : defaultFin },
                                            set: { newFin in
                                                let inicio = vm.diasAdicionales.count > idx - 1 ? vm.diasAdicionales[idx - 1].horarioInicio : defaultInicio
                                                let mins = Int(newFin.timeIntervalSince(inicio) / 60)
                                                if mins > 480 {
                                                    vm.diasAdicionales[idx - 1].horarioFin = Calendar.current.date(byAdding: .hour, value: 8, to: inicio) ?? newFin
                                                    mostrarAlerta8h = true
                                                } else {
                                                    vm.diasAdicionales[idx - 1].horarioFin = newFin
                                                }
                                            }
                                        ),
                                        componentes: .hourAndMinute,
                                        icono: "clock.badge.checkmark"
                                    )
                                }
                            }
                            .padding(10)
                            .background(BrandColors.primary.opacity(0.03))
                            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                        }
                    }
                    .onChange(of: diasRequeridos) { _, nuevos in
                        let needed = max(0, nuevos - 1)
                        if vm.diasAdicionales.count > needed {
                            vm.diasAdicionales = Array(vm.diasAdicionales.prefix(needed))
                        }
                    }
                }

                // Horario: inicio y fin en HStack
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Hora de inicio")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(.secondary)
                        CotizacionDatePicker(
                            titulo: "Hora de inicio",
                            selection: $vm.horarioInicio,
                            componentes: .hourAndMinute,
                            icono: "clock"
                        )
                    }
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Hora de fin")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(.secondary)
                        CotizacionDatePicker(
                            titulo: "Hora de fin",
                            selection: $vm.horarioFin,
                            componentes: .hourAndMinute,
                            icono: "clock.badge.checkmark"
                        )
                    }
                }

                // Enforce 8h cap via onChange
                .onChange(of: vm.horarioFin) { _, newFin in
                    let mins = Int(newFin.timeIntervalSince(vm.horarioInicio) / 60)
                    if mins > 480 {
                        vm.horarioFin = Calendar.current.date(byAdding: .hour, value: 8, to: vm.horarioInicio) ?? newFin
                        mostrarAlerta8h = true
                    }
                }

                campoTexto("Lugar / Sede",
                           texto: $vm.lugarSede,
                           placeholder: "Ej. Oficinas corporativas")

                campoTexto("Dirección completa del lugar",
                           texto: $vm.direccionServicio,
                           placeholder: "Calle, número, colonia, ciudad, CP")
            }
        }
    }

    // MARK: - Sección: Observaciones

    private var seccionObservaciones: some View {
        SectionCard(title: "Observaciones del Servicio", subtitle: "Accesos, equipo de seguridad, indicaciones especiales, etc.") {
            TextField("",
                      text: $vm.observaciones,
                      axis: .vertical)
                .lineLimit(5...10)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.characters)
                .onChange(of: vm.observaciones) { _, nuevo in
                    let upper = nuevo.uppercased()
                    if nuevo != upper { vm.observaciones = upper }
                }
                .padding(10)
                .background(BrandColors.fieldBackground)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                .font(.system(size: 14))
        }
    }

    // MARK: - Sección: Descuentos, IVA y forma de pago

    private var seccionDescuentos: some View {
        SectionCard(title: "Descuentos, IVA y Forma de Pago", subtitle: nil) {
            VStack(spacing: 14) {

                // Código de descuento
                VStack(alignment: .leading, spacing: 6) {
                    Text("Código de descuento")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.secondary)
                    HStack(spacing: 8) {
                        TextField("", text: $vm.codigoPromo)
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.characters)
                            .font(.system(size: 15, weight: .medium))
                            .padding(10)
                            .background(BrandColors.fieldBackground)
                            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                        if !vm.codigoPromo.isEmpty {
                            if vm.codigoPromoValido {
                                Label("10% OFF", systemImage: "checkmark.seal.fill")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundStyle(BrandColors.success)
                                    .transition(.scale.combined(with: .opacity))
                            } else {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 18))
                                    .foregroundStyle(BrandColors.danger.opacity(0.7))
                                    .transition(.scale.combined(with: .opacity))
                            }
                        }
                    }
                    .animation(.easeInOut(duration: 0.2), value: vm.codigoPromoValido)
                }

                Divider().opacity(0.3)

                // Emitir factura (IVA)
                if vm.esEfectivo {
                    // R3: efectivo — mostrar toggle deshabilitado con nota
                    HStack(spacing: 10) {
                        Toggle("", isOn: .constant(false))
                            .tint(BrandColors.primary)
                            .disabled(true)
                            .labelsHidden()
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Emitir factura")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundStyle(.secondary)
                            Text("Pago en efectivo: sin IVA ni ISR")
                                .font(.system(size: 12))
                                .foregroundStyle(BrandColors.warning)
                        }
                        Spacer()
                    }
                } else {
                    Toggle(isOn: Binding(
                        get: { vm.aplicarIVA },
                        set: { nuevo in
                            if nuevo { mostrarAlertaIVA = true }
                            vm.aplicarIVA = nuevo
                        }
                    )) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Emitir factura")
                                .font(.system(size: 15, weight: .medium))
                            Text("Agrega IVA 16% sobre armazón y micas")
                                .font(.system(size: 12))
                                .foregroundStyle(.secondary)
                        }
                    }
                    .tint(BrandColors.primary)
                }

                Divider().opacity(0.3)

                // Pago por día (solo Servicio Diario con varios días)
                if vm.paqueteSeleccionado == .servicioDiario && vm.diasNecesariosCalculados > 1 {
                    Toggle(isOn: $vm.pagoPorDia) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Pagar día a día")
                                .font(.system(size: 15, weight: .medium))
                            Text("Facturar \(fmt(vm.subtotal / Double(max(1, vm.diasNecesariosCalculados)))) por cada uno de los \(vm.diasNecesariosCalculados) días")
                                .font(.system(size: 12))
                                .foregroundStyle(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    .tint(BrandColors.primary)

                    Divider().opacity(0.3)
                }

                // Forma de pago
                VStack(alignment: .leading, spacing: 8) {
                    Text("Forma de pago")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.secondary)

                    HStack(spacing: 8) {
                        ForEach(MetodoPago.allCases, id: \.self) { metodo in
                            let sel = vm.metodoPago == metodo
                            Button { vm.metodoPago = metodo } label: {
                                HStack(spacing: 4) {
                                    Image(systemName: iconoMetodoPago(metodo))
                                        .font(.system(size: 12))
                                    Text(metodo.rawValue.components(separatedBy: " ").first ?? metodo.rawValue)
                                        .font(.system(size: 12, weight: .semibold))
                                }
                                .foregroundStyle(sel ? .white : BrandColors.secondary)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(
                                    sel ? BrandColors.secondary : BrandColors.fieldBackground
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .animation(.easeInOut(duration: 0.2), value: vm.metodoPago)

                    // Datos bancarios — solo si se eligió transferencia
                    if vm.metodoPago == .transferencia {
                        datosBancarios
                    }
                }
            }
        }
    }

    // MARK: - Sección: Resumen en tiempo real

    private var seccionResumen: some View {
        SectionCard(title: "Resumen Financiero", subtitle: "Cálculo en tiempo real") {
            VStack(spacing: 8) {

                // Desglose de componentes por persona (no Personalizado ni Servicio Diario)
                if vm.paqueteSeleccionado != .personalizado && vm.paqueteSeleccionado != .servicioDiario {
                    let examen  = vm.paqueteSeleccionado.costoExamen
                    let armazon = vm.paqueteSeleccionado.costoArmazon
                    let micas   = vm.paqueteSeleccionado.costoMicas
                    if examen > 0 || armazon > 0 || micas > 0 {
                        VStack(spacing: 4) {
                            if examen > 0  { filaDesglose("Examen",  "por persona", examen) }
                            if armazon > 0 { filaDesglose("Armazón", "por persona", armazon) }
                            if micas > 0   { filaDesglose("Micas",   "por persona", micas) }
                        }
                        .padding(10)
                        .background(BrandColors.primary.opacity(0.04))
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

                        Divider().opacity(0.3)
                    }
                }

                filaCalculo("Subtotal",           valor: vm.subtotal,              prefijo: "")

                if vm.codigoPromoValido {
                    filaCalculo("− ABRIL2026 (10%)", valor: vm.montoDescuentoPromo, prefijo: "−", verde: true)
                }
                if vm.aplicarIVA && !vm.esEfectivo {
                    filaCalculo("+ IVA (16%) en armazón/micas", valor: vm.montoIVA, prefijo: "+", ambar: true)
                }
                if vm.optometristasExtras > 0 {
                    filaCalculo("+ Optometristas extra (\(vm.optometristasExtras)×$2,500)",
                                valor: vm.costoOptometristasExtras, prefijo: "+", ambar: true)
                }

                Divider().opacity(0.3)

                HStack {
                    Text("TOTAL FINAL")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundStyle(BrandColors.secondary)
                    Spacer()
                    Text(fmt(vm.totalFinal))
                        .font(.system(size: 24, weight: .black))
                        .foregroundStyle(BrandColors.primary)
                }
                .padding(.vertical, 4)

                // ISR retención — informativo, no reduce total
                if !vm.esEfectivo && vm.montoISRRetencion > 0 {
                    HStack {
                        Text("ISR retenido (referencia)")
                            .font(.system(size: 12))
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(fmt(vm.montoISRRetencion))
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(.secondary)
                    }
                    .padding(8)
                    .background(Color.gray.opacity(0.06))
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                }

                Divider().opacity(0.3)

                if vm.esServicioDiario {
                    filaCalculo("Pago inicial (50%)",       valor: vm.pagoApartarFecha, prefijo: "")
                    filaCalculo("Al iniciar labores (50%)", valor: vm.anticipo,          prefijo: "")
                } else {
                    filaCalculo("Para apartar fecha (5%)", valor: vm.pagoApartarFecha,  prefijo: "")
                    filaCalculo("Al iniciar labores (65%)", valor: vm.anticipo,          prefijo: "")
                    filaCalculo("Al finalizar (30%)",       valor: vm.liquidacion,       prefijo: "")
                }
            }
        }
    }

    // MARK: - Sección: Ejecutivo y firma digital

    private var seccionEjecutivo: some View {
        SectionCard(title: "Datos del Ejecutivo", subtitle: "Quien genera esta cotización") {
            VStack(spacing: 14) {
                HStack(spacing: 12) {
                    campoTexto("Nombre del ejecutivo",
                               texto: $vm.nombreEjecutivo,
                               placeholder: "Ej. Rodrigo Marcos")
                    campoTexto("Cargo en Vission Wow",
                               texto: $vm.cargoEjecutivo,
                               placeholder: "Ej. Director General")
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text("Firma digital del ejecutivo")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.secondary)
                    SignaturePadView(signatureData: $vm.firmaEjecutivo)
                    Text("Se imprimirá en el PDF. El cliente firmará físicamente al aceptar.")
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }

    // MARK: - Botón continuar

    private var botonContinuar: some View {
        Button { mostrarResumen = true } label: {
            HStack(spacing: 8) {
                Image(systemName: "doc.richtext.fill")
                Text(vm.enModoEdicion ? "Actualizar Cotización" : "Generar Cotización Corporativa")
                    .fontWeight(.semibold)
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                vm.formularioValido
                    ? LinearGradient(colors: [BrandColors.primary, BrandColors.secondary],
                                     startPoint: .leading, endPoint: .trailing)
                    : LinearGradient(colors: [Color.gray.opacity(0.4), Color.gray.opacity(0.4)],
                                     startPoint: .leading, endPoint: .trailing)
            )
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .disabled(!vm.formularioValido)
        .animation(.easeInOut(duration: 0.2), value: vm.formularioValido)
    }

    // MARK: - Helpers de UI

    private func promoBanner(texto: String, color: Color) -> some View {
        HStack(spacing: 10) {
            Text(texto)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(color)
                .fixedSize(horizontal: false, vertical: true)
            Spacer()
        }
        .padding(10)
        .background(color.opacity(0.10))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 10, style: .continuous)
            .stroke(color.opacity(0.25), lineWidth: 1))
        .transition(.opacity.combined(with: .move(edge: .top)))
        .animation(.easeInOut(duration: 0.25), value: vm.colaboradores)
    }

    private func campoTexto(_ etiqueta: String, texto: Binding<String>,
                             placeholder: String, teclado: UIKeyboardType = .default) -> some View {
        let esEmail = teclado == .emailAddress
        return VStack(alignment: .leading, spacing: 4) {
            Text(etiqueta)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.secondary)
            TextField(placeholder, text: texto)
                .keyboardType(teclado)
                .autocorrectionDisabled()
                .textInputAutocapitalization(esEmail ? .never : .characters)
                .onChange(of: texto.wrappedValue) { _, nuevo in
                    if !esEmail {
                        let upper = nuevo.uppercased()
                        if nuevo != upper { texto.wrappedValue = upper }
                    }
                }
                .padding(10)
                .background(BrandColors.fieldBackground)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                .font(.system(size: 14))
        }
    }

    private func filaCalculo(_ etiqueta: String, valor: Double, prefijo: String,
                              verde: Bool = false, ambar: Bool = false) -> some View {
        let color: Color = verde ? BrandColors.success : (ambar ? BrandColors.warning : Color(.label))
        let colorVal: Color = verde ? BrandColors.success : (ambar ? BrandColors.warning : BrandColors.secondary)
        return HStack {
            Text(etiqueta).font(.system(size: 13)).foregroundStyle(color)
            Spacer()
            Text("\(prefijo)\(fmt(valor))").font(.system(size: 14, weight: .semibold)).foregroundStyle(colorVal)
        }
    }

    private var datosBancarios: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: "building.columns.fill")
                    .font(.system(size: 12))
                    .foregroundStyle(BrandColors.primary)
                Text("Datos para transferencia / depósito")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(BrandColors.secondary)
            }

            VStack(alignment: .leading, spacing: 4) {
                datosBanco("Banco",   "STP / CIBanco")
                datosBanco("Titular", "Vission Wow SA de CV")
                datosBanco("CLABE",   "638180010150676035")
                datosBanco("Concepto","Folio de cotización")
            }
        }
        .padding(12)
        .background(BrandColors.primary.opacity(0.07))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(BrandColors.primary.opacity(0.2), lineWidth: 1)
        )
        .transition(.opacity.combined(with: .move(edge: .top)))
        .animation(.easeInOut(duration: 0.25), value: vm.metodoPago)
    }

    private func datosBanco(_ etiqueta: String, _ valor: String) -> some View {
        HStack(spacing: 4) {
            Text(etiqueta + ":")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.secondary)
                .frame(width: 65, alignment: .leading)
            Text(valor)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Color(.label))
        }
    }

    private func iconoMetodoPago(_ metodo: MetodoPago) -> String {
        switch metodo {
        case .transferencia: return "building.columns"
        case .efectivo:      return "banknote"
        case .tarjeta:       return "creditcard"
        }
    }
}

// MARK: - CotizacionDatePicker
// Botón que muestra la fecha/hora seleccionada y abre un sheet con rueda — mismo patrón que PersonalDataView

private struct CotizacionDatePicker: View {
    let titulo:      String
    @Binding var selection: Date
    let componentes: DatePickerComponents
    let icono:       String

    @State private var mostrarSheet = false

    var body: some View {
        Button { mostrarSheet = true } label: {
            HStack(spacing: 10) {
                Image(systemName: icono)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.secondary)
                Text(textoFormateado)
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                Spacer()
                Image(systemName: "chevron.down")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .opacity(0.7)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity, minHeight: 44)
            .background(BrandColors.fieldBackground)
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(BrandColors.accent.opacity(0.18), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $mostrarSheet) {
            NavigationStack {
                VStack(alignment: .leading, spacing: 14) {
                    Text(titulo)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    DatePicker("", selection: $selection, displayedComponents: componentes)
                        .datePickerStyle(.wheel)
                        .labelsHidden()
                        .environment(\.locale, Locale(identifier: "es_MX"))
                        .frame(maxWidth: .infinity)
                        .frame(height: 260)
                        .clipped()
                        .background(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(Color.black.opacity(0.04))
                        )

                    Spacer()
                }
                .padding(16)
                .navigationTitle(titulo)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancelar") { mostrarSheet = false }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Listo") { mostrarSheet = false }
                            .fontWeight(.semibold)
                            .foregroundStyle(BrandColors.primary)
                    }
                }
            }
            .presentationDetents([.large])
        }
    }

    private var textoFormateado: String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "es_MX")
        if componentes == .date {
            f.dateStyle = .long
            f.timeStyle = .none
        } else {
            f.dateStyle = .none
            f.timeStyle = .short
        }
        return f.string(from: selection)
    }
}
