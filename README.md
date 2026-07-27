# ✈️ FlyMinder

A macOS menu bar app that flies a hand-drawn pink airplane across your screen on a
regular schedule, trailing a pink banner with **your custom message** — reminding
you to walk, stretch, and take breaks.

Native SwiftUI · menu bar only · floats above fullscreen apps · no account required.

---

## Requirements

- **macOS 26 (Tahoe)** or later
- **Xcode 26** or later (to build from source)

---

## Quick start (developers)

```bash
open MeetingReminder.xcodeproj
# Press ⌘R in Xcode
```

## Build for distribution

```bash
chmod +x scripts/build.sh
./scripts/build.sh          # → FlyMinder.app
./scripts/build.sh --dmg    # → FlyMinder.app + FlyMinder.dmg
```

See the end of `scripts/build.sh` for notarization steps (requires Apple Developer account).

---

## Public release checklist

| Done | Item |
|------|------|
| ✅ | Menu bar only (no Dock icon) |
| ✅ | System font fallback if Comic Sans unavailable |
| ✅ | About window + version + support links |
| ✅ | First-run welcome hint |
| ✅ | Sleep/wake countdown recovery |
| ✅ | Bundle ID `com.flyminder.app` |
| ✅ | Landing page (`website/index.html`) |
| ✅ | Privacy policy (`website/privacy.html`) |
| ⬜ | Apple Developer signing + notarization |
| ⬜ | Host `.dmg` and update download link on website |
| ⬜ | Update URLs/email in `MeetingReminder/AppInfo.swift` |

---

## Configuration

Edit `MeetingReminder/AppInfo.swift` before shipping:

- `supportEmail`
- `websiteURL`
- `privacyPolicyURL`

---

## Project structure

```
MeetingReminder/
├── MeetingReminderApp.swift       # @main + MenuBarExtra
├── AppController.swift            # Coordinator
├── AppInfo.swift                  # Version, URLs, support
├── MenuBarView.swift              # Settings UI
├── AboutView.swift                # About window
├── StretchReminderScheduler.swift # Interval timer
├── AirplaneView.swift             # Banner animation
├── BannerFont.swift               # Font with system fallback
└── Assets.xcassets/
scripts/build.sh                   # Release + .dmg builder
website/                           # Landing page + privacy policy
```

---

## License

MIT — see [LICENSE](LICENSE).
