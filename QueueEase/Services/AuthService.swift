import Foundation

final class AuthService {
    static let shared = AuthService()

    private let apiService: APIService

    private init(apiService: APIService = .shared) {
        self.apiService = apiService
    }

    func login(username: String, password: String) async throws -> User {
        let body = LoginRequest(username: username, password: password)
        let response: APIResponse<User> = try await apiService.post("/auth/login", body: body)

        guard response.success != false, let user = response.data else {
            throw APIError.httpError(statusCode: 200, message: response.message ?? "Login failed.")
        }

        return user
    }

    func register(name: String, username: String, email: String?, password: String) async throws -> User {
        let body = RegisterRequest(
            name: name,
            username: username,
            email: email?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == true ? nil : email,
            password: password
        )
        let response: APIResponse<User> = try await apiService.post("/auth/register", body: body)

        guard response.success != false, let user = response.data else {
            throw APIError.httpError(statusCode: 200, message: response.message ?? "Registration failed.")
        }

        return user
    }
}

private struct LoginRequest: Encodable {
    let username: String
    let password: String
}

private struct RegisterRequest: Encodable {
    let name: String
    let username: String
    let email: String?
    let password: String
}
