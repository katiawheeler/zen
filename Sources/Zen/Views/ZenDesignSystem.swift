import SwiftUI
import AppKit

// MARK: - Zen Design System
// "Ink & Stone" — Japanese garden-inspired aesthetic
// Refined minimalism with organic warmth and meditative motion

// MARK: - Color Palette
extension Color {
    // Primary palette - ink and stone
    static let zenInk = Color(red: 0.08, green: 0.08, blue: 0.10)
    static let zenCharcoal = Color(red: 0.12, green: 0.12, blue: 0.14)
    static let zenStone = Color(red: 0.22, green: 0.21, blue: 0.23)

    // Warm accents - paper and sand
    static let zenPaper = Color(red: 0.96, green: 0.94, blue: 0.90)
    static let zenSand = Color(red: 0.78, green: 0.74, blue: 0.68)
    static let zenCream = Color(red: 0.88, green: 0.85, blue: 0.80)

    // Nature accents
    static let zenMoss = Color(red: 0.45, green: 0.58, blue: 0.48)
    static let zenAmber = Color(red: 0.85, green: 0.62, blue: 0.35)
    static let zenCoral = Color(red: 0.82, green: 0.45, blue: 0.42)

    // Gradients for depth
    static let zenGradientStart = Color(red: 0.10, green: 0.10, blue: 0.12)
    static let zenGradientEnd = Color(red: 0.06, green: 0.06, blue: 0.08)
}

// MARK: - Typography
extension Font {
    // Display - for headers and titles
    static func zenDisplay(_ size: CGFloat) -> Font {
        .system(size: size, weight: .light, design: .rounded)
    }

    // Body - readable and warm
    static func zenBody(_ size: CGFloat) -> Font {
        .system(size: size, weight: .regular, design: .rounded)
    }

    // Accent - for labels and metadata
    static func zenAccent(_ size: CGFloat) -> Font {
        .system(size: size, weight: .medium, design: .rounded)
    }

    // Mono - for technical details
    static func zenMono(_ size: CGFloat) -> Font {
        .system(size: size, weight: .regular, design: .monospaced)
    }
}

// MARK: - Breathing Animation
struct BreathingCircle: View {
    @State private var isBreathing = false
    let isActive: Bool

    var body: some View {
        ZStack {
            // Outer glow
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color.zenMoss.opacity(isActive ? 0.3 : 0),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: 40
                    )
                )
                .frame(width: 80, height: 80)
                .scaleEffect(isBreathing ? 1.2 : 0.9)

            // Middle ring
            Circle()
                .stroke(
                    Color.zenMoss.opacity(isActive ? 0.4 : 0.1),
                    lineWidth: 1
                )
                .frame(width: 36, height: 36)
                .scaleEffect(isBreathing ? 1.15 : 0.95)

            // Core orb
            Circle()
                .fill(
                    RadialGradient(
                        colors: isActive ? [
                            Color.zenMoss.opacity(0.9),
                            Color.zenMoss.opacity(0.6)
                        ] : [
                            Color.zenStone.opacity(0.5),
                            Color.zenStone.opacity(0.3)
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: 12
                    )
                )
                .frame(width: 24, height: 24)
                .scaleEffect(isBreathing ? 1.1 : 1.0)
                .shadow(color: isActive ? Color.zenMoss.opacity(0.5) : .clear, radius: 8)
        }
        .onAppear {
            if isActive {
                withAnimation(
                    .easeInOut(duration: 4)
                    .repeatForever(autoreverses: true)
                ) {
                    isBreathing = true
                }
            }
        }
        .onChange(of: isActive) { active in
            if active {
                withAnimation(
                    .easeInOut(duration: 4)
                    .repeatForever(autoreverses: true)
                ) {
                    isBreathing = true
                }
            } else {
                withAnimation(.easeOut(duration: 0.5)) {
                    isBreathing = false
                }
            }
        }
    }
}

// MARK: - Ink Wash Background
struct InkWashBackground: View {
    var body: some View {
        ZStack {
            // Base gradient
            LinearGradient(
                colors: [Color.zenGradientStart, Color.zenGradientEnd],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            // Subtle noise texture overlay
            Canvas { context, size in
                for _ in 0..<200 {
                    let x = CGFloat.random(in: 0...size.width)
                    let y = CGFloat.random(in: 0...size.height)
                    let opacity = Double.random(in: 0.02...0.05)

                    context.fill(
                        Path(ellipseIn: CGRect(x: x, y: y, width: 1, height: 1)),
                        with: .color(Color.white.opacity(opacity))
                    )
                }
            }

            // Top-left subtle wash
            RadialGradient(
                colors: [
                    Color.zenStone.opacity(0.08),
                    Color.clear
                ],
                center: .topLeading,
                startRadius: 0,
                endRadius: 300
            )
        }
    }
}

// MARK: - Stone Divider
struct StoneDivider: View {
    var body: some View {
        HStack(spacing: 8) {
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [Color.clear, Color.zenStone.opacity(0.3)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(height: 1)

            Circle()
                .fill(Color.zenStone.opacity(0.4))
                .frame(width: 4, height: 4)

            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [Color.zenStone.opacity(0.3), Color.clear],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(height: 1)
        }
        .padding(.horizontal, 20)
    }
}

// MARK: - Zen Button Style
struct ZenButtonStyle: ButtonStyle {
    let isActive: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.zenAccent(13))
            .foregroundColor(isActive ? Color.zenInk : Color.zenPaper)
            .padding(.vertical, 12)
            .padding(.horizontal, 24)
            .background(
                Group {
                    if isActive {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.zenMoss)
                            .shadow(color: Color.zenMoss.opacity(0.3), radius: 8, y: 4)
                    } else {
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.zenStone, lineWidth: 1)
                    }
                }
            )
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

