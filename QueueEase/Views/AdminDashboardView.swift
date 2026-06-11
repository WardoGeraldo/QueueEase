//
//  AdminDashboardView.swift
//  QueueEase
//
//  Created by Edward Geraldo Kristian on 29/05/26.
//

import SwiftUI

struct AdminDashboardView: View {
    @EnvironmentObject private var session: AppSession
    @StateObject private var viewModel: AdminDashboardViewModel
    @State private var activeSheet: AdminManagementSheet?
    @State private var deactivateTarget: AdminDeactivateTarget?
    private let loadsOnAppear: Bool

    private let metricColumns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    private let reportColumns = [
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10)
    ]

    init() {
        _viewModel = StateObject(wrappedValue: AdminDashboardViewModel())
        self.loadsOnAppear = true
    }

    init(viewModel: AdminDashboardViewModel, loadsOnAppear: Bool = true) {
        _viewModel = StateObject(wrappedValue: viewModel)
        self.loadsOnAppear = loadsOnAppear
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    welcomeSection
                        .queueAppear(delay: 0.02)
                    messageSection
                        .queueAppear(delay: 0.06)

                    if viewModel.isLoading {
                        loadingSection
                            .queueTransition()
                    } else {
                        summarySection
                            .queueAppear(delay: 0.08)
                        reportsPreviewSection
                            .queueAppear(delay: 0.12)
                        categoriesSection
                            .queueAppear(delay: 0.16)
                        countersSection
                            .queueAppear(delay: 0.20)
                        usersSection
                            .queueAppear(delay: 0.24)
                        recentTicketsSection
                            .queueAppear(delay: 0.28)
                        futureScopeSection
                            .queueAppear(delay: 0.32)
                    }
                }
                .padding()
                .animation(QueueMotion.smooth, value: viewModel.isLoading)
                .animation(QueueMotion.smooth, value: viewModel.summary)
                .animation(QueueMotion.smooth, value: viewModel.categories)
                .animation(QueueMotion.smooth, value: viewModel.counters)
                .animation(QueueMotion.smooth, value: viewModel.users)
                .animation(QueueMotion.smooth, value: viewModel.recentTickets)
                .animation(QueueMotion.smooth, value: viewModel.errorMessage)
                .animation(QueueMotion.smooth, value: viewModel.successMessage)
            }
            .refreshable {
                await viewModel.refreshDashboard()
            }
            .background(QueueTheme.screenBackground)
            .navigationTitle("Admin")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        Task {
                            await viewModel.refreshDashboard()
                        }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                            .font(.body.weight(.semibold))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Refresh admin dashboard")
                    .disabled(viewModel.isLoading || viewModel.isRefreshing)
                }

                ToolbarItem(placement: .topBarTrailing) {
                    ConfirmedLogoutButton {
                        session.logout()
                    }
                }
            }
            .task {
                if loadsOnAppear {
                    await viewModel.loadDashboard()
                }
            }
            .sheet(item: $activeSheet) { sheet in
                adminSheetView(for: sheet)
            }
            .confirmationDialog(
                deactivateTarget?.title ?? "Deactivate item?",
                isPresented: deactivateDialogBinding,
                titleVisibility: .visible
            ) {
                Button(deactivateTarget?.actionTitle ?? "Deactivate", role: .destructive) {
                    performDeactivate()
                }
                Button("Cancel", role: .cancel) {
                    deactivateTarget = nil
                }
            } message: {
                Text(deactivateTarget?.message ?? "This item will be deactivated instead of permanently deleted.")
            }
        }
    }

    private var welcomeSection: some View {
        QueueHeroCard(
            title: "Welcome, \(session.currentUser?.name ?? "Admin")",
            subtitle: "Monitor queue activity, active counters, service categories, users, and recent ticket movement.",
            systemImage: "chart.bar.doc.horizontal.fill",
            footnote: "Admin Dashboard"
        )
    }

    @ViewBuilder
    private var messageSection: some View {
        if let errorMessage = viewModel.errorMessage {
            MessageBanner(message: errorMessage, style: .error)
                .queueTransition()
        }

        if let successMessage = viewModel.successMessage {
            MessageBanner(message: successMessage, style: .success)
                .queueTransition()
        }
    }

    private var loadingSection: some View {
        QueueCard {
            HStack(spacing: 12) {
                ProgressView()
                Text("Loading admin dashboard...")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var summarySection: some View {
        QueueCard {
            SectionHeaderText("Queue Overview", subtitle: "Live summary from backend data.")

            if let summary = viewModel.summary {
                LazyVGrid(columns: metricColumns, spacing: 12) {
                    AdminMetricCard(title: "Total Tickets", value: summary.totalTickets, systemImage: "ticket.fill", color: QueueTheme.primary)
                    AdminMetricCard(title: "Waiting", value: summary.waitingTickets, systemImage: "clock.fill", color: QueueTheme.warning)
                    AdminMetricCard(title: "Called", value: summary.calledTickets, systemImage: "speaker.wave.2.fill", color: QueueTheme.primary)
                    AdminMetricCard(title: "Checked In", value: summary.checkedInTickets, systemImage: "checkmark.circle.fill", color: QueueTheme.success)
                    AdminMetricCard(title: "Customers", value: summary.totalCustomers, systemImage: "person.2.fill", color: QueueTheme.secondary)
                    AdminMetricCard(title: "Staff", value: summary.totalStaff, systemImage: "person.badge.key.fill", color: .indigo)
                    AdminMetricCard(title: "Categories", value: summary.activeCategories, systemImage: "square.grid.2x2.fill", color: .purple)
                    AdminMetricCard(title: "Counters", value: summary.activeCounters, systemImage: "desktopcomputer", color: .teal)
                }
            } else {
                EmptyQueueState(
                    title: "No Summary Available",
                    message: "Refresh the dashboard after confirming the backend is running.",
                    systemImage: "chart.bar"
                )
            }
        }
    }

    private var reportsPreviewSection: some View {
        QueueCard {
            SectionHeaderText("Reports Preview", subtitle: "A simple read-only snapshot for the current prototype.")

            LazyVGrid(columns: reportColumns, spacing: 10) {
                SummaryChip(title: "Total", value: viewModel.summary?.totalTickets ?? 0, color: QueueTheme.primary)
                SummaryChip(title: "Today", value: viewModel.summary?.todayTickets ?? 0, color: QueueTheme.secondary)
                SummaryChip(title: "Waiting", value: viewModel.summary?.waitingTickets ?? 0, color: QueueTheme.warning)
                SummaryChip(title: "Called", value: viewModel.summary?.calledTickets ?? 0, color: QueueTheme.primary)
                SummaryChip(title: "Checked In", value: viewModel.summary?.checkedInTickets ?? 0, color: QueueTheme.success)
                SummaryChip(title: "Customers", value: viewModel.summary?.totalCustomers ?? 0, color: QueueTheme.secondary)
            }

            ShareLink(item: adminReportText) {
                Label("Export Daily Report", systemImage: "square.and.arrow.up")
                    .font(.subheadline.weight(.semibold))
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .controlSize(.large)
            .disabled(viewModel.summary == nil)

            MessageBanner(
                message: "This export shares a CSV-style report. Category, counter, and user management are available from this dashboard.",
                style: .info
            )
        }
    }

    private var categoriesSection: some View {
        QueueCard {
            SectionHeaderWithAction(
                title: "Queue Categories",
                subtitle: "Create, edit, activate, or deactivate service categories.",
                actionTitle: "Add",
                systemImage: "plus"
            ) {
                activeSheet = .newCategory
            }

            if viewModel.categories.isEmpty {
                EmptyQueueState(
                    title: "No Categories",
                    message: "No active queue categories were returned by the backend.",
                    systemImage: "square.grid.2x2"
                )
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(viewModel.categories.enumerated()), id: \.element.categoryId) { index, category in
                        AdminCategoryRow(category: category) {
                            activeSheet = .editCategory(category)
                        } onDeactivate: {
                            deactivateTarget = .category(category)
                        }
                            .transition(.opacity.combined(with: .move(edge: .bottom)))

                        if index < viewModel.categories.count - 1 {
                            Divider()
                                .padding(.leading, 60)
                        }
                    }
                }
            }
        }
    }

    private var countersSection: some View {
        QueueCard {
            SectionHeaderWithAction(
                title: "Service Counters",
                subtitle: "Create counters and update active or inactive status.",
                actionTitle: "Add",
                systemImage: "plus"
            ) {
                activeSheet = .newCounter
            }

            if viewModel.counters.isEmpty {
                EmptyQueueState(
                    title: "No Counters",
                    message: "No service counters were returned by the admin endpoint.",
                    systemImage: "desktopcomputer"
                )
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(viewModel.counters.enumerated()), id: \.element.counterId) { index, counter in
                        AdminCounterRow(counter: counter) {
                            activeSheet = .editCounter(counter)
                        } onDeactivate: {
                            deactivateTarget = .counter(counter)
                        }
                            .transition(.opacity.combined(with: .move(edge: .bottom)))

                        if index < viewModel.counters.count - 1 {
                            Divider()
                                .padding(.leading, 60)
                        }
                    }
                }
            }
        }
    }

    private var usersSection: some View {
        QueueCard {
            SectionHeaderWithAction(
                title: "Users Overview",
                subtitle: "Add users, edit account details, and deactivate accounts without exposing passwords.",
                actionTitle: "Add",
                systemImage: "plus"
            ) {
                activeSheet = .newUser
            }

            HStack(spacing: 12) {
                SummaryChip(title: "Customers", value: viewModel.customerUsersCount, color: QueueTheme.secondary)
                SummaryChip(title: "Staff", value: viewModel.staffUsersCount, color: .indigo)
                SummaryChip(title: "Admins", value: viewModel.adminUsersCount, color: .purple)
            }

            if viewModel.users.isEmpty {
                EmptyQueueState(
                    title: "No Users",
                    message: "No user records were returned by the backend.",
                    systemImage: "person.3"
                )
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(viewModel.users.enumerated()), id: \.element.userId) { index, user in
                        AdminUserRow(user: user) {
                            activeSheet = .editUser(user)
                        } onDeactivate: {
                            deactivateTarget = .user(user)
                        }
                            .transition(.opacity.combined(with: .move(edge: .bottom)))

                        if index < viewModel.users.count - 1 {
                            Divider()
                                .padding(.leading, 60)
                        }
                    }
                }
            }
        }
    }

    private var recentTicketsSection: some View {
        QueueCard {
            SectionHeaderText("Recent Queue Tickets", subtitle: "Latest tickets are shown first.")

            if viewModel.recentTickets.isEmpty {
                EmptyQueueState(
                    title: "No Tickets Yet",
                    message: "Recent queue activity will appear here after customers take numbers.",
                    systemImage: "tray"
                )
            } else {
                VStack(spacing: 8) {
                    ForEach(viewModel.recentTickets) { ticket in
                        TicketListRow(ticket: ticket)
                            .transition(.opacity.combined(with: .move(edge: .bottom)))

                        if ticket.id != viewModel.recentTickets.last?.id {
                            Divider()
                        }
                    }
                }
            }
        }
    }

    private var futureScopeSection: some View {
        QueueCard {
            SectionHeaderText("Future Admin Tools", subtitle: "Advanced reporting stays scoped for the next iteration.")

            AdminFeatureRow(
                icon: "chart.bar.xaxis",
                title: "Date Range Reports",
                description: "Filter queue volume and service performance by date."
            )
            AdminFeatureRow(
                icon: "lock.shield.fill",
                title: "Admin Permissions",
                description: "Add stricter admin authorization when the backend adds real auth tokens."
            )
        }
    }

    private var adminReportText: String {
        """
        Metric,Value
        Total Tickets,\(viewModel.summary?.totalTickets ?? 0)
        Today,\(viewModel.summary?.todayTickets ?? 0)
        Waiting,\(viewModel.summary?.waitingTickets ?? 0)
        Called,\(viewModel.summary?.calledTickets ?? 0)
        Checked In,\(viewModel.summary?.checkedInTickets ?? 0)
        Customers,\(viewModel.summary?.totalCustomers ?? 0)
        Staff,\(viewModel.summary?.totalStaff ?? 0)
        Active Categories,\(viewModel.summary?.activeCategories ?? 0)
        Active Counters,\(viewModel.summary?.activeCounters ?? 0)
        """
    }

    @ViewBuilder
    private func adminSheetView(for sheet: AdminManagementSheet) -> some View {
        switch sheet {
        case .newCategory:
            AdminCategoryFormView(
                title: "New Category",
                category: nil,
                isSaving: viewModel.isRefreshing
            ) { name, prefix, isActive in
                await viewModel.createCategory(name: name, prefix: prefix)
            }
        case .editCategory(let category):
            AdminCategoryFormView(
                title: "Edit Category",
                category: category,
                isSaving: viewModel.isRefreshing
            ) { name, prefix, isActive in
                await viewModel.updateCategory(category, name: name, prefix: prefix, isActive: isActive)
            }
        case .newCounter:
            AdminCounterFormView(
                title: "New Counter",
                counter: nil,
                staffUsers: viewModel.users.filter { $0.role == "service_staff" && $0.isActive != false },
                isSaving: viewModel.isRefreshing
            ) { name, status, assignedStaffId in
                await viewModel.createCounter(name: name, status: status, assignedStaffId: assignedStaffId)
            }
        case .editCounter(let counter):
            AdminCounterFormView(
                title: "Edit Counter",
                counter: counter,
                staffUsers: viewModel.users.filter { $0.role == "service_staff" && $0.isActive != false },
                isSaving: viewModel.isRefreshing
            ) { name, status, assignedStaffId in
                await viewModel.updateCounter(counter, name: name, status: status, assignedStaffId: assignedStaffId)
            }
        case .editUser(let user):
            AdminUserFormView(
                title: "Edit User",
                user: user,
                isSaving: viewModel.isRefreshing
            ) { name, username, email, role, isActive in
                await viewModel.updateUser(user, name: name, username: username, email: email, role: role, isActive: isActive)
            }
        case .newUser:
            AdminNewUserFormView(
                isSaving: viewModel.isRefreshing
            ) { name, username, email, password, role in
                await viewModel.createUser(name: name, username: username, email: email, password: password, role: role)
            }
        }
    }

    private var deactivateDialogBinding: Binding<Bool> {
        Binding(
            get: { deactivateTarget != nil },
            set: { isPresented in
                if !isPresented {
                    deactivateTarget = nil
                }
            }
        )
    }

    private func performDeactivate() {
        guard let deactivateTarget else {
            return
        }

        Task {
            switch deactivateTarget {
            case .category(let category):
                _ = await viewModel.deactivateCategory(category)
            case .counter(let counter):
                _ = await viewModel.deactivateCounter(counter)
            case .user(let user):
                _ = await viewModel.deactivateUser(user)
            }
            self.deactivateTarget = nil
        }
    }
}

