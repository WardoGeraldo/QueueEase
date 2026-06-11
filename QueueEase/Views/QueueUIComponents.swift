//
//  QueueNumberView.swift
//  QueueEase
//
//  Created by Edward Geraldo Kristian on 29/05/26.
//

import SwiftUI

enum QueueTheme {
    static let primary = Color(red: 0.05, green: 0.35, blue: 0.95)
    static let secondary = Color(red: 0.00, green: 0.62, blue: 0.72)
    static let success = Color(red: 0.08, green: 0.58, blue: 0.28)
    static let warning = Color(red: 0.95, green: 0.56, blue: 0.10)
    static let screenBackground = Color(.systemGroupedBackground)
}

enum QueueMotion {
    static let quick = Animation.spring(response: 0.26, dampingFraction: 0.82)
    static let smooth = Animation.spring(response: 0.42, dampingFraction: 0.86)
    static let gentle = Animation.easeOut(duration: 0.24)
}

struct QueueAppearModifier: ViewModifier {
    let delay: Double
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isVisible = false

    func body(content: Content) -> some View {
        content
            .opacity(isVisible ? 1 : 0)
            .offset(y: reduceMotion ? 0 : (isVisible ? 0 : 14))
            .scaleEffect(reduceMotion ? 1 : (isVisible ? 1 : 0.985))
            .onAppear {
                guard !isVisible else {
                    return
                }

                withAnimation((reduceMotion ? QueueMotion.gentle : QueueMotion.smooth).delay(delay)) {
                    isVisible = true
                }
            }
    }
}

struct QueuePressScaleButtonStyle: ButtonStyle {
    var pressedScale: CGFloat = 0.97
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(reduceMotion ? 1 : (configuration.isPressed ? pressedScale : 1))
            .opacity(configuration.isPressed ? 0.92 : 1)
            .animation(QueueMotion.quick, value: configuration.isPressed)
    }
}

extension View {
    func queueAppear(delay: Double = 0) -> some View {
        modifier(QueueAppearModifier(delay: delay))
    }

    func queueTransition() -> some View {
        transition(.opacity.combined(with: .move(edge: .top)).combined(with: .scale(scale: 0.98)))
    }
}

struct QueueCard<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            content
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 14))
        .overlay {
            RoundedRectangle(cornerRadius: 14)
                .stroke(.white.opacity(0.35), lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.04), radius: 10, y: 4)
    }
}

struct QueueActionButton: View {
    enum Style {
        case primary
        case secondary
    }

    let title: String
    let systemImage: String
    let isLoading: Bool
    let isDisabled: Bool
    let style: Style
    let action: () -> Void

    init(
        _ title: String,
        systemImage: String,
        isLoading: Bool = false,
        isDisabled: Bool = false,
        style: Style = .primary,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.systemImage = systemImage
        self.isLoading = isLoading
        self.isDisabled = isDisabled
        self.style = style
        self.action = action
    }

    var body: some View {
        switch style {
        case .primary:
            button
                .buttonStyle(.borderedProminent)
        case .secondary:
            button
                .buttonStyle(.bordered)
        }
    }

    private var button: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if isLoading {
                    ProgressView()
                        .controlSize(.small)
                        .tint(style == .primary ? .white : QueueTheme.primary)
                        .transition(.opacity.combined(with: .scale(scale: 0.92)))
                } else {
                    Image(systemName: systemImage)
                        .font(.subheadline.weight(.semibold))
                        .transition(.opacity.combined(with: .scale(scale: 0.92)))
                }

                Text(title)
                    .fontWeight(.semibold)
                    .lineLimit(1)
                    .minimumScaleFactor(0.82)
                    .contentTransition(.opacity)
            }
            .frame(maxWidth: .infinity)
        }
        .controlSize(.large)
        .disabled(isDisabled || isLoading)
        .scaleEffect(isLoading ? 0.99 : 1)
        .animation(QueueMotion.quick, value: isLoading)
        .animation(QueueMotion.quick, value: isDisabled)
        .accessibilityLabel(title)
        .accessibilityHint(isLoading ? "Please wait for this action to finish." : "Double tap to perform this action.")
    }
}