// MARK: - Pebble Indicator
struct PebbleIndicator: View {
    let isConnected: Bool

    var body: some View {
        ZStack {
            // Outer glow when connected
            Circle()
                .fill(Color.zenMoss.opacity(isConnected ? 0.2 : 0))
                .frame(width: 16, height: 16)

            // The pebble
            Ellipse()
                .fill(
                    RadialGradient(
                        colors: isConnected ? [
                            Color.zenMoss.opacity(0.9),
                            Color.zenMoss.opacity(0.7)
                        ] : [
                            Color.zenAmber.opacity(0.8),
                            Color.zenAmber.opacity(0.6)
                        ],
                        center: .topLeading,
                        startRadius: 0,
                        endRadius: 8
                    )
                )
                .frame(width: 8, height: 6)
                .rotationEffect(.degrees(-15))
        }
    }
}

// MARK: - Zen Card
struct ZenCard<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        content
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.zenCharcoal.opacity(0.6))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.zenStone.opacity(0.2), lineWidth: 1)
                    )
            )
    }
}

// MARK: - Status Row
struct ZenStatusRow: View {
    let icon: String
    let label: String
    let value: String
    var accentColor: Color = .zenSand

    var body: some View {
        HStack(spacing: 12) {
            // Icon in a subtle container
            ZStack {
                Circle()
                    .fill(accentColor.opacity(0.1))
                    .frame(width: 32, height: 32)

                Image(systemName: icon)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(accentColor)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(label.uppercased())
                    .font(.zenMono(9))
                    .foregroundColor(Color.zenSand.opacity(0.6))
                    .tracking(1.2)

                Text(value)
                    .font(.zenBody(13))
                    .foregroundColor(Color.zenPaper)
                    .lineLimit(1)
            }

            Spacer()
        }
    }
}

// MARK: - Event Row (Time-First Layout)
struct ZenEventRow: View {
    let icon: String
    let label: String
    let time: String
    let eventName: String
    var accentColor: Color = .zenSand
    var isFirst: Bool = false

    var body: some View {
        HStack(spacing: 12) {
            // Icon in a subtle container
            ZStack {
                Circle()
                    .fill(accentColor.opacity(0.1))
                    .frame(width: 32, height: 32)

                Image(systemName: icon)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(accentColor)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(label.uppercased())
                    .font(.zenMono(9))
                    .foregroundColor(Color.zenSand.opacity(0.6))
                    .tracking(1.2)

                HStack(spacing: 8) {
                    // Time badge - always visible, never truncates
                    Text(time)
                        .font(.zenMono(11))
                        .foregroundColor(isFirst ? Color.zenInk : Color.zenPaper)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(
                            RoundedRectangle(cornerRadius: 4)
                                .fill(isFirst ? accentColor : Color.zenStone.opacity(0.4))
                        )
                        .fixedSize()

                    // Event name - can truncate, has tooltip
                    Text(eventName)
                        .font(.zenBody(12))
                        .foregroundColor(Color.zenPaper.opacity(0.9))
                        .lineLimit(1)
                        .truncationMode(.tail)
                        .help(eventName) // Native tooltip on hover
                }
            }

            Spacer()
        }
    }
}

// MARK: - Animated Entrance
extension View {
    func zenEntrance(delay: Double = 0) -> some View {
        self
            .opacity(1)
            .offset(y: 0)
            .animation(
                .spring(response: 0.6, dampingFraction: 0.8)
                .delay(delay),
                value: true
            )
    }
}

// MARK: - Pointer Cursor
struct PointerCursorView: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView {
        let view = JsonCursorView()
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {}
}

private class JsonCursorView: NSView {
    override func resetCursorRects() {
        addCursorRect(bounds, cursor: .arrow)
    }
}

extension View {
    func pointerCursor() -> some View {
        self.background(PointerCursorView())
    }
}

// MARK: - Section Header
struct ZenSectionHeader: View {
    let title: String

    var body: some View {
        HStack(spacing: 12) {
            Text(title.uppercased())
                .font(.zenMono(10))
                .foregroundColor(Color.zenSand.opacity(0.5))
                .tracking(2)

            Rectangle()
                .fill(Color.zenStone.opacity(0.2))
                .frame(height: 1)
        }
    }
}

// MARK: - Preview
#Preview {
    VStack(spacing: 24) {
        BreathingCircle(isActive: true)

        StoneDivider()

        ZenCard {
            VStack(spacing: 12) {
                ZenStatusRow(icon: "calendar", label: "Next Meeting", value: "Team Standup in 15m")
                ZenStatusRow(icon: "message.fill", label: "Slack", value: "Focus Mode", accentColor: .zenMoss)
            }
        }

        HStack {
            PebbleIndicator(isConnected: true)
            Text("Connected")
                .font(.zenAccent(11))
                .foregroundColor(.zenSand)
        }

        Button("Enable Zen") {}
            .buttonStyle(ZenButtonStyle(isActive: false))

        Button("Disable Zen") {}
            .buttonStyle(ZenButtonStyle(isActive: true))
    }
    .padding(32)
    .frame(width: 320, height: 500)
    .background(InkWashBackground())
}
