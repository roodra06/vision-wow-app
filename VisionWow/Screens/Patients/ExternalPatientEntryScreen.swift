//
//  ExternalPatientEntryScreen.swift
//  VisionWow
//
//  Created by Rodrigo Marcos on 12/01/26.
//
import SwiftUI
import SwiftData

struct ExternalPatientEntryScreen: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var showPatientForm = false
    @State private var walkInCompany: Company? = nil

    var body: some View {
        ZStack {
            BrandColors.backgroundGradient.ignoresSafeArea()

            VStack(spacing: 14) {
                Text("Paciente en óptica")
                    .font(.system(size: 28, weight: .semibold, design: .rounded))
                    .foregroundStyle(BrandColors.secondary)

                Text("Registro directo de paciente (empresa por defecto: Óptica).")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 18)

                PrimaryButton(title: "Abrir formulario") {
                    prepareAndOpenForm()
                }
                .frame(maxWidth: 320)

                SecondaryButton(title: "Volver") {
                    dismiss()
                }
                .frame(maxWidth: 320)

                Spacer()
            }
            .padding(.top, 24)
            .padding(.horizontal, 16)
        }
        .onAppear {
            // Abrir directo al entrar, como pediste
            prepareAndOpenForm()
        }
        .sheet(isPresented: $showPatientForm) {
            if let company = walkInCompany {
                // MISMO FORMULARIO, con Company = Óptica
                NewPatientSheet(company: company)
            } else {
                // Esto ya casi nunca se verá, pero por seguridad:
                VStack(spacing: 12) {
                    ProgressView()
                    Text("No se pudo preparar el formulario.")
                        .foregroundStyle(.secondary)
                }
                .padding()
            }
        }
    }

    private func prepareAndOpenForm() {
        // 1) Asegurar empresa Óptica
        let c = WalkInCompanyStore.ensure(modelContext: modelContext)
        walkInCompany = c

        // 2) Presentar sheet DESPUÉS (garantiza que walkInCompany ya existe)
        DispatchQueue.main.async {
            showPatientForm = true
        }
    }
}
