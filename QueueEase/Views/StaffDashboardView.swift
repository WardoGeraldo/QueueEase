//
//  StaffDashboardView.swift
//  QueueEase
//
//  Created by Edward Geraldo Kristian on 10/06/26.
//

import SwiftUI

struct StaffDashboardView: View {
    @EnvironmentObject private var session: AppSession
    @StateObject private var viewModel: StaffQueueViewModel
    @State private var ticketFilter: StaffTicketFilter = .all
    private let loadsOnAppear: Bool

    init() {
        _viewModel = StateObject(wrappedValue: StaffQueueViewModel())
        self.loadsOnAppear = true
    }

    init(viewModel: StaffQueueViewModel, loadsOnAppear: Bool = true) {
        _viewModel = StateObject(wrappedValue: viewModel)
        self.loadsOnAppear = loadsOnAppear
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    QueueHeroCard(
                        title: "Welcome, \(session.currentUser?.name ?? "Staff")",
                        subtitle: "Call waiting customers, check them in, and keep the ticket list moving.",
                        systemImage: "person.badge.clock.fill",
                        footnote: "Staff Counter"
                    )
                    .queueAppear(delay: 0.02)
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
                }

                Section("Today") {
                    HStack(spacing: 10) {
                        SummaryChip(title: "Waiting", value: viewModel.waitingCount, color: QueueTheme.warning)
                        SummaryChip(title: "Called", value: viewModel.calledCount, color: QueueTheme.primary)
                        SummaryChip(title: "Checked In", value: viewModel.checkedInCount, color: QueueTheme.success)
                    }
                    .padding(.vertical, 4)
                    .queueAppear(delay: 0.06)
                }