struct ConfirmedLogoutButton: View {
    let action: () -> Void
    @State private var isConfirmingLogout = false

    var body: some View {
        Button {
            isConfirmingLogout = true
        } label: {
            Image(systemName: "rectangle.portrait.and.arrow.right")
                .font(.body.weight(.semibold))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Log out")
        .accessibilityHint("Shows a confirmation before returning to the login screen.")
        .confirmationDialog(
            "Log out of QueueEase?",
            isPresented: $isConfirmingLogout,
            titleVisibility: .visible
        ) {
            Button("Log Out", role: .destructive, action: action)
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("You will return to the login screen.")
        }
    }
}

struct QueueHeroCard: View {
    let title: String
    let subtitle: String
    let systemImage: String
    let footnote: String?

    init(title: String, subtitle: String, systemImage: String, footnote: String? = nil) {
        self.title = title
        self.subtitle = subtitle
        self.systemImage = systemImage
        self.footnote = footnote
    }

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: systemImage)
                .font(.system(size: 28, weight: .semibold))
                .frame(width: 54, height: 54)
                .foregroundStyle(.white)
                .background(.white.opacity(0.18), in: RoundedRectangle(cornerRadius: 14))

            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(.title2.bold())
                    .foregroundStyle(.white)
                    .lineLimit(2)
                    .minimumScaleFactor(0.86)

                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.85))
                    .fixedSize(horizontal: false, vertical: true)

                if let footnote {
                    Text(footnote)
                        .font(.caption.bold())
                        .foregroundStyle(.white.opacity(0.85))
                        .padding(.horizontal, 9)
                        .padding(.vertical, 5)
                        .background(.white.opacity(0.16), in: Capsule())
                }
            }
            .layoutPriority(1)

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(
            LinearGradient(
                colors: [QueueTheme.primary, QueueTheme.secondary],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: 18)
        )
        .shadow(color: QueueTheme.primary.opacity(0.18), radius: 18, y: 8)
    }
}

struct SectionHeaderText: View {
    let title: String
    let subtitle: String?

    init(_ title: String, subtitle: String? = nil) {
        self.title = title
        self.subtitle = subtitle
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.headline)

            if let subtitle {
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

struct StatusBadge: View {
    let status: String

    var body: some View {
            Text(statusLabel)
                .font(.caption.bold())
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .foregroundStyle(foregroundColor)
                .background(backgroundColor, in: Capsule())
                .fixedSize(horizontal: true, vertical: false)
                .contentTransition(.opacity)
                .animation(QueueMotion.quick, value: status)
    }

    private var statusLabel: String {
        switch status {
        case "waiting":
            return "Waiting"
        case "called":
            return "Called"
        case "checked_in":
            return "Checked In"
        case "completed":
            return "Checked In"
        case "skipped":
            return "Skipped"
        case "cancelled":
            return "Cancelled"
        default:
            return status.replacingOccurrences(of: "_", with: " ").capitalized
        }
    }

    private var backgroundColor: Color {
        switch status {
        case "waiting":
            return QueueTheme.warning.opacity(0.18)
        case "called":
            return QueueTheme.primary.opacity(0.14)
        case "checked_in":
            return QueueTheme.success.opacity(0.16)
        case "completed":
            return QueueTheme.success.opacity(0.16)
        case "skipped":
            return .orange.opacity(0.16)
        case "cancelled":
            return .red.opacity(0.12)
        default:
            return .secondary.opacity(0.14)
        }
    }

    private var foregroundColor: Color {
        switch status {
        case "waiting":
            return QueueTheme.warning
        case "called":
            return QueueTheme.primary
        case "checked_in":
            return QueueTheme.success
        case "completed":
            return QueueTheme.success
        case "skipped":
            return .orange
        case "cancelled":
            return .red
        default:
            return .secondary
        }
    }
}

struct MessageBanner: View {
    enum Style {
        case success
        case error
        case warning
        case info
    }

    let message: String
    let style: Style

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: iconName)
                .font(.subheadline.bold())

            Text(message)
                .font(.subheadline)
                .fixedSize(horizontal: false, vertical: true)
        }
        .foregroundStyle(foregroundColor)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(backgroundColor, in: RoundedRectangle(cornerRadius: 10))
        .contentTransition(.opacity)
        .animation(QueueMotion.quick, value: message)
        .animation(QueueMotion.quick, value: style)
    }

    private var iconName: String {
        switch style {
        case .success:
            return "checkmark.circle.fill"
        case .error:
            return "exclamationmark.triangle.fill"
        case .warning:
            return "exclamationmark.circle.fill"
        case .info:
            return "info.circle.fill"
        }
    }

    private var foregroundColor: Color {
        switch style {
        case .success:
            return QueueTheme.success
        case .error:
            return .red
        case .warning:
            return QueueTheme.warning
        case .info:
            return QueueTheme.primary
        }
    }

    private var backgroundColor: Color {
        foregroundColor.opacity(0.12)
    }
}

