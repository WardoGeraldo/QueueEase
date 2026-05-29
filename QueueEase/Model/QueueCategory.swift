//
//  QueueCategory.swift
//  QueueEase
//
//  Created by Edward Geraldo Kristian on 29/05/26.
//

import Foundation

struct QueueCategory: Identifiable, Codable {
    let id: String // Maps to categoryId
    let categoryName: String
    let description: String
    let isActive: Bool
}
