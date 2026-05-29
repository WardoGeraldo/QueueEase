//
//  AuthViewModel.swift
//  QueueEase
//
//  Created by Edward Geraldo Kristian on 29/05/26.
//

import Foundation
import SwiftUI
import Combine

@MainActor
class AuthViewModel: ObservableObject {
    @Published var username = ""
    @Published var password = ""
    
    @Published var currentUser: User?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let authService = AuthService()
    
    // Executes the login flow [cite: 130]
    func login() {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                let user = try await authService.login(username: username, password: password)
                self.currentUser = user // Authentication success [cite: 137]
                self.isLoading = false
            } catch {
                self.errorMessage = error.localizedDescription // Show login error [cite: 138]
                self.isLoading = false
            }
        }
    }
    
    func logout() {
        self.currentUser = nil
        self.username = ""
        self.password = ""
    }
}
