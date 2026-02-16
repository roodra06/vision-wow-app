//
//  IntakeStep1Screen.swift
//  VisionWow
//
//  Created by Rodrigo Marcos on 27/12/25.
//
import SwiftUI
import SwiftData

struct IntakeStep1Screen: View {
    @Bindable var encounter: Encounter
    let errors: [String: String]

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                ClinicalHistoryView(encounter: encounter, errors: errors)
                PersonalDataView(encounter: encounter, errors: errors)
            }
        }
    }
}

