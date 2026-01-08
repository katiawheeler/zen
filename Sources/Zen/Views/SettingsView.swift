import SwiftUI

struct SettingsView: View {
    @ObservedObject var googleAuth = GoogleAuthManager.shared
    @ObservedObject var calendarManager = CalendarManager.shared
    @ObservedObject var automationManager = AutomationManager.shared
    @Environment(\.dismiss) private var dismiss

    @State private var hasAppeared = false

    var body: some View {
        ZStack {
            InkWashBackground()
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                ZenSettingsHeader(onBack: { dismiss() })
                    .opacity(hasAppeared ? 1 : 0)
                    .offset(y: hasAppeared ? 0 : -10)

                StoneDivider()
                    .padding(.vertical, 12)

                ScrollView {
                    VStack(spacing: 24) {
                        // Google Calendar Section
                        ZenSettingsSection(title: "Calendar") {
                            if googleAuth.isAuthenticated {
                                VStack(spacing: 12) {
                                    ZenConnectionCard(
                                        icon: "calendar",
                                        title: "Google Calendar",
                                        subtitle: googleAuth.userEmail ?? "Connected",
                                        isConnected: true,
                                        action: { googleAuth.signOut() },
                                        actionLabel: "Disconnect"
                                    )

                                    // Calendar Selection
                                    if !calendarManager.availableCalendars.isEmpty {
                                        VStack(alignment: .leading, spacing: 8) {
                                            Text("INCLUDED CALENDARS")
                                                .font(.zenMono(9))
                                                .foregroundColor(Color.zenSand.opacity(0.5))
                                                .tracking(1.5)

                                            ForEach(calendarManager.availableCalendars) { calendar in
                                                ZenToggleRow(
                                                    title: calendar.summary,
                                                    isOn: Binding(
                                                        get: { calendar.isSelected },
                                                        set: { _ in calendarManager.toggleCalendar(calendar) }
                                                    )
                                                )
                                            }
                                        }
                                        .padding(.top, 8)
                                    }
                                }
                            } else {
                                ZenConnectionCard(
                                    icon: "calendar",
                                    title: "Google Calendar",
                                    subtitle: "Sync your events",
                                    isConnected: false,
                                    action: { googleAuth.startOAuthFlow() },
                                    actionLabel: "Connect"
                                )
                            }
                        }
                        .opacity(hasAppeared ? 1 : 0)
                        .offset(y: hasAppeared ? 0 : 10)

                        // Automation Section
                        ZenSettingsSection(title: "Automation") {
                            ZenToggleRow(
                                title: "Enable DND during meetings",
                                isOn: $automationManager.isAutomationEnabled
                            )
                        }
                        .opacity(hasAppeared ? 1 : 0)
                        .offset(y: hasAppeared ? 0 : 15)

                        // Shortcuts Section
                        ZenSettingsSection(title: "Connections") {
                            VStack(alignment: .leading, spacing: 12) {
                                // Warning banner
                                HStack(spacing: 8) {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .font(.system(size: 12))
                                        .foregroundColor(Color.zenAmber)

                                    Text("Manual setup required")
                                        .font(.zenAccent(11))
                                        .foregroundColor(Color.zenAmber)
                                }

                                Text("Apple security prevents automatic shortcut creation. Please create these shortcuts manually:")
                                    .font(.zenBody(11))
                                    .foregroundColor(Color.zenSand.opacity(0.6))
                                    .fixedSize(horizontal: false, vertical: true)

                                VStack(spacing: 6) {
                                    ZenShortcutItem(name: "Zen Mode On")
                                    ZenShortcutItem(name: "Zen Mode Off")
                                }
                                .padding(.vertical, 8)

                                HStack(spacing: 8) {
                                    Button(action: openShortcutsApp) {
                                        HStack(spacing: 6) {
                                            Image(systemName: "arrow.up.forward.app")
                                                .font(.system(size: 11))
                                            Text("Shortcuts App")
                                                .font(.zenAccent(11))
                                        }
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 10)
                                        .background(
                                            RoundedRectangle(cornerRadius: 8)
                                                .stroke(Color.zenStone, lineWidth: 1)
                                        )
                                        .foregroundColor(Color.zenPaper)
                                    }
                                    .buttonStyle(.plain)

                                    Button(action: { FocusManager.shared.syncShortcuts() }) {
                                        HStack(spacing: 6) {
                                            Image(systemName: "arrow.clockwise")
                                                .font(.system(size: 11))
                                            Text("Refresh")
                                                .font(.zenAccent(11))
                                        }
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 10)
                                        .background(
                                            RoundedRectangle(cornerRadius: 8)
                                                .fill(Color.zenStone.opacity(0.3))
                                        )
                                        .foregroundColor(Color.zenPaper)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                        .opacity(hasAppeared ? 1 : 0)
                        .offset(y: hasAppeared ? 0 : 25)
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                }
            }
        }
        .frame(width: 360, height: 480)
        .pointerCursor()
        .navigationBarBackButtonHidden(true)
        .onAppear {
            googleAuth.restoreSession()
            if googleAuth.isAuthenticated {
                calendarManager.fetchCalendarList()
            }

            withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.1)) {
                hasAppeared = true
            }
        }
        .onChange(of: googleAuth.isAuthenticated) { authenticated in
            if authenticated {
                calendarManager.fetchCalendarList()
            }
        }
    }