private enum AdminManagementSheet: Identifiable {
    case newCategory
    case editCategory(QueueCategory)
    case newCounter
    case editCounter(ServiceCounter)
    case newUser
    case editUser(AdminUser)

    var id: String {
        switch self {
        case .newCategory:
            return "new-category"
        case .editCategory(let category):
            return "edit-category-\(category.categoryId)"
        case .newCounter:
            return "new-counter"
        case .editCounter(let counter):
            return "edit-counter-\(counter.counterId)"
        case .newUser:
            return "new-user"
        case .editUser(let user):
            return "edit-user-\(user.userId)"
        }
    }
}

private enum AdminDeactivateTarget: Identifiable {
    case category(QueueCategory)
    case counter(ServiceCounter)
    case user(AdminUser)

    var id: String {
        switch self {
        case .category(let category):
            return "category-\(category.categoryId)"
        case .counter(let counter):
            return "counter-\(counter.counterId)"
        case .user(let user):
            return "user-\(user.userId)"
        }
    }

    var title: String {
        switch self {
        case .category:
            return "Deactivate Category?"
        case .counter:
            return "Deactivate Counter?"
        case .user:
            return "Deactivate User?"
        }
    }

    var actionTitle: String {
        switch self {
        case .category:
            return "Deactivate Category"
        case .counter:
            return "Deactivate Counter"
        case .user:
            return "Deactivate User"
        }
    }

