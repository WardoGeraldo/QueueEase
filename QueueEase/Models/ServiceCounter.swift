//
//  ServiceCounter.swift
//  QueueEase
//
//  Created by Edward Geraldo Kristian on 29/05/26.
//

import Foundation

struct ServiceCounter: Codable, Identifiable, Hashable {
    let counterId: Int
    let counterName: String
    let status: String
    let assignedStaffId: Int?
    let staffName: String?
    let assignedStaffName: String?
    let isActive: Bool?
    let createdAt: String?
    let updatedAt: String?

    var id: Int {
        counterId
    }

    var displayStaffName: String? {
        assignedStaffName ?? staffName
    }
}
