import Foundation

extension Notification.Name {
    static let preferencesDidChange = Notification.Name("RhythmReplica.preferencesDidChange")
    static let navigateToTab = Notification.Name("RhythmReplica.navigateToTab")
}

enum ThemePreference: String, Codable, CaseIterable {
    case system
    case dark
    case light
}

struct KeyBindingConfiguration: Codable, Equatable {
    var lane0: String = "d"
    var lane1: String = "f"
    var lane2: String = "j"
    var lane3: String = "k"
}

struct Preferences: Codable, Equatable {
    var inputDelayMilliseconds: Double = 0
    var defaultSpeed: Double = 2.0
    var judgementLineRatio: Double = 0.85
    var volume: Double = 1.0
    var theme: ThemePreference = .system
    var keyBindings: KeyBindingConfiguration = .init()
}

final class PreferencesStore {
    private let defaults: UserDefaults
    private let key = "RhythmReplica.Preferences"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func load() -> Preferences {
        guard let data = defaults.data(forKey: key), let preferences = try? JSONDecoder().decode(Preferences.self, from: data) else {
            return Preferences()
        }
        return preferences
    }

    func save(_ preferences: Preferences) {
        if let data = try? JSONEncoder().encode(preferences) {
            defaults.set(data, forKey: key)
            NotificationCenter.default.post(name: .preferencesDidChange, object: self)
        }
    }
}