    var message: String {
        switch self {
        case .category(let category):
            return "\(category.categoryName) will be hidden from the customer category list."
        case .counter(let counter):
            return "\(counter.counterName) will be marked as inactive."
        case .user(let user):
            return "\(user.name) will no longer be able to log in while inactive."
        }
    }
}

private struct AdminMetricCard: View {
    let title: String
    let value: Int
    let systemImage: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(systemName: systemImage)
                .font(.subheadline.weight(.bold))
                .frame(width: 34, height: 34)
                .foregroundStyle(color)
                .background(color.opacity(0.12), in: RoundedRectangle(cornerRadius: 10))

            Text("\(value)")
                .font(.title2.bold())
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.78)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(Color(.tertiarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 14))
    }
}

private struct SectionHeaderWithAction: View {
    let title: String
    let subtitle: String
    let actionTitle: String
    let systemImage: String
    let action: () -> Void

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            SectionHeaderText(title, subtitle: subtitle)
                .layoutPriority(1)

            Spacer(minLength: 8)

            Button(action: action) {
                Image(systemName: systemImage)
                    .font(.subheadline.weight(.bold))
                    .frame(width: 32, height: 32)
            }
            .buttonStyle(.plain)
            .foregroundStyle(QueueTheme.primary)
            .background(QueueTheme.primary.opacity(0.12), in: Circle())
            .accessibilityLabel(actionTitle)
        }
    }
}

