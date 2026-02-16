//
//  AppDelegate.swift
//  VisionWow
//
//  Created by Rodrigo Marcos on 27/12/25.
//

import UIKit

final class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        return OrientationLock.mask
    }
}
