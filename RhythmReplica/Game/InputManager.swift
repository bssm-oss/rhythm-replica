import AppKit

final class InputManager {
    private let keyBindingManager: KeyBindingManager

    init(keyBindingManager: KeyBindingManager) {
        self.keyBindingManager = keyBindingManager
    }

    func resolveAction(for event: NSEvent) -> InputAction? {
        keyBindingManager.action(for: event)
    }
}
