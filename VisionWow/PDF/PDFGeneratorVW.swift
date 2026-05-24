//
//  PDFGeneratorVW.swift
//  VisionWow — Módulo de Cotizaciones
//
//  Diseño editorial corporativo de 2 páginas.
//  100% UIGraphicsPDFRenderer — sin librerías externas.
//

import UIKit

enum PDFGeneratorVW {

    // MARK: - Dimensiones (US Letter en puntos)
    private static let pw: CGFloat  = 612   // page width
    private static let ph: CGFloat  = 792   // page height
    private static let mg: CGFloat  = 42    // margin horizontal
    private static var cw: CGFloat  { pw - mg * 2 }  // usable content width
    private static let fh: CGFloat  = 38    // footer height

    // MARK: - Paleta de marca
    private static let cFucsia     = UIColor(red: 0.906, green: 0.220, blue: 0.498, alpha: 1)  // #E7387F
    private static let cMorado     = UIColor(red: 0.463, green: 0.224, blue: 0.463, alpha: 1)  // #763976
    private static let cMoradoOsc  = UIColor(red: 0.420, green: 0.176, blue: 0.545, alpha: 1)  // #6B2D8B
    private static let cLavanda    = UIColor(red: 0.714, green: 0.451, blue: 0.678, alpha: 1)  // #B673AD
    private static let cFondoPag   = UIColor(red: 0.980, green: 0.976, blue: 0.984, alpha: 1)  // blanco lavanda
    private static let cGrisTitulo = UIColor(red: 0.30,  green: 0.30,  blue: 0.32,  alpha: 1)
    private static let cGrisTexto  = UIColor(red: 0.45,  green: 0.45,  blue: 0.47,  alpha: 1)
    private static let cGrisClaro  = UIColor(red: 0.95,  green: 0.93,  blue: 0.96,  alpha: 1)  // fila impar
    private static let cLinea      = UIColor(red: 0.88,  green: 0.86,  blue: 0.90,  alpha: 1)
    private static let cVerde      = UIColor(red: 0.18,  green: 0.54,  blue: 0.42,  alpha: 1)
    private static let cAmbar      = UIColor(red: 0.75,  green: 0.48,  blue: 0.17,  alpha: 1)
    private static let cBlanco     = UIColor.white

    // MARK: - Tipografías (caché para evitar creación repetida)
    private static var fontCache: [String: UIFont] = [:]
    private static func fuente(_ size: CGFloat, _ weight: UIFont.Weight = .regular) -> UIFont {
        let key = "\(size)-\(weight.rawValue)"
        if let cached = fontCache[key] { return cached }
        let f = UIFont.systemFont(ofSize: size, weight: weight)
        fontCache[key] = f
        return f
    }

    // MARK: - Estilo de párrafo con salto de línea (compartido — inmutable)
    private static let wrapStyle: NSParagraphStyle = {
        let s = NSMutableParagraphStyle()
        s.lineBreakMode = .byWordWrapping
        return s.copy() as! NSParagraphStyle
    }()

    /// Calcula el alto mínimo necesario para `texto` dentro de `width` con fuente `size`
    private static func textHeight(_ texto: String, size: CGFloat,
                                    weight: UIFont.Weight = .regular,
                                    width: CGFloat) -> CGFloat {
        guard !texto.isEmpty else { return 0 }
        let atrs: [NSAttributedString.Key: Any] = [
            .font: fuente(size, weight),
            .paragraphStyle: wrapStyle
        ]
        return ceil(NSAttributedString(string: texto, attributes: atrs)
            .boundingRect(with: CGSize(width: width, height: .greatestFiniteMagnitude),
                          options: .usesLineFragmentOrigin, context: nil).height)
    }

