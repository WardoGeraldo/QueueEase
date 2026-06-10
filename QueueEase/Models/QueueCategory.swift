//
//  QueueCategory.swift
//  QueueEase
//
//  Created by Edward Geraldo Kristian on 29/05/26.
//

import Foundation

struct QueueCategory: Codable, Hashable, Identifiable {
    let categoryId: Int
    let categoryName: String
    let prefix: String
    let currentNumber: Int?
    let isActive: Bool?
    let createdAt: String?
    let updatedAt: String?

    var id: Int {
        categoryId
    }
}

