//
//  UIImage+ProfileResize.swift
//  VisionWow
//
//  Redimensiona y comprime fotos de perfil antes de persistirlas.
//  Máximo 512×512 px, JPEG ≤ ~150 KB.
//

import UIKit

extension UIImage {
    /// Devuelve JPEG data redimensionada a 512×512 máximo y comprimida.
    func resizedForProfile() -> Data? {
        let maxSide: CGFloat = 512
        let size = self.size
        let scale = min(maxSide / size.width, maxSide / size.height, 1.0)
        let targetSize = CGSize(width: size.width * scale, height: size.height * scale)

        let renderer = UIGraphicsImageRenderer(size: targetSize)
        let resized = renderer.image { _ in
            self.draw(in: CGRect(origin: .zero, size: targetSize))
        }

        // Intenta calidad 0.7 primero; si sigue siendo grande, baja a 0.5
        if let data = resized.jpegData(compressionQuality: 0.7), data.count <= 200_000 {
            return data
        }
        return resized.jpegData(compressionQuality: 0.5)
    }
}
