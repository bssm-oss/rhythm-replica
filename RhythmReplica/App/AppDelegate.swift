import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var windowController: MainWindowController?
    private var environment: AppEnvironment?

    func applicationDidFinishLaunching(_ notification: Notification) {
        let environment = AppEnvironment.live()
        let controller = MainWindowController(environment: environment)
        controller.showWindow(nil)
        controller.window?.center()
        controller.window?.makeKeyAndOrderFront(nil)
        NSApplication.shared.activate(ignoringOtherApps: true)
        self.environment = environment
        windowController = controller
        applyPreferences(environment.preferencesStore.load())
        NotificationCenter.default.addObserver(self, selector: #selector(handlePreferencesChange), name: .preferencesDidChange, object: environment.preferencesStore)
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        true
    }

    @objc private func handlePreferencesChange() {
        guard let environment else { return }
        applyPreferences(environment.preferencesStore.load())
    }

    private func applyPreferences(_ preferences: Preferences) {
        switch preferences.theme {
        case .system:
            NSApp.appearance = nil
        case .dark:
            NSApp.appearance = NSAppearance(named: .darkAqua)
        case .light:
            NSApp.appearance = NSAppearance(named: .aqua)
        }
        environment?.audioPlaybackService.setVolume(preferences.volume)
    }
}
