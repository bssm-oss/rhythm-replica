import AppKit

final class SettingsViewController: NSViewController {
    private let environment: AppEnvironment
    private let statusLabel = NSTextField(labelWithString: "")
    private let inputDelayField = NSTextField(string: "0")
    private let volumeSlider = NSSlider(value: 1, minValue: 0, maxValue: 1, target: nil, action: nil)
    private let defaultSpeedField = NSTextField(string: "2.0")
    private let judgementLineField = NSTextField(string: "0.85")
    private let themePopup = NSPopUpButton(frame: .zero, pullsDown: false)
    private let outputDevicePopup = NSPopUpButton(frame: .zero, pullsDown: false)
    private let youtubeBehaviorPopup = NSPopUpButton(frame: .zero, pullsDown: false)
    private let lane0Field = NSTextField(string: "d")
    private let lane1Field = NSTextField(string: "f")
    private let lane2Field = NSTextField(string: "j")
    private let lane3Field = NSTextField(string: "k")
    private let youtubeBehaviorLabel = NSTextField(wrappingLabelWithString: "")

    init(environment: AppEnvironment) {
        self.environment = environment
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        nil
    }

    override func loadView() {
        view = NSView()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.wantsLayer = true
        view.layer?.backgroundColor = RRColor.baseBackground.cgColor

        let preferences = environment.preferencesStore.load()
        inputDelayField.stringValue = String(preferences.inputDelayMilliseconds)
        volumeSlider.doubleValue = preferences.volume
        defaultSpeedField.stringValue = String(preferences.defaultSpeed)
        judgementLineField.stringValue = String(preferences.judgementLineRatio)
        lane0Field.stringValue = preferences.keyBindings.lane0
        lane1Field.stringValue = preferences.keyBindings.lane1
        lane2Field.stringValue = preferences.keyBindings.lane2
        lane3Field.stringValue = preferences.keyBindings.lane3

        themePopup.addItems(withTitles: ThemePreference.allCases.map(\.rawValue))
        themePopup.selectItem(withTitle: preferences.theme.rawValue)
        outputDevicePopup.addItems(withTitles: ["System Default"])
        outputDevicePopup.selectItem(withTitle: preferences.outputDeviceName)
        youtubeBehaviorPopup.addItems(withTitles: YouTubeImportBehavior.allCases.map(\.rawValue))
        youtubeBehaviorPopup.selectItem(withTitle: preferences.youtubeImportBehavior.rawValue)
        let detection = environment.youtubeImportService.detectTools()
        youtubeBehaviorLabel.stringValue = "YouTube 가져오기: 사용자가 설치한 yt-dlp/ffmpeg만 사용합니다. yt-dlp=\(detection.ytDlpPath?.lastPathComponent ?? "없음"), ffmpeg=\(detection.ffmpegPath?.lastPathComponent ?? "없음")"
        youtubeBehaviorLabel.textColor = RRColor.secondaryText
        youtubeBehaviorLabel.font = RRTypography.caption()

        let saveButton = NSButton(title: "Save Settings", target: self, action: #selector(saveSettings))
        let openCacheButton = NSButton(title: "Open Cache Folder", target: self, action: #selector(openCacheFolder))
        let clearCacheButton = NSButton(title: "Clear Cache", target: self, action: #selector(clearCache))

        statusLabel.textColor = RRColor.primaryText

        let stack = NSStackView(views: [
            labeled("Input Delay (ms)", inputDelayField),
            labeled("Volume", volumeSlider),
            labeled("Default Speed", defaultSpeedField),
            labeled("Judgement Line Ratio", judgementLineField),
            keyBindingRow(),
            labeled("Theme", themePopup),
            labeled("Audio Output Device", outputDevicePopup),
            labeled("YouTube Import Behavior", youtubeBehaviorPopup),
            labeled("YouTube Import", youtubeBehaviorLabel),
            saveButton,
            openCacheButton,
            clearCacheButton,
            NSTextField(labelWithString: "App Version: 0.1.0-dev"),
            statusLabel
        ])
        stack.orientation = .vertical
        stack.spacing = 12
        stack.translatesAutoresizingMaskIntoConstraints = false

        for label in stack.views.compactMap({ $0 as? NSTextField }) {
            label.textColor = RRColor.primaryText
            label.font = RRTypography.body()
        }

        view.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: view.topAnchor, constant: 24),
            stack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            stack.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -24)
        ])
    }

    @objc private func saveSettings() {
        var preferences = environment.preferencesStore.load()
        preferences.inputDelayMilliseconds = Double(inputDelayField.stringValue) ?? preferences.inputDelayMilliseconds
        preferences.volume = volumeSlider.doubleValue
        preferences.defaultSpeed = Double(defaultSpeedField.stringValue) ?? preferences.defaultSpeed
        preferences.judgementLineRatio = Double(judgementLineField.stringValue) ?? preferences.judgementLineRatio
        preferences.theme = ThemePreference(rawValue: themePopup.selectedItem?.title ?? ThemePreference.system.rawValue) ?? .system
        preferences.outputDeviceName = outputDevicePopup.selectedItem?.title ?? "System Default"
        preferences.youtubeImportBehavior = YouTubeImportBehavior(rawValue: youtubeBehaviorPopup.selectedItem?.title ?? YouTubeImportBehavior.cacheFolder.rawValue) ?? .cacheFolder
        preferences.keyBindings = KeyBindingConfiguration(
            lane0: lane0Field.stringValue.lowercased(),
            lane1: lane1Field.stringValue.lowercased(),
            lane2: lane2Field.stringValue.lowercased(),
            lane3: lane3Field.stringValue.lowercased()
        )
        environment.preferencesStore.save(preferences)
        statusLabel.stringValue = "설정을 저장했습니다."
    }

    @objc private func openCacheFolder() {
        NSWorkspace.shared.open(environment.cacheManager.cacheDirectoryURL)
    }

    @objc private func clearCache() {
        do {
            try environment.cacheManager.clearCache()
            statusLabel.stringValue = "캐시를 삭제했습니다."
        } catch {
            statusLabel.stringValue = error.localizedDescription
        }
    }

    private func labeled(_ title: String, _ control: NSView) -> NSView {
        let label = NSTextField(labelWithString: title)
        label.font = RRTypography.caption()
        let stack = NSStackView(views: [label, control])
        stack.orientation = .vertical
        stack.spacing = 4
        return stack
    }

    private func keyBindingRow() -> NSView {
        let row = NSStackView(views: [
            labeled("Lane D", lane0Field),
            labeled("Lane F", lane1Field),
            labeled("Lane J", lane2Field),
            labeled("Lane K", lane3Field)
        ])
        row.orientation = .horizontal
        row.spacing = 8
        let container = NSStackView(views: [NSTextField(labelWithString: "Key Bindings"), row])
        container.orientation = .vertical
        container.spacing = 4
        if let label = container.views.first as? NSTextField {
            label.font = RRTypography.caption()
            label.textColor = RRColor.primaryText
        }
        return container
    }
}
