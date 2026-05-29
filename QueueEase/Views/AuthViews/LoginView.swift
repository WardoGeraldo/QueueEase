//
//  LoginView.swift
//  QueueEase
//
//  Created by Edward Geraldo Kristian on 29/05/26.
//

import SwiftUI

struct LoginView: View {
    // Connects the View to the ViewModel
    @StateObject private var viewModel = AuthViewModel()
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "person.badge.key")
                .resizable()
                .scaledToFit()
                .frame(width: 80, height: 80)
                .foregroundColor(.blue)
                .padding(.bottom, 20)
            
            Text("Welcome to QueueEase")
                .font(.title)
                .bold()
            
            if let user = viewModel.currentUser {
                // If logged in, display role-based dashboard [cite: 134]
                Text("Logged in successfully as \(user.name)!")
                    .foregroundColor(.green)
                Text("Role: \(user.role.rawValue)")
                    .font(.headline)
                
                Button("Logout") {
                    viewModel.logout()
                }
                .padding(.top)
            } else {
                // Login Form
                TextField("Username", text: $viewModel.username)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .autocapitalization(.none)
                
                SecureField("Password", text: $viewModel.password)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                if let error = viewModel.errorMessage {
                    Text(error)
                        .foregroundColor(.red)
                        .font(.caption)
                }
                
                if viewModel.isLoading {
                    ProgressView()
                } else {
                    Button(action: {
                        viewModel.login()
                    }) {
                        Text("Login")
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(10)
                    }
                }
            }
        }
        .padding(30)
    }
}

#Preview {
    LoginView()
}
