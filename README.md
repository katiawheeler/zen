# 禅 Zen

A minimalist macOS menu bar app for focus and flow.

Zen lives quietly in your menu bar, syncing with your calendar to automatically manage focus modes when meetings begin and end. No more manual toggling—just seamless transitions between focused work and collaboration.

## Features

- **Calendar Sync** — Connects to Google Calendar to fetch upcoming events
- **Automatic Focus** — Triggers focus mode when meetings start, releases when they end
- **Shortcuts Integration** — Works with Siri, Spotlight, and the Shortcuts app
- **Zen Aesthetic** — Calming ink wash visuals with breathing animations

## How It Works

Zen monitors your calendar in the background. When a meeting begins, it automatically activates your system Focus Mode. When the meeting ends, focus is released. You can also manually toggle focus with the "Begin Zen" button.

### Shortcuts Integration

Zen's actions automatically appear in:
- **Shortcuts app** — Search "Zen" or "Set Focus Mode"
- **Siri** — "Set Work focus"
- **Spotlight** — Type "Set Focus Mode"

### Required Setup: Focus Mode Shortcuts

Apple doesn't allow apps to directly control Focus Modes. Create these simple shortcuts:

1. Open **Shortcuts** app
2. Create shortcuts named exactly:
   - `Zen Mode On`
   - `Zen Mode Off`
3. Each shortcut has one action: **Set Focus** to your preferred focus mode (or turn it off)

## Setup

### 1. Clone and Configure

```bash
git clone https://github.com/katiawheeler/zen.git
cd zen
```

### 2. Add Google OAuth Credentials

Copy the example config and add your credentials:

```bash
cp Sources/Zen/Config.example.swift Sources/Zen/Config.swift
```

Edit `Sources/Zen/Config.swift` with your Google Cloud Console credentials:
- Create a project at [Google Cloud Console](https://console.cloud.google.com)
- Enable the Google Calendar API
- Create OAuth 2.0 credentials for an iOS app
- Add the client ID and redirect URI to Config.swift

### 3. Build and Run

```bash
swift build
swift run
```

Or open `Zen.xcodeproj` in Xcode and run from there.

The app appears in your menu bar with a leaf icon. The dock icon is hidden automatically.

## Architecture

```
Sources/Zen/
├── ZenApp.swift              # App entry point
├── Config.swift              # OAuth credentials (gitignored)
├── Views/
│   ├── MainView.swift        # Primary menu bar interface
│   └── SettingsView.swift    # Settings and account management
├── Managers/
│   ├── GoogleAuthManager.swift   # OAuth flow
│   ├── CalendarManager.swift     # Calendar sync
│   └── FocusManager.swift        # Focus mode control & automation
└── AppIntents/
    ├── SetFocusModeIntent.swift  # Shortcuts integration
    └── ZenShortcuts.swift        # App shortcuts provider
```

## License

MIT
