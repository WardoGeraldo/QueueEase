//
//  AdminService.swift
//  QueueEase
//
//  Created by Edward Geraldo Kristian on 29/05/26.
//

import Foundation

final class AdminService {
    static let shared = AdminService()

    private let apiService: APIService

    private init(apiService: APIService = .shared) {
        self.apiService = apiService
    }

    func fetchSummary() async throws -> AdminSummary {
        let response: APIResponse<AdminSummary> = try await apiService.get("/admin/summary")
        return try unwrap(response, fallbackMessage: "Unable to load admin summary.")
    }

    func fetchCounters() async throws -> [ServiceCounter] {
        let response: APIResponse<[ServiceCounter]> = try await apiService.get("/admin/counters")
        return try unwrap(response, fallbackMessage: "Unable to load service counters.")
    }

    func fetchCategories() async throws -> [QueueCategory] {
        let response: APIResponse<[QueueCategory]> = try await apiService.get("/admin/categories")
        return try unwrap(response, fallbackMessage: "Unable to load queue categories.")
    }

    func fetchUsers() async throws -> [AdminUser] {
        let response: APIResponse<[AdminUser]> = try await apiService.get("/admin/users")
        return try unwrap(response, fallbackMessage: "Unable to load users.")
    }

    func createCategory(categoryName: String, prefix: String) async throws -> QueueCategory {
        let body = CategoryRequest(categoryName: categoryName, prefix: prefix, isActive: nil)
        let response: APIResponse<QueueCategory> = try await apiService.post("/admin/categories", body: body)
        return try unwrap(response, fallbackMessage: "Unable to create queue category.")
    }

    func updateCategory(categoryId: Int, categoryName: String, prefix: String, isActive: Bool) async throws -> QueueCategory {
        let body = CategoryRequest(categoryName: categoryName, prefix: prefix, isActive: isActive)
        let response: APIResponse<QueueCategory> = try await apiService.put("/admin/categories/\(categoryId)", body: body)
        return try unwrap(response, fallbackMessage: "Unable to update queue category.")
    }

    func createCounter(counterName: String, status: String, assignedStaffId: Int?) async throws -> ServiceCounter {
        let body = CounterRequest(counterName: counterName, status: status, assignedStaffId: assignedStaffId)
        let response: APIResponse<ServiceCounter> = try await apiService.post("/admin/counters", body: body)
        return try unwrap(response, fallbackMessage: "Unable to create service counter.")
    }

    func updateCounter(counterId: Int, counterName: String, status: String, assignedStaffId: Int?) async throws -> ServiceCounter {
        let body = CounterRequest(counterName: counterName, status: status, assignedStaffId: assignedStaffId)
        let response: APIResponse<ServiceCounter> = try await apiService.put("/admin/counters/\(counterId)", body: body)
        return try unwrap(response, fallbackMessage: "Unable to update service counter.")
    }

    func deactivateCounter(counterId: Int) async throws -> ServiceCounter {
        let response: APIResponse<ServiceCounter> = try await apiService.delete("/admin/counters/\(counterId)")
        return try unwrap(response, fallbackMessage: "Unable to deactivate service counter.")
    }

    func deactivateCategory(categoryId: Int) async throws -> QueueCategory {
        let response: APIResponse<QueueCategory> = try await apiService.delete("/admin/categories/\(categoryId)")
        return try unwrap(response, fallbackMessage: "Unable to deactivate queue category.")
    }

    func createUser(name: String, username: String, email: String?, password: String, role: String) async throws -> AdminUser {
        let body = UserCreateRequest(
            name: name,
            username: username,
            email: email?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == true ? nil : email,
            password: password,
            role: role
        )
        let response: APIResponse<AdminUser> = try await apiService.post("/admin/users", body: body)
        return try unwrap(response, fallbackMessage: "Unable to create user.")
    }

    func updateUser(userId: Int, name: String, username: String, email: String?, role: String, isActive: Bool) async throws -> AdminUser {
        let body = UserUpdateRequest(
            name: name,
            username: username,
            email: email?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == true ? nil : email,
            role: role,
            isActive: isActive
        )
        let response: APIResponse<AdminUser> = try await apiService.put("/admin/users/\(userId)", body: body)
        return try unwrap(response, fallbackMessage: "Unable to update user.")
    }

    func deactivateUser(userId: Int) async throws -> AdminUser {
        let response: APIResponse<AdminUser> = try await apiService.delete("/admin/users/\(userId)")
        return try unwrap(response, fallbackMessage: "Unable to deactivate user.")
    }

    private func unwrap<T>(_ response: APIResponse<T>, fallbackMessage: String) throws -> T {
        guard response.success != false, let data = response.data else {
            throw APIError.httpError(statusCode: 200, message: response.message ?? fallbackMessage)
        }

        return data
    }
}

private struct CategoryRequest: Encodable {
    let categoryName: String
    let prefix: String
    let isActive: Bool?
}

private struct CounterRequest: Encodable {
    let counterName: String
    let status: String
    let assignedStaffId: Int?
}

private struct UserUpdateRequest: Encodable {
    let name: String
    let username: String
    let email: String?
    let role: String
    let isActive: Bool
}

private struct UserCreateRequest: Encodable {
    let name: String
    let username: String
    let email: String?
    let password: String
    let role: String
}
