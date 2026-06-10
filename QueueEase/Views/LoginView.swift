import SwiftUI

struct LoginView: View {
    @EnvironmentObject private var session: AppSession
    @StateObject private var viewModel = LoginViewModel()
    @FocusState private var focusedField: LoginField?

    var body: some View {
        NavigationStack {
            ZStack {
                LoginBackground()

                ScrollView {
                    VStack(spacing: 22) {
                        LoginBrandHeader()
                            .padding(.top, 36)
                            .queueAppear(delay: 0.02)

                        LoginPanel(
                            username: $viewModel.username,
                            password: $viewModel.password,
                            errorMessage: viewModel.errorMessage,
                            isLoading: viewModel.isLoading,
                            canSubmit: viewModel.canSubmit,
                            focusedField: $focusedField,
                            submitLogin: submitLogin
                        )
                        .queueAppear(delay: 0.10)

                        DemoAccountsPanel(fillCredentials: fillCredentials)
                            .queueAppear(delay: 0.18)

                        RegistrationActionPanel()
                            .queueAppear(delay: 0.24)
                    }
                    .padding(.horizontal, 22)
                    .padding(.bottom, 28)
                }
                .scrollDismissesKeyboard(.interactively)
            }
            .navigationBarHidden(true)
        }
    }

    private func fillCredentials(username: String, password: String) {
        withAnimation(QueueMotion.quick) {
            viewModel.username = username
            viewModel.password = password
            viewModel.errorMessage = nil
        }
    }

    private func submitLogin() {
        guard !viewModel.isLoading else {
            return
        }

        Task {
            await viewModel.login(session: session)
        }
    }
}

private enum LoginField {
    case username
    case password
}

private struct LoginBackground: View {
    var body: some View {
        LinearGradient(
            colors: [
                Color(red: 0.02, green: 0.06, blue: 0.16),
                Color(red: 0.04, green: 0.18, blue: 0.38),
                Color(.systemGroupedBackground)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }
}

private struct LoginBrandHeader: View {
    var body: some View {
        VStack(spacing: 16) {
            QueueEaseLogoMark()

            VStack(spacing: 7) {
                Text("QueueEase")
                    .font(.system(size: 38, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)

                Text("Smart queue management for faster service flow.")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.white.opacity(0.78))
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("QueueEase, smart queue management")
    }
}

private struct QueueEaseLogoMark: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isFloating = false

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 26)
                .fill(
                    LinearGradient(
                        colors: [Color.white.opacity(0.96), Color.white.opacity(0.78)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 92, height: 92)
                .shadow(color: .black.opacity(0.22), radius: 24, y: 16)

            RoundedRectangle(cornerRadius: 22)
                .stroke(.white.opacity(0.72), lineWidth: 1)
                .frame(width: 80, height: 80)

            ZStack(alignment: .bottomTrailing) {
                Image(systemName: "ticket.fill")
                    .font(.system(size: 42, weight: .bold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [QueueTheme.primary, QueueTheme.secondary],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 21, weight: .bold))
                    .foregroundStyle(QueueTheme.success, .white)
                    .offset(x: 10, y: 8)
            }
        }
        .scaleEffect(isFloating ? 1.02 : 1)
        .offset(y: reduceMotion ? 0 : (isFloating ? -3 : 0))
        .animation(
            reduceMotion ? QueueMotion.gentle : .easeInOut(duration: 1.8).repeatForever(autoreverses: true),
            value: isFloating
        )
        .onAppear {
            isFloating = true
        }
    }
}

private struct LoginPanel: View {
    @Binding var username: String
    @Binding var password: String
    let errorMessage: String?
    let isLoading: Bool
    let canSubmit: Bool
    var focusedField: FocusState<LoginField?>.Binding
    let submitLogin: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 5) {
                Text("Welcome Back")
                    .font(.title2.bold())

                Text("Sign in to continue to your queue dashboard.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            LoginInputRow(
                title: "Username",
                systemImage: "person.fill",
                text: $username
            )
            .textContentType(.username)
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()
            .submitLabel(.next)
            .focused(focusedField, equals: .username)
            .onSubmit {
                focusedField.wrappedValue = .password
            }

            LoginInputRow(
                title: "Password",
                systemImage: "lock.fill",
                text: $password,
                isSecure: true
            )
            .textContentType(.password)
            .submitLabel(.go)
            .focused(focusedField, equals: .password)
            .onSubmit(submitLogin)

            if let errorMessage {
                MessageBanner(message: errorMessage, style: .error)
                    .queueTransition()
            }

            LoginPrimaryButton(
                title: isLoading ? "Signing In..." : "Sign In",
                isLoading: isLoading,
                isDisabled: !canSubmit,
                action: submitLogin
            )
        }
        .padding(18)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 22))
        .overlay {
            RoundedRectangle(cornerRadius: 22)
                .stroke(.white.opacity(0.45), lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.16), radius: 28, y: 16)
        .animation(QueueMotion.smooth, value: errorMessage)
        .animation(QueueMotion.quick, value: isLoading)
    }
}

