//
//  EncounterValidator.swift
//  VisionWow
//
//  Created by Rodrigo Marcos on 27/12/25.
//

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

        if e.seniorityYears == nil { errs.append(.init(fieldKey: "seniorityYears", message: "Campo obligatorio.")) }
        if e.seniorityMonths == nil { errs.append(.init(fieldKey: "seniorityMonths", message: "Campo obligatorio.")) }
        if e.seniorityWeeks == nil { errs.append(.init(fieldKey: "seniorityWeeks", message: "Campo obligatorio.")) }

        req(e.companyName, "companyName")
        req(e.branch, "branch")
        req(e.department, "department")
        req(e.directBoss, "directBoss")

        req(e.shift, "shift", "Selecciona una opción.")
        req(e.companyEmail, "companyEmail")
        if !e.companyEmail.isEmpty && !isEmail(e.companyEmail) {
            errs.append(.init(fieldKey: "companyEmail", message: "Correo de empresa inválido."))
        }

        req(e.firstName, "firstName")
        req(e.lastName, "lastName")
        if e.dob == nil { errs.append(.init(fieldKey: "dob", message: "Campo obligatorio.")) }

        if e.sex == SexOption.noEspecificado.rawValue {
            errs.append(.init(fieldKey: "sex", message: "Selecciona una opción."))
        }

        req(e.cellPhone, "cellPhone")

        req(e.personalEmail, "personalEmail")
        if !e.personalEmail.isEmpty && !isEmail(e.personalEmail) {
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

        req(e.vaOdSc, "vaOdSc")
        req(e.vaOsSc, "vaOsSc")
        req(e.vaOdCc, "vaOdCc")
        req(e.vaOsCc, "vaOsCc")

        req(e.rxOdSph, "rxOdSph")
        req(e.rxOdCyl, "rxOdCyl")
        req(e.rxOdAxis, "rxOdAxis")
        req(e.rxOdAdd, "rxOdAdd")

        req(e.rxOsSph, "rxOsSph")
        req(e.rxOsCyl, "rxOsCyl")
        req(e.rxOsAxis, "rxOsAxis")
        req(e.rxOsAdd, "rxOsAdd")

        req(e.dp, "dp")
        req(e.lensType, "lensType")
        req(e.usage, "usage")
        if e.followUpDate == nil { errs.append(.init(fieldKey: "followUpDate", message: "Campo obligatorio.")) }

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
