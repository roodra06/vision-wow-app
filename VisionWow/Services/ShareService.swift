//
//  ShareService.swift
//  VisionWow
//
//  Created by Rodrigo Marcos on 27/12/25.
//

import UIKit

enum ShareService {
    static func share(items: [Any]) {
        guard let top = topMostVC() else { return }
        let vc = UIActivityViewController(activityItems: items, applicationActivities: nil)
        top.present(vc, animated: true)
    }

    private static func topMostVC() -> UIViewController? {
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let root = scene.windows.first?.rootViewController else { return nil }
        var top = root
        while let presented = top.presentedViewController {
            top = presented
        }
        return top
    }
}
