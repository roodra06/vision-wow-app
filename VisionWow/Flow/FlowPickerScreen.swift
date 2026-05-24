//
//  FlowPickerScreen.swift
//  VisionWow
//
//  Created by Rodrigo Marcos on 12/01/26.
//

import SwiftUI

struct FlowPickerScreen: View {
    @State private var showCompanies      = false
    @State private var showOpticaPatients = false
    @State private var showSync           = false
    @State private var showCotizacion     = false
    @State private var showHistorial      = false
    @Environment(AppSyncState.self) private var syncState

    var body: some View {
        ZStack {
            BrandColors.backgroundGradient.ignoresSafeArea()

            VStack(spacing: 22) {
                Spacer(minLength: 0)

                VStack(spacing: 20) {
                    Image("visionwow_logo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 280, height: 280)
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

                        // Botón Nueva Cotización
                        Button {
                            showCotizacion = true
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "doc.text.fill")
                                Text("Nueva Cotización")
                                    .font(.headline)
                            }
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color(hex: 0x6B2D8B))
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        }
                        .buttonStyle(BounceButtonStyle())
                        .frame(maxWidth: 360)

                        // Botón Historial de Cotizaciones
                        Button {
                            showHistorial = true
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "clock.arrow.circlepath")
                                Text("Historial de Cotizaciones")
                                    .font(.headline)
                            }
                            .foregroundStyle(BrandColors.secondary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(BrandColors.soft.opacity(0.60))
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .stroke(BrandColors.secondary.opacity(0.25), lineWidth: 1)
                            )
                        }
                        .buttonStyle(BounceButtonStyle())
                        .frame(maxWidth: 360)
                    }
                }
                .frame(maxWidth: 420)
                .padding(.horizontal, 20)

                Spacer(minLength: 0)
            }
            .padding(.top, 40)
            .padding(.bottom, 60)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)

            // Botón de sincronización en esquina inferior derecha
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button {
                        showSync = true
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "arrow.triangle.2.circlepath")
                                .font(.system(size: 14, weight: .semibold))
                            Text("Sincronizar iPads")
                                .font(.system(size: 13, weight: .semibold))
                        }
                        .foregroundStyle(BrandColors.secondary)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(BrandColors.soft.opacity(0.80))
                        .clipShape(Capsule())
                        .shadow(color: BrandColors.secondary.opacity(0.12), radius: 6, x: 0, y: 3)
                    }
                    .padding(.trailing, 28)
                    .padding(.bottom, 28)
                }
            }
        }
        .fullScreenCover(isPresented: $showCompanies) {
            CompaniesHomeScreen()
        }
        .fullScreenCover(isPresented: $showOpticaPatients) {
            OpticaPatientsScreen()
        }
        .fullScreenCover(isPresented: $showCotizacion) {
            // NuevaCotizacionView necesita NavigationStack para navegar al resumen
            NavigationStack {
                NuevaCotizacionView()
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Cerrar") { showCotizacion = false }
                                .foregroundStyle(BrandColors.primary)
                        }
                    }
            }
        }
        .fullScreenCover(isPresented: $showHistorial) {
            NavigationStack {
                HistorialCotizacionesView()
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Cerrar") { showHistorial = false }
                                .foregroundStyle(BrandColors.primary)
                        }
                    }
            }
        }
        .sheet(isPresented: $showSync) {
            SyncScreen()
        }
        // Cold-start: URL ya estaba seteada antes de que FlowPickerScreen apareciera
        .onAppear {
            if syncState.incomingURL != nil {
                showSync = true
            }
        }
        // Foreground/background: URL llega mientras la app ya estaba corriendo
        .onChange(of: syncState.incomingURL) { _, url in
            guard url != nil else { return }
            showSync = true
        }
    }
}
