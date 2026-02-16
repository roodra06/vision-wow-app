//
//  PDFLayout.swift
//  VisionWow
//
//  Created by Rodrigo Marcos on 28/12/25.
//
import UIKit

enum PDFLayout {
    // US Letter Portrait: 612 x 792
    static let pageRectLetterPortrait = CGRect(x: 0, y: 0, width: 612, height: 792)

    static let marginX: CGFloat = 22
    static let marginTop: CGFloat = 18
    static let marginBottom: CGFloat = 18

    static let contentWidth: CGFloat = pageRectLetterPortrait.width - (marginX * 2)
}
