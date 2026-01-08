import SwiftUI
import AppKit

// MARK: - Slack Token Input Sheet

struct SlackTokenInputSheet: View {
    let onDismiss: () -> Void

    @ObservedObject var slackManager = SlackManager.shared
    @State private var tokenInput = ""
    @State private var cookieInput = ""
    @State private var isValidating = false
    @State private var error: String?
    @State private var expandedStep: Int? = nil
    @State private var hasAppeared = false

    var body: some View {
        ZStack {
            Color.zenInk
            InkWashBackground()

            VStack(spacing: 0) {
                // Header
                headerView
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 12)

                StoneDivider()

                // Scrollable Content
                ScrollView(.vertical, showsIndicators: true) {
                    VStack(alignment: .leading, spacing: 0) {
                        Text("Extract your auth tokens from Chrome's Network tab.")
                            .font(.zenBody(11))
                            .foregroundColor(Color.zenSand.opacity(0.7))
                            .lineSpacing(2)
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(.bottom, 14)
                            .opacity(hasAppeared ? 1 : 0)

                        instructionsSection
                            .padding(.bottom, 16)

                        inputsSection

                        if let error = error {
                            errorView(error)
                                .padding(.top, 12)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 14)
                    .padding(.bottom, 12)
                }

                // Connect Button
                VStack(spacing: 0) {
                    StoneDivider()
                    connectButton
                        .padding(.horizontal, 20)
                        .padding(.top, 12)
                        .padding(.bottom, 16)
                }
            }
        }
        .frame(width: 340, height: 460)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.1)) {
                hasAppeared = true
            }
        }
    }

    // MARK: - Header

    private var headerView: some View {
        HStack {
            Button(action: onDismiss) {
                HStack(spacing: 5) {
                    Image(systemName: "xmark")
                        .font(.system(size: 9, weight: .bold))
                    Text("Cancel")
                        .font(.zenAccent(10))
                }
                .foregroundColor(Color.zenCoral.opacity(0.9))
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(Color.zenCoral.opacity(0.1))
                )
            }
            .buttonStyle(.plain)

            Spacer()

            Text("CONNECT SLACK")
                .font(.zenMono(9))
                .foregroundColor(Color.zenSand.opacity(0.4))
                .tracking(2)

            Spacer()

            // Balance spacer
            Color.clear
                .frame(width: 70)
        }
    }

    // MARK: - Instructions Section

    private var instructionsSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 5) {
                Image(systemName: "list.number")
                    .font(.system(size: 9, weight: .medium))
                    .foregroundColor(Color.zenMoss.opacity(0.7))
                Text("INSTRUCTIONS")
                    .font(.zenMono(8))
                    .foregroundColor(Color.zenSand.opacity(0.5))
                    .tracking(1.5)
            }
            .padding(.bottom, 8)
            .opacity(hasAppeared ? 1 : 0)

            VStack(spacing: 4) {
                CollapsibleStep(
                    number: 1,
                    title: "Open Slack in Chrome",
                    isExpanded: expandedStep == 1,
                    onTap: { toggleStep(1) }
                ) {
                    VStack(alignment: .leading, spacing: 6) {
                        StepDetail(text: "Go to your Slack workspace in Chrome")
                        StepDetail(text: "Make sure you're logged in")
                    }
                }

                CollapsibleStep(
                    number: 2,
                    title: "Open Developer Tools (F12)",
                    isExpanded: expandedStep == 2,
                    onTap: { toggleStep(2) }
                ) {
                    VStack(alignment: .leading, spacing: 6) {
                        StepDetail(text: "Press F12 or right-click → Inspect")
                        StepDetail(text: "Click the Network tab")
                    }
                }

                CollapsibleStep(
                    number: 3,
                    title: "Find a Slack API request",
                    isExpanded: expandedStep == 3,
                    onTap: { toggleStep(3) }
                ) {
                    VStack(alignment: .leading, spacing: 6) {
                        StepDetail(text: "Perform any action in Slack")
                        StepDetail(text: "Look for api.slack.com requests")
                    }
                }

                CollapsibleStep(
                    number: 4,
                    title: "Copy token & cookie",
                    isExpanded: expandedStep == 4,
                    onTap: { toggleStep(4) }
                ) {
                    VStack(alignment: .leading, spacing: 6) {
                        StepDetail(text: "Click request → Headers tab")
                        StepDetail(text: "Find xoxc-... token value")
                        StepDetail(text: "Find xoxd-... cookie value")
                    }
                }
            }
            .opacity(hasAppeared ? 1 : 0)
            .offset(y: hasAppeared ? 0 : 8)

            // Open Slack button
            Button(action: openSlackInBrowser) {
                HStack(spacing: 5) {
                    Image(systemName: "globe")
                        .font(.system(size: 10, weight: .medium))
                    Text("Open Slack in Browser")
                        .font(.zenAccent(10))
                    Image(systemName: "arrow.up.right")
                        .font(.system(size: 7, weight: .bold))
                        .opacity(0.4)
                }
                .foregroundColor(Color.zenPaper.opacity(0.8))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(Color.zenStone.opacity(0.3), lineWidth: 1)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color.zenCharcoal.opacity(0.3))
                        )
                )
            }
            .buttonStyle(.plain)
            .padding(.top, 10)
            .opacity(hasAppeared ? 1 : 0)
        }
    }

    // MARK: - Inputs Section

    private var inputsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Rectangle()
                    .fill(Color.zenStone.opacity(0.15))
                    .frame(height: 1)
                Text("CREDENTIALS")
                    .font(.zenMono(7))
                    .foregroundColor(Color.zenSand.opacity(0.35))
                    .tracking(1.5)
                Rectangle()
                    .fill(Color.zenStone.opacity(0.15))
                    .frame(height: 1)
            }

            // Token Input
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("TOKEN")
                        .font(.zenMono(8))
                        .foregroundColor(Color.zenSand.opacity(0.5))
                        .tracking(1)

                    Spacer()

                    Button(action: { pasteToField(&tokenInput) }) {
                        HStack(spacing: 3) {
                            Image(systemName: "doc.on.clipboard")
                                .font(.system(size: 8))
                            Text("Paste")
                                .font(.zenMono(8))
                        }
                        .foregroundColor(Color.zenMoss.opacity(0.8))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(Color.zenMoss.opacity(0.12))
                        )
                    }
                    .buttonStyle(.plain)
                }

                ZenCredentialInput(
                    text: $tokenInput,
                    placeholder: "xoxc-...",
                    isValid: tokenInput.hasPrefix("xoxc-")
                )
            }

            // Cookie Input
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("COOKIE")
                        .font(.zenMono(8))
                        .foregroundColor(Color.zenSand.opacity(0.5))
                        .tracking(1)

                    Spacer()

                    Button(action: { pasteToField(&cookieInput) }) {
                        HStack(spacing: 3) {
                            Image(systemName: "doc.on.clipboard")
                                .font(.system(size: 8))
                            Text("Paste")
                                .font(.zenMono(8))
                        }
                        .foregroundColor(Color.zenMoss.opacity(0.8))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(Color.zenMoss.opacity(0.12))
                        )
                    }
                    .buttonStyle(.plain)
                }

                ZenCredentialInput(
                    text: $cookieInput,
                    placeholder: "xoxd-...",
                    isValid: cookieInput.hasPrefix("xoxd-")
                )
            }

            // Validation indicators
            if !tokenInput.isEmpty || !cookieInput.isEmpty {
                HStack(spacing: 12) {
                    ValidationBadge(
                        label: "Token",
                        isValid: tokenInput.hasPrefix("xoxc-"),
                        isEmpty: tokenInput.isEmpty
                    )
                    ValidationBadge(
                        label: "Cookie",
                        isValid: cookieInput.hasPrefix("xoxd-"),
                        isEmpty: cookieInput.isEmpty
                    )
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .opacity(hasAppeared ? 1 : 0)
        .offset(y: hasAppeared ? 0 : 12)
    }

    // MARK: - Error View

    private func errorView(_ message: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 11))
            Text(message)
                .font(.zenBody(10))
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)
        }
        .foregroundColor(Color.zenCoral)
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.zenCoral.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.zenCoral.opacity(0.2), lineWidth: 1)
                )
        )
    }

    // MARK: - Connect Button

    private var connectButton: some View {
        let isReady = tokenInput.hasPrefix("xoxc-") && cookieInput.hasPrefix("xoxd-")

        return Button(action: validateAndConnect) {
            HStack(spacing: 6) {
                if isValidating {
                    ProgressView()
                        .scaleEffect(0.5)
                        .progressViewStyle(CircularProgressViewStyle(tint: Color.zenInk))
                } else {
                    Image(systemName: "link.circle.fill")
                        .font(.system(size: 12))
                }
                Text(isValidating ? "Connecting..." : "Connect Slack")
                    .font(.zenAccent(12))
            }
            .foregroundColor(isReady ? Color.zenInk : Color.zenSand.opacity(0.5))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isReady ? Color.zenMoss : Color.zenStone.opacity(0.25))
                    .shadow(
                        color: isReady ? Color.zenMoss.opacity(0.25) : .clear,
                        radius: 8,
                        y: 3
                    )
            )
        }
        .buttonStyle(.plain)
        .disabled(!isReady || isValidating)
        .animation(.easeOut(duration: 0.2), value: isReady)
        .opacity(hasAppeared ? 1 : 0)
    }

    // MARK: - Actions

    private func toggleStep(_ step: Int) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            expandedStep = expandedStep == step ? nil : step
        }
    }

    private func openSlackInBrowser() {
        if let url = URL(string: "https://app.slack.com") {
            NSWorkspace.shared.open(url)
        }
    }

    private func pasteToField(_ field: inout String) {
        if let string = NSPasteboard.general.string(forType: .string) {
            field = string
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .trimmingCharacters(in: CharacterSet(charactersIn: "\"'"))
        }
    }

    private func validateAndConnect() {
        guard tokenInput.hasPrefix("xoxc-"), cookieInput.hasPrefix("xoxd-") else { return }

        isValidating = true
        error = nil

        let cleanToken = tokenInput.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanCookie = cookieInput.trimmingCharacters(in: .whitespacesAndNewlines)

        slackManager.setCredentials(token: cleanToken, cookie: cleanCookie)

        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            isValidating = false
            if slackManager.isAuthenticated {
                onDismiss()
            } else {
                error = "Authentication failed. Verify your token and cookie are from the same Slack session."
            }
        }
    }
}

