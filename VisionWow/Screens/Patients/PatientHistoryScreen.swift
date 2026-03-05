//
//  PatientHistoryScreen.swift
//  VisionWow
//

import SwiftUI
import SwiftData

struct PatientHistoryScreen: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var patient: Patient
    var opticaCompany: Company

    @State private var showRevisionPicker = false
    @State private var encounterForWizard: Encounter? = nil
    @State private var pdfPreviewURL: URL? = nil
    @State private var pdfError: String? = nil
    @State private var showMissingSignaturesAlert = false

    private var sortedEncounters: [Encounter] {
        patient.encounters.sorted { $0.createdAt > $1.createdAt }
    }

    var body: some View {
        ZStack {
            BrandColors.backgroundGradient.ignoresSafeArea()

            VStack(spacing: 0) {
                patientHeader
                    .padding(.horizontal, 16)
                    .padding(.top, 14)
                    .padding(.bottom, 8)

                if sortedEncounters.isEmpty {
                    Spacer()
                    VStack(spacing: 8) {
                        Image(systemName: "clock.arrow.circlepath")
                            .font(.system(size: 40))
                            .foregroundStyle(BrandColors.accent.opacity(0.5))
                        Text("Sin historial de visitas")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                        Text("La primera revisión aparecerá aquí.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 10) {
                            ForEach(sortedEncounters) { enc in
                                encounterCard(enc)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 8)
                        .padding(.bottom, 16)
                    }
                }

                nuevaRevisionButton
                    .padding(.horizontal, 16)
                    .padding(.bottom, 18)
            }
        }
        .navigationTitle("Historial del paciente")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showRevisionPicker) {
            RevisionTypePickerSheet(patient: patient, opticaCompany: opticaCompany) { newEncounter in
                modelContext.insert(newEncounter)
                do { try modelContext.save() } catch { print("ERROR saving draft:", error) }
                showRevisionPicker = false
                encounterForWizard = newEncounter
            }
        }
        .navigationDestination(isPresented: Binding(
            get: { encounterForWizard != nil },
            set: { if !$0 { encounterForWizard = nil } }
        )) {
            if let enc = encounterForWizard {
                opticaWizardScreen(for: enc)
            }
        }
        .sheet(item: Binding(
            get: { pdfPreviewURL.map { PDFPreviewItem(url: $0) } },
            set: { if $0 == nil { pdfPreviewURL = nil } }
        )) { item in
            PDFPreviewScreen(fileURL: item.url)
        }
        .alert("Error al generar PDF", isPresented: Binding(
            get: { pdfError != nil },
            set: { if !$0 { pdfError = nil } }
        )) {
            Button("Aceptar", role: .cancel) { pdfError = nil }
        } message: {
            Text(pdfError ?? "")
        }
        .alert("Firmas pendientes", isPresented: $showMissingSignaturesAlert) {
            Button("Entendido", role: .cancel) {}
        } message: {
            Text("Este expediente requiere la firma del paciente y del optometrista antes de generar el PDF.\n\nAbre el expediente, completa el paso de firmas y vuelve a intentarlo.")
        }
    }

    // MARK: - Patient Header

    private var patientHeader: some View {
        HStack(spacing: 14) {
            avatar

            VStack(alignment: .leading, spacing: 4) {
                Text(fullName)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(.primary)

                if let dob = patient.dob {
                    Text("\(DateUtils.age(from: dob)) años · \(DateUtils.formatShort(dob))")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                let phone = patient.cellPhone.trimmingCharacters(in: .whitespacesAndNewlines)
                if !phone.isEmpty {
                    Label(phone, systemImage: "phone.fill")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()
        }
        .padding(14)
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

    private var avatar: some View {
        ZStack {
            Circle()
                .fill(BrandColors.primary.opacity(0.12))
                .frame(width: 60, height: 60)
            Circle()
                .stroke(BrandColors.strokeGradient, lineWidth: 2)
                .frame(width: 60, height: 60)
            if let data = patient.profileImageData, let img = UIImage(data: data) {
                Image(uiImage: img)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 56, height: 56)
                    .clipShape(Circle())
            } else {
                Image(systemName: "person.fill")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(BrandColors.secondary.opacity(0.8))
            }
        }
    }

    // MARK: - Encounter Card

    private func encounterCard(_ enc: Encounter) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                if enc.isGuarantee {
                    Label("GARANTÍA", systemImage: "shield.checkmark.fill")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(BrandColors.danger)
                        .clipShape(Capsule())
                }
                Text(DateUtils.formatShort(enc.createdAt))
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                Spacer()
                Text(paymentSummary(enc))
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(paymentColor(enc))
            }

            if !enc.diagnostico.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                Label(enc.diagnostico, systemImage: "stethoscope")
                    .font(.system(size: 14))
                    .foregroundStyle(.primary)
                    .lineLimit(2)
            }

            if !enc.lensType.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                Label(enc.lensType, systemImage: "eyeglasses")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            HStack(spacing: 10) {
                Button {
                    encounterForWizard = enc
                } label: {
                    Label("Editar", systemImage: "pencil")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(BrandColors.secondary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(BrandColors.secondary.opacity(0.1))
                        )
                }
                .buttonStyle(.plain)

                Spacer()

                Button {
                    generatePDF(for: enc)
                } label: {
                    Label("Ver PDF", systemImage: "doc.richtext.fill")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(BrandColors.primary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(BrandColors.primary.opacity(0.1))
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.white.opacity(0.86))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(enc.isGuarantee
                                ? BrandColors.danger.opacity(0.25)
                                : BrandColors.accent.opacity(0.16),
                                lineWidth: 1)
                )
                .shadow(color: BrandColors.secondary.opacity(0.07), radius: 14, x: 0, y: 8)
        )
    }

    // MARK: - Nueva Revisión Button

    private var nuevaRevisionButton: some View {
        Button {
            showRevisionPicker = true
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 16, weight: .semibold))
                Text("Nueva Revisión")
                    .font(.system(size: 16, weight: .semibold))
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(BrandColors.primary)
            )
            .shadow(color: BrandColors.primary.opacity(0.22), radius: 10, x: 0, y: 6)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Wizard Navigation

    private func opticaWizardScreen(for enc: Encounter) -> some View {
        ZStack {
            BrandColors.backgroundGradient.ignoresSafeArea()
            EncounterWizardView(
                encounter: enc,
                company: opticaCompany,
                onCancel: {
                    encounterForWizard = nil
                },
                onFinish: { _ in
                    do { try modelContext.save() } catch { print("ERROR saving:", error) }
                    encounterForWizard = nil
                },
                startAt: .antecedents
            )
            .padding(16)
        }
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - PDF

    private func generatePDF(for enc: Encounter) {
        guard enc.patientSignatureData != nil, enc.optometristSignatureData != nil else {
            showMissingSignaturesAlert = true
            return
        }
        do {
            let output = try PDFService.generate(encounter: enc)
            pdfPreviewURL = output.url
        } catch {
            pdfError = error.localizedDescription
        }
    }

    // MARK: - Helpers

    private var fullName: String {
        let f = patient.firstName.trimmingCharacters(in: .whitespacesAndNewlines)
        let l = patient.lastName.trimmingCharacters(in: .whitespacesAndNewlines)
        let combined = [f, l].filter { !$0.isEmpty }.joined(separator: " ")
        return combined.isEmpty ? "Paciente" : combined
    }

    private func paymentSummary(_ e: Encounter) -> String {
        let status = e.payStatus.trimmingCharacters(in: .whitespacesAndNewlines)
        let total  = e.payTotal.trimmingCharacters(in: .whitespacesAndNewlines)
        if !status.isEmpty && !total.isEmpty { return "\(status) · $\(total)" }
        if !status.isEmpty { return status }
        if !total.isEmpty { return "$\(total)" }
        return "Sin pago"
    }

    private func paymentColor(_ e: Encounter) -> Color {
        let s = e.payStatus.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if s.contains("pag") { return BrandColors.success }
        if s.contains("pend") { return BrandColors.warning }
        return .secondary
    }
}

// Identifiable wrapper for PDF URL sheet
private struct PDFPreviewItem: Identifiable {
    let id = UUID()
    let url: URL
}
