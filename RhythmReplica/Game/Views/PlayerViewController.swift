import AppKit
import UniformTypeIdentifiers

final class PlayerViewController: NSViewController {
    private let environment: AppEnvironment
    private let engine: GameEngine
    private let playfieldView = PlayfieldView(frame: .zero)
    private let statusLabel = NSTextField(labelWithString: "Load audio + chart to start")
    private let scoreLabel = NSTextField(labelWithString: "Score 0")
    private let comboLabel = NSTextField(labelWithString: "Combo 0")
    private let hpLabel = NSTextField(labelWithString: "HP 100")
    private let timeLabel = NSTextField(labelWithString: "00:00 / 00:00")
    private let speedLabel = NSTextField(labelWithString: "x2.0")
    private let progressIndicator = NSProgressIndicator()
    private let resultLabel = NSTextField(labelWithString: "")
    private let mismatchLabel = NSTextField(labelWithString: "")
    private var timer: Timer?
    private var resultWindowController: NSWindowController?

    init(environment: AppEnvironment) {
        self.environment = environment
        self.engine = GameEngine(audioService: environment.audioPlaybackService, preferencesStore: environment.preferencesStore)
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        nil
    }

    override func loadView() {
        view = PlayerContainerView()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.wantsLayer = true
        view.layer?.backgroundColor = RRColor.baseBackground.cgColor

        let openAudioButton = NSButton(title: "Open Audio", target: self, action: #selector(openAudio))
        let openChartButton = NSButton(title: "Open Chart", target: self, action: #selector(openChart))
        let playButton = NSButton(title: "Play / Resume", target: self, action: #selector(togglePlay))
        let pauseButton = NSButton(title: "Pause", target: self, action: #selector(pause))
        let restartButton = NSButton(title: "Restart", target: self, action: #selector(restart))
        let speedDownButton = NSButton(title: "- Speed", target: self, action: #selector(speedDown))
        let speedUpButton = NSButton(title: "+ Speed", target: self, action: #selector(speedUp))

        progressIndicator.isIndeterminate = false
        progressIndicator.minValue = 0
        progressIndicator.maxValue = 1
        progressIndicator.doubleValue = 0
        progressIndicator.controlSize = .regular

        [statusLabel, scoreLabel, comboLabel, hpLabel, timeLabel, speedLabel, resultLabel, mismatchLabel].forEach {
            $0.textColor = RRColor.primaryText
            $0.font = RRTypography.body()
        }
        statusLabel.font = RRTypography.section()
        resultLabel.textColor = RRColor.warning
        mismatchLabel.textColor = RRColor.warning

        playfieldView.applyCardStyle()
        playfieldView.engine = engine
        playfieldView.setAccessibilityLabel("Gameplay playfield")
        view.setAccessibilityLabel("Player screen")
        let relinkButton = NSButton(title: "Relink Audio", target: self, action: #selector(openAudio))

        let header = NSStackView(views: [openAudioButton, openChartButton, playButton, pauseButton, restartButton, speedDownButton, speedUpButton, speedLabel])
        header.orientation = .horizontal
        header.spacing = 8

        let stats = NSStackView(views: [statusLabel, scoreLabel, comboLabel, hpLabel, timeLabel, resultLabel])
        stats.orientation = .horizontal
        stats.spacing = 16

        let warningRow = NSStackView(views: [mismatchLabel, relinkButton])
        warningRow.orientation = .horizontal
        warningRow.spacing = 8

        let stack = NSStackView(views: [header, stats, progressIndicator, warningRow, playfieldView])
        stack.orientation = .vertical
        stack.spacing = 12
        stack.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: view.topAnchor, constant: 16),
            stack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            stack.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -16),
            playfieldView.heightAnchor.constraint(equalToConstant: 560)
        ])

        (view as? PlayerContainerView)?.keyDownHandler = { [weak self] event in
            self?.handleKey(event)
        }
        (view as? PlayerContainerView)?.keyUpHandler = { [weak self] event in
            self?.handleKeyUp(event)
        }
        if let currentAudioURL = environment.sessionStore.currentAudioURL {
            try? environment.audioPlaybackService.load(url: currentAudioURL)
            statusLabel.stringValue = "Audio: \(currentAudioURL.lastPathComponent)"
        }
        if environment.sessionStore.currentChart != .empty {
            engine.load(chart: environment.sessionStore.currentChart)
        }
        NotificationCenter.default.addObserver(self, selector: #selector(handleSessionChartChange), name: .sessionChartDidChange, object: environment.sessionStore)
        NotificationCenter.default.addObserver(self, selector: #selector(handleSessionAudioChange), name: .sessionAudioDidChange, object: environment.sessionStore)
        NotificationCenter.default.addObserver(self, selector: #selector(handlePreferencesChange), name: .preferencesDidChange, object: environment.preferencesStore)
        updateMismatchWarning()
        handlePreferencesChange()
        startTimer()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    private func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0 / 30.0, repeats: true) { [weak self] _ in
            self?.refreshUI()
        }
    }

    private func refreshUI() {
        engine.updateMisses()
        let score = engine.scoreState
        scoreLabel.stringValue = "Score \(score.score)"
        comboLabel.stringValue = "Combo \(score.combo)"
        hpLabel.stringValue = "HP \(score.hp)"
        timeLabel.stringValue = "\(TimeFormatting.clock(environment.audioPlaybackService.currentTime)) / \(TimeFormatting.clock(environment.audioPlaybackService.duration))"
        progressIndicator.doubleValue = environment.audioPlaybackService.duration > 0 ? min(1, max(0, environment.audioPlaybackService.currentTime / environment.audioPlaybackService.duration)) : 0
        speedLabel.stringValue = String(format: "x%.1f", engine.speed)
        resultLabel.stringValue = score.hp == 0 ? "GAME OVER" : "Rank \(engine.rank()) • Accuracy \(Int(score.accuracy * 100))%"
        updateMismatchWarning()
        playfieldView.needsDisplay = true
        if environment.audioPlaybackService.duration > 0,
           (score.hp == 0 || environment.audioPlaybackService.currentTime >= environment.audioPlaybackService.duration),
           resultWindowController == nil {
            presentResultWindow()
        }
    }

    @objc private func openAudio() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = []
        panel.beginSheetModal(for: view.window!) { [weak self] response in
            guard response == .OK, let url = panel.url, let self else { return }
            do {
                try self.environment.audioPlaybackService.load(url: url)
                self.environment.sessionStore.currentAudioURL = url
                if self.environment.sessionStore.currentChart != .empty {
                    var chart = self.environment.sessionStore.currentChart
                    chart.audioFileName = url.lastPathComponent
                    self.environment.sessionStore.currentChart = chart
                }
                self.statusLabel.stringValue = self.persistChartAudioLinkStatus(audioURL: url)
                self.environment.recentProjectsStore.add(chartURL: self.environment.sessionStore.currentChartURL, audioURL: url)
                self.updateMismatchWarning()
            } catch {
                self.statusLabel.stringValue = error.localizedDescription
            }
        }
    }

    @objc private func openChart() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.json]
        panel.beginSheetModal(for: view.window!) { [weak self] response in
            guard response == .OK, let url = panel.url, let self else { return }
            do {
                let chart = try self.environment.chartLoader.load(from: url)
                let issues = self.environment.chartValidator.validate(chart)
                self.environment.sessionStore.currentChart = chart
                self.environment.sessionStore.currentChartURL = url
                self.engine.load(chart: chart)
                self.statusLabel.stringValue = issues.isEmpty ? "Chart: \(chart.title)" : issues.map(\.message).joined(separator: " • ")
                self.environment.recentProjectsStore.add(chartURL: url, audioURL: self.environment.sessionStore.currentAudioURL)
                self.updateMismatchWarning()
            } catch {
                self.statusLabel.stringValue = error.localizedDescription
            }
        }
    }

    @objc private func togglePlay() {
        do {
            if environment.audioPlaybackService.isPlaying {
                environment.audioPlaybackService.pause()
            } else {
                try environment.audioPlaybackService.play()
            }
        } catch {
            statusLabel.stringValue = error.localizedDescription
        }
    }

    @objc private func pause() {
        environment.audioPlaybackService.pause()
    }

    @objc private func restart() {
        do {
            engine.resetState()
            try environment.audioPlaybackService.seek(to: 0)
            try environment.audioPlaybackService.play(from: 0)
        } catch {
            statusLabel.stringValue = error.localizedDescription
        }
    }

    @objc private func speedUp() {
        engine.speed += 0.5
    }

    @objc private func speedDown() {
        engine.speed -= 0.5
    }

    private func handleKey(_ event: NSEvent) {
        guard let action = environment.inputManager.resolveAction(for: event) else { return }
        switch action {
        case .lane(let lane):
            let judgement = engine.handleInput(lane: lane)
            statusLabel.stringValue = judgement.rawValue
        case .speedUp:
            speedUp()
        case .speedDown:
            speedDown()
        case .togglePause:
            togglePlay()
        }
    }

    private func handleKeyUp(_ event: NSEvent) {
        guard let action = environment.inputManager.resolveAction(for: event) else { return }
        if case .lane(let lane) = action, let judgement = engine.handleRelease(lane: lane) {
            statusLabel.stringValue = "LONG \(judgement.rawValue)"
        }
    }

    @objc private func handleSessionChartChange() {
        let chart = environment.sessionStore.currentChart
        guard chart != .empty else { return }
        engine.load(chart: chart)
        updateMismatchWarning()
        statusLabel.stringValue = "Chart synced: \(chart.title)"
    }

    @objc private func handleSessionAudioChange() {
        guard let url = environment.sessionStore.currentAudioURL else { return }
        try? environment.audioPlaybackService.load(url: url)
        updateMismatchWarning()
        statusLabel.stringValue = "Audio synced: \(url.lastPathComponent)"
    }

    @objc private func handlePreferencesChange() {
        let preferences = environment.preferencesStore.load()
        environment.audioPlaybackService.setVolume(preferences.volume)
        playfieldView.judgementLineRatio = preferences.judgementLineRatio
        playfieldView.needsDisplay = true
    }

    private func presentResultWindow() {
        environment.audioPlaybackService.pause()
        let resultViewController = ResultViewController(scoreState: engine.scoreState, rank: engine.rank()) { [weak self] in
            self?.restart()
        }
        let window = NSWindow(contentViewController: resultViewController)
        window.title = "Result"
        window.setContentSize(NSSize(width: 340, height: 360))
        let controller = NSWindowController(window: window)
        controller.showWindow(nil)
        resultWindowController = controller
        NotificationCenter.default.addObserver(forName: NSWindow.willCloseNotification, object: window, queue: .main) { [weak self] _ in
            self?.resultWindowController = nil
        }
    }

    private func updateMismatchWarning() {
        guard !environment.sessionStore.currentChart.audioFileName.isEmpty else {
            mismatchLabel.stringValue = environment.sessionStore.currentAudioURL == nil ? "채보에 연결된 오디오가 없습니다. 오디오를 선택해 주세요." : ""
            return
        }
        guard let audioURL = environment.sessionStore.currentAudioURL else {
            mismatchLabel.stringValue = "채보는 \(environment.sessionStore.currentChart.audioFileName)을 기대하지만 현재 연결된 오디오가 없습니다."
            return
        }
        mismatchLabel.stringValue = audioURL.lastPathComponent == environment.sessionStore.currentChart.audioFileName
            ? ""
            : "현재 오디오(\(audioURL.lastPathComponent))와 채보 오디오(\(environment.sessionStore.currentChart.audioFileName))가 다릅니다."
    }

    private func persistChartAudioLinkStatus(audioURL: URL) -> String {
        guard environment.sessionStore.currentChart != .empty else {
            return "Audio: \(audioURL.lastPathComponent)"
        }
        do {
            try environment.persistCurrentChart()
            return "차트에 오디오 파일명을 저장했습니다: \(audioURL.lastPathComponent)"
        } catch {
            return error.localizedDescription
        }
    }
}

private final class PlayfieldView: NSView {
    weak var engine: GameEngine?
    var judgementLineRatio: Double = 0.85

    override var acceptsFirstResponder: Bool { true }

    override func draw(_ dirtyRect: NSRect) {
        RRColor.elevatedBackground.setFill()
        dirtyRect.fill()

        let laneWidth = dirtyRect.width / 4
        RRColor.border.setStroke()
        for lane in 1..<4 {
            let x = CGFloat(lane) * laneWidth
            let path = NSBezierPath()
            path.move(to: NSPoint(x: x, y: 0))
            path.line(to: NSPoint(x: x, y: dirtyRect.height))
            path.stroke()
        }

        let judgementY = dirtyRect.height * CGFloat(min(max(judgementLineRatio, 0.1), 0.95))
        RRColor.accentBlue.setStroke()
        let line = NSBezierPath()
        line.move(to: NSPoint(x: 0, y: judgementY))
        line.line(to: NSPoint(x: dirtyRect.width, y: judgementY))
        line.lineWidth = 2
        line.stroke()

        engine?.visibleNotes().forEach { visible in
            let y = dirtyRect.height * CGFloat(visible.normalizedY)
            let height = dirtyRect.height * CGFloat(visible.normalizedHeight)
            NoteRenderer.draw(note: visible.note, rect: dirtyRect, in: laneWidth, yPosition: y, noteHeight: height)
        }
    }
}

private final class PlayerContainerView: NSView {
    var keyDownHandler: ((NSEvent) -> Void)?
    var keyUpHandler: ((NSEvent) -> Void)?

    override var acceptsFirstResponder: Bool { true }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        window?.makeFirstResponder(self)
    }

    override func keyDown(with event: NSEvent) {
        keyDownHandler?(event)
    }

    override func keyUp(with event: NSEvent) {
        keyUpHandler?(event)
    }
}
