//
//  Prospect.swift
//  HackingWithSwiftUI-HotProspects
//
//  Created by Michael Jones on 23/07/2026.
//

import SwiftData
import Foundation

@Model
class Prospect {
    var name: String
    var email: String
    var isContacted: Bool
    var dateAdded = Date.now
    
    init(name: String, email: String, isContacted: Bool) {
        self.name = name
        self.email = email
        self.isContacted = isContacted
    }
}
