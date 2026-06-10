import SwiftUI

struct CustomerDashboardView: View {
    @EnvironmentObject private var session: AppSession
    @StateObject private var viewModel: CustomerQueueViewModel
    private let loadsOnAppear: Bool

    init() {
        _viewModel = StateObject(wrappedValue: CustomerQueueViewModel())
        self.loadsOnAppear = true
    }

    init(viewModel: CustomerQueueViewModel, loadsOnAppear: Bool = true) {
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
                    categorySection
                        .queueAppear(delay: 0.10)
                    ticketSection
                        .queueAppear(delay: 0.14)
                    historySection
                        .queueAppear(delay: 0.18)
                }
                .padding()
                .animation(QueueMotion.smooth, value: viewModel.currentTicket)
                .animation(QueueMotion.smooth, value: viewModel.customerTickets)
                .animation(QueueMotion.smooth, value: viewModel.selectedCategory)
                .animation(QueueMotion.smooth, value: viewModel.errorMessage)
                .animation(QueueMotion.smooth, value: viewModel.successMessage)
            }
            .refreshable {
                if let customerId = session.currentUser?.userId {
                    await viewModel.loadDashboardData(customerId: customerId)
                }
            }
            .background(QueueTheme.screenBackground)
            .navigationTitle("Customer")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    ConfirmedLogoutButton {
                        viewModel.stopPolling()
                        session.logout()
                    }
                }
            }
            .task {
                if loadsOnAppear, let customerId = session.currentUser?.userId {
                    await viewModel.loadDashboardData(customerId: customerId)
                }
            }
            .onAppear {
                if loadsOnAppear, viewModel.currentTicket != nil {
                    viewModel.startPolling()
                }
            }
            .onDisappear {
                viewModel.stopPolling()
            }
        }
    }

    private var welcomeSection: some View {
        QueueHeroCard(
            title: "Welcome, \(session.currentUser?.name ?? "Customer")",
            subtitle: "Choose a service category, take a number, and monitor your status in real time.",
            systemImage: "ticket.fill",
            footnote: "Customer Flow"
        )
    }

    private var categorySection: some View {
        QueueCard {
            SectionHeaderText("Queue Category", subtitle: "Select the service you need before taking a number.")

            if viewModel.categories.isEmpty, viewModel.isLoading {
                ProgressView("Loading categories...")
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else if viewModel.categories.isEmpty {
                EmptyQueueState(
                    title: "No Categories Available",
                    message: "Ask staff to confirm that queue categories are active.",
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
                                isSelected: viewModel.selectedCategory?.categoryId == category.categoryId
                            )
                        }
                        .buttonStyle(QueuePressScaleButtonStyle())
                    }
                }

                if let category = viewModel.selectedCategory {
                    HStack {
                        Text(category.prefix)
                            .font(.caption.bold())
                            .padding(.horizontal, 8)
                            .padding(.vertical, 5)
                            .background(QueueTheme.primary.opacity(0.12), in: Capsule())
                            .foregroundStyle(QueueTheme.primary)

                        Text(category.categoryName)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .queueTransition()
                }

                QueueActionButton(
                    viewModel.isLoading ? "Processing..." : "Take Queue Number",
                    systemImage: "ticket.fill",
                    isLoading: viewModel.isLoading,
                    isDisabled: viewModel.selectedCategory == nil
                ) {
                    Task {
                        if let customerId = session.currentUser?.userId {
                            await viewModel.takeQueueNumber(customerId: customerId)
                        }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var ticketSection: some View {
        if let ticket = viewModel.currentTicket {
            QueueCard {
                SectionHeaderText("Current Queue", subtitle: "Keep this number visible while waiting.")

                QueueNumberDisplay(
                    queueNumber: ticket.queueNumber,
                    status: ticket.status,
                    caption: "Your number"
                )

                QueueStatusTimeline(status: ticket.status)

                MessageBanner(message: ticket.statusDescription, style: .info)

                DetailRow(title: "Category", value: ticket.categoryName ?? viewModel.selectedCategory?.categoryName ?? "-")
                DetailRow(title: "Counter", value: ticket.counterName ?? "Not assigned yet")
                DetailRow(title: "Created", value: ticket.createdAtDisplay)

                HStack(spacing: 10) {
                    QueueActionButton(
                        viewModel.isRefreshingTicket ? "Refreshing..." : "Refresh",
                        systemImage: "arrow.clockwise",
                        isLoading: viewModel.isRefreshingTicket,
                        style: .secondary
                    ) {
                        Task {
                            await viewModel.refreshCurrentTicket()
                        }
                    }

                    NavigationLink {
                        QueueStatusView(viewModel: viewModel)
                    } label: {
                        Text("Details")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                }
            }
            .queueTransition()
        } else {
            QueueCard {
                EmptyQueueState(
                    title: "No Queue Number Yet",
                    message: "Select a category and take a number to start monitoring your queue status.",
                    systemImage: "ticket"
                )
            }
            .queueTransition()
        }
    }

    private var historySection: some View {
        QueueCard {
            SectionHeaderText(
                "Queue History",
                subtitle: "Your previous and active tickets stay visible after staff calls or checks them in."
            )

            if viewModel.isRefreshingHistory, viewModel.customerTickets.isEmpty {
                ProgressView("Loading ticket history...")
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else if viewModel.customerTickets.isEmpty {
                EmptyQueueState(
                    title: "No Ticket History",
                    message: "Your tickets will appear here after you take a queue number.",
                    systemImage: "clock.arrow.circlepath"
                )
            } else {
                VStack(spacing: 0) {
                    ForEach(viewModel.customerTickets) { ticket in
                        TicketListRow(ticket: ticket, showsCustomerName: false)
                            .transition(.opacity.combined(with: .move(edge: .bottom)))

                        if ticket.ticketId != viewModel.customerTickets.last?.ticketId {
                            Divider()
                        }
                    }
                }

                QueueActionButton(
                    viewModel.isRefreshingHistory ? "Refreshing..." : "Refresh History",
                    systemImage: "arrow.clockwise",
                    isLoading: viewModel.isRefreshingHistory,
                    style: .secondary
                ) {
                    Task {
                        if let customerId = session.currentUser?.userId {
                            await viewModel.loadCustomerTickets(customerId: customerId)
                        }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var messageSection: some View {
        if let successMessage = viewModel.successMessage {
            MessageBanner(message: successMessage, style: .success)
                .queueTransition()
        }

        if let errorMessage = viewModel.errorMessage {
            MessageBanner(message: errorMessage, style: .error)
                .queueTransition()
        }
    }
}

#if DEBUG
struct CustomerDashboardView_Previews: PreviewProvider {
    static var previews: some View {
        CustomerDashboardView(
            viewModel: PreviewData.customerQueueViewModel(),
            loadsOnAppear: false
        )
        .environmentObject(PreviewData.session(for: PreviewData.customerUser))
        .previewDisplayName("Customer Dashboard")
    }
}
#endif
