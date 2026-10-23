//
//  Item.swift
//  Yarik
//
//  Created by Ярослав Шерстюк on 23/10/2026.
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
