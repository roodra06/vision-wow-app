//
//  PDFStyles.swift
//  VisionWow
//
//  Created by Rodrigo Marcos on 28/12/25.
//
import UIKit

enum PDFStyles {
    static let titleColor = UIColor(red: 112/255, green: 56/255, blue: 120/255, alpha: 1)
    static let subtleLine = UIColor.black.withAlphaComponent(0.18)

    static let headerRightFont = UIFont.systemFont(ofSize: 9.5, weight: .semibold)   // más chica
    static let headerCenterTitleFont = UIFont.systemFont(ofSize: 10.5, weight: .bold)
    static let headerCenterBodyFont  = UIFont.systemFont(ofSize: 8.8, weight: .regular)

    static let sectionTitleFont = UIFont.systemFont(ofSize: 11.5, weight: .bold)
    static let labelFont = UIFont.systemFont(ofSize: 9.5, weight: .semibold)
    static let valueFont = UIFont.systemFont(ofSize: 9.5, weight: .regular)
}

