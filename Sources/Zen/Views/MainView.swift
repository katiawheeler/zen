import SwiftUI

struct MainView: View {
    @State private var showSettings = false
    @State private var hasAppeared = false
    @ObservedObject var googleAuth = GoogleAuthManager.shared
    @ObservedObject var calendarManager = CalendarManager.shared
    @ObservedObject var focusManager = FocusManager.shared

    var body: some View {
        NavigationStack {
            ZStack {
                // Ink wash background
                InkWashBackground()
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    // Header
                    ZenHeader(
                        showSettings: $showSettings,
                        isConnected: googleAuth.isAuthenticated
                    )
                    .opacity(hasAppeared ? 1 : 0)
                    .offset(y: hasAppeared ? 0 : -10)

                    // Breathing orb - the centerpiece
                    BreathingCircle(isActive: focusManager.isZenModeEnabled)
                        .frame(height: 100)
                        .opacity(hasAppeared ? 1 : 0)
                        .scaleEffect(hasAppeared ? 1 : 0.8)

                    StoneDivider()
                        .padding(.vertical, 16)
                        .opacity(hasAppeared ? 1 : 0)

                    // Status section
                    VStack(spacing: 16) {
                        // Calendar events
                        if calendarManager.relevantEvents.isEmpty {
                            ZenStatusRow(
                                icon: "calendar",
                                label: "Next Meeting",
                                value: "No upcoming meetings",
                                accentColor: .zenSand
                            )
                        } else {
                            ForEach(Array(calendarManager.relevantEvents.enumerated()), id: \.element.id) { index, event in
                                ZenEventRow(
                                    icon: index == 0 ? "calendar" : "calendar.badge.clock",
                                    label: index == 0 ? "Next Meeting" : "Then",
                                    time: calendarManager.formatEventTime(event),
                                    eventName: event.summary,
                                    accentColor: index == 0 ? .zenAmber : .zenSand,
                                    isFirst: index == 0
                                )
                            }
                        }

                        // Focus mode status
                        ZenStatusRow(
                            icon: focusManager.isZenModeEnabled ? "moon.fill" : "moon",
                            label: "Focus Mode",
                            value: focusManager.isZenModeEnabled ? "Active — Distractions blocked" : "Inactive",
                            accentColor: focusManager.isZenModeEnabled ? .zenMoss : .zenSand
                        )
                    }
                    .padding(.horizontal, 20)
                    .opacity(hasAppeared ? 1 : 0)
                    .offset(y: hasAppeared ? 0 : 10)

                    Spacer()

                    // Action area
                    VStack(spacing: 12) {
                        StoneDivider()

                        HStack(spacing: 12) {
                            // Main zen toggle
                            Button(action: toggleFocus) {
                                HStack(spacing: 8) {
                                    Image(systemName: focusManager.isZenModeEnabled ? "leaf.fill" : "leaf")
                                        .font(.system(size: 14, weight: .medium))
                                    Text(focusManager.isZenModeEnabled ? "End Session" : "Begin Zen")
                                }
                                .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(ZenButtonStyle(isActive: focusManager.isZenModeEnabled))

                            // Quit button
                            Button(action: { NSApplication.shared.terminate(nil) }) {
                                Image(systemName: "power")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(Color.zenCoral.opacity(0.8))
                                    .frame(width: 40, height: 40)
                                    .background(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(Color.zenCoral.opacity(0.3), lineWidth: 1)
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 16)
                    }
                    .opacity(hasAppeared ? 1 : 0)
                    .offset(y: hasAppeared ? 0 : 20)
                }
            }
            .frame(width: 320)
            .pointerCursor()
            .navigationDestination(isPresented: $showSettings) {
                SettingsView()
            }
        }
        .onAppear {
            googleAuth.restoreSession()
            if googleAuth.isAuthenticated {
                calendarManager.fetchEvents()
            }

            // Staggered entrance animation
            withAnimation(.spring(response: 0.7, dampingFraction: 0.8).delay(0.1)) {
                hasAppeared = true
            }
        }
        .onChange(of: googleAuth.isAuthenticated) { authenticated in
            if authenticated {
                calendarManager.fetchEvents()
            }
        }
    }

    func toggleFocus() {
        withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
            focusManager.setZenMode(enabled: !focusManager.isZenModeEnabled)
        }
    }
}

// MARK: - Zen Header
struct ZenHeader: View {
    @Binding var showSettings: Bool
    var isConnected: Bool

    var body: some View {
        HStack(alignment: .center) {
            // Logo with subtle styling
            Text("禅")
                .font(.system(size: 20, weight: .light))
                .foregroundColor(Color.zenPaper.opacity(0.9))

            Text("ZEN")
                .font(.zenMono(11))
                .foregroundColor(Color.zenSand.opacity(0.6))
                .tracking(3)

            Spacer()

            // Connection status
            HStack(spacing: 6) {
                PebbleIndicator(isConnected: isConnected)

                Text(isConnected ? "Synced" : "Offline")
                    .font(.zenMono(9))
                    .foregroundColor(Color.zenSand.opacity(0.5))
            }

            // Settings button
            Button(action: { showSettings = true }) {
                Image(systemName: "slider.horizontal.3")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(Color.zenSand.opacity(0.6))
                    .frame(width: 28, height: 28)
                    .background(
                        Circle()
                            .fill(Color.zenStone.opacity(0.2))
                    )
            }
            .buttonStyle(.plain)
            .padding(.leading, 8)
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
        .padding(.bottom, 8)
    }
}

// MARK: - Visual Effect (keeping for compatibility)
struct VisualEffectView: NSViewRepresentable {
    let material: NSVisualEffectView.Material
    let blendingMode: NSVisualEffectView.BlendingMode

    func makeNSView(context: Context) -> NSVisualEffectView {
        let visualEffectView = NSVisualEffectView()
        visualEffectView.material = material
        visualEffectView.blendingMode = blendingMode
        visualEffectView.state = .active
        return visualEffectView
    }

    func updateNSView(_ visualEffectView: NSVisualEffectView, context: Context) {
        visualEffectView.material = material
        visualEffectView.blendingMode = blendingMode
    }
}

#Preview {
    MainView()
}
