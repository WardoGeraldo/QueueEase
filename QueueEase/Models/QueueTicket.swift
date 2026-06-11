//
//  QueueTicket.swift
//  QueueEase
//
//  Created by Edward Geraldo Kristian on 29/05/26.
//

import Foundation

struct QueueTicket: Codable, Identifiable, Hashable {
    let ticketId: Int
    let queueNumber: String
    let customerId: Int?
    let categoryId: Int?
    let counterId: Int?
    let handledBy: Int?
    let status: String
    let createdAt: String?
    let calledAt: String?
    let checkedInAt: String?
    let completedAt: String?
    let updatedAt: String?
    let categoryName: String?
    let counterName: String?
    let customerName: String?

    var id: Int {
        ticketId
    }
}

extension QueueTicket {
    var statusTitle: String {
        switch status {
        case "waiting":
            return "Waiting"
        case "called":
            return "Called"
        case "checked_in":
            return "Checked In"
        case "completed":
            return "Completed"
        case "skipped":
            return "Skipped"
        case "cancelled":
            return "Cancelled"
        default:
            return status.replacingOccurrences(of: "_", with: " ").capitalized
        }
    }

    var statusDescription: String {
        switch status {
        case "waiting":
            return "Your queue number is waiting to be called."
        case "called":
            return "Your queue number has been called. Please go to the assigned counter."
        case "checked_in":
            return "Customer has checked in at the counter."
        case "completed":
            return "This queue ticket has been completed."
        case "skipped":
            return "This queue ticket was skipped by staff."
        case "cancelled":
            return "This queue ticket was cancelled."
        default:
            return "Current ticket status: \(statusTitle)."
        }
    }

    var createdAtDisplay: String {
        Self.formattedDate(createdAt) ?? "-"
    }

    var calledAtDisplay: String {
        Self.formattedDate(calledAt) ?? "Not called yet"
    }

    var checkedInAtDisplay: String {
        Self.formattedDate(checkedInAt) ?? "Not checked in yet"
    }

    var completedAtDisplay: String {
        Self.formattedDate(completedAt) ?? "Not completed yet"
    }

    var updatedAtDisplay: String {
        Self.formattedDate(updatedAt) ?? "-"
    }

    private static func formattedDate(_ rawValue: String?) -> String? {
        guard let rawValue else {
            return nil
        }

        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        let date = formatter.date(from: rawValue) ?? {
            formatter.formatOptions = [.withInternetDateTime]
            return formatter.date(from: rawValue)
        }()

        return date?.formatted(date: .abbreviated, time: .shortened)
    }
}
