//
//  NotaVentaPDFRenderer.swift
//  VisionWow — Nota de venta / comprobante de servicio
//
import UIKit

enum NotaVentaPDFRenderer {

    // MARK: - Constantes

    // Media carta extendida: ancho 5.5", alto ~10.5" para que todo quepa sin encimarse
    private static let pageRect   = CGRect(x: 0, y: 0, width: 396, height: 760)
    private static let marginX:   CGFloat = 20
    private static let marginTop: CGFloat = 14
    private static let w:         CGFloat = 396 - 20 * 2   // 356

    private static let vwTelefono = "55 7209 8995"
    private static let vwWhatsApp  = "@vissionwow"
    private static let vwCorreo    = "visionwow@gmail.com"
    private static let vwSucursal  = "Valle de Chalco, Edo. Méx.  C.P. 56610"

    // MARK: - Punto de entrada

    static func render(encounter: Encounter) -> Data {
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect)
        return renderer.pdfData { ctx in
            ctx.beginPage()

            guard let logo = UIImage(named: "visionwow_logo") else { return }
            let cg = ctx.cgContext
            var y: CGFloat = marginTop

            y = drawHeader(logo: logo, cg: cg, y: y)
            y = drawFolio(encounter: encounter, cg: cg, y: y)
            y = drawOptometristaBar(encounter: encounter, cg: cg, y: y)
            y = drawSeccion("DATOS DEL CLIENTE", y: y)
            y = drawCliente(encounter: encounter, y: y)
            y = drawSeccion("SERVICIO", y: y)
            y = drawServicio(encounter: encounter, y: y)
            y = drawSeccion("PAGO", y: y)
            y = drawPago(encounter: encounter, cg: cg, y: y)
            drawLegendaYFirma(encounter: encounter, cg: cg, y: y)
            drawFooterNota(cg: cg)
        }
    }

    // MARK: - Folio

    static func folio(for encounter: Encounter) -> String {
        let df = DateFormatter()
        df.dateFormat = "yyyyMMdd"
        let dateStr = df.string(from: encounter.createdAt)
        let uuid6   = encounter.id.uuidString
            .replacingOccurrences(of: "-", with: "")
            .prefix(6)
            .uppercased()
        return "VW-\(dateStr)-\(uuid6)"
    }

    // MARK: - Header (gradiente + logo circular + contacto)

    private static func drawHeader(logo: UIImage, cg: CGContext, y: CGFloat) -> CGFloat {
        let h: CGFloat = 60
        let rect = CGRect(x: 0, y: y, width: pageRect.width, height: h)
        PDFStyles.drawBrandGradient(in: rect, ctx: cg)

        // Logo circular
        let logoSize: CGFloat = 44
        let logoRect = CGRect(x: marginX, y: y + (h - logoSize) / 2,
                              width: logoSize, height: logoSize)
        UIColor.white.withAlphaComponent(0.20).setFill()
        UIBezierPath(ovalIn: logoRect).fill()
        cg.saveGState()
        UIBezierPath(ovalIn: logoRect.insetBy(dx: 1, dy: 1)).addClip()
        logo.draw(in: logoRect.insetBy(dx: 1, dy: 1))
        cg.restoreGState()
        UIColor.white.withAlphaComponent(0.55).setStroke()
        let circ = UIBezierPath(ovalIn: logoRect.insetBy(dx: 0.5, dy: 0.5))
        circ.lineWidth = 1.2; circ.stroke()

        // Nombre + subtítulo (zona izquierda)
        let cx   = marginX + logoSize + 10
        let bndW: CGFloat = 148   // ancho zona marca
        txt("VISSION WOW",
            in: CGRect(x: cx, y: y + 10, width: bndW, height: 18),
            font: .systemFont(ofSize: 13, weight: .black), color: .white, align: .left)
        txt("Nota de Venta",
            in: CGRect(x: cx, y: y + 29, width: bndW, height: 11),
            font: .systemFont(ofSize: 7.5, weight: .semibold),
            color: UIColor.white.withAlphaComponent(0.85), align: .left)
        txt("Valle de Chalco  C.P. 56610",
            in: CGRect(x: cx, y: y + 42, width: bndW, height: 11),
            font: .systemFont(ofSize: 6.5, weight: .regular),
            color: UIColor.white.withAlphaComponent(0.65), align: .left)

        // Contacto (derecha)
        let cntW: CGFloat = 120
        let rx = marginX + w - cntW
        txt("Tel. \(vwTelefono)",
            in: CGRect(x: rx, y: y + 10, width: cntW, height: 11),
            font: .systemFont(ofSize: 7.5, weight: .semibold), color: .white, align: .right)
        txt(vwWhatsApp,
            in: CGRect(x: rx, y: y + 23, width: cntW, height: 11),
            font: .systemFont(ofSize: 7.5, weight: .regular),
            color: UIColor.white.withAlphaComponent(0.85), align: .right)
        txt(vwCorreo,
            in: CGRect(x: rx, y: y + 37, width: cntW, height: 11),
            font: .systemFont(ofSize: 7, weight: .regular),
            color: UIColor.white.withAlphaComponent(0.75), align: .right)

        return y + h
    }

    // MARK: - Barra de folio + fecha

    private static func drawFolio(encounter: Encounter, cg: CGContext, y: CGFloat) -> CGFloat {
        let h: CGFloat = 26
        let barRect = CGRect(x: 0, y: y, width: pageRect.width, height: h)
        PDFStyles.cGrisFondo.setFill()
        cg.fill(barRect)
        PDFStyles.cGrisLinea.setFill()
        cg.fill(CGRect(x: 0, y: y + h - 0.6, width: pageRect.width, height: 0.6))

        // Folio (izquierda)
        txt("FOLIO:",
            in: CGRect(x: marginX, y: y + 6, width: 40, height: 14),
            font: .systemFont(ofSize: 8, weight: .semibold), color: PDFStyles.cSecondary, align: .left)
        txt(folio(for: encounter),
            in: CGRect(x: marginX + 44, y: y + 6, width: 180, height: 14),
            font: .systemFont(ofSize: 9, weight: .black), color: PDFStyles.cPrimary, align: .left)

        // Fecha (derecha)
        let df = DateFormatter()
        df.locale = Locale(identifier: "es_MX")
        df.dateFormat = "dd 'de' MMMM 'de' yyyy"
        let dateStr = df.string(from: encounter.createdAt).uppercased()

        txt("FECHA:",
            in: CGRect(x: marginX + w - 166, y: y + 6, width: 38, height: 14),
            font: .systemFont(ofSize: 8, weight: .semibold), color: PDFStyles.cSecondary, align: .right)
        txt(dateStr,
            in: CGRect(x: marginX + w - 124, y: y + 6, width: 124, height: 14),
            font: .systemFont(ofSize: 7.5, weight: .bold), color: PDFStyles.cGrisTitulo, align: .right)

        return y + h + 8
    }

    // MARK: - Barra optometrista + cédula (debajo del folio)

    private static func drawOptometristaBar(encounter: Encounter, cg: CGContext, y: CGFloat) -> CGFloat {
        guard let opt = encounter.optometristName, !opt.isEmpty else { return y }

        let h: CGFloat = 22
        let barRect = CGRect(x: 0, y: y, width: pageRect.width, height: h)

        // Fondo con acento de marca
        PDFStyles.cPrimary.withAlphaComponent(0.07).setFill()
        cg.fill(barRect)
        PDFStyles.drawBrandGradientRounded(
            in: CGRect(x: 0, y: y, width: 4, height: h), radius: 0, ctx: cg)
        PDFStyles.cGrisLinea.setFill()
        cg.fill(CGRect(x: 0, y: y + h - 0.5, width: pageRect.width, height: 0.5))

        // Etiqueta "OPTOMETRISTA"
        txt("OPTOMETRISTA:",
            in: CGRect(x: marginX + 6, y: y + 5, width: 76, height: 12),
            font: .systemFont(ofSize: 7, weight: .semibold), color: PDFStyles.cSecondary, align: .left)

        // Nombre de la optometrista
        txt(opt,
            in: CGRect(x: marginX + 86, y: y + 5, width: 160, height: 12),
            font: .systemFont(ofSize: 8, weight: .bold), color: PDFStyles.cPrimary, align: .left)

        // Cédula (derecha)
        if let ced = cedula(for: opt) {
            txt("CÉD. PROF.  \(ced)",
                in: CGRect(x: marginX + w - 120, y: y + 5, width: 120, height: 12),
                font: .systemFont(ofSize: 7.5, weight: .black), color: PDFStyles.cAccent, align: .right)
        }

        return y + h + 6
    }

    // MARK: - Encabezado de sección compacto

    private static func drawSeccion(_ title: String, y: CGFloat) -> CGFloat {
        guard let ctx = UIGraphicsGetCurrentContext() else { return y + 20 }
        let h: CGFloat = 16
        let rect = CGRect(x: marginX, y: y, width: w, height: h)

        PDFStyles.cPrimary.withAlphaComponent(0.09).setFill()
        UIBezierPath(roundedRect: rect, cornerRadius: 2).fill()
        PDFStyles.cAccent.setFill()
        ctx.fill(CGRect(x: marginX, y: y, width: 3, height: h))

        txt(title,
            in: CGRect(x: marginX + 8, y: y + 2, width: w - 10, height: h - 2),
            font: .systemFont(ofSize: 7.5, weight: .black), color: PDFStyles.cPrimary, align: .left)

        return y + h + 6
    }

    // MARK: - Datos del cliente

    private static func drawCliente(encounter: Encounter, y: CGFloat) -> CGFloat {
        let p = encounter.patient
        let nombre  = [p?.firstName ?? "", p?.lastName ?? ""]
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }.joined(separator: " ")
        let phone   = p?.cellPhone ?? ""
        let email   = p?.personalEmail ?? ""

        var yy = y
        yy = fila("Nombre",   nombre.isEmpty  ? "—" : nombre, y: yy) + 4
        yy = fila("Teléfono", phone.isEmpty   ? "—" : phone,  y: yy) + 4
        yy = fila("Email",    email.isEmpty   ? "—" : email,  y: yy) + 8
        return yy
    }

    // MARK: - Graduación / RX

    private static func drawRx(encounter: Encounter, cg: CGContext, y: CGFloat) -> CGFloat {
        var yy = y
        // Cabecera mini OD / OS
        let halfW = (w - 10) / 2
        drawEyeLabel("OD — Ojo Derecho", color: PDFStyles.cPrimary,
                      x: marginX, y: yy, w: halfW, cg: cg)
        drawEyeLabel("OS — Ojo Izquierdo", color: PDFStyles.cAccent,
                      x: marginX + halfW + 10, y: yy, w: halfW, cg: cg)
        yy += 14 + 4

        // Fila OD
        yy = rxFila(
            sph: encounter.rxOdSph, cyl: encounter.rxOdCyl,
            axis: encounter.rxOdAxis, add: encounter.rxOdAdd,
            eyeColor: PDFStyles.cPrimary, cg: cg, y: yy
        ) + 6

        // Fila OS
        yy = rxFila(
            sph: encounter.rxOsSph, cyl: encounter.rxOsCyl,
            axis: encounter.rxOsAxis, add: encounter.rxOsAdd,
            eyeColor: PDFStyles.cAccent, cg: cg, y: yy
        ) + 6

        // DIP
        yy = fila("D.I.P.", encounter.dip.isEmpty ? "—" : "\(encounter.dip) mm", y: yy) + 8
        return yy
    }

    private static func drawEyeLabel(_ text: String, color: UIColor,
                                      x: CGFloat, y: CGFloat, w: CGFloat, cg: CGContext) {
        let h: CGFloat = 14
        color.withAlphaComponent(0.08).setFill()
        UIBezierPath(roundedRect: CGRect(x: x, y: y, width: w, height: h), cornerRadius: 2).fill()
        color.withAlphaComponent(0.60).setFill()
        cg.fill(CGRect(x: x, y: y, width: 2.5, height: h))
        txt(text, in: CGRect(x: x + 7, y: y + 2, width: w - 10, height: 10),
            font: .systemFont(ofSize: 7.5, weight: .bold), color: color, align: .left)
    }

    private static func rxFila(sph: String, cyl: String, axis: String, add: String,
                                 eyeColor: UIColor, cg: CGContext, y: CGFloat) -> CGFloat {
        let colW = (w - 18) / 4
        let h: CGFloat = 20
        let fields = [("Esfera", sph), ("Cilindro", cyl), ("Eje", axis), ("Adición", add)]
        let lineY = y + h - 1.5

        for (i, (label, value)) in fields.enumerated() {
            let cx = marginX + CGFloat(i) * (colW + 6)
            if !value.isEmpty {
                eyeColor.withAlphaComponent(0.06).setFill()
                UIBezierPath(roundedRect: CGRect(x: cx, y: y, width: colW, height: h), cornerRadius: 2).fill()
            }
            txt(label,
                in: CGRect(x: cx + 2, y: y, width: colW - 4, height: 10),
                font: .systemFont(ofSize: 7, weight: .semibold), color: PDFStyles.cSecondary, align: .left)
            txt(value.isEmpty ? "—" : value,
                in: CGRect(x: cx + 2, y: lineY - 11, width: colW - 4, height: 11),
                font: .systemFont(ofSize: 9, weight: .bold),
                color: value.isEmpty ? PDFStyles.cGrisLinea : PDFStyles.cGrisTitulo, align: .left)
            eyeColor.withAlphaComponent(0.22).setFill()
            cg.fill(CGRect(x: cx + 2, y: lineY, width: colW - 4, height: 0.7))
        }
        return y + h
    }

    // MARK: - Servicio / producto

    private static func drawServicio(encounter: Encounter, y: CGFloat) -> CGFloat {
        var yy = y
        let lensDisplay = formatLensTypeForNota(encounter.lensType)
        // Lente/armazón puede ser largo → usa multilinea para no truncar
        yy = filaMultilinea("Tipo de Lente / Armazón", lensDisplay.isEmpty ? "—" : lensDisplay, y: yy) + 4
        yy = fila("Uso",         encounter.usage.isEmpty      ? "—" : encounter.usage,        y: yy) + 4
        yy = fila("Diagnóstico", encounter.diagnostico.isEmpty ? "—" : encounter.diagnostico, y: yy) + 8
        return yy
    }

    /// Formatea el lensType para la nota:
    /// - Elimina el precio (segmento "· $XXX" al final)
    /// - Traduce colores de armazón a niveles de calidad
    private static func formatLensTypeForNota(_ raw: String) -> String {
        // 1. Quitar precio — todo lo que venga tras "· $" o "· $"
        var result = raw
        if let priceRange = result.range(of: #"\s*·\s*\$[\d,.]+"#,
                                         options: .regularExpression) {
            result = String(result[..<priceRange.lowerBound])
        }

        // 2. Mapear tipo de armazón (color) → calidad
        let frameMap: [(String, String)] = [
            ("Tipo Morado con Clip", "Calidad Premium + Clip Solar"),
            ("Tipo Morado",          "Calidad Premium"),
            ("Tipo Rosa",            "Calidad Estándar"),
            ("Tipo Blanco",          "Calidad Básica")
        ]
        for (from, to) in frameMap {
            result = result.replacingOccurrences(of: from, with: to)
        }

        return result.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // MARK: - Pago (desglose completo)

    private static func drawPago(encounter: Encounter, cg: CGContext, y: CGFloat) -> CGFloat {
        var yy = y

        // ── Tarjeta unificada: desglose + total ───────────────────────
        let steps = parseDiscountSteps(encounter.payDiscount)
        yy = drawPriceCard(steps: steps, encounter: encounter, cg: cg, y: yy)
        yy += 8

        // ── Método y referencia ───────────────────────────────────────
        yy = filaDoble("Método de Pago", encounter.payMethod,
                        "Referencia",    encounter.payReference.isEmpty ? "—" : encounter.payReference,
                        y: yy) + 6

        // ── Anticipo / depósito ───────────────────────────────────────
        if !encounter.payDeposit.isEmpty {
            yy = fila("Anticipo / Depósito", encounter.payDeposit, y: yy) + 6
        }

        // ── Saldo pendiente ───────────────────────────────────────────
        if let total   = monetaryValue(encounter.payTotal),
           let deposit = monetaryValue(encounter.payDeposit),
           total > 0 {
            let balance  = max(0, total - deposit)
            let balColor: UIColor = balance == 0 ? PDFStyles.cVerde : PDFStyles.cAmbar
            let balRect = CGRect(x: marginX, y: yy, width: w, height: 22)
            balColor.withAlphaComponent(0.08).setFill()
            UIBezierPath(roundedRect: balRect, cornerRadius: 3).fill()
            txt("SALDO PENDIENTE",
                in: CGRect(x: marginX + 8, y: yy + 5, width: w * 0.55, height: 12),
                font: .systemFont(ofSize: 7.5, weight: .semibold), color: balColor, align: .left)
            txt(balance == 0 ? "LIQUIDADO" : "$\(String(format: "%.2f", balance))",
                in: CGRect(x: marginX + 8, y: yy + 5, width: w - 16, height: 12),
                font: .systemFont(ofSize: 8.5, weight: .black), color: balColor, align: .right)
            yy += 22 + 6
        }

        // ── Notas ─────────────────────────────────────────────────────
        if let notes = encounter.payNotes, !notes.isEmpty {
            yy = fila("Notas de pago", notes, y: yy) + 4
        }

        return yy + 6
    }

    // MARK: - Tarjeta de precio (desglose + total en un solo bloque)

    private struct DiscountStep {
        let code: String; let pct: Int
        let before: Double; let saving: Double; let after: Double
    }

    private static func parseDiscountSteps(_ raw: String?) -> [DiscountStep] {
        guard let raw, raw.hasPrefix("BASE:"),
              let pipeIdx = raw.firstIndex(of: "|") else { return [] }
        let basePart = String(raw[raw.index(raw.startIndex, offsetBy: 5)..<pipeIdx])
        guard let baseVal = Double(basePart) else { return [] }
        var running = baseVal
        return raw[raw.index(after: pipeIdx)...]
            .split(separator: ",")
            .compactMap { token -> DiscountStep? in
                let kv = token.split(separator: ":")
                guard kv.count == 2, let pct = Int(kv[1]) else { return nil }
                let saving = running * Double(pct) / 100.0
                let after  = running - saving
                let step   = DiscountStep(code: String(kv[0]), pct: pct,
                                          before: running, saving: saving, after: after)
                running = after
                return step
            }
    }

    private static func drawPriceCard(steps: [DiscountStep],
                                       encounter: Encounter,
                                       cg: CGContext, y: CGFloat) -> CGFloat {
        // Columnas
        let colLabel: CGFloat = w * 0.32
        let colPct:   CGFloat = w * 0.13
        let colSave:  CGFloat = w * 0.27
        let colSub:   CGFloat = w - colLabel - colPct - colSave

        let rowH:     CGFloat = 18
        let totalRowH: CGFloat = 32
        let padV:     CGFloat = 8

        // Calcular altura total de la tarjeta
        var cardH = padV                            // padding top
        if !steps.isEmpty {
            cardH += 12                             // encabezado columnas
            cardH += 2                              // divisor
            cardH += rowH                           // fila "Precio base"
            cardH += CGFloat(steps.count) * rowH   // filas de descuento
            cardH += 6                              // separador antes del total
        }
        cardH += totalRowH                          // fila TOTAL
        cardH += padV                               // padding bottom

        // Fondo de tarjeta
        let cardRect = CGRect(x: marginX, y: y, width: w, height: cardH)
        PDFStyles.cGrisFondo.setFill()
        UIBezierPath(roundedRect: cardRect, cornerRadius: 6).fill()
        PDFStyles.cGrisLinea.setStroke()
        UIBezierPath(roundedRect: cardRect.insetBy(dx: 0.4, dy: 0.4), cornerRadius: 6).stroke()
        // Acento izquierdo degradado
        PDFStyles.drawBrandGradientRounded(
            in: CGRect(x: marginX, y: y, width: 3, height: cardH), radius: 1, ctx: cg)

        var yy = y + padV

        if !steps.isEmpty, let first = steps.first {
            // ── Encabezado columnas ──────────────────────────────────
            let hdrFont = UIFont.systemFont(ofSize: 6.5, weight: .semibold)
            let hdrColor = PDFStyles.cSecondary
            txt("CONCEPTO",  in: CGRect(x: marginX + 8, y: yy, width: colLabel - 8, height: 10),
                font: hdrFont, color: hdrColor, align: .left)
            txt("%",         in: CGRect(x: marginX + colLabel, y: yy, width: colPct, height: 10),
                font: hdrFont, color: hdrColor, align: .center)
            txt("AHORRO",    in: CGRect(x: marginX + colLabel + colPct, y: yy, width: colSave, height: 10),
                font: hdrFont, color: hdrColor, align: .right)
            txt("SUBTOTAL",  in: CGRect(x: marginX + colLabel + colPct + colSave, y: yy,
                                         width: colSub - 6, height: 10),
                font: hdrFont, color: hdrColor, align: .right)
            yy += 12

            // Divisor bajo encabezado
            PDFStyles.cGrisLinea.setStroke()
            let d1 = UIBezierPath()
            d1.move(to: CGPoint(x: marginX + 6, y: yy))
            d1.addLine(to: CGPoint(x: marginX + w - 6, y: yy))
            d1.lineWidth = 0.4; d1.stroke()
            yy += 2

            // ── Fila precio base ─────────────────────────────────────
            txt("Precio base",
                in: CGRect(x: marginX + 8, y: yy + 3, width: colLabel - 8, height: 12),
                font: .systemFont(ofSize: 8, weight: .regular), color: PDFStyles.cGrisTexto, align: .left)
            txt("$\(String(format: "%.2f", first.before))",
                in: CGRect(x: marginX + colLabel + colPct + colSave, y: yy + 3,
                            width: colSub - 6, height: 12),
                font: .systemFont(ofSize: 8, weight: .semibold), color: PDFStyles.cGrisTitulo, align: .right)
            yy += rowH

            // ── Una fila por descuento ───────────────────────────────
            for step in steps {
                // Fondo alternado suave
                PDFStyles.cPrimary.withAlphaComponent(0.025).setFill()
                cg.fill(CGRect(x: marginX + 3, y: yy, width: w - 3, height: rowH))

                txt(step.code,
                    in: CGRect(x: marginX + 8, y: yy + 3, width: colLabel - 8, height: 12),
                    font: .systemFont(ofSize: 8.5, weight: .bold), color: PDFStyles.cGrisTitulo, align: .left)
                txt("−\(step.pct)%",
                    in: CGRect(x: marginX + colLabel, y: yy + 3, width: colPct, height: 12),
                    font: .systemFont(ofSize: 8, weight: .bold), color: PDFStyles.cAmbar, align: .center)
                txt("−$\(String(format: "%.2f", step.saving))",
                    in: CGRect(x: marginX + colLabel + colPct, y: yy + 3, width: colSave, height: 12),
                    font: .systemFont(ofSize: 8, weight: .regular), color: PDFStyles.cVerde, align: .right)
                // Subtotal de cada paso (calculado)
                txt("$\(String(format: "%.2f", step.after))",
                    in: CGRect(x: marginX + colLabel + colPct + colSave, y: yy + 3,
                                width: colSub - 6, height: 12),
                    font: .systemFont(ofSize: 8, weight: .semibold), color: PDFStyles.cGrisTitulo, align: .right)
                yy += rowH
            }

            // Separador antes del total
            yy += 3
            PDFStyles.cPrimary.withAlphaComponent(0.18).setStroke()
            let d2 = UIBezierPath()
            d2.move(to: CGPoint(x: marginX + 6, y: yy))
            d2.addLine(to: CGPoint(x: marginX + w - 6, y: yy))
            d2.lineWidth = 0.6; d2.stroke()
            yy += 3
        }

        // ── Fila TOTAL A PAGAR (usa payTotal como valor autoritativo) ─
        PDFStyles.cPrimary.withAlphaComponent(0.10).setFill()
        cg.fill(CGRect(x: marginX + 3, y: yy, width: w - 3, height: totalRowH))

        txt("TOTAL A PAGAR",
            in: CGRect(x: marginX + 8, y: yy + 4, width: colLabel + colPct + colSave - 8, height: 11),
            font: .systemFont(ofSize: 7.5, weight: .semibold), color: PDFStyles.cSecondary, align: .left)

        // Estatus pill
        let statusColor = payStatusColor(encounter.payStatus)
        let statusLabel = encounter.payStatus.isEmpty ? "PENDIENTE" : encounter.payStatus.uppercased()
        let pillW: CGFloat = 86
        let pillRect = CGRect(x: marginX + 8, y: yy + 17, width: pillW, height: 12)
        statusColor.withAlphaComponent(0.12).setFill()
        UIBezierPath(roundedRect: pillRect, cornerRadius: 3).fill()
        statusColor.withAlphaComponent(0.55).setFill()
        cg.fillEllipse(in: CGRect(x: pillRect.minX + 4, y: pillRect.midY - 3, width: 6, height: 6))
        txt(statusLabel,
            in: CGRect(x: pillRect.minX + 13, y: pillRect.minY + 1, width: pillW - 15, height: 10),
            font: .systemFont(ofSize: 7, weight: .bold), color: statusColor, align: .left)

        // Monto final — usa encounter.payTotal directamente (sin re-calcular)
        let totalStr = encounter.payTotal.isEmpty ? "—" : "$\(encounter.payTotal)"
        txt(totalStr,
            in: CGRect(x: marginX + colLabel + colPct + colSave, y: yy + 4,
                        width: colSub - 6, height: 24),
            font: .systemFont(ofSize: 18, weight: .black), color: PDFStyles.cPrimary, align: .right)

        return y + cardH
    }

    // MARK: - Cédulas profesionales registradas

    private static let optometristCedulas: [String: String] = [
        "wendy yemely mazariego gonzález": "14168592",
        "wendy yemely mazariego gonzalez": "14168592",
        "wendy mazariego":                 "14168592"
    ]

    private static func cedula(for name: String) -> String? {
        optometristCedulas[name.lowercased()
            .trimmingCharacters(in: .whitespacesAndNewlines)]
    }

    // MARK: - Leyenda, optometrista y firma

    private static func drawLegendaYFirma(encounter: Encounter, cg: CGContext, y: CGFloat) {
        var yy = y

        // (Optometrista y cédula ya se muestran en la barra superior)

        // Disclaimer — altura calculada automáticamente según el texto real
        let disclaimerText = "Esta nota tiene vigencia de 30 días a partir de la fecha de emisión. " +
            "Conserve este comprobante para cualquier aclaración, cambio o garantía. " +
            "No válida sin sello ni firma."
        let discFont  = UIFont.systemFont(ofSize: 7, weight: .regular)
        let discStyle = NSMutableParagraphStyle()
        discStyle.lineBreakMode = .byWordWrapping
        discStyle.lineSpacing   = 1.5
        let discAttrs: [NSAttributedString.Key: Any] = [
            .font: discFont, .foregroundColor: PDFStyles.cGrisTexto, .paragraphStyle: discStyle
        ]
        let textW   = w - 16
        let textH   = ceil((disclaimerText.uppercased() as NSString).boundingRect(
            with: CGSize(width: textW, height: 9999),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            attributes: discAttrs, context: nil).height)
        let discH   = textH + 10   // padding vertical
        let discRect = CGRect(x: marginX, y: yy, width: w, height: discH)

        PDFStyles.cGrisFondo.setFill()
        UIBezierPath(roundedRect: discRect, cornerRadius: 3).fill()
        PDFStyles.cGrisLinea.setStroke()
        UIBezierPath(roundedRect: discRect.insetBy(dx: 0.4, dy: 0.4), cornerRadius: 3).stroke()

        // Dibujar el texto completo con wrap
        (disclaimerText.uppercased() as NSString).draw(
            in: CGRect(x: marginX + 8, y: yy + 5, width: textW, height: textH),
            withAttributes: discAttrs
        )
    }

    // MARK: - Pie de página de la nota

    private static func drawFooterNota(cg: CGContext) {
        let footerH: CGFloat = 42
        let startY  = pageRect.height - footerH - 14

        PDFStyles.drawBrandGradient(
            in: CGRect(x: 0, y: startY, width: pageRect.width, height: 2), ctx: cg)
        PDFStyles.cGrisFondo.setFill()
        cg.fill(CGRect(x: 0, y: startY + 2, width: pageRect.width, height: footerH - 2))

        let items: [(String, String)] = [
            ("☎", vwTelefono),
            ("◆", vwWhatsApp),
            ("✉", vwCorreo),
            ("◎", "Valle de Chalco, Edo. Méx.")
        ]
        let colW = w / 4
        for (i, (icon, text)) in items.enumerated() {
            let ix = marginX + CGFloat(i) * colW
            let iy = startY + 8

            if i > 0 {
                PDFStyles.cGrisLinea.setFill()
                cg.fill(CGRect(x: ix - 1, y: iy + 2, width: 0.5, height: 22))
            }
            txt(icon,
                in: CGRect(x: ix + 2, y: iy, width: 14, height: 14),
                font: .systemFont(ofSize: 9, weight: .regular), color: PDFStyles.cAccent, align: .center)
            txt(text,
                in: CGRect(x: ix + 18, y: iy + 1, width: colW - 20, height: 12),
                font: .systemFont(ofSize: 7.5, weight: .semibold), color: PDFStyles.cGrisTitulo, align: .left)
        }

        txt("VISSION WOW  ·  La mejor atención en servicio óptico",
            in: CGRect(x: marginX, y: startY + footerH - 16, width: w, height: 11),
            font: .systemFont(ofSize: 7, weight: .regular), color: PDFStyles.cSecondary, align: .center)
    }

    // MARK: - Helpers de layout

    /// Fila simple: label (izquierda) + valor (derecha) con subrayado de marca
    @discardableResult
    private static func fila(_ label: String, _ value: String, y: CGFloat) -> CGFloat {
        let h: CGFloat   = 18
        let labelW: CGFloat = min(100, w * 0.36)
        let lineY = y + h - 1.5
        let textY = lineY - 11 - 1

        txt(label.uppercased(),
            in: CGRect(x: marginX, y: textY, width: labelW, height: 11),
            font: .systemFont(ofSize: 7.5, weight: .semibold), color: PDFStyles.cSecondary, align: .left)
        txt(value.isEmpty ? "—" : value,
            in: CGRect(x: marginX + labelW + 4, y: textY, width: w - labelW - 4, height: 11),
            font: .systemFont(ofSize: 9, weight: .regular), color: PDFStyles.cGrisTitulo, align: .left)
        PDFDraw.drawLine(
            from: CGPoint(x: marginX + labelW + 4, y: lineY),
            to:   CGPoint(x: marginX + w, y: lineY),
            color: PDFStyles.cPrimary.withAlphaComponent(0.20), width: 0.7)
        return y + h
    }

    /// Dos campos en paralelo (2 columnas)
    @discardableResult
    private static func filaDoble(_ l1: String, _ v1: String,
                                   _ l2: String, _ v2: String,
                                   y: CGFloat) -> CGFloat {
        let h: CGFloat   = 18
        let halfW        = (w - 12) / 2
        let lineY        = y + h - 1.5
        let textY        = lineY - 11 - 1
        let labelW: CGFloat = 90

        // Columna 1
        txt(l1.uppercased(),
            in: CGRect(x: marginX, y: textY, width: labelW, height: 11),
            font: .systemFont(ofSize: 7.5, weight: .semibold), color: PDFStyles.cSecondary, align: .left)
        txt(v1.isEmpty ? "—" : v1,
            in: CGRect(x: marginX + labelW + 4, y: textY, width: halfW - labelW - 4, height: 11),
            font: .systemFont(ofSize: 9, weight: .regular), color: PDFStyles.cGrisTitulo, align: .left)
        PDFDraw.drawLine(
            from: CGPoint(x: marginX + labelW + 4, y: lineY),
            to:   CGPoint(x: marginX + halfW, y: lineY),
            color: PDFStyles.cPrimary.withAlphaComponent(0.20), width: 0.7)

        // Columna 2
        let cx = marginX + halfW + 12
        txt(l2.uppercased(),
            in: CGRect(x: cx, y: textY, width: labelW, height: 11),
            font: .systemFont(ofSize: 7.5, weight: .semibold), color: PDFStyles.cSecondary, align: .left)
        txt(v2.isEmpty ? "—" : v2,
            in: CGRect(x: cx + labelW + 4, y: textY, width: halfW - labelW - 4, height: 11),
            font: .systemFont(ofSize: 9, weight: .regular), color: PDFStyles.cGrisTitulo, align: .left)
        PDFDraw.drawLine(
            from: CGPoint(x: cx + labelW + 4, y: lineY),
            to:   CGPoint(x: marginX + w, y: lineY),
            color: PDFStyles.cPrimary.withAlphaComponent(0.20), width: 0.7)

        return y + h
    }

    /// Texto en una línea (trunca con "…" si no cabe)
    private static func txt(_ text: String, in rect: CGRect,
                             font: UIFont, color: UIColor, align: NSTextAlignment) {
        let style = NSMutableParagraphStyle()
        style.alignment = align
        style.lineBreakMode = .byTruncatingTail
        let attrs: [NSAttributedString.Key: Any] = [
            .font: font, .foregroundColor: color, .paragraphStyle: style
        ]
        NSString(string: text.uppercased()).draw(in: rect, withAttributes: attrs)
    }

    /// Texto multilinea que se ajusta al ancho (no trunca).
    /// Devuelve la altura real usada.
    @discardableResult
    private static func txtWrap(_ text: String, x: CGFloat, y: CGFloat, maxW: CGFloat,
                                 font: UIFont, color: UIColor,
                                 align: NSTextAlignment = .left) -> CGFloat {
        let style = NSMutableParagraphStyle()
        style.alignment = align
        style.lineBreakMode = .byWordWrapping
        let attrs: [NSAttributedString.Key: Any] = [
            .font: font, .foregroundColor: color, .paragraphStyle: style
        ]
        let str = text.uppercased() as NSString
        let boundingH = str.boundingRect(
            with: CGSize(width: maxW, height: 9999),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            attributes: attrs, context: nil
        ).height
        str.draw(in: CGRect(x: x, y: y, width: maxW, height: ceil(boundingH)), withAttributes: attrs)
        return ceil(boundingH)
    }

    /// Fila multilinea: etiqueta arriba en gris, valor debajo con wrap, línea al final.
    /// Úsala cuando el valor puede ser largo.
    @discardableResult
    private static func filaMultilinea(_ label: String, _ value: String, y: CGFloat) -> CGFloat {
        let labelW: CGFloat = w          // etiqueta ocupa todo el ancho
        let valueStr = value.isEmpty ? "—" : value
        let valueFont = UIFont.systemFont(ofSize: 9, weight: .regular)

        // Etiqueta pequeña arriba
        txt(label.uppercased(),
            in: CGRect(x: marginX, y: y, width: labelW, height: 11),
            font: .systemFont(ofSize: 7.5, weight: .semibold),
            color: PDFStyles.cSecondary, align: .left)

        // Valor con wrap
        let valY = y + 12
        let valH = txtWrap(valueStr, x: marginX, y: valY, maxW: w,
                           font: valueFont, color: PDFStyles.cGrisTitulo)

        // Línea debajo del valor
        let lineY = valY + valH + 2
        PDFDraw.drawLine(
            from: CGPoint(x: marginX, y: lineY),
            to:   CGPoint(x: marginX + w, y: lineY),
            color: PDFStyles.cPrimary.withAlphaComponent(0.20), width: 0.7)

        return lineY + 4   // siguiente y disponible
    }

    // MARK: - Helpers de lógica

    private static func payStatusColor(_ status: String) -> UIColor {
        let s = status.lowercased()
        if s.contains("pagado") || s.contains("liquidado") || s.contains("completo") {
            return PDFStyles.cVerde
        } else if s.contains("pendiente") || s.contains("parcial") {
            return PDFStyles.cAmbar
        } else {
            return PDFStyles.cSecondary
        }
    }

    private static func monetaryValue(_ str: String) -> Double? {
        let cleaned = str.replacingOccurrences(of: "[^0-9.]", with: "",
                                                options: .regularExpression)
        return Double(cleaned)
    }
}
