import AppKit

final class MainWindowController: NSWindowController {
    init(environment: AppEnvironment) {
        let rootViewController = MainTabViewController(environment: environment)
        let window = NSWindow(contentViewController: rootViewController)
        window.title = "Rhythm Replica"
        window.setContentSize(NSSize(width: 1360, height: 860))
        window.minSize = NSSize(width: 1100, height: 720)
        window.styleMask = [.titled, .closable, .miniaturizable, .resizable]
        window.titlebarAppearsTransparent = false
        super.init(window: window)
        shouldCascadeWindows = true
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        nil
    }
}

final class MainTabViewController: NSTabViewController {
    private let environment: AppEnvironment

    init(environment: AppEnvironment) {
        self.environment = environment
        super.init(nibName: nil, bundle: nil)
        tabStyle = .toolbar

        addTab(named: "Start", image: NSImage(systemSymbolName: "music.note.house", accessibilityDescription: nil)) {
            StartViewController(environment: environment)
        }
        addTab(named: "Player", image: NSImage(systemSymbolName: "play.circle", accessibilityDescription: nil)) {
            PlayerViewController(environment: environment)
        }
        addTab(named: "Editor", image: NSImage(systemSymbolName: "square.and.pencil", accessibilityDescription: nil)) {
            EditorViewController(environment: environment)
        }
        addTab(named: "Settings", image: NSImage(systemSymbolName: "gearshape", accessibilityDescription: nil)) {
            SettingsViewController(environment: environment)
        }
        NotificationCenter.default.addObserver(self, selector: #selector(handleNavigation(_:)), name: .navigateToTab, object: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        nil
    }

    private func addTab(named title: String, image: NSImage?, factory: () -> NSViewController) {
        let child = factory()
        child.title = title
        let item = NSTabViewItem(viewController: child)
        item.label = title
        item.image = image
        addTabViewItem(item)
    }

    @objc private func handleNavigation(_ notification: Notification) {
        guard let tab = notification.userInfo?["tab"] as? String,
              let index = tabViewItems.firstIndex(where: { $0.label == tab }) else { return }
        selectedTabViewItemIndex = index
    }
}
