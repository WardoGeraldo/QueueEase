//
//  AuthService.swift
//  QueueEase
//
//  Created by Edward Geraldo Kristian on 29/05/26.
//

import Foundation

class AuthService {
    
    // Simulates the authenticate(credentials) network call [cite: 131]
    func login(username: String, password: String) async throws -> User {
        // Simulate a 1-second network request to your backend
        try await Task.sleep(nanoseconds: 1_000_000_000)
        
        // Mocking the backend validation [cite: 133]
        if username == "admin" && password == "admin123" {
            return User(id: "u1", name: "System Admin", username: username, role: .systemAdministrator)
        } else if username == "staff" && password == "staff123" {
            return User(id: "u2", name: "Front Desk Staff", username: username, role: .serviceStaff)
        } else if username == "customer" && password == "cust123" {
            return User(id: "u3", name: "John Doe", username: username, role: .customer)
        } else {
            // Throw an error if credentials are invalid [cite: 144]
            throw NSError(domain: "AuthError", code: 401, userInfo: [NSLocalizedDescriptionKey: "Invalid username or password."])
        }
    }
}
