import SwiftUI

struct RegisterView: View {
    @EnvironmentObject private var session: AppSession
    @StateObject private var viewModel = RegisterViewModel()
    @FocusState private var focusedField: RegisterField?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                QueueHeroCard(
                    title: "Create Account",
                    subtitle: "Register as a customer, take queue numbers, and keep your ticket history in one place.",
                    systemImage: "person.crop.circle.badge.plus",
                    footnote: "Customer Registration"
                )
                .queueAppear(delay: 0.02)

                QueueCard {
                    SectionHeaderText("Customer Details", subtitle: "This account will use the customer role automatically.")

                    RegisterInputRow(
                        title: "Full Name",
                        systemImage: "person.text.rectangle.fill",
                        text: $viewModel.name
                    )
                    .textContentType(.name)
                    .submitLabel(.next)
                    .focused($focusedField, equals: .name)
                    .onSubmit { focusedField = .username }

                    RegisterInputRow(
                        title: "Username",
                        systemImage: "person.fill",
                        text: $viewModel.username
                    )
                    .textContentType(.username)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .submitLabel(.next)
                    .focused($focusedField, equals: .username)
                    .onSubmit { focusedField = .email }

                    RegisterInputRow(
                        title: "Email Optional",
                        systemImage: "envelope.fill",
                        text: $viewModel.email
                    )
                    .textContentType(.emailAddress)
                    .keyboardType(.emailAddress)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .submitLabel(.next)
                    .focused($focusedField, equals: .email)
                    .onSubmit { focusedField = .password }

                    RegisterInputRow(
                        title: "Password",
                        systemImage: "lock.fill",
                        text: $viewModel.password,
                        isSecure: true
                    )
                    .textContentType(.newPassword)
                    .submitLabel(.next)
                    .focused($focusedField, equals: .password)
                    .onSubmit { focusedField = .confirmPassword }

                    RegisterInputRow(
                        title: "Confirm Password",
                        systemImage: "checkmark.shield.fill",
                        text: $viewModel.confirmPassword,
                        isSecure: true
                    )
                    .textContentType(.newPassword)
                    .submitLabel(.go)
                    .focused($focusedField, equals: .confirmPassword)
                    .onSubmit(register)

                    if let errorMessage = viewModel.errorMessage {
                        MessageBanner(message: errorMessage, style: .error)
                            .queueTransition()
                    }

                    if let successMessage = viewModel.successMessage {
                        MessageBanner(message: successMessage, style: .success)
                            .queueTransition()
                    }

                    QueueActionButton(
                        viewModel.isLoading ? "Creating Account..." : "Create Customer Account",
                        systemImage: "person.badge.plus",
                        isLoading: viewModel.isLoading,
                        isDisabled: !viewModel.canSubmit,
                        action: register
                    )
                }
                .queueAppear(delay: 0.10)
            }
            .padding()
        }
        .background(QueueTheme.screenBackground)
        .navigationTitle("Register")
        .navigationBarTitleDisplayMode(.inline)
        .scrollDismissesKeyboard(.interactively)
        .animation(QueueMotion.smooth, value: viewModel.errorMessage)
        .animation(QueueMotion.smooth, value: viewModel.successMessage)
    }

    private func register() {
        guard !viewModel.isLoading else {
            return
        }

        Task {
            await viewModel.register(session: session)
        }
    }
}

private enum RegisterField {
    case name
    case username
    case email
    case password
    case confirmPassword
}

private struct RegisterInputRow: View {
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
            .background(Color(.tertiarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 14))
            .overlay {
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Color.secondary.opacity(0.10), lineWidth: 1)
            }
        }
        .accessibilityElement(children: .contain)
    }
}

#if DEBUG
struct RegisterView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            RegisterView()
                .environmentObject(AppSession())
        }
        .previewDisplayName("Register")
    }
}
#endif