private struct AdminCategoryRow: View {
    let category: QueueCategory
    let onEdit: () -> Void
    let onDeactivate: () -> Void

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            Text(category.prefix)
                .font(.headline.bold())
                .frame(width: 48, height: 48)
                .foregroundStyle(.white)
                .background(QueueTheme.primary, in: RoundedRectangle(cornerRadius: 12))

            VStack(alignment: .leading, spacing: 4) {
                Text(category.categoryName)
                    .font(.subheadline.bold())
                    .lineLimit(2)
                    .minimumScaleFactor(0.9)

                Text("Current number \(category.currentNumber ?? 0)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .layoutPriority(1)

            Spacer(minLength: 8)

            AdminInlineStatusBadge(
                title: category.isActive == false ? "Inactive" : "Active",
                color: category.isActive == false ? .secondary : QueueTheme.success
            )

            AdminRowActionMenu(
                itemName: category.categoryName,
                canDeactivate: category.isActive != false,
                onEdit: onEdit,
                onDeactivate: onDeactivate
            )
        }
        .padding(.vertical, 10)
        .contentShape(Rectangle())
        .onTapGesture(perform: onEdit)
        .accessibilityElement(children: .combine)
        .accessibilityHint("Double tap to edit. Use the actions menu to deactivate.")
    }
}