    // MARK: - Formateadores
    private static let mxn: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .currency; f.currencyCode = "MXN"
        f.currencySymbol = "$"; f.maximumFractionDigits = 2
        return f
    }()
    private static let fechaLarga: DateFormatter = {
        let f = DateFormatter(); f.dateStyle = .long
        f.locale = Locale(identifier: "es_MX"); return f
    }()
    private static let fechaCorta: DateFormatter = {
        let f = DateFormatter(); f.dateFormat = "dd/MM/yyyy"
        f.locale = Locale(identifier: "es_MX"); return f
    }()
    private static func fmt(_ v: Double) -> String {
        mxn.string(from: NSNumber(value: v)) ?? "$0.00"
    }
    private static func val(_ s: String) -> String { s.isEmpty ? "—" : s.uppercased() }

    // MARK: - Punto de entrada público

    static func generar(cotizacion: Cotizacion) -> Data {
        let pageRect = CGRect(x: 0, y: 0, width: pw, height: ph)
        let formato  = UIGraphicsPDFRendererFormat()
        formato.documentInfo = [
            kCGPDFContextTitle  as String: "Cotización \(cotizacion.folio) — Vission Wow",
            kCGPDFContextAuthor as String: "\(cotizacion.nombreEjecutivo.isEmpty ? "Vission Wow" : cotizacion.nombreEjecutivo) — Vission Wow",
            kCGPDFContextSubject as String: "Cotización de servicios de optometría empresarial"
        ]

        return UIGraphicsPDFRenderer(bounds: pageRect, format: formato).pdfData { pdfCtx in
            let ctx = pdfCtx.cgContext

            // ─── PÁGINA 1 ─────────────────────────────────────────────
            pdfCtx.beginPage()
            fondoPagina(ctx)
            var y: CGFloat = 0

            y = secHeader(ctx, y: y, cotizacion: cotizacion)
            y = secFolioStrip(ctx, y: y, cotizacion: cotizacion)
            y += 14
            y = secClienteProveedor(ctx, y: y, cotizacion: cotizacion)
            y += 12
            y = secPaquete(ctx, y: y, cotizacion: cotizacion)
            y += 12
            y = secDatosServicio(ctx, y: y, cotizacion: cotizacion)
            y += 12
            y = secFinanciero(ctx, y: y, cotizacion: cotizacion)
            y += 12
            secFormaPago(ctx, y: y, cotizacion: cotizacion)
            pie(ctx, pagina: 1)

            // ─── PÁGINA 2 ─────────────────────────────────────────────
            pdfCtx.beginPage()
            fondoPagina(ctx)
            y = mg - 4

            y = secObservaciones(ctx, y: y, cotizacion: cotizacion)
            y += 12
            y = secEntregables(ctx, y: y, cotizacion: cotizacion)
            y += 12
            y = secEncargadaOperaciones(ctx, y: y)
            y += 12
            y = secPoliticas(ctx, y: y)
            y += 16
            secFirmas(ctx, y: y, cotizacion: cotizacion)
            pie(ctx, pagina: 2)
        }
    }

    // ─────────────────────────────────────────────────────────────────
    // MARK: - PÁGINA 1
    // ─────────────────────────────────────────────────────────────────

    // MARK: 1 · Header con gradiente
    private static func secHeader(_ ctx: CGContext, y: CGFloat, cotizacion: Cotizacion) -> CGFloat {
        let h: CGFloat = 88

        // Fondo: gradiente diagonal morado oscuro → fucsia
        let espacio   = CGColorSpaceCreateDeviceRGB()
        let colores   = [cMoradoOsc.cgColor, cFucsia.cgColor] as CFArray
        if let grad   = CGGradient(colorsSpace: espacio, colors: colores, locations: [0, 1]) {
            ctx.saveGState()
            ctx.clip(to: CGRect(x: 0, y: y, width: pw, height: h))
            ctx.drawLinearGradient(grad,
                                   start: CGPoint(x: 0, y: y),
                                   end: CGPoint(x: pw, y: y + h),
                                   options: [])
            ctx.restoreGState()
        } else {
            cMoradoOsc.setFill(); ctx.fill(CGRect(x: 0, y: y, width: pw, height: h))
        }

        // Banda decorativa inferior fucsia
        cFucsia.withAlphaComponent(0.80).setFill()
        ctx.fill(CGRect(x: 0, y: y + h - 3, width: pw, height: 3))

        // Logo (si existe en assets) — círculo de respaldo
        let logoSize: CGFloat = 58
        let logoX: CGFloat    = mg
        let logoY: CGFloat    = y + (h - logoSize) / 2
        if let logo = UIImage(named: "visionwow_logo") {
            let imgRect = CGRect(x: logoX, y: logoY, width: logoSize, height: logoSize)
            ctx.saveGState()
            let path = UIBezierPath(ovalIn: imgRect); path.addClip()
            logo.draw(in: imgRect)
            ctx.restoreGState()
        } else {
            // Placeholder circular si no carga el logo
            cBlanco.withAlphaComponent(0.20).setFill()
            ctx.fillEllipse(in: CGRect(x: logoX, y: logoY, width: logoSize, height: logoSize))
            atr("VW", [.font: fuente(20, .black), .foregroundColor: cBlanco],
                rect: CGRect(x: logoX, y: logoY + 16, width: logoSize, height: 26), align: .center)
        }

        // Título principal
        let txtX: CGFloat = logoX + logoSize + 14
        atr("COTIZACIÓN DE SERVICIOS",
            [.font: fuente(18, .black), .foregroundColor: cBlanco,
             .kern: 1.5],
            rect: CGRect(x: txtX, y: y + 20, width: pw - txtX - mg - 80, height: 24))

        atr("Vission Wow  •  Optometría Empresarial",
            [.font: fuente(10, .medium), .foregroundColor: cBlanco.withAlphaComponent(0.80)],
            rect: CGRect(x: txtX, y: y + 47, width: pw - txtX - mg - 80, height: 14))

        // Folio (esquina superior derecha)
        let folioWidth: CGFloat = 110
        let folioX = pw - mg - folioWidth
        atr(cotizacion.folio,
            [.font: fuente(13, .black), .foregroundColor: cBlanco],
            rect: CGRect(x: folioX, y: y + 20, width: folioWidth, height: 18), align: .right)
        atr("FOLIO",
            [.font: fuente(8, .semibold), .foregroundColor: cBlanco.withAlphaComponent(0.65),
             .kern: 1.8],
            rect: CGRect(x: folioX, y: y + 40, width: folioWidth, height: 12), align: .right)

        return y + h
    }

    // MARK: 2 · Franja de folio / fechas
    private static func secFolioStrip(_ ctx: CGContext, y: CGFloat, cotizacion: Cotizacion) -> CGFloat {
        let h: CGFloat = 26
        cMoradoOsc.withAlphaComponent(0.10).setFill()
        ctx.fill(CGRect(x: 0, y: y, width: pw, height: h))

        let dias = cotizacion.diasNecesariosCalculados
        let colabODias: String = cotizacion.paquete == .servicioDiario
            ? "\(dias) día\(dias == 1 ? "" : "s")"
            : "\(cotizacion.numeroColaboradores) col."
        let items: [(String, String)] = [
            ("EMISIÓN",   fechaCorta.string(from: cotizacion.fechaEmision)),
            ("VIGENCIA",  fechaCorta.string(from: cotizacion.fechaVigencia)),
            ("PAQUETE",   cotizacion.paquete.rawValue),
            (cotizacion.paquete == .servicioDiario ? "DÍAS" : "COLABORADORES", colabODias)
        ]
        let colW = cw / CGFloat(items.count)

        for (i, (label, valor)) in items.enumerated() {
            let x = mg + CGFloat(i) * colW
            // Separador vertical
            if i > 0 {
                cLinea.setFill()
                ctx.fill(CGRect(x: x - 0.5, y: y + 4, width: 0.75, height: h - 8))
            }
            atr(label,
                [.font: fuente(7, .bold), .foregroundColor: cGrisTexto, .kern: 1.0],
                rect: CGRect(x: x, y: y + 3, width: colW, height: 9), align: .center)
            atr(valor,
                [.font: fuente(10, .semibold), .foregroundColor: cMorado],
                rect: CGRect(x: x, y: y + 13, width: colW, height: 12), align: .center)
        }

        return y + h
    }

    // MARK: 3 · Datos del cliente y proveedor (2 columnas)
    private static func secClienteProveedor(_ ctx: CGContext, y: CGFloat, cotizacion: Cotizacion) -> CGFloat {
        let tituloY = tituloSeccion(ctx, y: y, texto: "Datos del Cliente")
        var cyL = tituloY        // cursor columna izquierda
        var cyR = tituloY        // cursor columna derecha

        let colIzq = cw * 0.57
        let colDer = cw * 0.38
        let xDer   = mg + colIzq + cw * 0.05

        // ── Columna izquierda: datos del cliente ──
        let datosCliente: [(String, String)] = [
            ("Empresa",   val(cotizacion.cliente.nombreEmpresa)),
            ("RFC",       val(cotizacion.cliente.rfc)),
            ("Contacto",  val(cotizacion.cliente.nombreContacto)),
            ("Puesto",    val(cotizacion.cliente.puesto)),
            ("Teléfono",  val(cotizacion.cliente.telefono)),
            ("Correo",    val(cotizacion.cliente.correo)),
            ("Domicilio", val(cotizacion.cliente.domicilioFiscal))
        ]
        for (i, (etq, v)) in datosCliente.enumerated() {
            cyL = filaDato(ctx, y: cyL, etq: etq, valor: v,
                           x: mg, ancho: colIzq, impar: i % 2 == 1)
        }

        // ── Columna derecha: datos del proveedor ──
        let etqDer: [NSAttributedString.Key: Any] = [.font: fuente(8.5, .bold), .foregroundColor: cMorado]
        let valDer: [NSAttributedString.Key: Any] = [.font: fuente(9.5, .semibold), .foregroundColor: cGrisTitulo]
        let subDer: [NSAttributedString.Key: Any] = [.font: fuente(7.5, .medium), .foregroundColor: cGrisTexto]

        // Pequeño encabezado de proveedor con fondo
        cGrisClaro.setFill()
        ctx.fill(CGRect(x: xDer - 6, y: cyR - 2, width: colDer + 6, height: 14))
        NSAttributedString(string: "DATOS DEL PROVEEDOR", attributes: etqDer)
            .draw(at: CGPoint(x: xDer, y: cyR))
        cyR += 16

        let proveedor: [(String, String, Bool)] = [
            // (etiqueta, valor, esSeparador)
            ("Empresa",   "Vission Wow",        false),
            ("Teléfono",  "55 7209 8995",       false),
            ("Correo",    "visionwow@gmail.com", false),
            ("",          "",                    true),   // separador redes sociales
            ("Instagram", "@vissionwow",         false),
            ("Facebook",  "Vission Wow",         false)
        ]
        for (etq, v, esSep) in proveedor {
            if esSep {
                // Línea + etiqueta "Redes Sociales"
                cLinea.withAlphaComponent(0.6).setFill()
                ctx.fill(CGRect(x: xDer, y: cyR + 3, width: colDer, height: 0.5))
                NSAttributedString(string: "REDES SOCIALES",
                                   attributes: [.font: fuente(6.5, .bold),
                                                .foregroundColor: cGrisTexto,
                                                .kern: 0.8])
                    .draw(at: CGPoint(x: xDer, y: cyR + 6))
                cyR += 15
                continue
            }
            NSAttributedString(string: etq + ":", attributes: subDer)
                .draw(at: CGPoint(x: xDer, y: cyR))
            NSAttributedString(string: v, attributes: valDer)
                .draw(at: CGPoint(x: xDer + 56, y: cyR))
            cyR += 15
        }

        // Regresa el máximo Y de ambas columnas
        return max(cyL, cyR) + 6
    }

    // MARK: 4 · Paquete cotizado
    private static func secPaquete(_ ctx: CGContext, y: CGFloat, cotizacion: Cotizacion) -> CGFloat {
        var cy = tituloSeccion(ctx, y: y, texto: "Paquete Cotizado")

        // Los 3 paquetes fijos siempre se muestran en una fila
        let fixedCases: [Paquete] = [.esencial, .plus, .wowCorporativo]
        let boxH: CGFloat = 90
        let boxW = (cw - 16) / 3
        let gap:  CGFloat = 8

        for (i, paquete) in fixedCases.enumerated() {
            let x    = mg + CGFloat(i) * (boxW + gap)
            // Si el contrato es personalizado, ninguno de los 3 aparece seleccionado
            let sel  = cotizacion.paquete == paquete
            let rect = CGRect(x: x, y: cy, width: boxW, height: boxH)

            if sel {
                let espacio = CGColorSpaceCreateDeviceRGB()
                let cols    = [cMoradoOsc.cgColor, cFucsia.cgColor] as CFArray
                if let grad = CGGradient(colorsSpace: espacio, colors: cols, locations: [0, 1]) {
                    ctx.saveGState()
                    UIBezierPath(roundedRect: rect, cornerRadius: 8).addClip()
                    ctx.drawLinearGradient(grad,
                                           start: CGPoint(x: x, y: cy),
                                           end: CGPoint(x: x + boxW, y: cy + boxH),
                                           options: [])
                    ctx.restoreGState()
                }
            } else {
                cGrisClaro.setFill()
                UIBezierPath(roundedRect: rect, cornerRadius: 8).fill()
                cLinea.setStroke()
                UIBezierPath(roundedRect: rect, cornerRadius: 8).stroke()
            }

            if sel {
                let ckSize: CGFloat = 16
                let ckX = x + boxW - ckSize - 5
                let ckRect = CGRect(x: ckX, y: cy + 5, width: ckSize, height: ckSize)
                cBlanco.withAlphaComponent(0.35).setFill()
                UIBezierPath(ovalIn: ckRect).fill()
                NSAttributedString(string: "✓",
                                   attributes: [.font: fuente(10, .black),
                                                .foregroundColor: cBlanco])
                    .draw(at: CGPoint(x: ckX + 3, y: cy + 7))
            }

            let textColor = sel ? cBlanco : cMorado
            let subColor  = sel ? cBlanco.withAlphaComponent(0.78) : cGrisTexto

            atr(paquete.rawValue.uppercased(),
                [.font: fuente(9.5, .black), .foregroundColor: textColor, .kern: 0.8],
                rect: CGRect(x: x + 6, y: cy + 8, width: boxW - 12, height: 13))
            atr(fmt(paquete.precio) + " / col.",
                [.font: fuente(11, .bold), .foregroundColor: textColor],
                rect: CGRect(x: x + 6, y: cy + 24, width: boxW - 12, height: 14))
            atr(paquete.descripcion,
                [.font: fuente(7.5), .foregroundColor: subColor],
                rect: CGRect(x: x + 6, y: cy + 40, width: boxW - 12, height: boxH - 46))
        }

        cy += boxH + 8

        // ── Card especial para Servicio Diario ────────────────────────
        if cotizacion.paquete == .servicioDiario {
            let cardH: CGFloat = 80
            let cardRect = CGRect(x: mg, y: cy, width: cw, height: cardH)

            let espacio = CGColorSpaceCreateDeviceRGB()
            let cols    = [cMoradoOsc.cgColor, cFucsia.cgColor] as CFArray
            if let grad = CGGradient(colorsSpace: espacio, colors: cols, locations: [0, 1]) {
                ctx.saveGState()
                UIBezierPath(roundedRect: cardRect, cornerRadius: 8).addClip()
                ctx.drawLinearGradient(grad,
                                       start: CGPoint(x: mg, y: cy),
                                       end: CGPoint(x: mg + cw, y: cy + cardH),
                                       options: [])
                ctx.restoreGState()
            }

            // ✓ badge
            let ckRect = CGRect(x: mg + cw - 21, y: cy + 5, width: 16, height: 16)
            cBlanco.withAlphaComponent(0.35).setFill()
            UIBezierPath(ovalIn: ckRect).fill()
            NSAttributedString(string: "✓", attributes: [.font: fuente(10, .black),
                                                          .foregroundColor: cBlanco])
                .draw(at: CGPoint(x: mg + cw - 18, y: cy + 7))

            // Título
            atr("SERVICIO DIARIO — CAMPAÑA DE SALUD VISUAL",
                [.font: fuente(9.5, .black), .foregroundColor: cBlanco, .kern: 0.8],
                rect: CGRect(x: mg + 8, y: cy + 8, width: cw - 40, height: 13))

            // Precio por día / optometrista
            atr("$2,500 / día / optometrista",
                [.font: fuente(11, .bold), .foregroundColor: cBlanco],
                rect: CGRect(x: mg + 8, y: cy + 24, width: cw / 2, height: 14))

            // 3 columnas de métricas
            let dias = cotizacion.diasNecesariosCalculados
            let opts = cotizacion.totalOptometristasAsignados
            let components: [(String, String)] = [
                ("DÍAS NECESARIOS", "\(dias) día\(dias == 1 ? "" : "s")"),
                ("OPTOMETRISTAS",   "\(opts) (\(cotizacion.optometristasGratis) incl. + \(cotizacion.optometristasExtras) extra\(cotizacion.optometristasExtras == 1 ? "" : "s"))"),
                ("TOTAL SERVICIO",  fmt(cotizacion.totalFinal))
            ]
            let compW = (cw - 16) / 3
            for (j, (label, value)) in components.enumerated() {
                let cx2 = mg + 8 + CGFloat(j) * (compW + 4)
                atr(label, [.font: fuente(7, .semibold),
                             .foregroundColor: cBlanco.withAlphaComponent(0.65), .kern: 0.5],
                    rect: CGRect(x: cx2, y: cy + 44, width: compW, height: 10))
                atr(value, [.font: fuente(7.5), .foregroundColor: cBlanco.withAlphaComponent(0.9),
                             .paragraphStyle: wrapStyle],
                    rect: CGRect(x: cx2, y: cy + 55, width: compW, height: 22))
            }

            cy += cardH + 4
        }

        // ── Card especial para paquete personalizado ──────────────────
        if cotizacion.paquete == .personalizado, let custom = cotizacion.componentesPersonalizados {
            let cardH: CGFloat = 80
            let cardRect = CGRect(x: mg, y: cy, width: cw, height: cardH)

            // Fondo degradado
            let espacio = CGColorSpaceCreateDeviceRGB()
            let cols    = [cMoradoOsc.cgColor, cFucsia.cgColor] as CFArray
            if let grad = CGGradient(colorsSpace: espacio, colors: cols, locations: [0, 1]) {
                ctx.saveGState()
                UIBezierPath(roundedRect: cardRect, cornerRadius: 8).addClip()
                ctx.drawLinearGradient(grad,
                                       start: CGPoint(x: mg, y: cy),
                                       end: CGPoint(x: mg + cw, y: cy + cardH),
                                       options: [])
                ctx.restoreGState()
            }

            // ✓ badge
            let ckRect = CGRect(x: mg + cw - 21, y: cy + 5, width: 16, height: 16)
            cBlanco.withAlphaComponent(0.35).setFill()
            UIBezierPath(ovalIn: ckRect).fill()
            NSAttributedString(string: "✓", attributes: [.font: fuente(10, .black),
                                                          .foregroundColor: cBlanco])
                .draw(at: CGPoint(x: mg + cw - 18, y: cy + 7))

            // Título
            atr("PERSONALIZADO — A LA MEDIDA",
                [.font: fuente(9.5, .black), .foregroundColor: cBlanco, .kern: 0.8],
                rect: CGRect(x: mg + 8, y: cy + 8, width: cw - 40, height: 13))

            // Precio total por colaborador
            atr(fmt(custom.precioUnitario) + " / col.",
                [.font: fuente(11, .bold), .foregroundColor: cBlanco],
                rect: CGRect(x: mg + 8, y: cy + 24, width: cw / 2, height: 14))

            // Componentes en 3 columnas
            let compW = (cw - 16) / 3
            let components: [(String, String)] = [
                ("EXAMEN",   "Examen Visual Completo $150"),
                ("ARMAZÓN",  custom.armazon != .ninguno ? custom.armazon.rawValue : "No incluido"),
                ("MICAS",    custom.baseMica != .ninguna ? custom.descripcionMicas : "No incluidas")
            ]
            for (j, (label, value)) in components.enumerated() {
                let cx2 = mg + 8 + CGFloat(j) * (compW + 4)
                atr(label, [.font: fuente(7, .semibold),
                             .foregroundColor: cBlanco.withAlphaComponent(0.65), .kern: 0.5],
                    rect: CGRect(x: cx2, y: cy + 44, width: compW, height: 10))
                atr(value, [.font: fuente(7.5), .foregroundColor: cBlanco.withAlphaComponent(0.9),
                             .paragraphStyle: wrapStyle],
                    rect: CGRect(x: cx2, y: cy + 55, width: compW, height: 22))
            }

            cy += cardH + 4
        }

        return cy
    }

    // MARK: 5 · Datos operativos del servicio
    private static func secDatosServicio(_ ctx: CGContext, y: CGFloat, cotizacion: Cotizacion) -> CGFloat {
        var cy = tituloSeccion(ctx, y: y, texto: "Datos Operativos del Servicio")

        let colW = cw / 2 - 6

        // Formateadores locales
        let fFecha = DateFormatter(); fFecha.locale = Locale(identifier: "es_MX")
        fFecha.dateStyle = .long; fFecha.timeStyle = .none
        let fHora = DateFormatter(); fHora.locale = Locale(identifier: "es_MX")
        fHora.dateStyle = .none; fHora.timeStyle = .short

        let horario = "\(fHora.string(from: cotizacion.horarioInicio)) – \(fHora.string(from: cotizacion.horarioFin)) hrs"

        // Fila 1: fecha | horario
        cy = filaDato(ctx, y: cy, etq: "Fecha de campaña",
                      valor: fFecha.string(from: cotizacion.fechaCampana),
                      x: mg, ancho: colW, impar: false)
        let yFila1 = cy - 14
        filaDato(ctx, y: yFila1, etq: "Horario de atención", valor: horario,
                 x: mg + colW + 12, ancho: colW, impar: false)

        // Fila 2: sede | forma de pago
        cy = filaDato(ctx, y: cy, etq: "Lugar / Sede", valor: val(cotizacion.lugarSede),
                      x: mg, ancho: colW, impar: true)
        filaDato(ctx, y: cy - 14, etq: "Forma de pago", valor: cotizacion.metodoPago.rawValue,
                 x: mg + colW + 12, ancho: colW, impar: true)

        cy = filaDato(ctx, y: cy, etq: "Dirección del servicio", valor: val(cotizacion.direccionServicio),
                      x: mg, ancho: cw, impar: false)

        return cy + 4
    }

    // MARK: 6 · Resumen financiero
    private static func secFinanciero(_ ctx: CGContext, y: CGFloat, cotizacion: Cotizacion) -> CGFloat {
        var cy = tituloSeccion(ctx, y: y, texto: "Resumen Financiero")

        let colEtq: CGFloat = cw - 130
        let colMonto: CGFloat = 126
        let xMonto = mg + cw - colMonto

        // Encabezado de tabla
        cGrisClaro.setFill()
        ctx.fill(CGRect(x: mg, y: cy, width: cw, height: 16))
        atr("CONCEPTO", [.font: fuente(8, .bold), .foregroundColor: cMorado, .kern: 0.8],
            rect: CGRect(x: mg + 4, y: cy + 3, width: colEtq, height: 11))
        atr("IMPORTE (MXN)", [.font: fuente(8, .bold), .foregroundColor: cMorado, .kern: 0.8],
            rect: CGRect(x: xMonto, y: cy + 3, width: colMonto - 4, height: 11), align: .right)
        cy += 18

        // Construcción dinámica de conceptos
        // (etq, monto, isDescuento, isIVA_color)
        var conceptos: [(String, String, Bool, Bool)] = []

        let diasSD = cotizacion.diasNecesariosCalculados
        if cotizacion.paquete == .servicioDiario {
            let optSD = cotizacion.totalOptometristasAsignados
            conceptos.append(("Servicio Diario × \(diasSD) día\(diasSD == 1 ? "" : "s") × \(optSD) optometrista\(optSD == 1 ? "" : "s") ($2,500/día/opto.)",
                               fmt(cotizacion.subtotal), false, false))
        } else if cotizacion.paquete == .personalizado, let custom = cotizacion.componentesPersonalizados {
            conceptos.append(("Examen Visual Completo × \(cotizacion.numeroColaboradores) col.",
                               fmt(150 * Double(cotizacion.numeroColaboradores)), false, false))
            if custom.armazon != .ninguno {
                conceptos.append(("Armazón \(custom.armazon.rawValue) × \(cotizacion.numeroColaboradores) col.",
                                   fmt(custom.armazon.precio * Double(cotizacion.numeroColaboradores)), false, false))
            }
            if custom.baseMica != .ninguna {
                conceptos.append(("Micas \(custom.descripcionMicas) × \(cotizacion.numeroColaboradores) col.",
                                   fmt(custom.precioMicas * Double(cotizacion.numeroColaboradores)), false, false))
            }
        } else {
            let examen  = cotizacion.paquete.costoExamen
            let armazon = cotizacion.paquete.costoArmazon
            let micas   = cotizacion.paquete.costoMicas
            if examen > 0 {
                conceptos.append(("Examen visual ($\(Int(examen))/col.) × \(cotizacion.numeroColaboradores)",
                                   fmt(examen * Double(cotizacion.numeroColaboradores)), false, false))
            }
            if armazon > 0 {
                conceptos.append(("Armazón ($\(Int(armazon))/col.) × \(cotizacion.numeroColaboradores)",
                                   fmt(armazon * Double(cotizacion.numeroColaboradores)), false, false))
            }
            if micas > 0 {
                conceptos.append(("Micas ($\(Int(micas))/col.) × \(cotizacion.numeroColaboradores)",
                                   fmt(micas * Double(cotizacion.numeroColaboradores)), false, false))
            }
        }

        if cotizacion.costoOptometristasExtras > 0 {
            conceptos.append(("Optometristas adicionales (\(cotizacion.optometristasExtras)×$2,500)",
                               fmt(cotizacion.costoOptometristasExtras), false, true))
        }
        if cotizacion.descuentoPromoAplicado {
            conceptos.append(("Descuento ABRIL2026 (−10%)",
                               "−\(fmt(cotizacion.montoDescuentoPromo))", true, false))
        }
        if cotizacion.aplicarIVA && !cotizacion.esEfectivo {
            conceptos.append(("IVA 16% (armazón, micas, servicios)",
                               "+\(fmt(cotizacion.montoIVA))", false, true))
        }

        for (i, (etq, monto, isDes, isIVA)) in conceptos.enumerated() {
            if i % 2 == 1 { cGrisClaro.setFill(); ctx.fill(CGRect(x: mg, y: cy, width: cw, height: 15)) }
            let cEtq = isDes ? cVerde : (isIVA ? cAmbar : cGrisTitulo)
            let cMnt = isDes ? cVerde : (isIVA ? cAmbar : cMorado)
            NSAttributedString(string: etq, attributes: [.font: fuente(8.5), .foregroundColor: cEtq])
                .draw(at: CGPoint(x: mg + 4, y: cy + 2))
            atr(monto, [.font: fuente(9, .semibold), .foregroundColor: cMnt],
                rect: CGRect(x: xMonto, y: cy + 2, width: colMonto - 4, height: 12), align: .right)
            cy += 15
        }

        // ISR informativo
        if !cotizacion.esEfectivo && cotizacion.montoISRRetencion > 0 {
            cy += 4
            cGrisClaro.withAlphaComponent(0.6).setFill()
            ctx.fill(CGRect(x: mg, y: cy, width: cw, height: 14))
            NSAttributedString(string: "ISR retención 10% (referencia — no reduce el total)",
                               attributes: [.font: fuente(7.5), .foregroundColor: cGrisTexto])
                .draw(at: CGPoint(x: mg + 4, y: cy + 2))
            atr(fmt(cotizacion.montoISRRetencion),
                [.font: fuente(8, .semibold), .foregroundColor: cGrisTexto],
                rect: CGRect(x: xMonto, y: cy + 2, width: colMonto - 4, height: 11), align: .right)
            cy += 14
        }

        // Caja del total final
        cy += 4
        let totalH: CGFloat = 32
        let espacio = CGColorSpaceCreateDeviceRGB()
        let cols    = [cMoradoOsc.cgColor, cFucsia.cgColor] as CFArray
        if let grad = CGGradient(colorsSpace: espacio, colors: cols, locations: [0, 1]) {
            ctx.saveGState()
            ctx.clip(to: CGRect(x: mg, y: cy, width: cw, height: totalH))
            ctx.drawLinearGradient(grad,
                                   start: CGPoint(x: mg, y: cy),
                                   end: CGPoint(x: mg + cw, y: cy + totalH),
                                   options: [])
            ctx.restoreGState()
        }
        atr("TOTAL FINAL",
            [.font: fuente(11, .black), .foregroundColor: cBlanco, .kern: 1.2],
            rect: CGRect(x: mg + 10, y: cy + 10, width: cw / 2, height: 16))
        atr(fmt(cotizacion.totalFinal),
            [.font: fuente(16, .black), .foregroundColor: cBlanco],
            rect: CGRect(x: mg, y: cy + 8, width: cw - 10, height: 20), align: .right)

        return cy + totalH + 12
    }

    // MARK: 7 · Forma de pago y estructura de pagos
    private static func secFormaPago(_ ctx: CGContext, y: CGFloat, cotizacion: Cotizacion) {
        var cy = tituloSeccion(ctx, y: y, texto: "Forma de Pago y Condiciones")

        // Checkboxes de método de pago
        let metodos = MetodoPago.allCases
        let boxSize: CGFloat = 10
        let itemW   = cw / CGFloat(metodos.count)

        for (i, m) in metodos.enumerated() {
            let x   = mg + CGFloat(i) * itemW
            let sel = cotizacion.metodoPago == m
            // Cuadro
            if sel {
                cFucsia.setFill()
                ctx.fill(CGRect(x: x, y: cy, width: boxSize, height: boxSize))
                NSAttributedString(string: "✓", attributes: [.font: fuente(7, .bold),
                    .foregroundColor: cBlanco]).draw(at: CGPoint(x: x + 1.5, y: cy))
            } else {
                cLinea.setStroke()
                ctx.stroke(CGRect(x: x, y: cy, width: boxSize, height: boxSize))
            }
            NSAttributedString(string: m.rawValue,
                               attributes: [.font: fuente(sel ? 9.5 : 9, sel ? .semibold : .regular),
                                            .foregroundColor: sel ? cMorado : cGrisTexto])
                .draw(at: CGPoint(x: x + boxSize + 4, y: cy))
        }
        cy += 18

        // Estructura de pagos — 50/50 para Servicio Diario, 5/65/30 para otros
        let pagoH: CGFloat = 70
        let pagoGap: CGFloat = 10

        let pagos: [(String, String, Double, UIColor)]
        if cotizacion.esServicioDiario {
            let pagoW = (cw - pagoGap) / 2
            pagos = [
                ("PAGO INICIAL",      "50% — Anticipo para confirmar\nla asignación del servicio.",
                 cotizacion.pagoApartarFecha, cMorado),
                ("AL INICIAR LABORES","50% — Liquidación completa\nal comenzar el servicio.",
                 cotizacion.anticipo, cFucsia)
            ]
            for (i, (titulo, desc, monto, color)) in pagos.enumerated() {
                let x = mg + CGFloat(i) * (pagoW + pagoGap)
                color.withAlphaComponent(0.10).setFill()
                UIBezierPath(roundedRect: CGRect(x: x, y: cy, width: pagoW, height: pagoH),
                             cornerRadius: 7).fill()
                color.setFill()
                ctx.fill(CGRect(x: x, y: cy, width: 3.5, height: pagoH))
                atr(titulo, [.font: fuente(7.5, .black), .foregroundColor: color, .kern: 0.5],
                    rect: CGRect(x: x + 8, y: cy + 5, width: pagoW - 12, height: 10))
                atr(fmt(monto), [.font: fuente(12, .black), .foregroundColor: color],
                    rect: CGRect(x: x + 8, y: cy + 17, width: pagoW - 12, height: 16))
                atr(desc, [.font: fuente(7), .foregroundColor: cGrisTexto],
                    rect: CGRect(x: x + 8, y: cy + 35, width: pagoW - 12, height: pagoH - 40))
            }
        } else {
            let pagoW = (cw - pagoGap * 2) / 3
            let pagosTres: [(String, String, Double, UIColor)] = [
                ("PARA APARTAR FECHA", "5% — Reserva la fecha. No\nreembolsable si se cancela.",
                 cotizacion.pagoApartarFecha, cLavanda),
                ("AL INICIAR LABORES", "65% — Completa el 70% total\nal comenzar el servicio.",
                 cotizacion.anticipo, cMorado),
                ("AL FINALIZAR",       "30% — Liquidación total al\nconcluir el servicio.",
                 cotizacion.liquidacion, cFucsia)
            ]
            for (i, (titulo, desc, monto, color)) in pagosTres.enumerated() {
                let x = mg + CGFloat(i) * (pagoW + pagoGap)
                color.withAlphaComponent(0.10).setFill()
                UIBezierPath(roundedRect: CGRect(x: x, y: cy, width: pagoW, height: pagoH),
                             cornerRadius: 7).fill()
                color.setFill()
                ctx.fill(CGRect(x: x, y: cy, width: 3.5, height: pagoH))
                atr(titulo, [.font: fuente(7.5, .black), .foregroundColor: color, .kern: 0.5],
                    rect: CGRect(x: x + 8, y: cy + 5, width: pagoW - 12, height: 10))
                atr(fmt(monto), [.font: fuente(12, .black), .foregroundColor: color],
                    rect: CGRect(x: x + 8, y: cy + 17, width: pagoW - 12, height: 16))
                atr(desc, [.font: fuente(7), .foregroundColor: cGrisTexto],
                    rect: CGRect(x: x + 8, y: cy + 35, width: pagoW - 12, height: pagoH - 40))
            }
        }
    }

    // ─────────────────────────────────────────────────────────────────
    // MARK: - PÁGINA 2
    // ─────────────────────────────────────────────────────────────────

    // MARK: · Entregables
    private static func secEntregables(_ ctx: CGContext, y: CGFloat, cotizacion: Cotizacion) -> CGFloat {
        var cy = tituloSeccion(ctx, y: y, texto: "Entregables del Servicio")

        let entregables: [(String, String, Bool)] = [
            ("Examen visual completo",
             "Evaluación optométrica individualizada por colaborador.", true),
            ("Receta visual individual",
             "Documento oficial con prescripción y recomendaciones (si aplica).", true),
            ("Reporte ejecutivo para RH",
             "Resumen estadístico del estado visual del grupo.", true),
            ("Lentes graduados",
             "Incluidos según paquete contratado (Plus, Wow Corporativo y Personalizado con micas).",
             cotizacion.paquete != .esencial
                 && !(cotizacion.paquete == .personalizado
                      && cotizacion.componentesPersonalizados?.baseMica == .ninguna)),
            ("Recomendaciones visuales generales",
             "Guía ergonómica y de salud visual para el equipo.", true)
        ]

        // Una sola columna para evitar truncado en textos largos
        let descAtrs: [NSAttributedString.Key: Any] = [.font: fuente(8), .foregroundColor: cGrisTexto,
                                                        .paragraphStyle: wrapStyle]
        let descW = cw - 22 - 4

        for (i, (titulo, desc, incluido)) in entregables.enumerated() {
            // Fondo alterno
            let descH = max(12, textHeight(desc, size: 8, width: descW))
            let filaH = 14 + descH + 6
            if i % 2 == 1 {
                cGrisClaro.setFill()
                ctx.fill(CGRect(x: mg, y: cy, width: cw, height: filaH))
            }

            // Icono check/x
            let iconColor = incluido ? cVerde : cLinea
            iconColor.setFill()
            ctx.fillEllipse(in: CGRect(x: mg, y: cy + 2, width: 16, height: 16))
            NSAttributedString(string: incluido ? "✓" : "—",
                               attributes: [.font: fuente(9, .black), .foregroundColor: cBlanco])
                .draw(at: CGPoint(x: mg + (incluido ? 2.5 : 4), y: cy + 3.5))

            let cTit = incluido ? cMorado : cGrisTexto
            NSAttributedString(string: titulo,
                               attributes: [.font: fuente(9.5, .semibold), .foregroundColor: cTit])
                .draw(at: CGPoint(x: mg + 22, y: cy + 2))
            NSAttributedString(string: desc, attributes: descAtrs)
                .draw(in: CGRect(x: mg + 22, y: cy + 14, width: descW, height: descH + 2))

            cy += filaH
        }

        return cy + 6
    }

    // MARK: · Observaciones del servicio
    private static func secObservaciones(_ ctx: CGContext, y: CGFloat, cotizacion: Cotizacion) -> CGFloat {
        let cy = tituloSeccion(ctx, y: y, texto: "Observaciones del Servicio")

        // Caja de observaciones — mínimo 72 pt (~5 líneas), crece con el contenido
        let texto = cotizacion.observaciones.uppercased()
        let atrs2: [NSAttributedString.Key: Any] = [
            .font: fuente(9),
            .foregroundColor: cGrisTitulo,
            .paragraphStyle: wrapStyle
        ]

        let cajaW = cw
        let minH: CGFloat = 72
        let textH = texto.isEmpty ? 0 : textHeight(texto, size: 9, width: cajaW - 16)
        let cajaH = max(minH, textH + 16)

        // Fondo de la caja
        cGrisClaro.setFill()
        UIBezierPath(roundedRect: CGRect(x: mg, y: cy, width: cajaW, height: cajaH),
                     cornerRadius: 6).fill()

        // Borde izquierdo decorativo
        cMorado.withAlphaComponent(0.35).setFill()
        ctx.fill(CGRect(x: mg, y: cy, width: 3, height: cajaH))

        if texto.isEmpty {
            // Placeholder cuando está vacío
            atr("Sin observaciones adicionales.",
                [.font: fuente(8.5), .foregroundColor: cGrisTexto.withAlphaComponent(0.6)],
                rect: CGRect(x: mg + 12, y: cy + cajaH / 2 - 6, width: cajaW - 16, height: 14))
        } else {
            NSAttributedString(string: texto, attributes: atrs2)
                .draw(in: CGRect(x: mg + 12, y: cy + 8, width: cajaW - 16, height: textH + 4))
        }

        return cy + cajaH
    }

    // MARK: · Políticas comerciales
    private static func secPoliticas(_ ctx: CGContext, y: CGFloat) -> CGFloat {
        var cy = tituloSeccion(ctx, y: y, texto: "Políticas Comerciales")

        let politicas: [(String, String)] = [
            ("Vigencia",
             "Esta cotización tiene una validez de 30 días naturales a partir de la fecha de emisión."),
            ("Cancelación",
             "El pago para apartar fecha (5%) no es reembolsable en caso de cancelación con menos de 48 horas de anticipación."),
            ("Reprogramación",
             "Cambios de fecha deben solicitarse con mínimo 3 días de anticipación. De lo contrario, se aplica una penalización del 5% del costo total."),
            ("Precios",
             "Los precios pueden variar según volumen, ubicación o requerimientos especiales. Consultar con el ejecutivo de cuenta."),
            ("Facturación",
             "Factura disponible a solicitud. Proporcionar datos fiscales (RFC y domicilio fiscal) al momento de confirmar el servicio.")
        ]

        let descAtrs: [NSAttributedString.Key: Any] = [.font: fuente(8), .foregroundColor: cGrisTexto,
                                                        .paragraphStyle: wrapStyle]

        for (i, (titulo, desc)) in politicas.enumerated() {
            let descH = max(10, textHeight(desc, size: 8, width: cw - 14))
            let filaH = max(28, 14 + descH + 4)

            // Fondo alterno
            if i % 2 == 1 {
                cGrisClaro.setFill()
                ctx.fill(CGRect(x: mg, y: cy, width: cw, height: filaH))
            }

            // Bullet fucsia
            cFucsia.setFill()
            ctx.fillEllipse(in: CGRect(x: mg, y: cy + 4.5, width: 5, height: 5))

            // Título en negrita
            NSAttributedString(string: titulo + ":",
                               attributes: [.font: fuente(8.5, .bold), .foregroundColor: cMorado])
                .draw(at: CGPoint(x: mg + 10, y: cy + 1))

            // Descripción en segunda línea
            NSAttributedString(string: desc, attributes: descAtrs)
                .draw(in: CGRect(x: mg + 10, y: cy + 14, width: cw - 14, height: descH + 2))

            cy += filaH + 2
        }

        return cy + 6
    }

    // MARK: · Encargada de Operaciones
    private static func secEncargadaOperaciones(_ ctx: CGContext, y: CGFloat) -> CGFloat {
        let cy = tituloSeccion(ctx, y: y, texto: "Encargada de Operaciones")

        let cardH: CGFloat = 40
        cGrisClaro.setFill()
        UIBezierPath(roundedRect: CGRect(x: mg, y: cy, width: cw, height: cardH),
                     cornerRadius: 8).fill()
        // Acento lateral fucsia
        cFucsia.setFill()
        ctx.fill(CGRect(x: mg, y: cy, width: 4, height: cardH))

        // Avatar circular
        let avatarSize: CGFloat = 30
        let avatarY = cy + (cardH - avatarSize) / 2
        let espacio = CGColorSpaceCreateDeviceRGB()
        let cols    = [cMoradoOsc.cgColor, cFucsia.cgColor] as CFArray
        if let grad = CGGradient(colorsSpace: espacio, colors: cols, locations: [0, 1]) {
            ctx.saveGState()
            UIBezierPath(ovalIn: CGRect(x: mg + 10, y: avatarY, width: avatarSize, height: avatarSize)).addClip()
            ctx.drawLinearGradient(grad,
                                   start: CGPoint(x: mg + 10, y: avatarY),
                                   end: CGPoint(x: mg + 10 + avatarSize, y: avatarY + avatarSize),
                                   options: [])
            ctx.restoreGState()
        }
        atr("WM", [.font: fuente(11, .black), .foregroundColor: cBlanco],
            rect: CGRect(x: mg + 10, y: avatarY + 8, width: avatarSize, height: 16), align: .center)

        // Datos
        let textX = mg + 10 + avatarSize + 10
        atr("Wendy Yemely Mazariego González",
            [.font: fuente(10, .bold), .foregroundColor: cMorado],
            rect: CGRect(x: textX, y: cy + 8, width: cw - (textX - mg), height: 13))
        atr("Encargada de Operaciones  ·  Vission Wow",
            [.font: fuente(8.5, .medium), .foregroundColor: cGrisTexto],
            rect: CGRect(x: textX, y: cy + 22, width: cw - (textX - mg), height: 11))

        return cy + cardH + 4
    }

    // MARK: · Firmas
    private static func secFirmas(_ ctx: CGContext, y: CGFloat, cotizacion: Cotizacion) {
        var cy = tituloSeccion(ctx, y: y, texto: "Aceptación y Firmas")
        cy += 10

        let colW: CGFloat = (cw - 40) / 2
        let xDer: CGFloat = mg + colW + 40

        let ejecutivo = cotizacion.nombreEjecutivo.isEmpty ? "EJECUTIVO VISSION WOW" : cotizacion.nombreEjecutivo.uppercased()
        let cargo     = cotizacion.cargoEjecutivo.isEmpty  ? "REPRESENTANTE VISSION WOW" : cotizacion.cargoEjecutivo.uppercased()

        let columnas: [(CGFloat, String, [(String, String)], Bool)] = [
            // (x, título, campos, esEjecutivo)
            (mg, "CLIENTE — ACEPTA Y CONTRATA", [
                ("Nombre",  cotizacion.cliente.nombreContacto.uppercased()),
                ("Empresa", cotizacion.cliente.nombreEmpresa.uppercased()),
                ("Fecha",   "")
            ], false),
            (xDer, "VISSION WOW — AUTORIZA", [
                ("Ejecutivo", ejecutivo),
                ("Cargo",     cargo),
                ("Fecha",     "")
            ], true)
        ]

        for (xCol, titulo, campos, esEjecutivo) in columnas {
            // Encabezado
            cGrisClaro.setFill()
            ctx.fill(CGRect(x: xCol, y: cy, width: colW, height: 18))
            atr(titulo, [.font: fuente(8, .black), .foregroundColor: cMorado, .kern: 0.5],
                rect: CGRect(x: xCol, y: cy + 3, width: colW, height: 13), align: .center)

            var fy = cy + 26

            // Área de firma
            let firmaH: CGFloat = 36
            let firmaData: Data? = esEjecutivo ? cotizacion.firmaEjecutivo : cotizacion.firmaCliente
            if let data = firmaData, let img = UIImage(data: data) {
                // Renderizar firma digital
                let sigRect = CGRect(x: xCol + 8, y: fy, width: colW - 16, height: firmaH)
                ctx.saveGState()
                UIBezierPath(roundedRect: sigRect, cornerRadius: 4).addClip()
                img.draw(in: sigRect)
                ctx.restoreGState()
            } else {
                // Placeholder
                cGrisClaro.withAlphaComponent(0.5).setFill()
                UIBezierPath(roundedRect: CGRect(x: xCol + 8, y: fy, width: colW - 16, height: firmaH),
                             cornerRadius: 4).fill()
                let placeholderTexto = esEjecutivo ? "(firma digital no capturada)" : "(firma pendiente del cliente)"
                atr(placeholderTexto,
                    [.font: fuente(7), .foregroundColor: cGrisTexto.withAlphaComponent(0.6)],
                    rect: CGRect(x: xCol + 8, y: fy + 12, width: colW - 16, height: 14), align: .center)
            }
            fy += firmaH + 4

            // Línea de firma
            cFucsia.withAlphaComponent(0.55).setFill()
            ctx.fill(CGRect(x: xCol + 8, y: fy, width: colW - 16, height: 1))
            atr(esEjecutivo ? "Firma digital" : "Firma",
                [.font: fuente(7.5), .foregroundColor: cGrisTexto],
                rect: CGRect(x: xCol, y: fy + 3, width: colW, height: 10), align: .center)
            fy += 16

            // Campos: etiqueta + valor en la misma línea
            let etqAtrs: [NSAttributedString.Key: Any] = [.font: fuente(7.5, .semibold), .foregroundColor: cMorado]
            for (etq, valor) in campos {
                NSAttributedString(string: etq + ":", attributes: etqAtrs)
                    .draw(at: CGPoint(x: xCol + 6, y: fy + 1))
                let etqW = (etq + ": ").size(withAttributes: etqAtrs).width
                if !valor.isEmpty {
                    NSAttributedString(string: valor,
                                       attributes: [.font: fuente(8), .foregroundColor: cGrisTitulo])
                        .draw(at: CGPoint(x: xCol + 6 + etqW, y: fy + 1))
                }
                cLinea.setFill()
                ctx.fill(CGRect(x: xCol + 6, y: fy + 13, width: colW - 12, height: 0.5))
                fy += 18
            }
        }

        // Nota legal
        let notaY = cy + 168
        cGrisClaro.setFill()
        ctx.fill(CGRect(x: mg, y: notaY, width: cw, height: 22))
        cMorado.withAlphaComponent(0.30).setFill()
        ctx.fill(CGRect(x: mg, y: notaY, width: 3, height: 22))
        atr("Al firmar esta cotización, el cliente acepta las condiciones del servicio, la política de cancelación y la estructura de pagos establecida.",
            [.font: fuente(7.5), .foregroundColor: cGrisTexto],
            rect: CGRect(x: mg + 8, y: notaY + 4, width: cw - 12, height: 16))
    }

    // ─────────────────────────────────────────────────────────────────
    // MARK: - Elementos comunes
    // ─────────────────────────────────────────────────────────────────

    // Fondo de página: blanco lavanda muy suave
    private static func fondoPagina(_ ctx: CGContext) {
        cFondoPag.setFill()
        ctx.fill(CGRect(x: 0, y: 0, width: pw, height: ph))
    }

    // Pie de página en todas las hojas
    private static func pie(_ ctx: CGContext, pagina: Int) {
        let y = ph - fh
        // Gradiente fino
        let espacio = CGColorSpaceCreateDeviceRGB()
        let cols = [cMoradoOsc.cgColor, cFucsia.cgColor] as CFArray
        if let grad = CGGradient(colorsSpace: espacio, colors: cols, locations: [0, 1]) {
            ctx.saveGState()
            ctx.clip(to: CGRect(x: 0, y: y, width: pw, height: fh))
            ctx.drawLinearGradient(grad, start: CGPoint(x: 0, y: y),
                                   end: CGPoint(x: pw, y: y), options: [])
            ctx.restoreGState()
        }

        atr("Rodrigo Marcos  •  Vission Wow 👁  •  55 7209 8995  •  visionwow@gmail.com  •  @vissionwow",
            [.font: fuente(8, .medium), .foregroundColor: cBlanco],
            rect: CGRect(x: mg, y: y + 10, width: cw - 40, height: 12), align: .center)

        // Número de página
        atr("Pág. \(pagina)",
            [.font: fuente(8, .semibold), .foregroundColor: cBlanco.withAlphaComponent(0.75)],
            rect: CGRect(x: mg, y: y + 10, width: cw, height: 12), align: .right)
    }

    // ─────────────────────────────────────────────────────────────────
    // MARK: - Primitivos de dibujo
    // ─────────────────────────────────────────────────────────────────

    /// Encabezado de sección: barra fucsia + título en morado + línea
    @discardableResult
    private static func tituloSeccion(_ ctx: CGContext, y: CGFloat, texto: String) -> CGFloat {
        cFucsia.setFill()
        ctx.fill(CGRect(x: mg, y: y, width: 3.5, height: 16))

        NSAttributedString(string: texto.uppercased(),
                           attributes: [.font: fuente(9, .black),
                                        .foregroundColor: cMorado, .kern: 1.2])
            .draw(at: CGPoint(x: mg + 8, y: y + 1))

        cLinea.setFill()
        ctx.fill(CGRect(x: mg, y: y + 19, width: cw, height: 0.75))

        return y + 24
    }

    /// Fila de dato etiqueta: valor con fondo alterno (1 línea)
    @discardableResult
    private static func filaDato(_ ctx: CGContext, y: CGFloat,
                                  etq: String, valor: String,
                                  x: CGFloat, ancho: CGFloat, impar: Bool) -> CGFloat {
        let h: CGFloat = 14
        if impar {
            cGrisClaro.setFill()
            ctx.fill(CGRect(x: x, y: y, width: ancho, height: h))
        }
        let etqW: CGFloat = min(90, ancho * 0.38)
        NSAttributedString(string: etq + ":",
                           attributes: [.font: fuente(7.5, .semibold),
                                        .foregroundColor: cGrisTexto])
            .draw(at: CGPoint(x: x + 2, y: y + 1.5))
        NSAttributedString(string: valor.isEmpty ? "—" : valor,
                           attributes: [.font: fuente(8.5),
                                        .foregroundColor: cGrisTitulo])
            .draw(at: CGPoint(x: x + etqW + 4, y: y + 1.5))
        return y + h
    }

    /// Fila de dato con valor multilinea — para observaciones largas
    @discardableResult
    private static func filaDatoMultilinea(_ ctx: CGContext, y: CGFloat,
                                            etq: String, valor: String,
                                            x: CGFloat, ancho: CGFloat, impar: Bool) -> CGFloat {
        let etqW: CGFloat = min(90, ancho * 0.38)
        let valorAncho = ancho - etqW - 6
        let valAtrs: [NSAttributedString.Key: Any] = [.font: fuente(8.5), .foregroundColor: cGrisTitulo,
                                                       .paragraphStyle: wrapStyle]
        let h = max(14, textHeight(valor, size: 8.5, width: valorAncho) + 6)

        if impar {
            cGrisClaro.setFill()
            ctx.fill(CGRect(x: x, y: y, width: ancho, height: h))
        }
        NSAttributedString(string: etq + ":",
                           attributes: [.font: fuente(7.5, .semibold), .foregroundColor: cGrisTexto])
            .draw(at: CGPoint(x: x + 2, y: y + 2))
        NSAttributedString(string: valor, attributes: valAtrs)
            .draw(in: CGRect(x: x + etqW + 4, y: y + 2, width: valorAncho, height: h))
        return y + h
    }

    // Caché de estilos de párrafo por alineación
    private static let alignStyles: [NSTextAlignment: NSParagraphStyle] = {
        var d: [NSTextAlignment: NSParagraphStyle] = [:]
        for align: NSTextAlignment in [.left, .center, .right] {
            let s = NSMutableParagraphStyle()
            s.alignment = align
            s.lineBreakMode = .byWordWrapping
            d[align] = s.copy() as? NSParagraphStyle
        }
        return d
    }()

    /// Dibuja texto con alineación dentro de un rect
    private static func atr(_ texto: String,
                              _ atrs: [NSAttributedString.Key: Any],
                              rect: CGRect,
                              align: NSTextAlignment = .left) {
        var atrs2 = atrs
        atrs2[.paragraphStyle] = alignStyles[align] ?? wrapStyle
        NSAttributedString(string: texto, attributes: atrs2).draw(in: rect)
    }
}
