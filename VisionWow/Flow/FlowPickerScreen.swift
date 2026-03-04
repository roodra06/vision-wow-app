//
//  FlowPickerScreen.swift
//  VisionWow
//
//  Created by Rodrigo Marcos on 12/01/26.
//

import SwiftUI

struct FlowPickerScreen: View {
    @State private var showCompanies = false
    @State private var showOpticaPatients = false

    var body: some View {
        ZStack {
            BrandColors.backgroundGradient.ignoresSafeArea()

            VStack(spacing: 22) {
                Spacer(minLength: 0)

                VStack(spacing: 20) {
                    Image("visionwow_logo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 280, height: 280)   // ✅ doble
                        .clipShape(Circle())
                        .shadow(color: BrandColors.secondary.opacity(0.10), radius: 18, x: 0, y: 10)

                    Text("Selecciona el tipo de atención")
                        .font(.system(size: 26, weight: .semibold, design: .rounded))
                        .foregroundStyle(BrandColors.secondary)
                        .multilineTextAlignment(.center)

                    VStack(spacing: 14) {
                        PrimaryButton(title: "Atender empresa") {
                            showCompanies = true
                        }
                        .frame(maxWidth: 360)

                        SecondaryButton(title: "Pacientes en óptica") {
                            showOpticaPatients = true
                        }
                        .frame(maxWidth: 360)
                    }
                }
                // ✅ Centrado horizontal + ancho controlado
                .frame(maxWidth: 420)
                .padding(.horizontal, 20)

                Spacer(minLength: 0)
            }
            // ✅ Ajuste fino para que quede “más abajo” sin verse pegado al centro exacto
            .padding(.top, 40)
            .padding(.bottom, 60)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        }
        .fullScreenCover(isPresented: $showCompanies) {
            CompaniesHomeScreen()
        }
        .fullScreenCover(isPresented: $showOpticaPatients) {
            OpticaPatientsScreen()
        }
    }
}
