//
//  Antecedents.swift
//  VisionWow
//
//  Created by Rodrigo Marcos on 27/12/25.
//

import Foundation

struct Antecedents: Codable, Equatable {
    // Cada subsección es un diccionario [key: Bool] + "otherText"
    var antecedentes: [String: Bool] = [:]
    var antecedentesOther: String = ""

    var sintomas: [String: Bool] = [:]
    var sintomasOther: String = ""

    var cirugias: [String: Bool] = [:]
    var cirugiasOther: String = ""

    var conjuntivitis: [String: Bool] = [:]
    var conjuntivitisOther: String = ""

    var computadora: [String: Bool] = [:]
    var computadoraOther: String = ""

    var anexos: [String: Bool] = [:]
    var anexosOther: String = ""

    var salud: [String: Bool] = [:]
    var saludOther: String = ""

    var saludOcular: [String: Bool] = [:]
    var saludOcularOther: String = ""

    var consultas: [String: Bool] = [:]
    var consultasOther: String = ""

    static func defaults() -> Antecedents {
        var a = Antecedents()

        a.antecedentes = [
            "Alergia a algun medicamento": false,
            "Toma algun medicamento": false,
            "Dolor de Cabeza": false,
            "Migraña": false,
            "Comezon": false,
            "Ardor": false,
            "Lagrimeo": false,
            "Lagaña": false,
            "Manchas o puntos negros": false,
            "Cuerpo Extraño": false,
            "Otra": false
        ]

        a.sintomas = [
            "Ojo flojo": false,
            "Ojo Rojo": false,
            "Ojo seco": false,
            "Pinguecula": false,
            "Pterigion": false,
            "Otra": false
        ]

        a.cirugias = [
            "Cirujia Refractiva": false,
            "Cirujia de catarata": false,
            "Otra": false
        ]

        a.conjuntivitis = [
            "Alergias": false,
            "Bacterianas": false,
            "Virales": false,
            "Hongos": false,
            "Otra": false
        ]

        a.computadora = [
            "Fatiga Ocular": false,
            "Molestia a la luz solar": false,
            "Molestia a los reflejos": false,
            "Otra": false
        ]

        a.anexos = [
            "Cejas": false,
            "Pestañas superiores": false,
            "Pestañas inferiores": false,
            "Parpado superior": false,
            "Parpado inferior": false,
            "Otra": false
        ]

        a.salud = [
            "Diabetes": false,
            "Hipertension": false,
            "Hipotension": false,
            "Tiroides": false,
            "Embarazo": false,
            "Otra": false
        ]

        a.saludOcular = [
            "Afaco": false,
            "Carnosidad": false,
            "Catarata": false,
            "Lefaritis": false,
            "Degeneracon Ocular": false,
            "Desprendimiento de Retina": false,
            "Estravismo": false,
            "Glaucoma": false,
            "Queratocono": false,
            "Retinopatia diabetica": false,
            "Otra": false
        ]

        a.consultas = [
            "Optometria": false,
            "Oftalmologica": false,
            "Medico general": false,
            "Otra": false
        ]

        return a
    }
}
