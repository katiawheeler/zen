# Zen 🧘‍♂️

A macOS Menu Bar app that syncs your Focus, Calendar, and Slack.

## Features
- **Google Calendar**: Fetches upcoming events and auto-triggers focus modes.
- **Slack Sync**: Updates your status and toggles Do Not Disturb.
- **Focus Modes**: Uses App Intents to integrate with Shortcuts, Siri, and Spotlight.

## How It Works

When you install Zen, its actions **automatically appear** in:
- 📱 **Shortcuts app** (search "Zen")
- 🎙️ **Siri** ("Hey Siri, set Work focus with Zen")
- 🔍 **Spotlight** (type "Set Focus Mode")

### Still Need: System Focus Mode Shortcuts
Apple doesn't allow apps to directly set Focus Modes. You'll need simple 1-step Shortcuts:
1. Open **Shortcuts** app
2. Create shortcuts named: `Set Work Focus`, `Set Deep Work Focus`, `Set Personal Focus`, `Set Meeting Focus`
3. Each shortcut should have one action: **Set Focus** → [Your Focus Name]

## API Keys
Add your OAuth tokens in:
- `Managers/SlackManager.swift` → `token`
- `Managers/CalendarManager.swift` → `accessToken`

## Build and Run
```bash
cd Zen
swift run
```
The app appears in your menu bar. Dock icon is hidden automatically.

