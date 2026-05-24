//
//  ClienteModel.swift
//  VisionWow — Módulo de Cotizaciones
//

import Foundation

struct Cliente: Codable {
    var nombreContacto:  String  // persona de contacto
    var nombreEmpresa:   String  // razón social o nombre comercial
    var puesto:          String  // cargo del contacto
    var telefono:        String  // 10 dígitos
    var correo:          String  // correo electrónico válido
    var rfc:             String  // RFC (opcional)
    var domicilioFiscal: String  // domicilio fiscal (opcional)

    // MARK: - Validaciones

    var telefonoValido: Bool {
        telefono.filter { $0.isNumber }.count == 10
    }

    var correoValido: Bool {
        guard !correo.isEmpty else { return false }
        let patron = #"^[A-Za-z0-9._%+\-]+@[A-Za-z0-9.\-]+\.[A-Za-z]{2,}$"#
        return correo.range(of: patron, options: .regularExpression) != nil
    }

    var esValido: Bool {
        !nombreContacto.trimmingCharacters(in: .whitespaces).isEmpty &&
        !nombreEmpresa.trimmingCharacters(in: .whitespaces).isEmpty &&
        telefonoValido &&
        correoValido
    }

    // MARK: - Init

    init(nombreContacto:  String = "",
         nombreEmpresa:   String = "",
         puesto:          String = "",
         telefono:        String = "",
         correo:          String = "",
         rfc:             String = "",
         domicilioFiscal: String = "") {
        self.nombreContacto  = nombreContacto
        self.nombreEmpresa   = nombreEmpresa
        self.puesto          = puesto
        self.telefono        = telefono
        self.correo          = correo
        self.rfc             = rfc
        self.domicilioFiscal = domicilioFiscal
    }
}
