//
//  Item.swift
//  VisionWow
//
//  Created by Rodrigo Marcos on 27/12/25.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
