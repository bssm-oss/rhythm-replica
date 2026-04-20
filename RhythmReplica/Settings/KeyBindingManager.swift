import AppKit
import Foundation

enum InputAction: Equatable {
    case lane(Int)
    case speedUp
    case speedDown
    case togglePause
}

final class KeyBindingManager {
    private let preferencesStore: PreferencesStore

    init(preferencesStore: PreferencesStore) {
        self.preferencesStore = preferencesStore
    }

    var bindings: KeyBindingConfiguration {
        get { preferencesStore.load().keyBindings }
        set {
            var preferences = preferencesStore.load()
            preferences.keyBindings = newValue
            preferencesStore.save(preferences)
        }
    }

    func action(for event: NSEvent) -> InputAction? {
        if event.keyCode == 126 { return .speedUp }
        if event.keyCode == 125 { return .speedDown }
        if event.keyCode == 49 { return .togglePause }

        guard let text = event.charactersIgnoringModifiers?.lowercased() else {
            return nil
        }

        let bindings = bindings
        if text == bindings.lane0 { return .lane(0) }
        if text == bindings.lane1 { return .lane(1) }
        if text == bindings.lane2 { return .lane(2) }
        if text == bindings.lane3 { return .lane(3) }
        return nil
    }
}
