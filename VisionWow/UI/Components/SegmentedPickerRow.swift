//
//  SegmentedPickerRow.swift
//  VisionWow
//
//  Created by Rodrigo Marcos on 27/12/25.
//
import SwiftUI

struct SegmentedPickerRow<T: Hashable & Identifiable>: View {
    let label: String
    let required: Bool
    let error: String?
    let options: [T]
    let title: (T) -> String
    @Binding var selection: T

    var body: some View {
        FieldRow(label, required: required, error: error) {
            Picker("", selection: $selection) {
                ForEach(options) { opt in
                    Text(title(opt)).tag(opt)
                }
            }
            .pickerStyle(.segmented)
        }
    }
}