                Section("Daily Report Preview") {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(spacing: 10) {
                            SummaryChip(title: "Total", value: viewModel.totalTicketsCount, color: QueueTheme.primary)
                            SummaryChip(title: "Called", value: viewModel.calledCount, color: QueueTheme.secondary)
                            SummaryChip(title: "Checked In", value: viewModel.checkedInCount, color: QueueTheme.success)
                        }

                        ShareLink(item: dailyReportText) {
                            Label("Export Daily Report", systemImage: "square.and.arrow.up")
                                .font(.subheadline.weight(.semibold))
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.large)
                        .disabled(viewModel.tickets.isEmpty)

                        Text("Export shares a CSV-style summary for the current local demo data.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                    .queueAppear(delay: 0.08)
                }

                Section("Queue Category") {
                    if viewModel.categories.isEmpty, viewModel.isLoading {
                        ProgressView("Loading categories...")
                    } else if viewModel.categories.isEmpty {
                        EmptyQueueState(
                            title: "No Categories",
                            message: "No active queue categories were returned by the backend.",
                            systemImage: "tray"
                        )
                    } else {
                        VStack(spacing: 10) {
                            ForEach(viewModel.categories) { category in
                                Button {
                                    withAnimation(QueueMotion.quick) {
                                        viewModel.selectedCategory = category
                                    }
                                } label: {
                                    CategorySelectionCard(
                                        category: category,
                                        isSelected: viewModel.selectedCategory?.categoryId == category.categoryId,
                                        detail: "\(viewModel.waitingCount(for: category)) waiting"
                                    )
                                }
                                .buttonStyle(QueuePressScaleButtonStyle())
                            }
                        }

                        if let selectedCategory = viewModel.selectedCategory {
                            MessageBanner(
                                message: "\(selectedCategory.categoryName) has \(viewModel.selectedCategoryWaitingCount) waiting ticket\(viewModel.selectedCategoryWaitingCount == 1 ? "" : "s").",
                                style: viewModel.selectedCategoryWaitingCount > 0 ? .info : .warning
                            )
                            .queueTransition()
                        }
                    }
                }

                Section {
                    QueueActionButton(
                        viewModel.isRefreshingTickets ? "Refreshing..." : "Refresh Tickets",
                        systemImage: "arrow.clockwise",
                        isLoading: viewModel.isRefreshingTickets,
                        isDisabled: viewModel.isLoading,
                        style: .secondary
                    ) {
                        Task {
                            await viewModel.loadTickets()
                        }
                    }

                    QueueActionButton(
                        callNextTitle,
                        systemImage: "speaker.wave.2.fill",
                        isLoading: viewModel.isLoading,
                        isDisabled: !viewModel.canCallNextQueue
                    ) {
                        Task {
                            if let staffId = session.currentUser?.userId {
                                await viewModel.callNext(staffId: staffId)
                            }
                        }
                    }
                }

                if let ticket = viewModel.lastCalledTicket {
                    Section("Last Called") {
                        VStack(alignment: .leading, spacing: 10) {
                            QueueNumberDisplay(
                                queueNumber: ticket.queueNumber,
                                status: ticket.status,
                                caption: "Now serving"
                            )

                            DetailRow(title: "Category", value: ticket.categoryName ?? "-")
                            DetailRow(title: "Counter", value: ticket.counterName ?? "Counter 1")
                            DetailRow(title: "Customer", value: ticket.customerName ?? "-")
                            DetailRow(title: "Updated", value: ticket.updatedAtDisplay)

                            if viewModel.canCheckInLastCalledTicket {
                                QueueActionButton(
                                    viewModel.isLoading ? "Checking In..." : "Check In",
                                    systemImage: "checkmark.circle.fill",
                                    isLoading: viewModel.isLoading
                                ) {
                                    Task {
                                        if let staffId = session.currentUser?.userId {
                                            await viewModel.checkIn(staffId: staffId, ticketId: ticket.ticketId)
                                        }
                                    }
                                }
                            } else {
                                MessageBanner(
                                    message: ticket.statusDescription,
                                    style: .info
                                )
                            }
                        }
                        .padding(.vertical, 4)
                        .queueAppear(delay: 0.08)
                    }
                } else {
                    Section("Last Called") {
                        EmptyQueueState(
                            title: "No Called Ticket",
                            message: "Call the next queue to show the check-in action here.",
                            systemImage: "speaker.slash"
                        )
                    }
                }

                if let successMessage = viewModel.successMessage {
                    Section {
                        MessageBanner(message: successMessage, style: .success)
                            .queueTransition()
                    }
                }

                if let errorMessage = viewModel.errorMessage {
                    Section {
                        MessageBanner(message: errorMessage, style: .error)
                            .queueTransition()
                    }
                }

                Section("Queue Tickets") {
                    HStack {
                        Label("Filter", systemImage: "line.3.horizontal.decrease.circle")
                            .font(.subheadline.weight(.semibold))

                        Spacer()

                        Picker("Ticket Filter", selection: $ticketFilter) {
                            ForEach(StaffTicketFilter.allCases) { filter in
                                Text(filter.title).tag(filter)
                            }
                        }
                        .pickerStyle(.menu)
                    }
                    .accessibilityLabel("Ticket status filter")
                    .accessibilityHint("Filters the monitoring list by ticket status.")

                    if (viewModel.isLoading || viewModel.isRefreshingTickets), viewModel.tickets.isEmpty {
                        ProgressView("Loading tickets...")
                    } else if viewModel.tickets.isEmpty {
                        EmptyQueueState(
                            title: "No Tickets Yet",
                            message: "Tickets will appear here after customers take queue numbers.",
                            systemImage: "list.bullet.rectangle"
                        )
                    } else if filteredTickets.isEmpty {
                        EmptyQueueState(
                            title: ticketFilter.emptyTitle,
                            message: ticketFilter.emptyMessage,
                            systemImage: "line.3.horizontal.decrease.circle"
                        )
                    } else {
                        ForEach(filteredTickets) { ticket in
                            TicketListRow(ticket: ticket)
                                .transition(.opacity.combined(with: .move(edge: .bottom)))
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .animation(QueueMotion.smooth, value: viewModel.categories)
            .animation(QueueMotion.smooth, value: viewModel.selectedCategory)
            .animation(QueueMotion.smooth, value: viewModel.tickets)
            .animation(QueueMotion.smooth, value: viewModel.lastCalledTicket)
            .animation(QueueMotion.smooth, value: viewModel.successMessage)
            .animation(QueueMotion.smooth, value: viewModel.errorMessage)
            .animation(QueueMotion.quick, value: ticketFilter)
            .refreshable {
                await viewModel.loadDashboardData()
            }
            .navigationTitle("Staff")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    ConfirmedLogoutButton {
                        session.logout()
                    }
                }
            }
            .task {
                if loadsOnAppear {
                    await viewModel.loadDashboardData()
                }
            }
        }
    }

