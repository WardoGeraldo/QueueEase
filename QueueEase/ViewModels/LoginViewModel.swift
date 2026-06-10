import Foundation
import Combine

@MainActor
final class RegisterViewModel: ObservableObject {
    @Published var name = ""
    @Published var username = ""
    @Published var email = ""
    @Published var password = ""
    @Published var confirmPassword = ""
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var successMessage: String?

    private let authService: AuthService

    init() {
        self.authService = .shared
    }

    init(authService: AuthService) {
        self.authService = authService
    }

    var canSubmit: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !username.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !password.isEmpty &&
        !confirmPassword.isEmpty &&
        !isLoading
    }

    func register(session: AppSession) async {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedUsername = username.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedName.isEmpty, !trimmedUsername.isEmpty, !password.isEmpty else {
            errorMessage = "Name, username, and password are required."
            return
        }

        guard trimmedUsername.count >= 3, password.count >= 3 else {
            errorMessage = "Username and password must be at least 3 characters."
            return
        }

        guard password == confirmPassword else {
            errorMessage = "Password confirmation does not match."
            return
        }

        isLoading = true
        errorMessage = nil
        successMessage = nil

        do {
            let user = try await authService.register(
                name: trimmedName,
                username: trimmedUsername,
                email: trimmedEmail.isEmpty ? nil : trimmedEmail,
                password: password
            )
            successMessage = "Account created. Opening customer dashboard..."
            session.login(user: user)
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }
}