private struct AdminCounterRow: View {
    let counter: ServiceCounter
    let onEdit: () -> Void
    let onDeactivate: () -> Void

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            Image(systemName: "desktopcomputer")
                .font(.subheadline.weight(.semibold))
                .frame(width: 48, height: 48)
                .foregroundStyle(QueueTheme.primary)
                .background(QueueTheme.primary.opacity(0.12), in: RoundedRectangle(cornerRadius: 12))

            VStack(alignment: .leading, spacing: 5) {
                Text(counter.counterName)
                    .font(.subheadline.bold())
                    .lineLimit(2)
                    .minimumScaleFactor(0.9)

                Text(counter.displayStaffName ?? "No staff assigned")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
            }
            .layoutPriority(1)

            Spacer(minLength: 8)

            AdminInlineStatusBadge(
                title: counter.status.replacingOccurrences(of: "_", with: " ").capitalized,
                color: counter.status == "active" ? QueueTheme.success : .secondary
            )

            AdminRowActionMenu(
                itemName: counter.counterName,
                canDeactivate: counter.status != "inactive",
                onEdit: onEdit,
                onDeactivate: onDeactivate
            )
        }
        .padding(.vertical, 10)
        .contentShape(Rectangle())
        .onTapGesture(perform: onEdit)
        .accessibilityElement(children: .combine)
        .accessibilityHint("Double tap to edit. Use the actions menu to deactivate.")
    }
}