    private var callNextTitle: String {
        if viewModel.isLoading {
            return "Calling..."
        }

        guard let selectedCategory = viewModel.selectedCategory else {
            return "Select Category First"
        }

        if viewModel.selectedCategoryWaitingCount == 0 {
            return "No Waiting in \(selectedCategory.prefix)"
        }

        return "Call Next \(selectedCategory.prefix)"
    }

    private var filteredTickets: [QueueTicket] {
        switch ticketFilter {
        case .all:
            return viewModel.tickets
        case .waiting:
            return viewModel.tickets.filter { $0.status == "waiting" }
        case .called:
            return viewModel.tickets.filter { $0.status == "called" }
        case .checkedIn:
            return viewModel.tickets.filter { $0.status == "checked_in" }
        case .skipped:
            return viewModel.tickets.filter { $0.status == "skipped" }
        case .cancelled:
            return viewModel.tickets.filter { $0.status == "cancelled" }
        }
    }

    private var dailyReportText: String {
        """
        Metric,Value
        Total Tickets,\(viewModel.totalTicketsCount)
        Waiting,\(viewModel.waitingCount)
        Called,\(viewModel.calledCount)
        Checked In,\(viewModel.checkedInCount)
        """
    }
}

#if DEBUG
struct StaffDashboardView_Previews: PreviewProvider {
    static var previews: some View {
        StaffDashboardView(
            viewModel: PreviewData.staffQueueViewModel(),
            loadsOnAppear: false
        )
        .environmentObject(PreviewData.session(for: PreviewData.staffUser))
        .previewDisplayName("Staff Dashboard")
    }
}
#endif

private enum StaffTicketFilter: String, CaseIterable, Identifiable {
    case all
    case waiting
    case called
    case checkedIn
    case skipped
    case cancelled

    var id: String {
        rawValue
    }

    var title: String {
        switch self {
        case .all:
            return "All"
        case .waiting:
            return "Waiting"
        case .called:
            return "Called"
        case .checkedIn:
            return "Checked In"
        case .skipped:
            return "Skipped"
        case .cancelled:
            return "Cancelled"
        }
    }

    var emptyTitle: String {
        switch self {
        case .all:
            return "No Tickets"
        case .waiting:
            return "No Waiting Tickets"
        case .called:
            return "No Called Tickets"
        case .checkedIn:
            return "No Checked In Tickets"
        case .skipped:
            return "No Skipped Tickets"
        case .cancelled:
            return "No Cancelled Tickets"
        }
    }

    var emptyMessage: String {
        switch self {
        case .all:
            return "Tickets will appear here after customers take queue numbers."
        case .waiting:
            return "Waiting tickets will appear here before staff calls them."
        case .called:
            return "Called tickets will appear here after using Call Next Queue."
        case .checkedIn:
            return "Checked in tickets will appear here after staff confirms the customer."
        case .skipped:
            return "Skipped tickets will appear here if a customer misses their call."
        case .cancelled:
            return "Cancelled tickets will appear here if a queue request is cancelled."
        }
    }
}

