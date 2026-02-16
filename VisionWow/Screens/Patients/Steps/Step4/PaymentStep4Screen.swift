//
//  PaymentStep4Screen.swift
//  VisionWow
//
//  Created by Rodrigo Marcos on 27/12/25.
//

import SwiftUI
import UIKit

struct PaymentStep4Screen: View {
    @Bindable var encounter: Encounter
    let errors: [String: String]

    // Paso 5/5 (si Pago es el último)
    private let stepIndex = 5
    private let totalSteps = 5

    @State private var showShare = false
    @State private var pdfURL: URL? = nil

    private var patientIdText: String {
        let raw = String(describing: encounter.id)
        return "ID: \(raw.prefix(8))"
    }

    private var fullNameText: String {
        let first = (encounter.patient?.firstName ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        let last  = (encounter.patient?.lastName ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        let combined = [first, last].filter { !$0.isEmpty }.joined(separator: " ")
        return combined.isEmpty ? "Sin nombre" : combined
    }

    private var profileUIImage: UIImage? {
        guard let data = encounter.patient?.profileImageData else { return nil }
        return UIImage(data: data)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                headerCard
                paymentCard
                pdfCard
            }
            .padding(.horizontal, 16)
            .padding(.top, 14)
            .padding(.bottom, 28)
        }
        .sheet(isPresented: $showShare) {
            if let pdfURL {
                ShareSheet(activityItems: [pdfURL])
            }
        }
    }

    // MARK: - Header

    private var headerCard: some View {
        VStack(spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                avatar

                VStack(alignment: .leading, spacing: 8) {
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 6) {
                            Image(systemName: "creditcard.fill")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(BrandColors.accent)

                            Text("Pago")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.secondary)
                        }

                        Text(fullNameText)
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundStyle(.primary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.85)
                    }

                    HStack(spacing: 8) {
                        Image(systemName: "building.2.fill")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(BrandColors.accent)

                        Text(encounter.companyName.isEmpty ? "Empresa" : encounter.companyName)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }

                    HStack(spacing: 8) {
                        Image(systemName: "number")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(BrandColors.accent)

                        Text(patientIdText)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }

