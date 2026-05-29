//
//  QueueStatusView.swift
//  QueueEase
//
//  Created by Edward Geraldo Kristian on 29/05/26.
//

import SwiftUI

struct QueueStatusView: View {
    @StateObject private var viewModel = QueueStatusViewModel()
    
    // We pass the ticket ID that the user got from the Take Queue Number screen
    let activeQueueId: String
    
    var body: some View {
        VStack(spacing: 30) {
            Text("Live Queue Status")
                .font(.largeTitle)
                .bold()
            
            if let ticket = viewModel.currentTicket {
                VStack(spacing: 15) {
                    Text("Your Number")
                        .font(.title2)
                        .foregroundColor(.gray)
                    
                    Text(ticket.queueNumber)
                        .font(.system(size: 70, weight: .black, design: .rounded))
                        .foregroundColor(ticket.status == "Serving" ? .green : .blue)
                    
                    HStack {
                        Text("Current Status:")
                            .font(.headline)
                        Text(ticket.status)
                            .font(.headline)
                            .foregroundColor(ticket.status == "Serving" ? .green : .orange)
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(10)
                }
                .padding(40)
                .background(RoundedRectangle(cornerRadius: 20).stroke(Color.gray.opacity(0.3), lineWidth: 2))
                .shadow(radius: 5)
            } else if viewModel.errorMessage != nil {
                Text(viewModel.errorMessage!)
                    .foregroundColor(.red)
            } else {
                VStack {
                    ProgressView()
                    Text("Fetching your status...")
                        .foregroundColor(.gray)
                        .padding(.top)
                }
            }
            
            Spacer()
        }
        .padding()
        // Start the polling loop when the view loads
        .onAppear {
            viewModel.startQueueStatusRefresh(for: activeQueueId)
        }
        // Clean up the loop when they leave the screen
        .onDisappear {
            viewModel.stopRefresh()
        }
    }
}

#Preview {
    QueueStatusView(activeQueueId: "sample_id_123")
}
