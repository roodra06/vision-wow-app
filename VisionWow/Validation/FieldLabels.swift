//
//  FieldLabels.swift
//  VisionWow
//
//  Created by Rodrigo Marcos on 27/12/25.
//
import Foundation

enum FieldLabels {
    static let map: [String: String] = [
        "seniorityYears": "Antigüedad (Años)",
        "seniorityMonths": "Antigüedad (Meses)",
        "seniorityWeeks": "Antigüedad (Semanas)",
        "companyName": "Nombre de la empresa",
        "branch": "Sucursal",
        "department": "Departamento",
        "directBoss": "Jefe inmediato",
        "shift": "Turno",
        "companyEmail": "Correo de la empresa",
        "firstName": "Nombre",
        "lastName": "Apellidos",
        "dob": "Fecha de nacimiento",
        "sex": "Sexo",
        "cellPhone": "Teléfono celular",
        "personalEmail": "Correo personal",
        "vaOdSc": "Agudeza visual OD S/C",
        "vaOsSc": "Agudeza visual OS S/C",
        "vaOdCc": "Agudeza visual OD C/C",
        "vaOsCc": "Agudeza visual OS C/C",
        "rxOdSph": "RX OD Esfera",
        "rxOdCyl": "RX OD Cilindro",
        "rxOdAxis": "RX OD Eje",
        "rxOdAdd": "RX OD ADD",
        "rxOsSph": "RX OS Esfera",
        "rxOsCyl": "RX OS Cilindro",
        "rxOsAxis": "RX OS Eje",
        "rxOsAdd": "RX OS ADD",
        "dp": "Distancia pupilar (DP)",
        "lensType": "Tipo de lente",
        "usage": "Uso recomendado",
        "followUpDate": "Fecha de seguimiento",
        "ishihara": "Prueba Ishihara",
        "campimetry": "Campimetría",
        "payStatus": "Estatus de pago",
        "payTotal": "Total",
        "payMethod": "Método de pago",
        "payReference": "Referencia"
    ]

    static func human(_ key: String) -> String { map[key] ?? key }
}