                Spacer(minLength: 0)
            }

            VStack(spacing: 6) {
                HStack {
                    Text("Paso \(stepIndex) de \(totalSteps)")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                    Spacer()
                }

                ProgressPillBar(
                    progress: CGFloat(stepIndex) / CGFloat(totalSteps),
                    height: 10
                )
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.white.opacity(0.72))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(BrandColors.accent.opacity(0.16), lineWidth: 1)
                )
                .shadow(color: BrandColors.secondary.opacity(0.06), radius: 14, x: 0, y: 8)
        )
    }

    private var avatar: some View {
        ZStack {
            Circle()
                .fill(BrandColors.primary.opacity(0.12))
                .frame(width: 76, height: 76)

            Circle()
                .stroke(BrandColors.strokeGradient, lineWidth: 3)
                .frame(width: 76, height: 76)

            if let img = profileUIImage {
                Image(uiImage: img)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 70, height: 70)
                    .clipShape(Circle())
            } else {
                Image(systemName: "person.fill")
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundStyle(BrandColors.secondary.opacity(0.85))
            }
        }
    }

    // MARK: - Cards

    private var paymentCard: some View {
        VStack(spacing: 16) {
            sectionHeader(icon: "creditcard.fill", title: "Estatus y método")

            HStack(spacing: 12) {
                FieldRow("Estatus", required: true, error: errors["payStatus"]) {
                    menuPickerInput(
                        icon: "checkmark.seal.fill",
                        selection: $encounter.payStatus,
                        placeholder: "Selecciona…",
                        isError: errors["payStatus"] != nil,
                        options: ["Pagado", "Pendiente", "Cortesía"]
                    )
                }

                FieldRow("Total", required: true, error: errors["payTotal"]) {
                    iconTextField(
                        icon: "dollarsign.circle.fill",
                        placeholder: "0.00",
                        text: $encounter.payTotal,
                        isError: errors["payTotal"] != nil
                    )
                    .keyboardType(.decimalPad)
                }
            }

            HStack(spacing: 12) {
                FieldRow("Método", required: true, error: errors["payMethod"]) {
                    menuPickerInput(
                        icon: "creditcard.and.123",
                        selection: $encounter.payMethod,
                        placeholder: "Selecciona…",
                        isError: errors["payMethod"] != nil,
                        options: ["Efectivo", "Tarjeta", "Transferencia", "Mixto"]
                    )
                }

                FieldRow("Referencia", required: true, error: errors["payReference"]) {
                    iconTextField(
                        icon: "number.circle.fill",
                        placeholder: "",
                        text: $encounter.payReference,
                        isError: errors["payReference"] != nil
                    )
                }
            }

            Divider().opacity(0.35)

            sectionHeader(icon: "tag.fill", title: "Ajustes")

            HStack(spacing: 12) {
                FieldRow("Descuento (opcional)") {
                    iconTextField(
                        icon: "percent",
                        placeholder: "",
                        text: Binding(
                            get: { encounter.payDiscount ?? "" },
                            set: { encounter.payDiscount = $0.isEmpty ? nil : $0 }
                        ),
                        isError: false
                    )
                    .keyboardType(.decimalPad)
                }

                FieldRow("Notas (opcional)") {
                    iconTextField(
                        icon: "note.text",
                        placeholder: "",
                        text: Binding(
                            get: { encounter.payNotes ?? "" },
                            set: { encounter.payNotes = $0.isEmpty ? nil : $0 }
                        ),
                        isError: false
                    )
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.white.opacity(0.82))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(BrandColors.accent.opacity(0.16), lineWidth: 1)
                )
                .shadow(color: BrandColors.secondary.opacity(0.06), radius: 14, x: 0, y: 8)
        )
    }

    private var pdfCard: some View {
        VStack(spacing: 12) {
            sectionHeader(icon: "doc.richtext.fill", title: "PDF")

            Text("Genera el PDF para guardarlo en el iPad y compartirlo (WhatsApp, correo, etc.).")
                .font(.system(size: 14))
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: 10) {
                Button {
                    generatePDFAndShare()
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "square.and.arrow.up")
                        Text("Generar y compartir PDF")
                    }
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(BrandColors.primary)
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.white.opacity(0.82))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(BrandColors.accent.opacity(0.16), lineWidth: 1)
                )
                .shadow(color: BrandColors.secondary.opacity(0.06), radius: 14, x: 0, y: 8)
        )
    }

    // MARK: - UI helpers

    private func sectionHeader(icon: String, title: String) -> some View {
        HStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(BrandColors.primary.opacity(0.10))
                    .frame(width: 28, height: 28)

                Image(systemName: icon)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(BrandColors.secondary.opacity(0.9))
            }

            Text(title)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(BrandColors.secondary)

            Spacer()
        }
        .padding(.top, 2)
    }

    private func iconTextField(
        icon: String,
        placeholder: String,
        text: Binding<String>,
        isError: Bool
    ) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.secondary)

            TextField(placeholder, text: text)
                .visionTextField(isError: isError)
        }
    }

    private func menuPickerInput(
        icon: String,
        selection: Binding<String>,
        placeholder: String,
        isError: Bool,
        options: [String]
    ) -> some View {
        Menu {
            ForEach(options, id: \.self) { opt in
                Button {
                    selection.wrappedValue = opt
                } label: {
                    if selection.wrappedValue == opt {
                        Label(opt, systemImage: "checkmark")
                    } else {
                        Text(opt)
                    }
                }
            }
        } label: {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.secondary)

                Text(selection.wrappedValue.isEmpty ? placeholder : selection.wrappedValue)
                    .foregroundStyle(selection.wrappedValue.isEmpty ? .secondary : .primary)
                    .lineLimit(1)

                Spacer()

                Image(systemName: "chevron.down")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 12)
            .frame(maxWidth: .infinity, minHeight: 44)
            .background(Color.black.opacity(0.04))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(
                        isError ? BrandColors.danger.opacity(0.90)
                                : BrandColors.accent.opacity(0.12),
                        lineWidth: 1
                    )
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity, minHeight: 44)
    }

    // MARK: - PDF

    private func generatePDFAndShare() {
        guard let logo = UIImage(named: "visionwow_logo") else {
            print("ERROR: No se encontró el asset visionwow_logo en Assets.xcassets")
            return
        }

        let data = PDFRenderer.render(encounter: encounter, logo: logo)

        do {
            let url = try writePDFToDocuments(data: data, fileName: makePDFName())
            pdfURL = url
            showShare = true
        } catch {
            print("ERROR writing PDF:", error)
        }
    }

    private func makePDFName() -> String {
        let id = String(describing: encounter.id).prefix(8)
        let safeName = fullNameText
            .replacingOccurrences(of: " ", with: "_")
            .replacingOccurrences(of: "/", with: "-")
        return "VisionWow_\(safeName)_\(id).pdf"
    }

    private func writePDFToDocuments(data: Data, fileName: String) throws -> URL {
        let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let url = dir.appendingPathComponent(fileName)
        try data.write(to: url, options: [.atomic])
        return url
    }
}

// MARK: - Share Sheet (UIActivityViewController)
struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
