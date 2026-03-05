//
//  ReportAuthGate.swift
//  VisionWow
//
//  Pantalla de acceso protegido para los reportes.
//  Muestra usuario + contraseña; al autenticar, muestra el contenido envuelto.
//

import SwiftUI

struct ReportAuthGate<Content: View>: View {
    @ViewBuilder let content: () -> Content

    @State private var username  = ""
    @State private var password  = ""
    @State private var unlocked  = false
    @State private var shake     = false
    @State private var showError = false

    // Credenciales hardcoded (cambiar en el futuro por Keychain/servidor)
    private let validUser = "melimaza"
    private let validPass = "rodrigoywendy2025"

    var body: some View {
        if unlocked {
            content()
        } else {
            loginScreen
        }
    }

    // MARK: - Login screen

    private var loginScreen: some View {
        ZStack {
            BrandColors.backgroundGradient.ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                // Card central
                VStack(spacing: 28) {
                    // Ícono + título
                    VStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(BrandColors.primary.opacity(0.12))
                                .frame(width: 72, height: 72)
                            Image(systemName: "lock.shield.fill")
                                .font(.system(size: 34))
                                .foregroundStyle(BrandColors.strokeGradient)
                        }

                        Text("Acceso restringido")
                            .font(.system(size: 22, weight: .bold, design: .rounded))
                            .foregroundStyle(BrandColors.secondary)

                        Text("Solo personal autorizado puede ver los reportes.")
                            .font(.system(size: 14))
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }

                    // Campos
                    VStack(spacing: 14) {
                        authField(
                            icon: "person.fill",
                            placeholder: "Usuario",
                            text: $username,
                            isSecure: false
                        )

                        authField(
                            icon: "lock.fill",
                            placeholder: "Contraseña",
                            text: $password,
                            isSecure: true
                        )
                    }
                    .offset(x: shake ? -8 : 0)
                    .animation(shake ? .default.repeatCount(4, autoreverses: true).speed(6) : .default, value: shake)

                    // Error
                    if showError {
                        HStack(spacing: 6) {
                            Image(systemName: "exclamationmark.circle.fill")
                            Text("Usuario o contraseña incorrectos")
                        }
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(BrandColors.danger)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                    }

                    // Botón
                    Button(action: attemptLogin) {
                        Text("Entrar")
                            .font(.system(size: 16, weight: .semibold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(BrandColors.primary)
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 13))
                    }
                }
                .padding(32)
                .background(BrandColors.cardFill)
                .clipShape(RoundedRectangle(cornerRadius: 24))
                .shadow(color: BrandColors.secondary.opacity(0.12), radius: 20, x: 0, y: 8)
                .frame(maxWidth: 380)
                .padding(.horizontal, 24)

                Spacer()
            }
        }
        .navigationBarBackButtonHidden(false)
    }

    // MARK: - Field helper

    @ViewBuilder
    private func authField(icon: String, placeholder: String, text: Binding<String>, isSecure: Bool) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .foregroundStyle(BrandColors.primary)
                .frame(width: 20)

            if isSecure {
                SecureField(placeholder, text: text)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .submitLabel(.done)
                    .onSubmit { attemptLogin() }
            } else {
                TextField(placeholder, text: text)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .submitLabel(.next)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 13)
        .background(BrandColors.fieldBackground)
        .clipShape(RoundedRectangle(cornerRadius: 11))
    }

    // MARK: - Auth logic

    private func attemptLogin() {
        if username.lowercased() == validUser && password == validPass {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.80)) {
                showError = false
                unlocked  = true
            }
        } else {
            withAnimation {
                showError = true
                shake     = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                shake = false
            }
        }
    }
}