private struct LoginInputRow: View {
    let title: String
    let systemImage: String
    @Binding var text: String
    var isSecure = false

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)

            HStack(spacing: 12) {
                Image(systemName: systemImage)
                    .font(.subheadline.weight(.semibold))
                    .frame(width: 34, height: 34)
                    .foregroundStyle(QueueTheme.primary)
                    .background(QueueTheme.primary.opacity(0.12), in: RoundedRectangle(cornerRadius: 10))

                if isSecure {
                    SecureField(title, text: $text)
                } else {
                    TextField(title, text: $text)
                }
            }
            .padding(12)
            .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 14))
            .overlay {
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Color.secondary.opacity(0.10), lineWidth: 1)
            }
        }
        .accessibilityElement(children: .contain)
    }
}

private struct LoginPrimaryButton: View {
    let title: String
    let isLoading: Bool
    let isDisabled: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                if isLoading {
                    ProgressView()
                        .controlSize(.small)
                        .tint(.white)
                        .transition(.opacity.combined(with: .scale(scale: 0.92)))
                } else {
                    Image(systemName: "arrow.right.circle.fill")
                        .font(.headline)
                        .transition(.opacity.combined(with: .scale(scale: 0.92)))
                }

                Text(title)
                    .font(.headline.weight(.bold))
                    .contentTransition(.opacity)
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(
                LinearGradient(
                    colors: isDisabled ? [.gray.opacity(0.55), .gray.opacity(0.42)] : [QueueTheme.primary, QueueTheme.secondary],
                    startPoint: .leading,
                    endPoint: .trailing
                ),
                in: RoundedRectangle(cornerRadius: 16)
            )
            .shadow(color: isDisabled ? .clear : QueueTheme.primary.opacity(0.22), radius: 16, y: 8)
        }
        .disabled(isDisabled || isLoading)
        .buttonStyle(QueuePressScaleButtonStyle())
        .animation(QueueMotion.quick, value: isLoading)
        .animation(QueueMotion.quick, value: isDisabled)
        .accessibilityLabel(title)
    }
}

private struct DemoAccountsPanel: View {
    let fillCredentials: (String, String) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Demo Access")
                    .font(.headline)
                    .foregroundStyle(.white)

