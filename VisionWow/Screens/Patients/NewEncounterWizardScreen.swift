//
//  NewEncounterWizardScreen.swift
//  VisionWow
//
//  Created by Rodrigo Marcos on 27/12/25.
//

import SwiftUI
import SwiftData

struct NewEncounterWizardScreen: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @Bindable var company: Company
    @State private var draftEncounter = Encounter()

    private var isExternalOptica: Bool {
        company.name == WalkInCompanyStore.name
    }

    var body: some View {
        ZStack {
            BrandColors.backgroundGradient.ignoresSafeArea()

            EncounterWizardView(
                encounter: draftEncounter,
                company: company,
                onCancel: { dismiss() },
                onFinish: { finalizedEncounter in
                    save(finalizedEncounter)
                },
                startAt: isExternalOptica ? .personalData : .clinicalHistory
            )
            .padding(16)
        }
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            // Empresa
            draftEncounter.company = company
            draftEncounter.companyName = company.name

            // Paciente (evita nil en el wizard; puedes reemplazar esto por tu selector real de paciente)
            if draftEncounter.patient == nil {
                draftEncounter.patient = Patient()
            }
        }
    }

    private func save(_ encounter: Encounter) {
        encounter.company = company
        encounter.companyName = company.name

        modelContext.insert(encounter)
        do {
            try modelContext.save()
            dismiss()
        } catch {
            print("ERROR saving encounter:", error)
        }
    }
}