struct DetailRow: View {
    let title: String
    let value: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text(title)
                .foregroundStyle(.secondary)

            Spacer(minLength: 16)

            Text(value)
                .fontWeight(.medium)
                .multilineTextAlignment(.trailing)
        }
        .font(.subheadline)
    }
}

struct QueueNumberDisplay: View {
    let queueNumber: String
    let status: String
    let caption: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(caption)
                .font(.caption.bold())
                .foregroundStyle(.secondary)
                .textCase(.uppercase)

            HStack(alignment: .firstTextBaseline) {
                Text(queueNumber)
                    .font(.system(size: 58, weight: .bold, design: .rounded))
                    .lineLimit(1)
                    .minimumScaleFactor(0.65)
                    .contentTransition(.numericText())
                    .animation(QueueMotion.smooth, value: queueNumber)

                Spacer(minLength: 12)

                StatusBadge(status: status)
            }
        }
    }
}

struct QueueStatusTimeline: View {
    let status: String
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let steps = [
        QueueStatusStep(key: "waiting", title: "Waiting", icon: "clock.fill"),
        QueueStatusStep(key: "called", title: "Called", icon: "speaker.wave.2.fill"),
        QueueStatusStep(key: "checked_in", title: "Checked In", icon: "checkmark.circle.fill"),
        QueueStatusStep(key: "skipped", title: "Skipped", icon: "forward.fill"),
        QueueStatusStep(key: "cancelled", title: "Cancelled", icon: "xmark.circle.fill")
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Progress")
                .font(.caption.bold())
                .foregroundStyle(.secondary)
                .textCase(.uppercase)

            HStack(alignment: .top, spacing: 0) {
                ForEach(Array(visibleSteps.enumerated()), id: \.element.key) { index, step in
                    VStack(spacing: 8) {
                        ZStack {
                            Circle()
                                .fill(circleFill(for: step))
                                .frame(width: 34, height: 34)
                                .scaleEffect(reduceMotion ? 1 : (step.key == activeStatusKey ? 1.08 : 1))

                            Image(systemName: step.icon)
                                .font(.caption.weight(.bold))
                                .foregroundStyle(iconColor(for: step))
                                .scaleEffect(reduceMotion ? 1 : (step.key == activeStatusKey ? 1.06 : 1))
                        }
                        .animation(QueueMotion.quick, value: activeStatusKey)

                        Text(step.title)
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(isReached(step) ? .primary : .secondary)
                            .multilineTextAlignment(.center)
                            .lineLimit(2)
                            .minimumScaleFactor(0.8)
                            .frame(maxWidth: .infinity)
                    }
                    .frame(maxWidth: .infinity)

                    if index < visibleSteps.count - 1 {
                        Rectangle()
                            .fill(isReached(visibleSteps[index + 1]) ? statusAccentColor.opacity(0.45) : Color.secondary.opacity(0.18))
                            .frame(height: 3)
                            .padding(.top, 16)
                            .frame(maxWidth: 24)
                            .animation(QueueMotion.smooth, value: activeStatusKey)
                    }
                }
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Queue progress is \(statusLabel)")
        .animation(QueueMotion.smooth, value: status)
    }

    private var currentIndex: Int {
        visibleSteps.firstIndex { $0.key == activeStatusKey } ?? 0
    }

    private var visibleSteps: [QueueStatusStep] {
        if activeStatusKey == "skipped" || activeStatusKey == "cancelled" {
            return [
                QueueStatusStep(key: "waiting", title: "Waiting", icon: "clock.fill"),
                QueueStatusStep(key: activeStatusKey, title: statusLabel, icon: activeStatusKey == "skipped" ? "forward.fill" : "xmark.circle.fill")
            ]
        }

        return steps.filter { $0.key != "skipped" && $0.key != "cancelled" }
    }

    private var statusLabel: String {
        steps.first { $0.key == status }?.title ?? status.replacingOccurrences(of: "_", with: " ").capitalized
    }

    private var activeStatusKey: String {
        status == "completed" ? "checked_in" : status
    }

    private func isReached(_ step: QueueStatusStep) -> Bool {
        guard let stepIndex = visibleSteps.firstIndex(where: { $0.key == step.key }) else {
            return false
        }

        return stepIndex <= currentIndex
    }

    private func circleFill(for step: QueueStatusStep) -> Color {
        if step.key == activeStatusKey {
            return statusAccentColor
        }

        return isReached(step) ? statusAccentColor.opacity(0.16) : Color.secondary.opacity(0.12)
    }

    private func iconColor(for step: QueueStatusStep) -> Color {
        if step.key == activeStatusKey {
            return .white
        }

        return isReached(step) ? statusAccentColor : .secondary
    }

    private var statusAccentColor: Color {
        switch status {
        case "waiting":
            return QueueTheme.warning
        case "called":
            return QueueTheme.primary
        case "checked_in":
            return QueueTheme.success
        case "skipped":
            return .orange
        case "cancelled":
            return .red
        default:
            return QueueTheme.primary
        }
    }
}

private struct QueueStatusStep {
    let key: String
    let title: String
    let icon: String
}

struct SummaryChip: View {
    let title: String
    let value: Int
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("\(value)")
                .font(.title3.bold())
                .contentTransition(.numericText())
                .animation(QueueMotion.smooth, value: value)
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(color.opacity(0.12), in: RoundedRectangle(cornerRadius: 12))
    }
}

