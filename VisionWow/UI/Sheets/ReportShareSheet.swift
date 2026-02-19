//
//  ReportShareSheet.swift
//  VisionWow
//
//  Created by Rodrigo Marcos on 19/02/26.
//
import SwiftUI
import UIKit

struct ReportShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