private struct AdminUserRow: View {
    let user: AdminUser
    let onEdit: () -> Void
    let onDeactivate: () -> Void

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            Image(systemName: iconName)
                .font(.subheadline.weight(.semibold))
                .frame(width: 48, height: 48)
                .foregroundStyle(roleColor)
                .background(roleColor.opacity(0.12), in: RoundedRectangle(cornerRadius: 12))

            VStack(alignment: .leading, spacing: 4) {
                Text(user.name)
                    .font(.subheadline.bold())
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)

                Text("@\(user.username) • \(roleTitle)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.82)
            }
            .layoutPriority(1)

            Spacer(minLength: 8)

            AdminInlineStatusBadge(
                title: user.isActive == false ? "Inactive" : "Active",
                color: user.isActive == false ? .secondary : QueueTheme.success
            )

            AdminRowActionMenu(
                itemName: user.name,
                canDeactivate: user.isActive != false,
                onEdit: onEdit,
                onDeactivate: onDeactivate
            )
        }
        .padding(.vertical, 10)
        .contentShape(Rectangle())
        .onTapGesture(perform: onEdit)
        .accessibilityElement(children: .combine)
        .accessibilityHint("Double tap to edit. Use the actions menu to deactivate.")
    }

    private var iconName: String {
        switch user.role {
        case "admin":
            return "person.crop.circle.badge.checkmark"
        case "service_staff":
            return "person.badge.key.fill"
        default:
            return "person.fill"
        }
    }

    private var roleTitle: String {
        switch user.role {
        case "admin":
            return "Admin"
        case "service_staff":
            return "Service Staff"
        case "customer":
            return "Customer"
        default:
            return user.role.replacingOccurrences(of: "_", with: " ").capitalized
        }
    }

    private var roleColor: Color {
        switch user.role {
        case "admin":
            return .purple
        case "service_staff":
            return .indigo
        default:
            return QueueTheme.secondary
        }
    }
}

private struct AdminInlineStatusBadge: View {
    let title: String
    let color: Color

    var body: some View {
        Text(title)
            .font(.caption2.weight(.bold))
            .lineLimit(1)
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .foregroundStyle(color)
            .background(color.opacity(0.13), in: Capsule())
            .fixedSize(horizontal: true, vertical: false)
            .contentTransition(.opacity)
            .animation(QueueMotion.quick, value: title)
    }
}

private struct AdminRowActionMenu: View {
    let itemName: String
    let canDeactivate: Bool
    let onEdit: () -> Void
    let onDeactivate: () -> Void

