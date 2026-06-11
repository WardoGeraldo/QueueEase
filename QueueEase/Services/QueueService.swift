import Foundation

final class QueueService {
    static let shared = QueueService()

    private let apiService: APIService

    private init(apiService: APIService = .shared) {
        self.apiService = apiService
    }

    func fetchCategories() async throws -> [QueueCategory] {
        let response: APIResponse<[QueueCategory]> = try await apiService.get("/queue/categories")
        return try unwrap(response, fallbackMessage: "Unable to load queue categories.")
    }

    func takeQueueNumber(customerId: Int, categoryId: Int) async throws -> QueueTicket {
        let body = TakeQueueNumberRequest(customerId: customerId, categoryId: categoryId)
        let response: APIResponse<QueueTicket> = try await apiService.post("/queue/take-number", body: body)
        return try unwrap(response, fallbackMessage: "Unable to take queue number.")
    }

    func fetchQueueStatus(ticketId: Int) async throws -> QueueTicket {
        let response: APIResponse<QueueTicket> = try await apiService.get("/queue/status/\(ticketId)")
        return try unwrap(response, fallbackMessage: "Unable to load queue status.")
    }

    func fetchCustomerTickets(customerId: Int) async throws -> [QueueTicket] {
        let response: APIResponse<[QueueTicket]> = try await apiService.get("/customers/\(customerId)/tickets")
        return try unwrap(response, fallbackMessage: "Unable to load customer ticket history.")
    }

    func callNextQueue(staffId: Int, categoryId: Int, counterId: Int) async throws -> QueueTicket {
        let body = CallNextQueueRequest(staffId: staffId, categoryId: categoryId, counterId: counterId)
        let response: APIResponse<QueueTicket> = try await apiService.post("/staff/call-next", body: body)
        return try unwrap(response, fallbackMessage: "Unable to call next queue.")
    }

    func checkInCustomer(staffId: Int, ticketId: Int) async throws -> QueueTicket {
        let body = CheckInRequest(staffId: staffId, ticketId: ticketId)
        let response: APIResponse<QueueTicket> = try await apiService.post("/staff/check-in", body: body)
        return try unwrap(response, fallbackMessage: "Unable to check in customer.")
    }

    func fetchAllTickets() async throws -> [QueueTicket] {
        let response: APIResponse<[QueueTicket]> = try await apiService.get("/queue/tickets")
        return try unwrap(response, fallbackMessage: "Unable to load queue tickets.")
    }

    private func unwrap<T>(_ response: APIResponse<T>, fallbackMessage: String) throws -> T {
        guard response.success != false, let data = response.data else {
            throw APIError.httpError(statusCode: 200, message: response.message ?? fallbackMessage)
        }

        return data
    }
}

private struct TakeQueueNumberRequest: Encodable {
    let customerId: Int
    let categoryId: Int
}

private struct CallNextQueueRequest: Encodable {
    let staffId: Int
    let categoryId: Int
    let counterId: Int
}

private struct CheckInRequest: Encodable {
    let staffId: Int
    let ticketId: Int
}
