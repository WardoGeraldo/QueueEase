import SwiftUI

struct QueueStatusView: View {
    @ObservedObject var viewModel: CustomerQueueViewModel
    private let enablesPolling: Bool

    init(viewModel: CustomerQueueViewModel, enablesPolling: Bool = true) {
        self.viewModel = viewModel
        self.enablesPolling = enablesPolling
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                if let ticket = viewModel.currentTicket {
                    QueueCard {
                        QueueNumberDisplay(
                            queueNumber: ticket.queueNumber,
                            status: ticket.status,
                            caption: "Live queue status"
                        )

                        QueueStatusTimeline(status: ticket.status)
                    }
                    .queueAppear(delay: 0.02)

                    MessageBanner(message: ticket.statusDescription, style: .info)
                        .queueAppear(delay: 0.06)

                    QueueCard {
                        SectionHeaderText("Ticket Details", subtitle: "This screen refreshes automatically every 3 seconds.")
                        DetailRow(title: "Category", value: ticket.categoryName ?? "-")
                        DetailRow(title: "Counter", value: ticket.counterName ?? "Not assigned yet")
                        DetailRow(title: "Created", value: ticket.createdAtDisplay)
                        DetailRow(title: "Called", value: ticket.calledAtDisplay)
                        DetailRow(title: "Checked In", value: ticket.checkedInAtDisplay)
                        DetailRow(title: "Last Updated", value: ticket.updatedAtDisplay)
                    }
                    .queueAppear(delay: 0.10)

                    QueueActionButton(
                        viewModel.isRefreshingTicket ? "Refreshing..." : "Refresh Now",
                        systemImage: "arrow.clockwise",
                        isLoading: viewModel.isRefreshingTicket
                    ) {
                        Task {
                            await viewModel.refreshCurrentTicket()
                        }
                    }
                    .queueAppear(delay: 0.14)
                } else {
                    QueueCard {
                        EmptyQueueState(
                            title: "No Queue Ticket",
                            message: "Take a queue number first to monitor your status.",
                            systemImage: "ticket"
                        )
                    }
                    .queueTransition()
                }

                if let errorMessage = viewModel.errorMessage {
                    MessageBanner(message: errorMessage, style: .error)
                        .queueTransition()
                }
            }
            .animation(QueueMotion.smooth, value: viewModel.currentTicket)
            .animation(QueueMotion.smooth, value: viewModel.errorMessage)
            .padding()
        }
        .refreshable {
            await viewModel.refreshCurrentTicket()
        }
        .background(QueueTheme.screenBackground)
        .navigationTitle("Queue Status")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            if enablesPolling {
                await viewModel.refreshCurrentTicket()
                viewModel.startPolling()
            }
        }
        .onDisappear {
            if enablesPolling {
                viewModel.stopPolling()
            }
        }
    }
}

#if DEBUG
struct QueueStatusView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            QueueStatusView(
                viewModel: PreviewData.customerQueueViewModel(),
                enablesPolling: false
            )
        }
        .previewDisplayName("Queue Status")
    }
}
#endif