struct CategorySelectionCard: View {
    let category: QueueCategory
    let isSelected: Bool
    let detail: String?

    init(category: QueueCategory, isSelected: Bool, detail: String? = nil) {
        self.category = category
        self.isSelected = isSelected
        self.detail = detail
    }

    var body: some View {
        HStack(spacing: 12) {
            Text(category.prefix)
                .font(.headline.bold())
                .frame(width: 50, height: 50)
                .foregroundStyle(isSelected ? .white : QueueTheme.primary)
                .background(
                    isSelected ? QueueTheme.primary : QueueTheme.primary.opacity(0.12),
                    in: RoundedRectangle(cornerRadius: 14)
                )
                .scaleEffect(isSelected ? 1.03 : 1)

            VStack(alignment: .leading, spacing: 4) {
                Text(category.categoryName)
                    .font(.subheadline.bold())
                    .foregroundStyle(.primary)

                Text(detail ?? "Current number: \(category.currentNumber ?? 0)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 8)

            Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                .font(.title3)
                .foregroundStyle(isSelected ? QueueTheme.primary : .secondary.opacity(0.55))
                .contentTransition(.symbolEffect(.replace))
        }
        .padding(12)
        .background(
            isSelected ? QueueTheme.primary.opacity(0.08) : Color(.tertiarySystemGroupedBackground),
            in: RoundedRectangle(cornerRadius: 14)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 14)
                .stroke(isSelected ? QueueTheme.primary.opacity(0.65) : .clear, lineWidth: 1.5)
        }
        .scaleEffect(isSelected ? 1 : 0.995)
        .animation(QueueMotion.quick, value: isSelected)
        .contentShape(RoundedRectangle(cornerRadius: 14))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(category.categoryName), prefix \(category.prefix)")
        .accessibilityValue("\(detail ?? "Current number \(category.currentNumber ?? 0)")\(isSelected ? ", selected" : "")")
    }
}

struct TicketListRow: View {
    let ticket: QueueTicket
    let showsCustomerName: Bool

