//
//  StepHeader.swift
//  VisionWow
//
//  Created by Rodrigo Marcos on 27/12/25.
//
import SwiftUI

struct StepHeader: View {
    let title: String
    let subtitle: String
    let step: Int
    let total: Int
    let showError: Bool

    var body: some View {
        SectionCard(title: title, subtitle: subtitle) {
            StepProgress(step: step, total: total)
                .padding(.top, 6)

            if showError {
                ToastBanner(text: "Faltan campos obligatorios. Revisa los mensajes en cada sección.")
                    .padding(.top, 10)
            }
        }
    }
}

