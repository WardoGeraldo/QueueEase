import Foundation
import Combine

@MainActor
final class AppSession: ObservableObject {
    @Published private(set) var currentUser: User?
    @Published private(set) var isLoggedIn = false
    @Published private(set) var userRole: String?

    func login(user: User) {
        currentUser = user
        userRole = user.role
        isLoggedIn = true
    }

    func logout() {
        currentUser = nil
        userRole = nil
        isLoggedIn = false
    }
}
