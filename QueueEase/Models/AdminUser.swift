//
//  AdminUser.swift
//  QueueEase
//
//  Created by Edward Geraldo Kristian on 10/06/26.
//

import Foundation

struct AdminUser: Codable, Identifiable, Hashable {
    let userId: Int
    let name: String
    let username: String
    let email: String?
    let role: String
    let isActive: Bool?
    let createdAt: String?
    let updatedAt: String?

    var id: Int {
        userId
    }
}
