//
//  PDFDraw.swift
//  VisionWow
//
//  Created by Rodrigo Marcos on 28/12/25.
//
import UIKit

enum PDFDraw {

    static func drawText(_ text: String, in rect: CGRect, font: UIFont, color: UIColor, alignment: NSTextAlignment) {
        let style = NSMutableParagraphStyle()
        style.alignment = alignment
        style.lineBreakMode = .byWordWrapping

        let attrs: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: color,
            .paragraphStyle: style
        ]

        NSString(string: text).draw(in: rect, withAttributes: attrs)
    }

    static func drawLine(from: CGPoint, to: CGPoint, color: UIColor, width: CGFloat) {
        let path = UIBezierPath()
        path.move(to: from)
        path.addLine(to: to)
        color.setStroke()
        path.lineWidth = width
        path.stroke()
    }

    static func drawImageAspectFit(_ image: UIImage, in rect: CGRect) {
        let imgSize = image.size
        guard imgSize.width > 0, imgSize.height > 0 else { return }

        let scale = min(rect.width / imgSize.width, rect.height / imgSize.height)
        let w = imgSize.width * scale
        let h = imgSize.height * scale

        let x = rect.minX + (rect.width - w) / 2
        let y = rect.minY + (rect.height - h) / 2

        image.draw(in: CGRect(x: x, y: y, width: w, height: h))
    }
}
