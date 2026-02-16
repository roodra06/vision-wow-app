//
//  EditEncounterWizardScreen.swift
//  VisionWow
//
//  Created by Rodrigo Marcos on 27/12/25.
//

import SwiftUI
import SwiftData

struct EditEncounterWizardScreen: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @Bindable var company: Company
    @Bindable var encounter: Encounter

    private var isExternalOptica: Bool {
        company.name == WalkInCompanyStore.name
    }

    var body: some View {
        ZStack {
            BrandColors.backgroundGradient.ignoresSafeArea()

            EncounterWizardView(
                encounter: .constant(encounter),
                company: company,
                onCancel: { dismiss() },
                onFinish: { _ in
                    save()
                },
                startAt: isExternalOptica ? .personalData : .clinicalHistory   // ✅ al final
            )
            .padding(16)
        }
        .navigationBarTitleDisplayMode(.inline)
    }

    private func save() {
        do {
            try modelContext.save()
            dismiss()
        } catch {
            print("ERROR updating encounter:", error)
        }
    }
}
