//
//  QueueStatusViewModel.swift
//  QueueEase
//
//  Created by Edward Geraldo Kristian on 29/05/26.
//

import Foundation
import SwiftUI
import Combine

@MainActor
class QueueStatusViewModel: ObservableObject {
    @Published var currentTicket: QueueTicket?
    @Published var errorMessage: String?
    
    private let queueService = QueueService()
    private var refreshTask: Task<Void, Never>? // Holds our loop
    
    // Starts the 3-second polling loop as defined in UC-04
    func startQueueStatusRefresh(for queueId: String) {
        // Cancel any existing loop just in case
        refreshTask?.cancel()
        
        refreshTask = Task {
            while !Task.isCancelled {
                do {
                    let updatedTicket = try await queueService.fetchQueueStatus(queueId: queueId)
                    self.currentTicket = updatedTicket
                    self.errorMessage = nil
                } catch {
                    self.errorMessage = "Failed to update queue status."
                }
                
                // Wait for 3 seconds before checking again (NFR-04)
                try? await Task.sleep(nanoseconds: 3_000_000_000)
            }
        }
    }
    
    // Stop the loop when the user leaves the screen
    func stopRefresh() {
        refreshTask?.cancel()
    }
}
