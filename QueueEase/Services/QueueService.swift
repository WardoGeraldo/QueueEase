//
//  QueueService.swift
//  QueueEase
//
//  Created by Edward Geraldo Kristian on 29/05/26.
//

import Foundation

class QueueService {
    // This handles the POST /queue/take-number request[cite: 208].
    func requestQueueNumber(category: QueueCategory) async throws -> QueueTicket {
        // In a real app, you would use URLSession here to hit your backend API.
        // For now, we will simulate a successful network response from the Queue Engine API.
        
        try await Task.sleep(nanoseconds: 1_000_000_000) // Simulate 1-second network delay
        
        // Simulating the backend returning the new generated queue number data[cite: 219].
        return QueueTicket(
            id: UUID().uuidString,
            queueNumber: "A-024",
            status: "Waiting",
            createdAt: Date()
        )
    }
    
    // Simulates the GET /queue/status request
    func fetchQueueStatus(queueId: String) async throws -> QueueTicket {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        
        // Mocking the backend returning the updated status
        // In reality, this would query your DB to see if the status changed from "Waiting" to "Serving"
        return QueueTicket(
            id: queueId,
            queueNumber: "A-024",
            status: "Serving", // We will mock that it is now their turn!
            createdAt: Date()
        )
    }
}
