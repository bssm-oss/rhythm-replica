import AppKit

final class StartViewController: NSViewController, NSDraggingDestination {
    private let environment: AppEnvironment
    private let recentList = NSTextView(frame: .zero)
    private let toolStatusLabel = NSTextField(labelWithString: "")

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
        view.registerForDraggedTypes([.fileURL])

        let titleLabel = NSTextField(labelWithString: "Rhythm Replica")
        titleLabel.font = RRTypography.heading()
        titleLabel.textColor = RRColor.primaryText

        let descriptionLabel = NSTextField(wrappingLabelWithString: "로컬 오디오 + JSON 플레이, 채보 편집, 안전한 외부 도구 기반 YouTube 가져오기를 위한 macOS 네이티브 리듬게임 워크스테이션")
        descriptionLabel.font = RRTypography.body()
        descriptionLabel.textColor = RRColor.secondaryText

        let newPlayButton = NSButton(title: "새 플레이 준비", target: self, action: #selector(openPlayerHint))
        let editorButton = NSButton(title: "채보 편집 시작", target: self, action: #selector(openEditorHint))
        let importButton = NSButton(title: "로컬 오디오 가져오기", target: self, action: #selector(importAudio))
        let youtubeButton = NSButton(title: "YouTube 링크 가져오기", target: self, action: #selector(showYouTubeStatus))
        let onboardingButton = NSButton(title: "첫 실행 안내", target: self, action: #selector(showOnboarding))

        let recentContainer = NSScrollView()
        recentContainer.documentView = recentList
        recentContainer.hasVerticalScroller = true
        recentContainer.applyCardStyle()
        recentList.isEditable = false
        recentList.backgroundColor = .clear
        recentList.textColor = RRColor.primaryText
        recentList.font = RRTypography.body()

        toolStatusLabel.textColor = RRColor.warning
        toolStatusLabel.font = RRTypography.body()
        refreshRecentItems()

        let stack = NSStackView(views: [titleLabel, descriptionLabel, newPlayButton, editorButton, importButton, youtubeButton, onboardingButton, toolStatusLabel, recentContainer])
        stack.orientation = .vertical
        stack.spacing = 12
        stack.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: view.topAnchor, constant: 24),
            stack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            stack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            stack.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -24),
            recentContainer.heightAnchor.constraint(equalToConstant: 320)
        ])
    }

    func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
        .copy
    }

    func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        guard let files = sender.draggingPasteboard.readObjects(forClasses: [NSURL.self]) as? [URL], !files.isEmpty else {
            return false
        }
        toolStatusLabel.stringValue = "드롭된 파일: \(files.map(\.lastPathComponent).joined(separator: ", "))"
        return true
    }

    private func refreshRecentItems() {
        let items = environment.recentProjectsStore.load()
        recentList.string = items.isEmpty
            ? "최근 프로젝트가 없습니다. 플레이어나 에디터에서 오디오와 채보를 연 뒤 다시 여기로 돌아오면 최근 목록이 표시됩니다."
            : items.map { "• \($0.chartPath)\n  ↳ \($0.audioPath)" }.joined(separator: "\n")
    }

    @objc private func openPlayerHint() {
        toolStatusLabel.stringValue = "Player 탭에서 오디오와 채보를 열어 바로 플레이할 수 있습니다."
    }

    @objc private func openEditorHint() {
        toolStatusLabel.stringValue = "Editor 탭에서 BPM, 스냅, 노트 배치를 수정한 뒤 바로 테스트 플레이할 수 있습니다."
    }

    @objc private func importAudio() {
        let panel = NSOpenPanel()
        panel.beginSheetModal(for: view.window!) { [weak self] response in
            guard response == .OK, let url = panel.url else { return }
            self?.environment.sessionStore.currentAudioURL = url
            self?.toolStatusLabel.stringValue = "오디오 선택됨: \(url.lastPathComponent)"
        }
    }

    @objc private func showYouTubeStatus() {
        let controller = YouTubeImportViewController(service: environment.youtubeImportService)
        let window = NSWindow(contentViewController: controller)
        window.title = "YouTube Import"
        window.styleMask = [.titled, .closable]
        let host = NSWindowController(window: window)
        host.showWindow(nil)
        toolStatusLabel.stringValue = "YouTube 가져오기 창을 열었습니다. 권리가 있는 영상만 사용하세요."
    }

    @objc private func showOnboarding() {
        let message = "1. Start 화면에서 오디오를 선택합니다.\n2. Player에서 오디오와 채보를 열고 D/F/J/K로 플레이합니다.\n3. Editor에서 BPM, SNAP, 노트를 수정하고 Test Play로 연결합니다.\n4. YouTube 가져오기는 외부 도구가 있을 때만 사용 가능합니다."
        let alert = NSAlert()
        alert.messageText = "Rhythm Replica 시작 안내"
        alert.informativeText = message
        alert.addButton(withTitle: "확인")
        alert.beginSheetModal(for: view.window!) { _ in }
    }
}
