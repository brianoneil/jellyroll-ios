//
//  Item.swift
//  jellyroll-2
//
//  Created by boneil on 28/12/2024.
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