    var body: some View {
        Menu {
            Button(action: onEdit) {
                Label("Edit", systemImage: "pencil")
            }

            if canDeactivate {
                Button(role: .destructive, action: onDeactivate) {
                    Label("Deactivate", systemImage: "minus.circle")
                }
            }
        } label: {
            Image(systemName: "ellipsis")
                .font(.subheadline.weight(.bold))
                .frame(width: 34, height: 34)
                .foregroundStyle(.secondary)
                .background(Color(.tertiarySystemGroupedBackground), in: Circle())
        }
        .accessibilityLabel("Actions for \(itemName)")
    }
}

private struct AdminCategoryFormView: View {
    let title: String
    let isSaving: Bool
    let onSave: (String, String, Bool) async -> Bool

    @Environment(\.dismiss) private var dismiss
    @State private var name: String
    @State private var prefix: String
    @State private var isActive: Bool
    @State private var errorMessage: String?

    init(
        title: String,
        category: QueueCategory?,
        isSaving: Bool,
        onSave: @escaping (String, String, Bool) async -> Bool
    ) {
        self.title = title
        self.isSaving = isSaving
        self.onSave = onSave
        _name = State(initialValue: category?.categoryName ?? "")
        _prefix = State(initialValue: category?.prefix ?? "")
        _isActive = State(initialValue: category?.isActive != false)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Category") {
                    TextField("Category name", text: $name)
                    TextField("Prefix", text: $prefix)
                        .textInputAutocapitalization(.characters)
                    Toggle("Active", isOn: $isActive)
                }

                if let errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button(isSaving ? "Saving..." : "Save") {
                        save()
                    }
                    .disabled(isSaving)
                }
            }
        }
    }

    private func save() {
        let cleanName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanPrefix = prefix.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()

        guard !cleanName.isEmpty, !cleanPrefix.isEmpty else {
            errorMessage = "Category name and prefix are required."
            return
        }

        Task {
            if await onSave(cleanName, cleanPrefix, isActive) {
                dismiss()
            }
        }
    }
}

private struct AdminCounterFormView: View {
    let title: String
    let staffUsers: [AdminUser]
    let isSaving: Bool
    let onSave: (String, String, Int?) async -> Bool

    @Environment(\.dismiss) private var dismiss
    @State private var name: String
    @State private var status: String
    @State private var assignedStaffId: Int
    @State private var errorMessage: String?

    init(
        title: String,
        counter: ServiceCounter?,
        staffUsers: [AdminUser],
        isSaving: Bool,
        onSave: @escaping (String, String, Int?) async -> Bool
    ) {
        self.title = title
        self.staffUsers = staffUsers
        self.isSaving = isSaving
        self.onSave = onSave
        _name = State(initialValue: counter?.counterName ?? "")
        _status = State(initialValue: counter?.status ?? "active")
        _assignedStaffId = State(initialValue: counter?.assignedStaffId ?? 0)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Counter") {
                    TextField("Counter name", text: $name)

                    Picker("Status", selection: $status) {
                        Text("Active").tag("active")
                        Text("Inactive").tag("inactive")
                    }

                    Picker("Assigned Staff", selection: $assignedStaffId) {
                        Text("No staff").tag(0)
                        ForEach(staffUsers) { user in
                            Text(user.name).tag(user.userId)
                        }
                    }
                }

                if let errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button(isSaving ? "Saving..." : "Save") {
                        save()
                    }
                    .disabled(isSaving)
                }
            }
        }
    }

    private func save() {
        let cleanName = name.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !cleanName.isEmpty else {
            errorMessage = "Counter name is required."
            return
        }

        Task {
            if await onSave(cleanName, status, assignedStaffId == 0 ? nil : assignedStaffId) {
                dismiss()
            }
        }
    }
}