    func openShortcutsApp() {
        NSWorkspace.shared.open(URL(string: "shortcuts://")!)
    }
}

// MARK: - Settings Header
struct ZenSettingsHeader: View {
    let onBack: () -> Void

    var body: some View {
        HStack {
            Button(action: onBack) {
                HStack(spacing: 4) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 11, weight: .semibold))
                    Text("Back")
                        .font(.zenAccent(12))
                }
                .foregroundColor(Color.zenMoss)
            }
            .buttonStyle(.plain)

            Spacer()

            Text("SETTINGS")
                .font(.zenMono(10))
                .foregroundColor(Color.zenSand.opacity(0.5))
                .tracking(2)

            Spacer()

            // Invisible spacer for balance
            Text("Back")
                .font(.zenAccent(12))
                .opacity(0)
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
    }
}

// MARK: - Settings Section
struct ZenSettingsSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ZenSectionHeader(title: title)
            content
        }
    }
}

// MARK: - Connection Card
struct ZenConnectionCard: View {
    let icon: String
    let title: String
    let subtitle: String
    let isConnected: Bool
    let action: () -> Void
    let actionLabel: String

    var body: some View {
        HStack(spacing: 12) {
            // Icon with status indicator
            ZStack(alignment: .bottomTrailing) {
                ZStack {
                    Circle()
                        .fill(isConnected ? Color.zenMoss.opacity(0.15) : Color.zenStone.opacity(0.2))
                        .frame(width: 40, height: 40)

                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(isConnected ? Color.zenMoss : Color.zenSand)
                }

                if isConnected {
                    Circle()
                        .fill(Color.zenMoss)
                        .frame(width: 10, height: 10)
                        .overlay(
                            Image(systemName: "checkmark")
                                .font(.system(size: 6, weight: .bold))
                                .foregroundColor(Color.zenInk)
                        )
                        .offset(x: 2, y: 2)
                }
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.zenAccent(13))
                    .foregroundColor(Color.zenPaper)

                Text(subtitle)
                    .font(.zenMono(10))
                    .foregroundColor(Color.zenSand.opacity(0.6))
            }

            Spacer()

            Button(action: action) {
                Text(actionLabel)
                    .font(.zenAccent(11))
                    .foregroundColor(isConnected ? Color.zenCoral : Color.zenMoss)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(isConnected ? Color.zenCoral.opacity(0.1) : Color.zenMoss.opacity(0.15))
                    )
            }
            .buttonStyle(.plain)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.zenCharcoal.opacity(0.5))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isConnected ? Color.zenMoss.opacity(0.2) : Color.zenStone.opacity(0.15), lineWidth: 1)
                )
        )
    }
}

// MARK: - Toggle Row
struct ZenToggleRow: View {
    let title: String
    @Binding var isOn: Bool

    var body: some View {
        HStack {
            // Custom checkbox
            Button(action: { isOn.toggle() }) {
                HStack(spacing: 10) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 4)
                            .stroke(isOn ? Color.zenMoss : Color.zenStone, lineWidth: 1.5)
                            .frame(width: 18, height: 18)

                        if isOn {
                            RoundedRectangle(cornerRadius: 3)
                                .fill(Color.zenMoss)
                                .frame(width: 12, height: 12)
                        }
                    }

                    Text(title)
                        .font(.zenBody(12))
                        .foregroundColor(Color.zenPaper.opacity(0.9))
                }
            }
            .buttonStyle(.plain)

            Spacer()
        }
    }
}

// MARK: - Shortcut Item
struct ZenShortcutItem: View {
    let name: String
    @State private var exists: Bool = false
    let timer = Timer.publish(every: 2, on: .main, in: .common).autoconnect()

    var body: some View {
        HStack {
            // Status icon
            ZStack {
                Circle()
                    .fill(exists ? Color.zenMoss.opacity(0.15) : Color.zenAmber.opacity(0.15))
                    .frame(width: 24, height: 24)

                Image(systemName: exists ? "checkmark" : "exclamationmark")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(exists ? Color.zenMoss : Color.zenAmber)
            }

            Text(name)
                .font(.zenMono(11))
                .foregroundColor(Color.zenPaper.opacity(0.8))

            Spacer()

            if !exists {
                Button(action: createShortcut) {
                    Text("Create")
                        .font(.zenAccent(10))
                        .foregroundColor(Color.zenAmber)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.zenAmber.opacity(0.15))
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 10)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.zenStone.opacity(0.1))
        )
        .onAppear { check() }
        .onReceive(timer) { _ in check() }
    }

    private func check() {
        exists = FocusManager.shared.shortcutExists(name: name)
    }

    private func createShortcut() {
        if let url = URL(string: "shortcuts://create-shortcut?name=\(name.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")") {
            NSWorkspace.shared.open(url)
        }
    }
}

// MARK: - Secondary Button Style
struct ZenSecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.zenAccent(12))
            .foregroundColor(Color.zenSand)
            .padding(.vertical, 10)
            .padding(.horizontal, 20)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.zenStone, lineWidth: 1)
            )
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

#Preview {
    SettingsView()
}
