//
//  QueueTicket.swift
//  QueueEase
//
//  Created by Edward Geraldo Kristian on 29/05/26.
//

import Foundation

struct QueueTicket: Identifiable, Codable {
    let id: String // Maps to queueId
    let queueNumber: String
    let status: String
    let createdAt: Date
}
