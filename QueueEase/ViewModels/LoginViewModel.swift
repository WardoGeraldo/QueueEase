import Foundation
import Combine

@MainActor
final class LoginViewModel: ObservableObject {
    @Published var username = ""
    @Published var password = ""
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let authService: AuthService

    init() {
        self.authService = .shared
    }

    init(authService: AuthService) {
        self.authService = authService
    }

    var canSubmit: Bool {
        !username.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !password.isEmpty && !isLoading
    }

    func login(session: AppSession) async {
        let trimmedUsername = username.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedUsername.isEmpty, !password.isEmpty else {
            errorMessage = "Username and password are required."
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            let user = try await authService.login(username: trimmedUsername, password: password)
            session.login(user: user)
            password = ""
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }
}

