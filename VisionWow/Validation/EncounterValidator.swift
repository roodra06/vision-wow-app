//
//  EncounterValidator.swift
//  VisionWow
//
//  Created by Rodrigo Marcos on 27/12/25.
//

import Foundation

enum EncounterValidator {
    static func isEmail(_ s: String) -> Bool {
        let pattern = #"^[^\s@]+@[^\s@]+\.[^\s@]+$"#
        return s.range(of: pattern, options: .regularExpression) != nil
    }

    static func validateStep1(_ e: Encounter) -> [FormValidationError] {
        var errs: [FormValidationError] = []

        func req(_ v: String, _ key: String, _ msg: String = "Campo obligatorio.") {
            if v.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                errs.append(.init(fieldKey: key, message: msg))
            }
        }

        // Datos corporativos (Encounter) — al menos uno de los tres campos de antigüedad
        if e.seniorityYears == nil && e.seniorityMonths == nil && e.seniorityWeeks == nil {
            errs.append(.init(fieldKey: "seniorityYears", message: "Captura antigüedad en años, meses o semanas."))
        }

        req(e.companyName, "companyName")
        req(e.branch, "branch")
        req(e.department, "department")
        req(e.directBoss, "directBoss")

        req(e.shift, "shift", "Selecciona una opción.")
        req(e.companyEmail, "companyEmail")
        if !e.companyEmail.isEmpty && !isEmail(e.companyEmail) {
            errs.append(.init(fieldKey: "companyEmail", message: "Correo de empresa inválido."))
        }

        // Datos personales (Patient)
        guard let p = e.patient else {
            // Si no hay paciente asociado, marca campos clave como faltantes
            errs.append(.init(fieldKey: "patient", message: "Selecciona o crea un paciente."))
            return errs
        }

        req(p.firstName, "firstName")
        req(p.lastName, "lastName")
        if p.dob == nil { errs.append(.init(fieldKey: "dob", message: "Campo obligatorio.")) }

        if p.sex == SexOption.noEspecificado.rawValue {
            errs.append(.init(fieldKey: "sex", message: "Selecciona una opción."))
        }

        req(p.cellPhone, "cellPhone")

        req(p.personalEmail, "personalEmail")
        if !p.personalEmail.isEmpty && !isEmail(p.personalEmail) {
            errs.append(.init(fieldKey: "personalEmail", message: "Correo personal inválido."))
        }

        return errs
    }

    static func validateStep3(_ e: Encounter) -> [FormValidationError] {
        var errs: [FormValidationError] = []

        func req(_ v: String, _ key: String) {
            if v.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                errs.append(.init(fieldKey: key, message: "Campo obligatorio."))
            }
        }

        // Agudeza visual lejana (OD, OI, AO)
        req(e.vaOdSc, "vaOdSc")
        req(e.vaOsSc, "vaOsSc")
        req(e.vaOuSc, "vaOuSc")
        req(e.vaOdCc, "vaOdCc")
        req(e.vaOsCc, "vaOsCc")
        req(e.vaOuCc, "vaOuCc")

        // Agudeza visual cercana (OD, OI, AO)
        req(e.nearVaOdSc, "nearVaOdSc")
        req(e.nearVaOsSc, "nearVaOsSc")
        req(e.nearVaOuSc, "nearVaOuSc")
        req(e.nearVaOdCc, "nearVaOdCc")
        req(e.nearVaOsCc, "nearVaOsCc")
        req(e.nearVaOuCc, "nearVaOuCc")

        req(e.rxOdSph, "rxOdSph")
        req(e.rxOdCyl, "rxOdCyl")
        req(e.rxOdAxis, "rxOdAxis")
        // ADD es opcional — no se valida

        req(e.rxOsSph, "rxOsSph")
        req(e.rxOsCyl, "rxOsCyl")
        req(e.rxOsAxis, "rxOsAxis")
        // ADD es opcional — no se valida

        req(e.dip, "dip")
        req(e.lensType, "lensType")
        req(e.usage, "usage")
        if e.followUpDate == nil {
            errs.append(.init(fieldKey: "followUpDate", message: "Campo obligatorio."))
        }

        req(e.ishihara, "ishihara")
        req(e.campimetry, "campimetry")

        return errs
    }

    static func validateStep4(_ e: Encounter) -> [FormValidationError] {
        var errs: [FormValidationError] = []

        func req(_ v: String, _ key: String) {
            if v.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                errs.append(.init(fieldKey: key, message: "Campo obligatorio."))
            }
        }

        req(e.payStatus, "payStatus")
        req(e.payTotal, "payTotal")
        req(e.payMethod, "payMethod")
        req(e.payReference, "payReference")

        return errs
    }
}