                Text("Tap an account to fill credentials instantly.")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.72))
            }

            VStack(spacing: 10) {
                CredentialRow(
                    role: "Admin",
                    description: "Manage demo data",
                    systemImage: "chart.bar.doc.horizontal.fill",
                    tint: QueueTheme.success,
                    username: "admin",
                    password: "admin"
                ) {
                    fillCredentials("admin", "admin")
                }
                CredentialRow(
                    role: "Service Staff",
                    description: "Call and check in tickets",
                    systemImage: "person.badge.clock.fill",
                    tint: QueueTheme.secondary,
                    username: "staff",
                    password: "staff"
                ) {
                    fillCredentials("staff", "staff")
                }
                CredentialRow(
                    role: "Budi Santoso",
                    description: "Customer queue history",
                    systemImage: "ticket.fill",
                    tint: QueueTheme.primary,
                    username: "budi",
                    password: "budi"
                ) {
                    fillCredentials("budi", "budi")
                }
                CredentialRow(
                    role: "Siti Aminah",
                    description: "Customer queue history",
                    systemImage: "ticket.fill",
                    tint: QueueTheme.warning,
                    username: "siti",
                    password: "siti"
                ) {
                    fillCredentials("siti", "siti")
                }
            }
        }
        .padding(16)
        .background(Color.white.opacity(0.10), in: RoundedRectangle(cornerRadius: 22))
        .overlay {
            RoundedRectangle(cornerRadius: 22)
                .stroke(.white.opacity(0.18), lineWidth: 1)
        }
    }
}

private struct RegistrationActionPanel: View {
    var body: some View {
        NavigationLink {
            RegisterView()
        } label: {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "person.crop.circle.badge.plus")
                    .font(.subheadline.weight(.bold))
                    .frame(width: 36, height: 36)
                    .foregroundStyle(QueueTheme.secondary)
                    .background(QueueTheme.secondary.opacity(0.14), in: RoundedRectangle(cornerRadius: 11))

                VStack(alignment: .leading, spacing: 4) {
                    Text("Create Customer Account")
                        .font(.subheadline.bold())
                        .foregroundStyle(.white)

                    Text("New customers can register for the demo and go straight to the customer dashboard.")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.72))
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 8)

                Image(systemName: "chevron.right")
                    .font(.caption.bold())
                    .foregroundStyle(.white.opacity(0.70))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(14)
            .background(Color.white.opacity(0.09), in: RoundedRectangle(cornerRadius: 18))
            .overlay {
                RoundedRectangle(cornerRadius: 18)
                    .stroke(.white.opacity(0.14), lineWidth: 1)
            }
        }
        .buttonStyle(QueuePressScaleButtonStyle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Create customer account")
    }
}

private struct CredentialRow: View {
    let role: String
    let description: String
    let systemImage: String
    let tint: Color
    let username: String
    let password: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: systemImage)
                    .font(.subheadline.weight(.bold))
                    .frame(width: 38, height: 38)
                    .foregroundStyle(tint)
                    .background(tint.opacity(0.12), in: RoundedRectangle(cornerRadius: 12))

                VStack(alignment: .leading, spacing: 4) {
                    Text(role)
                        .font(.subheadline.bold())
                        .foregroundStyle(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.86)

                    Text(description)
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.68))
                        .lineLimit(2)
                }
                .layoutPriority(1)

                Spacer(minLength: 8)

                Text("\(username) / \(password)")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(tint)
                    .monospaced()
                    .lineLimit(1)
                    .minimumScaleFactor(0.82)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 5)
                    .background(tint.opacity(0.10), in: Capsule())

                Image(systemName: "chevron.right")
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)
            }
            .padding(10)
            .background(.white.opacity(0.11), in: RoundedRectangle(cornerRadius: 16))
            .overlay {
                RoundedRectangle(cornerRadius: 16)
                    .stroke(.white.opacity(0.12), lineWidth: 1)
            }
            .contentShape(RoundedRectangle(cornerRadius: 14))
        }
        .buttonStyle(QueuePressScaleButtonStyle())
        .accessibilityLabel("\(role) demo account")
        .accessibilityValue("Username \(username), password \(password)")
        .accessibilityHint("Fills the login form with this demo account.")
    }
}

#if DEBUG
struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView()
            .environmentObject(AppSession())
            .previewDisplayName("Login")
    }
}
#endif
