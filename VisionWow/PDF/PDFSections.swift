//
//  PDFSections.swift
//  VisionWow
//
//  Created by Rodrigo Marcos on 28/12/25.
//
import UIKit

enum PDFSections {

    static func drawSectionTitle(_ text: String, x: CGFloat, y: CGFloat, w: CGFloat) -> CGFloat {
        PDFDraw.drawText(
            text,
            in: CGRect(x: x, y: y, width: w, height: 14),
            font: .systemFont(ofSize: 10.5, weight: .bold),
            color: UIColor.black.withAlphaComponent(0.8),
            alignment: .left
        )
        return y + 14
    }

    static func drawMiniGridTitle(_ s: String, x: CGFloat, y: CGFloat, w: CGFloat) -> CGFloat {
        PDFDraw.drawText(
            s,
            in: CGRect(x: x, y: y, width: w, height: 12),
            font: .systemFont(ofSize: 9.5, weight: .bold),
            color: UIColor.black.withAlphaComponent(0.8),
            alignment: .left
        )
        return y + 12
    }
}

