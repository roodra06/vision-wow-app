//
//  ResumenCotizacionView.swift
//  VisionWow — Módulo de Cotizaciones
//

import SwiftUI

struct ResumenCotizacionView: View {

    @State private var cotizacion: Cotizacion
    var yaGuardada: Bool  = false
    var modoEdicion: Bool = false

    @State private var guardada          = false
    @State private var mostrarToast      = false
    @State private var generandoPDF      = false
    @State private var shareURL: URL?    = nil
    @State private var firmaClienteData: Data? = nil

    init(cotizacion: Cotizacion, yaGuardada: Bool = false, modoEdicion: Bool = false) {
        self._cotizacion = State(initialValue: cotizacion)
        self.yaGuardada  = yaGuardada
        self.modoEdicion = modoEdicion
        self._guardada   = State(initialValue: yaGuardada && !modoEdicion)
    }

    private let mxn: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle           = .currency
        f.currencyCode          = "MXN"
        f.currencySymbol        = "$"
        f.maximumFractionDigits = 2
        return f
    }()

    private let fechaLarga: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .long
        f.locale    = Locale(identifier: "es_MX")
        return f
    }()

    private func fmt(_ v: Double) -> String { mxn.string(from: NSNumber(value: v)) ?? "$0.00" }

    private func horaCorta(_ d: Date) -> String {
        let f = DateFormatter()
        f.dateStyle = .none
        f.timeStyle = .short
        f.locale    = Locale(identifier: "es_MX")
        return f.string(from: d)
    }

    var body: some View {
        ZStack(alignment: .top) {
            BrandColors.backgroundGradient.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {
                    encabezado
                    seccionCliente
                    seccionServicio
                    seccionPromos
                    seccionFinanciera
                    seccionEncargadaOperaciones
                    seccionCondiciones
                    seccionFirmaCliente
                    botonesAccion
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 20)
                .padding(.bottom, 40)
            }

            if mostrarToast {
                VStack {
                    Text(modoEdicion ? "✓ Cotización actualizada" : "✓ Cotización guardada")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 22)
                        .padding(.vertical, 12)
                        .background(BrandColors.success)
                        .clipShape(Capsule())
                        .shadow(radius: 6)
                        .transition(.move(edge: .top).combined(with: .opacity))
                        .padding(.top, 8)
                    Spacer()
                }
                .animation(.spring(), value: mostrarToast)
            }
        }
        .navigationTitle("Cotización \(cotizacion.folio)")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: Binding(
            get: { shareURL != nil },
            set: { if !$0 { shareURL = nil } }
        )) {
            if let url = shareURL {
                ReportShareSheet(activityItems: [url])
            }
        }
    }

    // MARK: - Encabezado

    private var encabezado: some View {
        SectionCard(title: "", subtitle: nil) {
            VStack(spacing: 0) {
                // Banner de marca
                HStack(spacing: 16) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(LinearGradient(colors: [BrandColors.primary, BrandColors.secondary],
                                                 startPoint: .topLeading, endPoint: .bottomTrailing))
                            .frame(width: 56, height: 56)
                        Text("VW")
                            .font(.system(size: 20, weight: .black))
                            .foregroundStyle(.white)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("VISSION WOW")
                            .font(.system(size: 20, weight: .black))
                            .foregroundStyle(BrandColors.secondary)
                            .tracking(1.5)
                        Text("Cotización Corporativa de Servicios")
                            .font(.system(size: 14))
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Text("Vigente")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 7)
                        .background(BrandColors.success)
                        .clipShape(Capsule())
                }

                Divider().padding(.vertical, 16).opacity(0.25)

                HStack(alignment: .top, spacing: 0) {
                    etiquetaDato(titulo: "FOLIO", valor: cotizacion.folio,
                                 colorValor: BrandColors.primary)
                    Spacer()
                    etiquetaDato(titulo: "EMISIÓN",
                                 valor: fechaLarga.string(from: cotizacion.fechaEmision),
                                 alineacion: .center)
                    Spacer()
                    etiquetaDato(titulo: "VIGENCIA",
                                 valor: fechaLarga.string(from: cotizacion.fechaVigencia),
                                 alineacion: .trailing)
                }
            }
        }
    }

    // MARK: - Cliente

    private var seccionCliente: some View {
        SectionCard(title: "Cliente", subtitle: nil) {
            VStack(spacing: 16) {
                // Empresa destacada
                HStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(LinearGradient(
                                colors: [BrandColors.primary.opacity(0.85), BrandColors.secondary],
                                startPoint: .topLeading, endPoint: .bottomTrailing))
                            .frame(width: 60, height: 60)
                        Text(String(cotizacion.cliente.nombreEmpresa.prefix(1)))
                            .font(.system(size: 26, weight: .black))
                            .foregroundStyle(.white)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text(cotizacion.cliente.nombreEmpresa)
                            .font(.system(size: 19, weight: .bold))
                            .foregroundStyle(BrandColors.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                        Text("EMPRESA CLIENTE")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(BrandColors.primary)
                            .tracking(1.5)
                    }
                    Spacer()
                }

                Divider().opacity(0.2)

                VStack(spacing: 0) {
                    filaDetalle(icono: "person.fill",
                                etiqueta: "Contacto",
                                valor: cotizacion.cliente.nombreContacto,
                                impar: true)
                    if !cotizacion.cliente.puesto.isEmpty {
                        filaDetalle(icono: "briefcase.fill",
                                    etiqueta: "Puesto",
                                    valor: cotizacion.cliente.puesto,
                                    impar: false)
                    }
                    filaDetalle(icono: "phone.fill",
                                etiqueta: "Teléfono",
                                valor: cotizacion.cliente.telefono,
                                impar: cotizacion.cliente.puesto.isEmpty)
                    filaDetalle(icono: "envelope.fill",
                                etiqueta: "Correo electrónico",
                                valor: cotizacion.cliente.correo,
                                impar: !cotizacion.cliente.puesto.isEmpty)
                    if !cotizacion.cliente.rfc.isEmpty {
                        filaDetalle(icono: "doc.text.fill",
                                    etiqueta: "RFC",
                                    valor: cotizacion.cliente.rfc,
                                    impar: cotizacion.cliente.puesto.isEmpty)
                    }
                    if !cotizacion.cliente.domicilioFiscal.isEmpty {
                        filaDetalle(icono: "mappin.circle.fill",
                                    etiqueta: "Domicilio fiscal",
                                    valor: cotizacion.cliente.domicilioFiscal,
                                    impar: false)
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(Color.black.opacity(0.06), lineWidth: 1))
            }
        }
    }

    // MARK: - Servicio Contratado

    private var seccionServicio: some View {
        SectionCard(title: "Servicio Contratado", subtitle: nil) {
            VStack(spacing: 18) {

                // Badge paquete + descripción
                HStack(spacing: 14) {
                    Text(cotizacion.paquete.rawValue.uppercased())
                        .font(.system(size: 12, weight: .black))
                        .foregroundStyle(.white)
                        .tracking(1.2)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            LinearGradient(colors: [BrandColors.primary, BrandColors.secondary],
                                           startPoint: .leading, endPoint: .trailing)
                        )
                        .clipShape(Capsule())

                    let descripcionPaquete = cotizacion.componentesPersonalizados?.descripcionCompleta
                        ?? cotizacion.paquete.descripcion
                    Text(descripcionPaquete)
                        .font(.system(size: 14))
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                // Desglose del paquete personalizado
                if let custom = cotizacion.componentesPersonalizados {
                    VStack(spacing: 0) {
                        filaDetalle(icono: "eye.fill",
                                    etiqueta: "Examen",
                                    valor: "Examen Visual Completo — \(fmt(150))/persona",
                                    impar: true)
                        if custom.armazon != .ninguno {
                            filaDetalle(icono: "eyeglasses",
                                        etiqueta: "Armazón",
                                        valor: custom.armazon.rawValue + " — \(fmt(custom.armazon.precio))/persona",
                                        impar: false)
                        }
                        if custom.baseMica != .ninguna {
                            filaDetalle(icono: "sparkles",
                                        etiqueta: "Micas",
                                        valor: custom.descripcionMicas + " — \(fmt(custom.precioMicas))/persona",
                                        impar: custom.armazon == .ninguno)
                        }
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(Color.black.opacity(0.06), lineWidth: 1))
                }

                // Métricas: 3 columnas
                HStack(spacing: 0) {
                    if cotizacion.paquete == .servicioDiario {
                        metricaServicio(valor: "\(cotizacion.diasNecesariosCalculados)",
                                        etiqueta: "Días")
                        Rectangle()
                            .fill(Color.black.opacity(0.08))
                            .frame(width: 1, height: 44)
                        metricaServicio(valor: fmt(2_500),
                                        etiqueta: "Por día")
                    } else {
                        metricaServicio(valor: "\(cotizacion.numeroColaboradores)",
                                        etiqueta: "Colaboradores")
                        Rectangle()
                            .fill(Color.black.opacity(0.08))
                            .frame(width: 1, height: 44)
                        metricaServicio(valor: fmt(cotizacion.precioPorColaborador),
                                        etiqueta: "Por persona")
                    }
                    Rectangle()
                        .fill(Color.black.opacity(0.08))
                        .frame(width: 1, height: 44)
                    metricaServicio(valor: fmt(cotizacion.subtotal),
                                    etiqueta: "Subtotal",
                                    destacado: true)
                }
                .padding(.vertical, 14)
                .background(BrandColors.primary.opacity(0.04))
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(BrandColors.primary.opacity(0.10), lineWidth: 1))

                Divider().opacity(0.2)

                // Detalles operativos
                VStack(spacing: 0) {
                    filaDetalle(icono: "calendar",
                                etiqueta: "Fecha de campaña",
                                valor: fechaLarga.string(from: cotizacion.fechaCampana),
                                impar: true)
                    filaDetalle(icono: "clock.fill",
                                etiqueta: "Horario del servicio",
                                valor: "\(horaCorta(cotizacion.horarioInicio)) – \(horaCorta(cotizacion.horarioFin))",
                                impar: false)
                    if !cotizacion.lugarSede.isEmpty {
                        filaDetalle(icono: "building.2.fill",
                                    etiqueta: "Sede",
                                    valor: cotizacion.lugarSede,
                                    impar: true)
                    }
                    if !cotizacion.direccionServicio.isEmpty {
                        filaDetalle(icono: "mappin.circle.fill",
                                    etiqueta: "Dirección",
                                    valor: cotizacion.direccionServicio,
                                    impar: false)
                    }
                    if !cotizacion.observaciones.isEmpty {
                        filaDetalle(icono: "note.text",
                                    etiqueta: "Observaciones",
                                    valor: cotizacion.observaciones,
                                    impar: true)
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(Color.black.opacity(0.06), lineWidth: 1))
            }
        }
    }

    // MARK: - Promociones automáticas (R4)

    @ViewBuilder
    private var seccionPromos: some View {
        if cotizacion.promoBeneficiarioContacto || cotizacion.promoBeneficiarioFamilia {
            SectionCard(title: "Beneficios Incluidos", subtitle: nil) {
                VStack(spacing: 10) {
                    if cotizacion.promoBeneficiarioContacto {
                        promoBanner(
                            texto: "🎁 Beneficio incluido: 1 par de lentes completo GRATIS para el contacto principal",
                            color: BrandColors.success
                        )
                    }
                    if cotizacion.promoBeneficiarioFamilia {
                        promoBanner(
                            texto: "👨‍👩‍👧‍👦 Beneficio Plus: Familiares directos (esposa e hijos c/ID oficial) reciben armazón + lentes GRATIS",
                            color: BrandColors.primary
                        )
                    }
                }
            }
        }
    }

    private func promoBanner(texto: String, color: Color) -> some View {
        HStack(spacing: 10) {
            Text(texto)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(color)
                .fixedSize(horizontal: false, vertical: true)
            Spacer()
        }
        .padding(12)
        .background(color.opacity(0.10))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 10, style: .continuous)
            .stroke(color.opacity(0.25), lineWidth: 1))
    }

    // MARK: - Resumen Financiero

    private var seccionFinanciera: some View {
        SectionCard(title: "Resumen Financiero", subtitle: nil) {
            VStack(spacing: 12) {

                // Desglose de componentes por persona
                if cotizacion.paquete != .personalizado && cotizacion.paquete != .servicioDiario {
                    let examen  = cotizacion.paquete.costoExamen
                    let armazon = cotizacion.paquete.costoArmazon
                    let micas   = cotizacion.paquete.costoMicas
                    if examen > 0 || armazon > 0 || micas > 0 {
                        VStack(spacing: 4) {
                            if examen > 0  { filaComponente("Examen",  examen) }
                            if armazon > 0 { filaComponente("Armazón", armazon) }
                            if micas > 0   { filaComponente("Micas",   micas) }
                        }
                        .padding(10)
                        .background(BrandColors.primary.opacity(0.04))
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    }
                }

                filaImporte("Subtotal", cotizacion.subtotal, estilo: .normal)

                if cotizacion.descuentoPromoAplicado {
                    filaImporte("− Descuento ABRIL2026 (10%)",
                                cotizacion.montoDescuentoPromo, estilo: .descuento)
                }
                if cotizacion.aplicarIVA && !cotizacion.esEfectivo {
                    filaImporte("+ IVA (16%) en armazón/micas", cotizacion.montoIVA, estilo: .iva)
                }
                if cotizacion.costoOptometristasExtras > 0 {
                    filaImporte("+ Optometristas extra (\(cotizacion.optometristasExtras)×$2,500)",
                                cotizacion.costoOptometristasExtras, estilo: .iva)
                }

                // ISR retención — informativo
                if !cotizacion.esEfectivo && cotizacion.montoISRRetencion > 0 {
                    HStack {
                        Text("ISR retenido (referencia)")
                            .font(.system(size: 13))
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(fmt(cotizacion.montoISRRetencion))
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(.secondary)
                    }
                    .padding(8)
                    .background(Color.gray.opacity(0.06))
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                }

                Divider().opacity(0.4).padding(.vertical, 4)

                HStack {
                    Text("TOTAL FINAL")
                        .font(.system(size: 18, weight: .black))
                        .foregroundStyle(BrandColors.secondary)
                    Spacer()
                    Text(fmt(cotizacion.totalFinal))
                        .font(.system(size: 32, weight: .black))
                        .foregroundStyle(BrandColors.primary)
                }

                Divider().opacity(0.3).padding(.vertical, 4)

                // Tarjetas de pago — por día / 50/50 para Servicio Diario, 5/65/30 para otros
                if cotizacion.esServicioDiario && cotizacion.pagoPorDia {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("PAGO DÍA A DÍA")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(BrandColors.primary)
                            .tracking(1)
                        HStack(spacing: 12) {
                            tarjetaPago(titulo: "Por día",
                                        porcentaje: "×\(cotizacion.diasNecesariosCalculados)",
                                        monto: cotizacion.costoPorDia,
                                        color: BrandColors.primary)
                        }
                        Text("Se factura \(fmt(cotizacion.costoPorDia)) al inicio de cada día de servicio.")
                            .font(.system(size: 12))
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                } else if cotizacion.esServicioDiario {
                    HStack(spacing: 12) {
                        tarjetaPago(titulo: "Pago inicial",
                                    porcentaje: "50%",
                                    monto: cotizacion.pagoApartarFecha,
                                    color: BrandColors.secondary)
                        tarjetaPago(titulo: "Al iniciar labores",
                                    porcentaje: "50%",
                                    monto: cotizacion.anticipo,
                                    color: BrandColors.primary)
                    }
                } else {
                    HStack(spacing: 12) {
                        tarjetaPago(titulo: "Apartar fecha",
                                    porcentaje: "5%",
                                    monto: cotizacion.pagoApartarFecha,
                                    color: BrandColors.primary.opacity(0.75))
                        tarjetaPago(titulo: "Al iniciar",
                                    porcentaje: "65%",
                                    monto: cotizacion.anticipo,
                                    color: BrandColors.secondary)
                        tarjetaPago(titulo: "Al finalizar",
                                    porcentaje: "30%",
                                    monto: cotizacion.liquidacion,
                                    color: BrandColors.primary)
                    }
                }

                // Forma de pago
                HStack(spacing: 8) {
                    Image(systemName: iconoMetodoPago(cotizacion.metodoPago))
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(BrandColors.primary)
                    Text("Forma de pago: \(cotizacion.metodoPago.rawValue)")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 2)
            }
        }
    }

    // MARK: - Encargada de Operaciones

    private var seccionEncargadaOperaciones: some View {
        SectionCard(title: "Encargada de Operaciones", subtitle: "Responsable del servicio en campo") {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(LinearGradient(
                            colors: [BrandColors.primary, BrandColors.secondary],
                            startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 52, height: 52)
                    Text("WM")
                        .font(.system(size: 18, weight: .black))
                        .foregroundStyle(.white)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Wendy Yemely Mazariego González")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(BrandColors.secondary)
                    Text("Encargada de Operaciones · Vission Wow")
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }
            .padding(4)
        }
    }

    // MARK: - Condiciones Comerciales

    private var seccionCondiciones: some View {
        SectionCard(title: "Condiciones Comerciales", subtitle: nil) {
            VStack(spacing: 12) {
                condicionEjecutiva(
                    num: "01",
                    icono: "dollarsign.circle.fill",
                    titulo: "Estructura de pago",
                    texto: "5% para apartar fecha (no reembolsable en caso de cancelación). 65% al iniciar labores — completa el 70% total. 30% de liquidación al finalizar el servicio.")

                condicionEjecutiva(
                    num: "02",
                    icono: "calendar.badge.exclamationmark",
                    titulo: "Reprogramación y cancelación",
                    texto: "Los cambios de fecha deben solicitarse con mínimo 3 días naturales de anticipación. De lo contrario se aplica una penalización del 5% sobre el total.")

                condicionEjecutiva(
                    num: "03",
                    icono: "clock.badge.checkmark",
                    titulo: "Entrega de resultados",
                    texto: "El reporte de examen visual individual se entrega en un máximo de 48 horas posteriores a la realización del servicio.")

                condicionEjecutiva(
                    num: "04",
                    icono: "doc.text.fill",
                    titulo: "Facturación",
                    texto: "Factura disponible a solicitud del cliente. Es necesario proporcionar RFC y domicilio fiscal completo al momento de confirmar el servicio.")

                condicionEjecutiva(
                    num: "05",
                    icono: "timer",
                    titulo: "Vigencia de la cotización",
                    texto: "Esta cotización tiene una validez de 30 días naturales a partir de la fecha de emisión. Transcurrido ese plazo, los precios y condiciones están sujetos a revisión.")
            }
        }
    }

    // MARK: - Firma del Cliente

    private var seccionFirmaCliente: some View {
        SectionCard(title: "Aceptación del Cliente", subtitle: "Firma digital opcional — se incluirá en el PDF") {
            VStack(alignment: .leading, spacing: 14) {
                HStack(spacing: 10) {
                    Image(systemName: "info.circle.fill")
                        .font(.system(size: 15))
                        .foregroundStyle(BrandColors.primary.opacity(0.75))
                    Text("Al firmar, el cliente acepta las condiciones y la estructura de pagos de esta cotización.")
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(12)
                .background(BrandColors.primary.opacity(0.05))
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

                SignaturePadView(signatureData: $firmaClienteData)
                    .onChange(of: firmaClienteData) { _, data in
                        cotizacion.firmaCliente = data
                    }

                if firmaClienteData != nil {
                    Label("Firma capturada — se incluirá en el PDF al compartir",
                          systemImage: "checkmark.seal.fill")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(BrandColors.success)
                }
            }
        }
    }

    // MARK: - Botones de acción

    private var botonesAccion: some View {
        VStack(spacing: 14) {
            Button { generarYCompartirPDF() } label: {
                HStack(spacing: 10) {
                    if generandoPDF {
                        ProgressView().tint(.white).scaleEffect(0.95)
                        Text("Generando PDF…").fontWeight(.semibold)
                    } else {
                        Image(systemName: "square.and.arrow.up.fill")
                        Text("Compartir Cotización (PDF)").fontWeight(.semibold)
                    }
                }
                .font(.system(size: 17))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(
                    LinearGradient(colors: [BrandColors.primary, BrandColors.secondary],
                                   startPoint: .leading, endPoint: .trailing)
                )
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .opacity(generandoPDF ? 0.85 : 1)
            }
            .disabled(generandoPDF)

            Button { guardarCotizacion() } label: {
                HStack(spacing: 10) {
                    Image(systemName: guardada
                          ? "checkmark.circle.fill"
                          : (modoEdicion ? "arrow.triangle.2.circlepath" : "square.and.arrow.down"))
                    Text(guardada
                         ? (modoEdicion ? "Cotización actualizada" : "Guardada en historial")
                         : (modoEdicion ? "Guardar cambios" : "Guardar en historial"))
                        .fontWeight(.medium)
                }
                .font(.system(size: 16))
                .foregroundStyle(guardada ? BrandColors.success : BrandColors.secondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(BrandColors.fieldBackground)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(guardada ? BrandColors.success : BrandColors.secondary.opacity(0.3), lineWidth: 1.5))
            }
            .disabled(guardada)
            .animation(.easeInOut(duration: 0.25), value: guardada)
        }
    }

    // MARK: - Lógica

    private func generarYCompartirPDF() {
        guard !generandoPDF else { return }
        generandoPDF = true
        let snap = cotizacion
        DispatchQueue.global(qos: .userInitiated).async {
            let data     = PDFGeneratorVW.generar(cotizacion: snap)
            let fileName = "Cotizacion-\(snap.folio)-VissionWow.pdf"
            let url      = FileManager.default.temporaryDirectory
                               .appendingPathComponent(fileName)
            try? data.write(to: url, options: .atomic)
            DispatchQueue.main.async {
                generandoPDF = false
                shareURL     = url
            }
        }
    }

    private func guardarCotizacion() {
        guard !guardada else { return }
        if modoEdicion {
            CotizacionStorage.shared.actualizar(cotizacion)
        } else {
            CotizacionStorage.shared.guardar(cotizacion)
        }
        guardada = true
        withAnimation { mostrarToast = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            withAnimation { mostrarToast = false }
        }
    }

    // MARK: - Componentes reutilizables

    private func etiquetaDato(titulo: String, valor: String,
                               colorValor: Color = BrandColors.secondary,
                               alineacion: HorizontalAlignment = .leading) -> some View {
        VStack(alignment: alineacion, spacing: 4) {
            Text(titulo)
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(.secondary)
                .tracking(1.2)
            Text(valor)
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(colorValor)
                .multilineTextAlignment(alineacion == .leading ? .leading : .trailing)
        }
    }

    /// Fila con fondo alternado
    private func filaDetalle(icono: String, etiqueta: String,
                              valor: String, impar: Bool) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icono)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(BrandColors.primary)
                .frame(width: 34, height: 34)
                .background(BrandColors.primary.opacity(0.09))
                .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))

            VStack(alignment: .leading, spacing: 2) {
                Text(etiqueta.uppercased())
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .tracking(0.6)
                Text(valor)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(Color(.label))
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(impar ? BrandColors.primary.opacity(0.03) : Color.clear)
    }

    /// Columna métrica (strip de servicio)
    private func metricaServicio(valor: String, etiqueta: String,
                                  destacado: Bool = false) -> some View {
        VStack(spacing: 5) {
            Text(valor)
                .font(.system(size: destacado ? 18 : 17, weight: .black))
                .foregroundStyle(destacado ? BrandColors.primary : BrandColors.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            Text(etiqueta)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    /// Tarjeta de pago (estructura 5/65/30)
    private func tarjetaPago(titulo: String, porcentaje: String,
                              monto: Double, color: Color) -> some View {
        VStack(spacing: 5) {
            Text(porcentaje)
                .font(.system(size: 16, weight: .black))
                .foregroundStyle(color)
            Text(fmt(monto))
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(color)
                .lineLimit(1)
                .minimumScaleFactor(0.55)
            Text(titulo)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(color.opacity(0.07))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous)
            .stroke(color.opacity(0.22), lineWidth: 1))
    }

    private func filaComponente(_ etiqueta: String, _ precio: Double) -> some View {
        HStack {
            Text(etiqueta)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.secondary)
            Text("$\(Int(precio)) / persona")
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
            Spacer()
            Text(fmt(precio))
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(BrandColors.secondary)
        }
    }

    private enum EstiloImporte { case normal, descuento, iva }

    private func filaImporte(_ etiqueta: String, _ valor: Double, estilo: EstiloImporte) -> some View {
        let color: Color = {
            switch estilo {
            case .normal:    return BrandColors.secondary
            case .descuento: return BrandColors.success
            case .iva:       return BrandColors.warning
            }
        }()
        let colorEtq: Color = estilo == .normal ? Color(.label) : color
        let prefijo = estilo == .descuento ? "−" : (estilo == .iva ? "+" : "")
        return HStack {
            Text(etiqueta).font(.system(size: 15)).foregroundStyle(colorEtq)
            Spacer()
            Text("\(prefijo)\(fmt(valor))").font(.system(size: 16, weight: .semibold)).foregroundStyle(color)
        }
    }

    /// Condición ejecutiva — mini-card con acento lateral
    private func condicionEjecutiva(num: String, icono: String,
                                    titulo: String, texto: String) -> some View {
        HStack(alignment: .top, spacing: 0) {
            // Acento lateral
            RoundedRectangle(cornerRadius: 2, style: .continuous)
                .fill(BrandColors.primary)
                .frame(width: 4)

            VStack(alignment: .leading, spacing: 10) {
                // Número + icono + título
                HStack(spacing: 10) {
                    Text(num)
                        .font(.system(size: 11, weight: .black))
                        .foregroundStyle(.white)
                        .frame(width: 28, height: 28)
                        .background(BrandColors.primary)
                        .clipShape(Circle())

                    Image(systemName: icono)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(BrandColors.primary)

                    Text(titulo)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(BrandColors.secondary)
                }

                // Cuerpo del texto
                Text(texto)
                    .font(.system(size: 13))
                    .foregroundStyle(Color(.secondaryLabel))
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.leading, 38)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 14)
        }
        .background(BrandColors.primary.opacity(0.03))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous)
            .stroke(BrandColors.primary.opacity(0.10), lineWidth: 1))
    }

    private func iconoMetodoPago(_ metodo: MetodoPago) -> String {
        switch metodo {
        case .transferencia: return "building.columns"
        case .efectivo:      return "banknote"
        case .tarjeta:       return "creditcard"
        }
    }
}