// MARK: - Collapsible Step

struct CollapsibleStep<Content: View>: View {
    let number: Int
    let title: String
    let isExpanded: Bool
    let onTap: () -> Void
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button(action: onTap) {
                HStack(spacing: 8) {
                    ZStack {
                        Circle()
                            .fill(isExpanded ? Color.zenMoss.opacity(0.2) : Color.zenStone.opacity(0.12))
                            .frame(width: 18, height: 18)

                        Text("\(number)")
                            .font(.zenMono(9))
                            .foregroundColor(isExpanded ? Color.zenMoss : Color.zenSand.opacity(0.7))
                    }

                    Text(title)
                        .font(.zenAccent(10))
                        .foregroundColor(isExpanded ? Color.zenPaper : Color.zenSand.opacity(0.85))

                    Spacer()

                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundColor(Color.zenStone.opacity(0.5))
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 10)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(isExpanded ? Color.zenCharcoal.opacity(0.5) : Color.clear)
                )
            }
            .buttonStyle(.plain)

            if isExpanded {
                content
                    .padding(.leading, 36)
                    .padding(.trailing, 10)
                    .padding(.bottom, 8)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }
}

// MARK: - Step Detail

struct StepDetail: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.zenBody(10))
            .foregroundColor(Color.zenSand.opacity(0.6))
            .fixedSize(horizontal: false, vertical: true)
    }
}

