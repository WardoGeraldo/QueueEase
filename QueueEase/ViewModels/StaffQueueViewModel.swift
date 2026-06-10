//
//  StaffQueueViewModel.swift
//  QueueEase
//
//  Created by Edward Geraldo Kristian on 29/05/26.
//

import Foundation
import Combine

@MainActor
final class StaffQueueViewModel: ObservableObject {
    @Published var categories: [QueueCategory] = []
    @Published var selectedCategory: QueueCategory?
    @Published var tickets: [QueueTicket] = []
    @Published var lastCalledTicket: QueueTicket?
    @Published var isLoading = false
    @Published var isRefreshingTickets = false
    @Published var errorMessage: String?
    @Published var successMessage: String?

    private let queueService: QueueService

    init() {
        self.queueService = .shared
    }

    init(queueService: QueueService) {
        self.queueService = queueService
    }

    func loadDashboardData() async {
        isLoading = true
        errorMessage = nil
        successMessage = nil
        defer {
            isLoading = false
        }

        do {
            async let categories = queueService.fetchCategories()
            async let tickets = queueService.fetchAllTickets()

            self.categories = try await categories
            self.tickets = sortedTickets(try await tickets)

            if selectedCategory == nil {
                selectedCategory = preferredCategory()
            }

            updateLastCalledTicketIfNeeded()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func loadTickets() async {
        isRefreshingTickets = true
        errorMessage = nil
        successMessage = nil
        defer {
            isRefreshingTickets = false
        }

        do {
            tickets = sortedTickets(try await queueService.fetchAllTickets())
            updateLastCalledTicketIfNeeded()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func callNext(staffId: Int) async {
        guard let selectedCategory else {
            errorMessage = "Please select a queue category."
            return
        }

        guard waitingCount(for: selectedCategory) > 0 else {
            errorMessage = "No waiting ticket found for \(selectedCategory.categoryName). Select a category with waiting tickets or refresh the list."
            successMessage = nil
            return
        }

        isLoading = true
        errorMessage = nil
        successMessage = nil
        defer {
            isLoading = false
        }

        do {
            let ticket = try await queueService.callNextQueue(
                staffId: staffId,
                categoryId: selectedCategory.categoryId,
                counterId: 1
            )
            successMessage = "Called \(ticket.queueNumber)."
            tickets = sortedTickets(try await queueService.fetchAllTickets())
            lastCalledTicket = tickets.first { $0.ticketId == ticket.ticketId } ?? ticket
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func checkIn(staffId: Int, ticketId: Int) async {
        isLoading = true
        errorMessage = nil
        successMessage = nil
        defer {
            isLoading = false
        }

        do {
            let ticket = try await queueService.checkInCustomer(staffId: staffId, ticketId: ticketId)
            successMessage = "Checked in \(ticket.queueNumber)."

            tickets = sortedTickets(try await queueService.fetchAllTickets())
            if lastCalledTicket?.ticketId == ticketId {
                lastCalledTicket = tickets.first { $0.ticketId == ticketId } ?? ticket
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    var canCheckInLastCalledTicket: Bool {
        lastCalledTicket?.status == "called"
    }

    var waitingCount: Int {
        tickets.filter { $0.status == "waiting" }.count
    }

    var calledCount: Int {
        tickets.filter { $0.status == "called" }.count
    }

    var checkedInCount: Int {
        tickets.filter { $0.status == "checked_in" }.count
    }

    var totalTicketsCount: Int {
        tickets.count
    }

    var selectedCategoryWaitingCount: Int {
        guard let selectedCategory else {
            return 0
        }

        return waitingCount(for: selectedCategory)
    }

    var canCallNextQueue: Bool {
        selectedCategory != nil && selectedCategoryWaitingCount > 0 && !isLoading && !isRefreshingTickets
    }

    func waitingCount(for category: QueueCategory) -> Int {
        tickets.filter {
            $0.status == "waiting" && $0.categoryName == category.categoryName
        }.count
    }

    private func preferredCategory() -> QueueCategory? {
        if let waitingTicket = tickets.first(where: { $0.status == "waiting" }),
           let category = categories.first(where: { $0.categoryName == waitingTicket.categoryName }) {
            return category
        }

        return categories.first
    }

    private func updateLastCalledTicketIfNeeded() {
        if let lastCalledTicket,
           let updatedTicket = tickets.first(where: { $0.ticketId == lastCalledTicket.ticketId }) {
            self.lastCalledTicket = updatedTicket
            return
        }

        if lastCalledTicket == nil {
            lastCalledTicket = tickets.first(where: { $0.status == "called" })
        }
    }

    private func sortedTickets(_ tickets: [QueueTicket]) -> [QueueTicket] {
        tickets.sorted { first, second in
            first.ticketId > second.ticketId
        }
    }
}