    init(ticket: QueueTicket, showsCustomerName: Bool = true) {
        self.ticket = ticket
        self.showsCustomerName = showsCustomerName
    }

    var body: some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 3)
                .fill(statusColor)
                .frame(width: 5)

            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .firstTextBaseline) {
                    Text(ticket.queueNumber)
                        .font(.title3.bold())
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                        .contentTransition(.numericText())
                        .layoutPriority(1)

                    Spacer()

                    StatusBadge(status: ticket.status)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Label(ticket.categoryName ?? "No category", systemImage: "square.grid.2x2")
                    Label(ticket.counterName ?? "No counter assigned", systemImage: "desktopcomputer")
                    if showsCustomerName {
                    Label(ticket.customerName ?? "No customer name", systemImage: "person")
                    }
                    Label(timestampText, systemImage: "clock")
                }
                .font(.footnote)
                .foregroundStyle(.secondary)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.vertical, 5)
        .contentTransition(.opacity)
        .animation(QueueMotion.smooth, value: ticket.status)
    }

    private var statusColor: Color {
        switch ticket.status {
        case "waiting":
            return QueueTheme.warning
        case "called":
            return QueueTheme.primary
        case "checked_in":
            return QueueTheme.success
        case "skipped":
            return .orange
        case "cancelled":
            return .red
        default:
            return .secondary
        }
    }

    private var timestampText: String {
        if ticket.updatedAt != nil {
            return "Updated \(ticket.updatedAtDisplay)"
        }

        return "Created \(ticket.createdAtDisplay)"
    }
}

struct EmptyQueueState: View {
    let title: String
    let message: String
    let systemImage: String

    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: systemImage)
                .font(.system(size: 30, weight: .semibold))
                .foregroundStyle(.secondary)

            Text(title)
                .font(.headline)

            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 18)
    }
}

#if DEBUG
struct QueueUIComponents_Previews: PreviewProvider {
    static var previews: some View {
        ScrollView {
            VStack(spacing: 16) {
                QueueHeroCard(
                    title: "QueueEase",
                    subtitle: "Preview the shared cards, status labels, and queue number treatment.",
                    systemImage: "ticket.fill",
                    footnote: "Design System"
                )

                QueueCard {
                    QueueNumberDisplay(
                        queueNumber: PreviewData.calledTicket.queueNumber,
                        status: PreviewData.calledTicket.status,
                        caption: "Now serving"
                    )
                    QueueStatusTimeline(status: PreviewData.calledTicket.status)
                }

                CategorySelectionCard(
                    category: PreviewData.categories[0],
                    isSelected: true,
                    detail: "2 waiting"
                )

                TicketListRow(ticket: PreviewData.checkedInTicket)
                MessageBanner(message: "Customer checked in successfully.", style: .success)
                MessageBanner(message: "No waiting tickets in this category.", style: .warning)
            }
            .padding()
        }
        .background(QueueTheme.screenBackground)
        .previewDisplayName("Queue Components")
    }
}
#endif
