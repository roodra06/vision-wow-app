//
//  PDFStyles.swift
//  VisionWow — Paleta de marca para documentos PDF
//
import UIKit

enum PDFStyles {

    // MARK: - Paleta de marca (idéntica a PDFGeneratorVW)

    /// Morado oscuro — fondo de gradientes
    static let cPrimary    = UIColor(red: 107/255, green: 45/255,  blue: 139/255, alpha: 1)
    /// Morado medio — títulos y texto de marca
    static let cSecondary  = UIColor(red: 118/255, green: 57/255,  blue: 118/255, alpha: 1)
    /// Fucsia — extremo del gradiente y acentos
    static let cAccent     = UIColor(red: 230/255, green: 56/255,  blue: 127/255, alpha: 1)
    /// Lavanda — acentos suaves
    static let cLavanda    = UIColor(red: 182/255, green: 115/255, blue: 173/255, alpha: 1)
    /// Verde — estados positivos / pagado
    static let cVerde      = UIColor(red: 46/255,  green: 138/255, blue: 107/255, alpha: 1)
    /// Ámbar — advertencias
    static let cAmbar      = UIColor(red: 191/255, green: 122/255, blue: 43/255,  alpha: 1)

    // MARK: - Grises funcionales
    static let cGrisFondo  = UIColor(red: 246/255, green: 245/255, blue: 250/255, alpha: 1)
    static let cGrisLinea  = UIColor(red: 210/255, green: 207/255, blue: 218/255, alpha: 1)
    static let cGrisTexto  = UIColor(red: 100/255, green: 98/255,  blue: 110/255, alpha: 1)
    static let cGrisTitulo = UIColor(red: 38/255,  green: 35/255,  blue: 48/255,  alpha: 1)
    static let cBlanco     = UIColor.white

    // MARK: - Tipografías PDF

    static let sectionTitleFont  = UIFont.systemFont(ofSize: 10,   weight: .black)
    static let miniTitleFont     = UIFont.systemFont(ofSize: 9,     weight: .bold)
    static let labelFont         = UIFont.systemFont(ofSize: 8.5,  weight: .semibold)
    static let valueFont         = UIFont.systemFont(ofSize: 9.0,  weight: .regular)
    static let captionFont       = UIFont.systemFont(ofSize: 7.5,  weight: .regular)

    // Mantenidos para compatibilidad
    static let titleColor        = UIColor(red: 112/255, green: 56/255, blue: 120/255, alpha: 1)
    static let subtleLine        = UIColor.black.withAlphaComponent(0.18)
    static let headerRightFont   = UIFont.systemFont(ofSize: 9.5,  weight: .semibold)
    static let headerCenterTitleFont = UIFont.systemFont(ofSize: 10.5, weight: .bold)
    static let headerCenterBodyFont  = UIFont.systemFont(ofSize: 8.8,  weight: .regular)

    // MARK: - Helpers de dibujo

    /// Gradiente horizontal de marca (morado → fucsia)
    static func drawBrandGradient(in rect: CGRect, ctx: CGContext) {
        let esp   = CGColorSpaceCreateDeviceRGB()
        let cols  = [cPrimary.cgColor, cAccent.cgColor] as CFArray
        guard let grad = CGGradient(colorsSpace: esp, colors: cols, locations: [0, 1]) else { return }
        ctx.saveGState()
        UIBezierPath(roundedRect: rect, cornerRadius: 0).addClip()
        ctx.drawLinearGradient(grad,
                               start: CGPoint(x: rect.minX, y: rect.midY),
                               end:   CGPoint(x: rect.maxX, y: rect.midY),
                               options: [])
        ctx.restoreGState()
    }

    /// Gradiente horizontal de marca con esquinas redondeadas
    static func drawBrandGradientRounded(in rect: CGRect, radius: CGFloat, ctx: CGContext) {
        let esp   = CGColorSpaceCreateDeviceRGB()
        let cols  = [cPrimary.cgColor, cAccent.cgColor] as CFArray
        guard let grad = CGGradient(colorsSpace: esp, colors: cols, locations: [0, 1]) else { return }
        ctx.saveGState()
        UIBezierPath(roundedRect: rect, cornerRadius: radius).addClip()
        ctx.drawLinearGradient(grad,
                               start: CGPoint(x: rect.minX, y: rect.midY),
                               end:   CGPoint(x: rect.maxX, y: rect.midY),
                               options: [])
        ctx.restoreGState()
    }

    /// Dibuja una tarjeta blanca con borde izquierdo de acento y fondo muy suave
    static func drawSectionCard(in rect: CGRect, ctx: CGContext) {
        // Fondo blanco con sombra suave
        ctx.saveGState()
        UIBezierPath(roundedRect: rect, cornerRadius: 4).addClip()
        cGrisFondo.setFill()
        UIBezierPath(roundedRect: rect, cornerRadius: 4).fill()
        ctx.restoreGState()

        // Borde izquierdo de acento
        cPrimary.withAlphaComponent(0.70).setFill()
        ctx.fill(CGRect(x: rect.minX, y: rect.minY, width: 3, height: rect.height))

        // Borde exterior sutil
        cGrisLinea.setStroke()
        let border = UIBezierPath(roundedRect: rect.insetBy(dx: 0.5, dy: 0.5), cornerRadius: 4)
        border.lineWidth = 0.6
        border.stroke()
    }

    // MARK: - Parseo de descuentos

    /// Convierte el string interno de descuentos en texto legible.
    /// Formato interno: "BASE:3500.00|FAMILIA:10,PROMO5:5"
    /// Resultado:       "FAMILIA −10%  ·  PROMO5 −5%"   (o "—" si no hay)
    static func formatDiscount(_ raw: String?) -> String {
        guard let raw, raw.hasPrefix("BASE:"),
              let pipeIdx = raw.firstIndex(of: "|") else {
            return "—"
        }
        let codesPart = String(raw[raw.index(after: pipeIdx)...])
        guard !codesPart.isEmpty else { return "—" }

        let parts = codesPart.split(separator: ",").compactMap { token -> String? in
            let kv = token.split(separator: ":")
            guard kv.count == 2 else { return nil }
            return "\(kv[0]) −\(kv[1])%"
        }
        return parts.isEmpty ? "—" : parts.joined(separator: "  ·  ")
    }
}