// MARK: - Validation Badge

struct ValidationBadge: View {
    let label: String
    let isValid: Bool
    let isEmpty: Bool

    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: isEmpty ? "circle" : (isValid ? "checkmark.circle.fill" : "exclamationmark.circle"))
                .font(.system(size: 10))
            Text(label)
                .font(.zenMono(9))
        }
        .foregroundColor(isEmpty ? Color.zenStone : (isValid ? Color.zenMoss : Color.zenAmber))
    }
}

// MARK: - Credential Input

struct ZenCredentialInput: View {
    @Binding var text: String
    var placeholder: String
    var isValid: Bool

    var body: some View {
        HStack(spacing: 0) {
            TextField(placeholder, text: $text)
                .textFieldStyle(.plain)
                .font(.system(size: 11, weight: .regular, design: .monospaced))
                .foregroundColor(Color.zenPaper)
                .padding(.leading, 12)
                .padding(.trailing, text.isEmpty ? 12 : 6)

            if !text.isEmpty {
                Button(action: { text = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 12))
                        .foregroundColor(Color.zenStone.opacity(0.6))
                }
                .buttonStyle(.plain)
                .padding(.trailing, 10)
            }
        }
        .frame(height: 36)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.zenCharcoal.opacity(0.8))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(
                            text.isEmpty ? Color.zenStone.opacity(0.2) :
                                (isValid ? Color.zenMoss.opacity(0.5) : Color.zenAmber.opacity(0.4)),
                            lineWidth: 1
                        )
                )
        )
    }
}
