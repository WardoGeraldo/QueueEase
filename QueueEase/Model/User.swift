//
//  User.swift
//  QueueEase
//
//  Created by Edward Geraldo Kristian on 29/05/26.
//

import Foundation

// Defines the strict roles allowed in the system
enum UserRole: String, Codable {
    case customer = "Customer"
    case serviceStaff = "Service Staff"
    case systemAdministrator = "System Administrator"
}

// Represents a general system user [cite: 601]
struct User: Identifiable, Codable {
    var id: String // Maps to userId [cite: 532]
    var name: String
    var username: String
    var role: UserRole
    
    // Note: In a production app, never store passwords locally after login.
    // We include it here to match your Class Diagram strictly. [cite: 535]
    var password: String?
}
