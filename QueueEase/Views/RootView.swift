import SwiftUI

struct RootView: View {
    @EnvironmentObject private var session: AppSession

    var body: some View {
        Group {
            if session.isLoggedIn, let user = session.currentUser {
                dashboard(for: user)
                    .id(user.userId)
                    .transition(.opacity.combined(with: .scale(scale: 0.985)))
            } else {
                LoginView()
                    .transition(.opacity.combined(with: .scale(scale: 0.985)))
            }
        }
        .animation(QueueMotion.smooth, value: session.isLoggedIn)
        .animation(QueueMotion.smooth, value: session.userRole)
    }

    @ViewBuilder
    private func dashboard(for user: User) -> some View {
        switch user.role {
        case "customer":
            CustomerDashboardView()
        case "service_staff":
            StaffDashboardView()
        case "admin":
            AdminDashboardView()
        default:
            NavigationStack {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        QueueHeroCard(
                            title: "Unsupported Role",
                            subtitle: "QueueEase received a role that is not part of the current demo routing.",
                            systemImage: "person.crop.circle.badge.exclamationmark",
                            footnote: user.role
                        )

                        QueueCard {
                            SectionHeaderText(
                                "Cannot Open Dashboard",
                                subtitle: "Please log in with customer, staff, or admin demo credentials."
                            )

                            ConfirmedLogoutButton {
                                session.logout()
                            }
                        }
                    }
                    .padding()
                }
                .background(QueueTheme.screenBackground)
                .navigationTitle("QueueEase")
            }
        }
    }
}

