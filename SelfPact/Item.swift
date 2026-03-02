//
//  Item.swift
//  SelfPact
//
//  Created by Ayush Kumar Agarwal on 02/03/26.
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
