import Foundation
import Combine

/// Shared banner message + reminder interval, synced via iCloud Key-Value Storage.
@MainActor
final class FlyMinderSettings: ObservableObject {
    static let shared = FlyMinderSettings()

    static let maxBannerMessageLength = 45
    static let defaultBannerMessage = "Get up and stretch!"
    static let defaultIntervalMinutes: Double = 30

    static let interval20: Double = 20
    static let interval30: Double = 30
    static let interval45: Double = 45
    static let interval60: Double = 60

    @Published private(set) var bannerMessage: String
    @Published private(set) var intervalMinutes: Double

    private let cloud = NSUbiquitousKeyValueStore.default
    private let local = UserDefaults.standard
    private var isApplyingRemoteChange = false
    private var observer: NSObjectProtocol?

    private enum Key {
        static let bannerMessage = "bannerMessage"
        static let intervalMinutes = "intervalMinutes"
    }

    private init() {
        cloud.synchronize()

        if let cloudMessage = cloud.string(forKey: Key.bannerMessage) {
            bannerMessage = Self.clampBannerMessage(cloudMessage)
        } else if let localMessage = local.string(forKey: Key.bannerMessage) {
            bannerMessage = Self.clampBannerMessage(localMessage)
        } else {
            bannerMessage = Self.defaultBannerMessage
        }

        let cloudInterval = cloud.double(forKey: Key.intervalMinutes)
        if cloudInterval > 0 {
            intervalMinutes = cloudInterval
        } else {
            let localInterval = local.double(forKey: Key.intervalMinutes)
            intervalMinutes = localInterval > 0 ? localInterval : Self.defaultIntervalMinutes
        }

        persistToLocalAndCloud()

        observer = NotificationCenter.default.addObserver(
            forName: NSUbiquitousKeyValueStore.didChangeExternallyNotification,
            object: cloud,
            queue: .main
        ) { [weak self] notification in
            Task { @MainActor in
                self?.applyRemoteChanges(notification)
            }
        }
    }

    deinit {
        if let observer {
            NotificationCenter.default.removeObserver(observer)
        }
    }

    var effectiveBannerMessage: String {
        let trimmed = bannerMessage.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? Self.defaultBannerMessage : trimmed
    }

    func setBannerMessage(_ text: String) {
        let clamped = Self.clampBannerMessage(text)
        guard clamped != bannerMessage else { return }
        bannerMessage = clamped
        persistToLocalAndCloud()
    }

    func setIntervalMinutes(_ minutes: Double) {
        guard minutes != intervalMinutes else { return }
        intervalMinutes = minutes
        persistToLocalAndCloud()
    }

    static func clampBannerMessage(_ text: String) -> String {
        String(text.prefix(maxBannerMessageLength))
    }

    // MARK: Private

    private func persistToLocalAndCloud() {
        guard !isApplyingRemoteChange else { return }
        local.set(bannerMessage, forKey: Key.bannerMessage)
        local.set(intervalMinutes, forKey: Key.intervalMinutes)
        cloud.set(bannerMessage, forKey: Key.bannerMessage)
        cloud.set(intervalMinutes, forKey: Key.intervalMinutes)
        cloud.synchronize()
    }

    private func applyRemoteChanges(_ notification: Notification) {
        guard let keys = notification.userInfo?[NSUbiquitousKeyValueStoreChangedKeysKey] as? [String] else {
            return
        }

        isApplyingRemoteChange = true
        defer {
            isApplyingRemoteChange = false
            persistToLocalAndCloud()
        }

        if keys.contains(Key.bannerMessage),
           let remote = cloud.string(forKey: Key.bannerMessage) {
            bannerMessage = Self.clampBannerMessage(remote)
        }

        if keys.contains(Key.intervalMinutes) {
            let remote = cloud.double(forKey: Key.intervalMinutes)
            if remote > 0 {
                intervalMinutes = remote
            }
        }
    }
}
