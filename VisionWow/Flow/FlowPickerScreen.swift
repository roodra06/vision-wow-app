//
//  FlowPickerScreen.swift
//  VisionWow
//
//  Created by Rodrigo Marcos on 12/01/26.
//
//
//  FlowPickerScreen.swift
//  VisionWow
//

import SwiftUI

struct FlowPickerScreen: View {
    @State private var showCompanies = false
    @State private var showOpticaPatients = false

    var body: some View {
        ZStack {
            BrandColors.backgroundGradient.ignoresSafeArea()

            VStack(spacing: 20) {
                Image("visionwow_logo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 90, height: 90)
                    .clipShape(Circle())

                Text("Selecciona el tipo de atención")
                    .font(.system(size: 26, weight: .semibold, design: .rounded))
                    .foregroundStyle(BrandColors.secondary)

                PrimaryButton(title: "Atender empresa") {
                    showCompanies = true
                }
                .frame(maxWidth: 340)

                SecondaryButton(title: "Pacientes en óptica") {
                    showOpticaPatients = true
                }
                .frame(maxWidth: 340)

                Spacer()
            }
            .padding(.top, 30)
            .padding(.horizontal, 16)
        }
        .fullScreenCover(isPresented: $showCompanies) {
            CompaniesHomeScreen()
        }
        .fullScreenCover(isPresented: $showOpticaPatients) {
            OpticaPatientsScreen()
        }
    }
}



