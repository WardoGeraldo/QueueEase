//
//  PreviewData.swift
//  QueueEase
//
//  Created by Edward Geraldo Kristian on 10/06/26.
//

#if DEBUG
import Foundation

@MainActor
enum PreviewData {
    static let customerUser = User(
        userId: 3,
        name: "Budi Santoso",
        username: "budi",
        role: "customer",
        isActive: true
    )

    static let sitiUser = User(
        userId: 4,
        name: "Siti Aminah",
        username: "siti",
        role: "customer",
        isActive: true
    )

    static let staffUser = User(
        userId: 2,
        name: "Staff Demo",
        username: "staff",
        role: "service_staff",
        isActive: true
    )

    static let adminUser = User(
        userId: 1,
        name: "Admin Demo",
        username: "admin",
        role: "admin",
        isActive: true
    )

    static let categories = [
        QueueCategory(
            categoryId: 1,
            categoryName: "General Service",
            prefix: "GS",
            currentNumber: 12,
            isActive: true,
            createdAt: nil,
            updatedAt: nil
        ),
        QueueCategory(
            categoryId: 2,
            categoryName: "Payment Service",
            prefix: "PY",
            currentNumber: 4,
            isActive: true,
            createdAt: nil,
            updatedAt: nil
        ),
        QueueCategory(
            categoryId: 3,
            categoryName: "Information Desk",
            prefix: "ID",
            currentNumber: 3,
            isActive: true,
            createdAt: nil,
            updatedAt: nil
        ),
        QueueCategory(
            categoryId: 4,
            categoryName: "Consultation",
            prefix: "CN",
            currentNumber: 2,
            isActive: true,
            createdAt: nil,
            updatedAt: nil
        )
    ]

    static let waitingTicket = QueueTicket(
        ticketId: 12,
        queueNumber: "GS001",
        customerId: 3,
        categoryId: 1,
        counterId: nil,
        handledBy: nil,
        status: "waiting",
        createdAt: "2026-05-30T06:06:09.691Z",
        calledAt: nil,
        checkedInAt: nil,
        completedAt: nil,
        updatedAt: "2026-05-30T06:08:09.691Z",
        categoryName: "General Service",
        counterName: nil,
        customerName: "Budi Santoso"
    )

    static let calledTicket = QueueTicket(
        ticketId: 13,
        queueNumber: "PY001",
        customerId: 4,
        categoryId: 2,
        counterId: 1,
        handledBy: 2,
        status: "called",
        createdAt: "2026-05-30T06:02:09.691Z",
        calledAt: "2026-05-30T06:10:09.691Z",
        checkedInAt: nil,
        completedAt: nil,
        updatedAt: "2026-05-30T06:10:09.691Z",
        categoryName: "Payment Service",
        counterName: "Counter 1",
        customerName: "Siti Aminah"
    )

    static let checkedInTicket = QueueTicket(
        ticketId: 11,
        queueNumber: "GS002",
        customerId: 3,
        categoryId: 1,
        counterId: 1,
        handledBy: 2,
        status: "checked_in",
        createdAt: "2026-05-30T05:58:09.691Z",
        calledAt: "2026-05-30T06:01:09.691Z",
        checkedInAt: "2026-05-30T06:04:09.691Z",
        completedAt: nil,
        updatedAt: "2026-05-30T06:04:09.691Z",
        categoryName: "General Service",
        counterName: "Counter 1",
        customerName: "Budi Santoso"
    )

    static let adminSummary = AdminSummary(
        totalTickets: 18,
        waitingTickets: 4,
        calledTickets: 2,
        checkedInTickets: 12,
        totalCustomers: 2,
        totalStaff: 1,
        totalAdmins: 1,
        activeCategories: 4,
        activeCounters: 2,
        todayTickets: 6,
        completedTickets: 0
    )

    static let counters = [
        ServiceCounter(
            counterId: 1,
            counterName: "Counter 1",
            status: "active",
            assignedStaffId: 2,
            staffName: "Staff Demo",
            assignedStaffName: "Staff Demo",
            isActive: true,
            createdAt: nil,
            updatedAt: nil
        ),
        ServiceCounter(
            counterId: 2,
            counterName: "Counter 2",
            status: "inactive",
            assignedStaffId: nil,
            staffName: nil,
            assignedStaffName: nil,
            isActive: nil,
            createdAt: nil,
            updatedAt: nil
        )
    ]

    static let adminUsers = [
        AdminUser(
            userId: 1,
            name: "Admin Demo",
            username: "admin",
            email: nil,
            role: "admin",
            isActive: true,
            createdAt: nil,
            updatedAt: nil
        ),
        AdminUser(
            userId: 2,
            name: "Staff Demo",
            username: "staff",
            email: nil,
            role: "service_staff",
            isActive: true,
            createdAt: nil,
            updatedAt: nil
        ),
        AdminUser(
            userId: 3,
            name: "Budi Santoso",
            username: "budi",
            email: nil,
            role: "customer",
            isActive: true,
            createdAt: nil,
            updatedAt: nil
        ),
        AdminUser(
            userId: 4,
            name: "Siti Aminah",
            username: "siti",
            email: nil,
            role: "customer",
            isActive: true,
            createdAt: nil,
            updatedAt: nil
        )
    ]

    static func session(for user: User) -> AppSession {
        let session = AppSession()
        session.login(user: user)
        return session
    }

    static func customerQueueViewModel() -> CustomerQueueViewModel {
        let viewModel = CustomerQueueViewModel()
        viewModel.categories = categories
        viewModel.selectedCategory = categories.first
        viewModel.currentTicket = waitingTicket
        viewModel.customerTickets = [waitingTicket, checkedInTicket]
        viewModel.successMessage = "Queue number GS001 created."
        return viewModel
    }

    static func staffQueueViewModel() -> StaffQueueViewModel {
        let viewModel = StaffQueueViewModel()
        viewModel.categories = categories
        viewModel.selectedCategory = categories[0]
        viewModel.tickets = [checkedInTicket, calledTicket, waitingTicket]
        viewModel.lastCalledTicket = calledTicket
        viewModel.successMessage = "Called PY001."
        return viewModel
    }

    static func adminDashboardViewModel() -> AdminDashboardViewModel {
        let viewModel = AdminDashboardViewModel()
        viewModel.summary = adminSummary
        viewModel.categories = categories
        viewModel.counters = counters
        viewModel.users = adminUsers
        viewModel.recentTickets = [calledTicket, waitingTicket, checkedInTicket]
        return viewModel
    }
}
#endif