private struct AdminUserFormView: View {
    let title: String
    let user: AdminUser
    let isSaving: Bool
    let onSave: (String, String, String?, String, Bool) async -> Bool

    @Environment(\.dismiss) private var dismiss
    @State private var name: String
    @State private var username: String
    @State private var email: String
    @State private var role: String
    @State private var isActive: Bool
    @State private var errorMessage: String?

    init(
        title: String,
        user: AdminUser,
        isSaving: Bool,
        onSave: @escaping (String, String, String?, String, Bool) async -> Bool
    ) {
        self.title = title
        self.user = user
        self.isSaving = isSaving
        self.onSave = onSave
        _name = State(initialValue: user.name)
        _username = State(initialValue: user.username)
        _email = State(initialValue: user.email ?? "")
        _role = State(initialValue: user.role)
        _isActive = State(initialValue: user.isActive != false)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("User") {
                    TextField("Name", text: $name)
                    TextField("Username", text: $username)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()

                    TextField("Email optional", text: $email)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.emailAddress)

                    Picker("Role", selection: $role) {
                        Text("Customer").tag("customer")
                        Text("Service Staff").tag("service_staff")
                        Text("Admin").tag("admin")
                    }

                    Toggle("Active", isOn: $isActive)
                }

                Section {
                    Text("Passwords are not shown or changed from this demo admin screen.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                if let errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button(isSaving ? "Saving..." : "Save") {
                        save()
                    }
                    .disabled(isSaving)
                }
            }
        }
    }

    private func save() {
        let cleanName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanUsername = username.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let cleanEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !cleanName.isEmpty, !cleanUsername.isEmpty else {
            errorMessage = "Name and username are required."
            return
        }

        Task {
            if await onSave(cleanName, cleanUsername, cleanEmail.isEmpty ? nil : cleanEmail, role, isActive) {
                dismiss()
            }
        }
    }
}

private struct AdminNewUserFormView: View {
    let isSaving: Bool
    let onSave: (String, String, String?, String, String) async -> Bool

    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var username = ""
    @State private var email = ""
    @State private var password = ""
    @State private var role = "customer"
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            Form {
                Section("New User") {
                    TextField("Name", text: $name)

                    TextField("Username", text: $username)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()

                    TextField("Email optional", text: $email)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.emailAddress)

                    SecureField("Password", text: $password)

                    Picker("Role", selection: $role) {
                        Text("Customer").tag("customer")
                        Text("Service Staff").tag("service_staff")
                        Text("Admin").tag("admin")
                    }
                }

                Section {
                    Text("Passwords are saved using the current local prototype style and are never displayed in admin responses.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                if let errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle("New User")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button(isSaving ? "Saving..." : "Save") {
                        save()
                    }
                    .disabled(isSaving)
                }
            }
        }
    }

    private func save() {
        let cleanName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanUsername = username.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let cleanEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanPassword = password.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !cleanName.isEmpty, !cleanUsername.isEmpty, !cleanPassword.isEmpty else {
            errorMessage = "Name, username, and password are required."
            return
        }

        Task {
            if await onSave(cleanName, cleanUsername, cleanEmail.isEmpty ? nil : cleanEmail, cleanPassword, role) {
                dismiss()
            }
        }
    }
}

private struct AdminFeatureRow: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.subheadline.weight(.semibold))
                .frame(width: 34, height: 34)
                .foregroundStyle(QueueTheme.primary)
                .background(QueueTheme.primary.opacity(0.12), in: RoundedRectangle(cornerRadius: 10))

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline.bold())
                Text(description)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

#if DEBUG
struct AdminDashboardView_Previews: PreviewProvider {
    static var previews: some View {
        AdminDashboardView(viewModel: PreviewData.adminDashboardViewModel(), loadsOnAppear: false)
            .environmentObject(PreviewData.session(for: PreviewData.adminUser))
            .previewDisplayName("Admin Dashboard")
    }
}
#endif

