//
//  ExamStep3Screen.swift
//  VisionWow
//
//  Created by Rodrigo Marcos on 27/12/25.
//

import SwiftUI
import UIKit

struct ExamStep3Screen: View {
    @Bindable var encounter: Encounter
    let errors: [String: String]

    // Paso 4/4
    private let stepIndex = 4
    private let totalSteps = 4

    private var patientIdText: String {
        let raw = String(describing: encounter.id)
        return "ID: \(raw.prefix(8))"
    }

    private var fullNameText: String {
        let first = encounter.firstName.trimmingCharacters(in: .whitespacesAndNewlines)
        let last  = encounter.lastName.trimmingCharacters(in: .whitespacesAndNewlines)
        let combined = [first, last].filter { !$0.isEmpty }.joined(separator: " ")
        return combined.isEmpty ? "Sin nombre" : combined
    }

    private var profileUIImage: UIImage? {
        guard let data = encounter.profileImageData else { return nil }
        return UIImage(data: data)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                headerCard
                examCard
                TestsView(encounter: encounter, errors: errors)
            }
            .padding(.horizontal, 16)
            .padding(.top, 14)
            .padding(.bottom, 28)
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
                            Image(systemName: "eye.fill")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(BrandColors.accent)

                            Text("Examen visual")
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

    // MARK: - Main Card

    private var examCard: some View {
        VStack(spacing: 16) {

            sectionHeader(icon: "eye.fill", title: "Agudeza visual")

            HStack(spacing: 12) {
                FieldRow("OD S/C", required: true, error: errors["vaOdSc"]) {
                    iconTextField(systemName: "eye", text: $encounter.vaOdSc, isError: errors["vaOdSc"] != nil)
                }
                FieldRow("OS S/C", required: true, error: errors["vaOsSc"]) {
                    iconTextField(systemName: "eye", text: $encounter.vaOsSc, isError: errors["vaOsSc"] != nil)
                }
                FieldRow("OD C/C", required: true, error: errors["vaOdCc"]) {
                    iconTextField(systemName: "eyeglasses", text: $encounter.vaOdCc, isError: errors["vaOdCc"] != nil)
                }
                FieldRow("OS C/C", required: true, error: errors["vaOsCc"]) {
                    iconTextField(systemName: "eyeglasses", text: $encounter.vaOsCc, isError: errors["vaOsCc"] != nil)
                }
            }

            Divider().opacity(0.35)

            sectionHeader(icon: "scope", title: "Refracción")

            // OD
            subsectionLabel("OD", icon: "r.circle.fill")

            HStack(spacing: 12) {
                FieldRow("SPH", required: true, error: errors["rxOdSph"]) {
                    iconTextField(systemName: "plus.forwardslash.minus", text: $encounter.rxOdSph, isError: errors["rxOdSph"] != nil)
                }
                FieldRow("CYL", required: true, error: errors["rxOdCyl"]) {
                    iconTextField(systemName: "circlebadge.2.fill", text: $encounter.rxOdCyl, isError: errors["rxOdCyl"] != nil)
                }
                FieldRow("AXIS", required: true, error: errors["rxOdAxis"]) {
                    iconTextField(systemName: "dial.high.fill", text: $encounter.rxOdAxis, isError: errors["rxOdAxis"] != nil)
                }
                FieldRow("ADD", required: true, error: errors["rxOdAdd"]) {
                    iconTextField(systemName: "plus.circle.fill", text: $encounter.rxOdAdd, isError: errors["rxOdAdd"] != nil)
                }
            }

            // OS
            subsectionLabel("OS", icon: "l.circle.fill")

            HStack(spacing: 12) {
                FieldRow("SPH", required: true, error: errors["rxOsSph"]) {
                    iconTextField(systemName: "plus.forwardslash.minus", text: $encounter.rxOsSph, isError: errors["rxOsSph"] != nil)
                }
                FieldRow("CYL", required: true, error: errors["rxOsCyl"]) {
                    iconTextField(systemName: "circlebadge.2.fill", text: $encounter.rxOsCyl, isError: errors["rxOsCyl"] != nil)
                }
                FieldRow("AXIS", required: true, error: errors["rxOsAxis"]) {
                    iconTextField(systemName: "dial.high.fill", text: $encounter.rxOsAxis, isError: errors["rxOsAxis"] != nil)
                }
                FieldRow("ADD", required: true, error: errors["rxOsAdd"]) {
                    iconTextField(systemName: "plus.circle.fill", text: $encounter.rxOsAdd, isError: errors["rxOsAdd"] != nil)
                }
            }

            HStack(spacing: 12) {
                FieldRow("DP", required: true, error: errors["dp"]) {
                    iconTextField(systemName: "ruler.fill", text: $encounter.dp, isError: errors["dp"] != nil)
                }
                Spacer()
            }

            Divider().opacity(0.35)

            sectionHeader(icon: "sparkles", title: "Recomendación")

            HStack(spacing: 12) {
                FieldRow("Tipo de lente", required: true, error: errors["lensType"]) {
                    iconTextField(systemName: "eyeglasses", text: $encounter.lensType, isError: errors["lensType"] != nil)
                }
                FieldRow("Uso", required: true, error: errors["usage"]) {
                    iconTextField(systemName: "person.fill.checkmark", text: $encounter.usage, isError: errors["usage"] != nil)
                }
            }

            FieldRow("Fecha de seguimiento", required: true, error: errors["followUpDate"]) {
                dateField(
                    selection: Binding(
                        get: { encounter.followUpDate ?? Date() },
                        set: { encounter.followUpDate = $0 }
                    ),
                    isError: errors["followUpDate"] != nil
                )
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
                    .foregroundStyle(BrandColors.secondary.opacity(0.90))
            }

            Text(title)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(BrandColors.secondary)

            Spacer()
        }
        .padding(.top, 2)
    }

    private func subsectionLabel(_ title: String, icon: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(BrandColors.secondary.opacity(0.85))

            Text(title)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.primary)

            Spacer()
        }
        .padding(.top, 2)
    }

    private func iconTextField(systemName: String, text: Binding<String>, isError: Bool) -> some View {
        HStack(spacing: 10) {
            Image(systemName: systemName)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.secondary)

            TextField("", text: text)
                .visionTextField(isError: isError)
                .textInputAutocapitalization(.never)
        }
    }

    private func dateField(selection: Binding<Date>, isError: Bool) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "calendar")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.secondary)

            DatePicker("", selection: selection, displayedComponents: .date)
                .labelsHidden()
                .datePickerStyle(.compact)

            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(Color.black.opacity(0.04))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(isError ? BrandColors.danger.opacity(0.90) : BrandColors.accent.opacity(0.12), lineWidth: 1)
        )
    }
}
