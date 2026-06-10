//
//  AdminViewModel.swift
//  QueueEase
//
//  Created by Edward Geraldo Kristian on 29/05/26.
//

import Foundation
import Combine

@MainActor
final class AdminDashboardViewModel: ObservableObject {
    @Published var summary: AdminSummary?
    @Published var categories: [QueueCategory] = []
    @Published var counters: [ServiceCounter] = []
    @Published var users: [AdminUser] = []
    @Published var recentTickets: [QueueTicket] = []
    @Published var isLoading = false
    @Published var isRefreshing = false
    @Published var errorMessage: String?
    @Published var successMessage: String?

    private let adminService: AdminService
    private let queueService: QueueService

    init() {
        self.adminService = .shared
        self.queueService = .shared
    }

    init(adminService: AdminService, queueService: QueueService) {
        self.adminService = adminService
        self.queueService = queueService
    }

    func loadDashboard() async {
        let isInitialLoad = summary == nil && categories.isEmpty && counters.isEmpty && users.isEmpty && recentTickets.isEmpty
        isLoading = isInitialLoad
        isRefreshing = !isInitialLoad
        errorMessage = nil

        do {
            async let summary = adminService.fetchSummary()
            async let categories = adminService.fetchCategories()
            async let counters = adminService.fetchCounters()
            async let users = adminService.fetchUsers()
            async let tickets = queueService.fetchAllTickets()

            self.summary = try await summary
            self.categories = try await categories
            self.counters = try await counters
            self.users = try await users
            self.recentTickets = sortedRecentTickets(try await tickets)
            successMessage = isInitialLoad ? nil : "Admin dashboard refreshed."
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
        isRefreshing = false
    }

    func refreshDashboard() async {
        await loadDashboard()
    }

    func createCategory(name: String, prefix: String) async -> Bool {
        await performAdminAction(successMessage: "Queue category created.") {
            _ = try await adminService.createCategory(categoryName: name, prefix: prefix)
        }
    }

    func updateCategory(_ category: QueueCategory, name: String, prefix: String, isActive: Bool) async -> Bool {
        await performAdminAction(successMessage: "Queue category updated.") {
            _ = try await adminService.updateCategory(
                categoryId: category.categoryId,
                categoryName: name,
                prefix: prefix,
                isActive: isActive
            )
        }
    }

    func deactivateCategory(_ category: QueueCategory) async -> Bool {
        await performAdminAction(successMessage: "Queue category deactivated.") {
            _ = try await adminService.deactivateCategory(categoryId: category.categoryId)
        }
    }

    func createCounter(name: String, status: String, assignedStaffId: Int?) async -> Bool {
        await performAdminAction(successMessage: "Service counter created.") {
            _ = try await adminService.createCounter(
                counterName: name,
                status: status,
                assignedStaffId: assignedStaffId
            )
        }
    }

    func updateCounter(_ counter: ServiceCounter, name: String, status: String, assignedStaffId: Int?) async -> Bool {
        await performAdminAction(successMessage: "Service counter updated.") {
            _ = try await adminService.updateCounter(
                counterId: counter.counterId,
                counterName: name,
                status: status,
                assignedStaffId: assignedStaffId
            )
        }
    }

    func deactivateCounter(_ counter: ServiceCounter) async -> Bool {
        await performAdminAction(successMessage: "Service counter deactivated.") {
            _ = try await adminService.deactivateCounter(counterId: counter.counterId)
        }
    }

    func createUser(name: String, username: String, email: String?, password: String, role: String) async -> Bool {
        await performAdminAction(successMessage: "User created.") {
            _ = try await adminService.createUser(
                name: name,
                username: username,
                email: email,
                password: password,
                role: role
            )
        }
    }

    func updateUser(_ user: AdminUser, name: String, username: String, email: String?, role: String, isActive: Bool) async -> Bool {
        await performAdminAction(successMessage: "User updated.") {
            _ = try await adminService.updateUser(
                userId: user.userId,
                name: name,
                username: username,
                email: email,
                role: role,
                isActive: isActive
            )
        }
    }

    func deactivateUser(_ user: AdminUser) async -> Bool {
        await performAdminAction(successMessage: "User deactivated.") {
            _ = try await adminService.deactivateUser(userId: user.userId)
        }
    }

    var activeUsersCount: Int {
        users.filter { $0.isActive != false }.count
    }

    var inactiveUsersCount: Int {
        users.filter { $0.isActive == false }.count
    }

    var customerUsersCount: Int {
        users.filter { $0.role == "customer" }.count
    }

    var staffUsersCount: Int {
        users.filter { $0.role == "service_staff" }.count
    }

    var adminUsersCount: Int {
        users.filter { $0.role == "admin" }.count
    }

    private func sortedRecentTickets(_ tickets: [QueueTicket]) -> [QueueTicket] {
        Array(
            tickets
                .sorted { $0.ticketId > $1.ticketId }
                .prefix(6)
        )
    }

    private func performAdminAction(successMessage message: String, action: () async throws -> Void) async -> Bool {
        isRefreshing = true
        errorMessage = nil
        successMessage = nil

        do {
            try await action()
            await loadDashboard()
            successMessage = message
            isRefreshing = false
            return true
        } catch {
            errorMessage = error.localizedDescription
            isRefreshing = false
            return false
        }
    }
}
