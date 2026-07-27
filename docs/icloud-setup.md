# iCloud Key-Value sync (optional)

FlyMinder syncs **banner message** and **reminder interval** via iCloud Key-Value Storage when enabled.

## Enable in Xcode (requires Apple Developer account)

1. Select the **MeetingReminder** or **FlyMinderMobile** target
2. **Signing & Capabilities → + Capability → iCloud**
3. Check **Key-value storage**
4. Use the same team / Apple ID on Mac and iPhone
5. Sign in to iCloud on both devices

Add this to the target entitlements:

```xml
<key>com.apple.developer.ubiquity-kvstore-identifier</key>
<string>$(TeamIdentifierPrefix)com.flyminder.app</string>
```

Without iCloud, settings still save locally on each device via UserDefaults.
