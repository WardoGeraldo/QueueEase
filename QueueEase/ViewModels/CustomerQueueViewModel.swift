import Foundation
import Combine

@MainActor
final class CustomerQueueViewModel: ObservableObject {
    @Published var categories: [QueueCategory] = []
    @Published var selectedCategory: QueueCategory?
    @Published var currentTicket: QueueTicket?
    @Published var customerTickets: [QueueTicket] = []
    @Published var isLoading = false
    @Published var isRefreshingTicket = false
    @Published var isRefreshingHistory = false
    @Published var errorMessage: String?
    @Published var successMessage: String?

    private let queueService: QueueService
    private var pollingTask: Task<Void, Never>?

    init() {
        self.queueService = .shared
    }

    init(queueService: QueueService) {
        self.queueService = queueService
    }

    func loadDashboardData(customerId: Int) async {
        isLoading = true
        errorMessage = nil
        successMessage = nil
        defer {
            isLoading = false
        }

        do {
            async let loadedCategories = queueService.fetchCategories()
            async let loadedTickets = queueService.fetchCustomerTickets(customerId: customerId)

            categories = try await loadedCategories
            customerTickets = sortedTickets(try await loadedTickets)

            if selectedCategory == nil {
                selectedCategory = categories.first
            }

            currentTicket = latestTicket(from: customerTickets)

            if currentTicket != nil {
                startPolling()
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func loadCategories() async {
        isLoading = true
        errorMessage = nil
        successMessage = nil
        defer {
            isLoading = false
        }

        do {
            categories = try await queueService.fetchCategories()
            if selectedCategory == nil {
                selectedCategory = categories.first
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func loadCustomerTickets(customerId: Int) async {
        isRefreshingHistory = true
        errorMessage = nil
        defer {
            isRefreshingHistory = false
        }

        do {
            customerTickets = sortedTickets(try await queueService.fetchCustomerTickets(customerId: customerId))
            currentTicket = latestTicket(from: customerTickets)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func takeQueueNumber(customerId: Int) async {
        guard let selectedCategory else {
            errorMessage = "Please select a queue category."
            return
        }

        isLoading = true
        errorMessage = nil
        successMessage = nil
        defer {
            isLoading = false
        }

        do {
            let ticket = try await queueService.takeQueueNumber(
                customerId: customerId,
                categoryId: selectedCategory.categoryId
            )
            currentTicket = ticket
            upsertTicket(ticket)
            successMessage = "Queue number \(ticket.queueNumber) created."
            await loadCustomerTickets(customerId: customerId)
            startPolling()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func refreshCurrentTicket() async {
        guard let ticketId = currentTicket?.ticketId else {
            return
        }

        isRefreshingTicket = true
        errorMessage = nil
        defer {
            isRefreshingTicket = false
        }

        do {
            let ticket = try await queueService.fetchQueueStatus(ticketId: ticketId)
            currentTicket = ticket
            upsertTicket(ticket)
        } catch {
            guard !Task.isCancelled else {
                return
            }
            errorMessage = error.localizedDescription
        }
    }

    func startPolling() {
        stopPolling()

        pollingTask = Task { [weak self] in
            while !Task.isCancelled {
                await self?.refreshCurrentTicket()
                try? await Task.sleep(nanoseconds: 3_000_000_000)
            }
        }
    }

    func stopPolling() {
        pollingTask?.cancel()
        pollingTask = nil
    }

    private func upsertTicket(_ ticket: QueueTicket) {
        if let index = customerTickets.firstIndex(where: { $0.ticketId == ticket.ticketId }) {
            customerTickets[index] = ticket
        } else {
            customerTickets.append(ticket)
        }

        customerTickets = sortedTickets(customerTickets)
    }

    private func latestTicket(from tickets: [QueueTicket]) -> QueueTicket? {
        tickets.max { first, second in
            first.ticketId < second.ticketId
        }
    }

    private func sortedTickets(_ tickets: [QueueTicket]) -> [QueueTicket] {
        tickets.sorted { first, second in
            first.ticketId > second.ticketId
        }
    }
}
