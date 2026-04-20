import AppKit
import UniformTypeIdentifiers

final class EditorViewController: NSViewController, NSWindowDelegate {
    private let environment: AppEnvironment
    private let timelineView = EditorTimelineView(frame: .zero)
    private let waveformView = WaveformView(frame: .zero)
    private let miniMapView = TimelineMiniMapView(frame: .zero)
    private let statusLabel = NSTextField(labelWithString: "No chart loaded")
    private let chartInfoLabel = NSTextField(labelWithString: "TOTAL NOTES 0 • NORMAL 0 • LONG 0 • SPECIAL 0 • DENSITY 0")
    private let bpmField = NSTextField(string: "120")
    private let totalBeatsField = NSTextField(string: "64")
    private let offsetField = NSTextField(string: "0.0")
    private let snapControl = NSSegmentedControl(labels: ["1/1", "1/2", "1/4", "1/8", "1/16", "1/3", "1/6"], trackingMode: .selectOne, target: nil, action: nil)
    private let modeControl = NSSegmentedControl(labels: ["Q", "W", "E", "R", "T"], trackingMode: .selectOne, target: nil, action: nil)
    private let lanePopup = NSPopUpButton(frame: .zero, pullsDown: false)
    private let noteTypePopup = NSPopUpButton(frame: .zero, pullsDown: false)
    private let zoomSlider = NSSlider(value: 1.0, minValue: 0.5, maxValue: 4.0, target: nil, action: nil)
    private var chart = Chart.empty
    private var playbackTimer: Timer?
    private var clipboardNotes: [Note] = []
    private var undoStack: [Chart] = []
    private var redoStack: [Chart] = []
    private var hasUnsavedChanges = false

    init(environment: AppEnvironment) {
        self.environment = environment
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        nil
    }

    override func loadView() {
        view = EditorContainerView()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.wantsLayer = true
        view.layer?.backgroundColor = RRColor.baseBackground.cgColor

        [statusLabel, chartInfoLabel].forEach {
            $0.textColor = RRColor.primaryText
            $0.font = RRTypography.body()
        }

        snapControl.selectedSegment = 2
        modeControl.selectedSegment = 0
        lanePopup.addItems(withTitles: ["Lane 1", "Lane 2", "Lane 3", "Lane 4"])
        noteTypePopup.addItems(withTitles: EditorTimelineView.PlacementKind.allCases.map(\.rawValue))
        zoomSlider.target = self
        zoomSlider.action = #selector(updateZoom)
        noteTypePopup.target = self
        noteTypePopup.action = #selector(updatePlacementKind)
        snapControl.target = self
        snapControl.action = #selector(updateSnap)
        modeControl.target = self
        modeControl.action = #selector(updateMode)

        timelineView.applyCardStyle()
        waveformView.applyCardStyle()
        miniMapView.applyCardStyle()
        timelineView.chart = chart
        miniMapView.chart = chart
        timelineView.onChartWillChange = { [weak self] chart in
            self?.undoStack.append(chart)
            self?.redoStack.removeAll()
        }
        timelineView.onChartChanged = { [weak self] chart in
            self?.chart = chart
            self?.updateChartInfo()
            self?.autosaveCurrentChart()
            self?.miniMapView.chart = chart
            self?.hasUnsavedChanges = true
        }
        timelineView.onSeek = { [weak self] beat in
            guard let self else { return }
            let time = TimingConverter.time(forBeat: beat, bpm: self.chart.bpm, offset: self.chart.offset)
            try? self.environment.audioPlaybackService.seek(to: time)
            self.statusLabel.stringValue = String(format: "Seek to beat %.2f", beat)
        }

        let loadButton = NSButton(title: "Load JSON", target: self, action: #selector(loadChart))
        let saveButton = NSButton(title: "Save JSON", target: self, action: #selector(saveChart))
        let sampleButton = NSButton(title: "Load Sample", target: self, action: #selector(loadSample))
        let openAudioButton = NSButton(title: "Open Audio", target: self, action: #selector(openAudio))
        let previewAudioButton = NSButton(title: "Play/Pause Audio", target: self, action: #selector(toggleAudioPreview))
        let stampButton = NSButton(title: "Stamp @ Playhead", target: self, action: #selector(stampAtPlayhead))
        let undoButton = NSButton(title: "Undo", target: self, action: #selector(undoChange))
        let redoButton = NSButton(title: "Redo", target: self, action: #selector(redoChange))
        let copyButton = NSButton(title: "Copy", target: self, action: #selector(copySelection))
        let pasteButton = NSButton(title: "Paste", target: self, action: #selector(pasteSelection))
        let selectAllButton = NSButton(title: "Select All", target: self, action: #selector(selectAllNotes))
        let deleteButton = NSButton(title: "Delete", target: self, action: #selector(deleteSelection))
        let helpButton = NSButton(title: "Shortcut Help", target: self, action: #selector(showShortcutHelp))
        let testPlayButton = NSButton(title: "Test Play", target: self, action: #selector(testPlay))

        let metadataStack = NSStackView(views: [labeledField("BPM", field: bpmField), labeledField("TOTAL BEATS", field: totalBeatsField), labeledField("OFFSET", field: offsetField), labeledView("SNAP", snapControl), labeledView("MODE", modeControl), labeledView("NOTE TYPE", noteTypePopup), labeledView("STAMP LANE", lanePopup), labeledView("ZOOM", zoomSlider), loadButton, saveButton, sampleButton, openAudioButton, previewAudioButton, stampButton, undoButton, redoButton, copyButton, pasteButton, selectAllButton, deleteButton, helpButton, testPlayButton])
        metadataStack.orientation = .horizontal
        metadataStack.spacing = 8

        let stack = NSStackView(views: [metadataStack, statusLabel, chartInfoLabel, waveformView, miniMapView, timelineView])
        stack.orientation = .vertical
        stack.spacing = 12
        stack.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: view.topAnchor, constant: 16),
            stack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            stack.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -16),
            waveformView.heightAnchor.constraint(equalToConstant: 120),
            miniMapView.heightAnchor.constraint(equalToConstant: 80),
            timelineView.heightAnchor.constraint(equalToConstant: 520)
        ])
        updateChartInfo()
        startPlaybackTimer()
        if let url = environment.sessionStore.currentAudioURL {
            loadWaveform(for: url)
        }
        view.setAccessibilityLabel("Chart editor screen")
        timelineView.setAccessibilityLabel("Chart timeline")
        waveformView.setAccessibilityLabel("Audio waveform")
        miniMapView.setAccessibilityLabel("Timeline minimap")
        NotificationCenter.default.addObserver(self, selector: #selector(handleSessionAudioChange), name: .sessionAudioDidChange, object: environment.sessionStore)
        NotificationCenter.default.addObserver(self, selector: #selector(handleSessionChartChange), name: .sessionChartDidChange, object: environment.sessionStore)
        (view as? EditorContainerView)?.keyDownHandler = { [weak self] event in
            self?.handleKey(event)
        }
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    private func startPlaybackTimer() {
        playbackTimer?.invalidate()
        playbackTimer = Timer.scheduledTimer(withTimeInterval: 1.0 / 15.0, repeats: true) { [weak self] _ in
            guard let self else { return }
            let time = self.environment.audioPlaybackService.currentTime
            let beat = TimingConverter.beat(forTime: time, bpm: self.chart.bpm, offset: self.chart.offset)
            self.timelineView.playbackBeat = beat
            self.miniMapView.playbackBeat = beat
        }
    }

    @objc private func updateSnap() {
        let options: [Double] = [1, 2, 4, 8, 16, 3, 6]
        timelineView.snapDivisor = options[snapControl.selectedSegment]
        timelineView.needsDisplay = true
    }

    @objc private func updateZoom() {
        timelineView.zoomScale = zoomSlider.doubleValue
    }

    @objc private func updateMode() {
        let modes: [EditorMode] = [.normal, .long, .delete, .edit, .select]
        timelineView.mode = modes[modeControl.selectedSegment]
        statusLabel.stringValue = "Mode: \(timelineView.mode.rawValue)"
    }

    @objc private func updatePlacementKind() {
        let kinds = EditorTimelineView.PlacementKind.allCases
        timelineView.placementKind = kinds[noteTypePopup.indexOfSelectedItem]
    }

    @objc private func loadChart() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.json]
        panel.beginSheetModal(for: view.window!) { [weak self] response in
            guard response == .OK, let url = panel.url, let self else { return }
            do {
                self.chart = try self.environment.chartLoader.load(from: url)
                self.environment.sessionStore.currentChart = self.chart
                self.environment.sessionStore.currentChartURL = url
                self.timelineView.chart = self.chart
                self.populateMetadataFields()
                self.updateChartInfo()
                self.miniMapView.chart = self.chart
                self.statusLabel.stringValue = "Loaded \(url.lastPathComponent)"
                self.hasUnsavedChanges = false
            } catch {
                self.statusLabel.stringValue = error.localizedDescription
            }
        }
    }

    @objc private func saveChart() {
        applyMetadataFields()
        let panel = NSSavePanel()
        panel.nameFieldStringValue = "chart.rrchart.json"
        panel.beginSheetModal(for: view.window!) { [weak self] response in
            guard response == .OK, let url = panel.url, let self else { return }
            do {
                let data = try self.environment.chartExporter.exportInternal(self.chart)
                try data.write(to: url)
                self.environment.sessionStore.currentChartURL = url
                self.statusLabel.stringValue = "Saved \(url.lastPathComponent)"
                self.hasUnsavedChanges = false
            } catch {
                self.statusLabel.stringValue = error.localizedDescription
            }
        }
    }

    @objc private func loadSample() {
        guard let url = Bundle.main.url(forResource: "sample-chart.rrchart", withExtension: "json", subdirectory: "SampleCharts") else {
            statusLabel.stringValue = "Sample chart not found"
            return
        }
        do {
            chart = try environment.chartLoader.load(from: url)
            timelineView.chart = chart
            miniMapView.chart = chart
            populateMetadataFields()
            updateChartInfo()
            statusLabel.stringValue = "Loaded bundled sample chart"
            hasUnsavedChanges = false
        } catch {
            statusLabel.stringValue = error.localizedDescription
        }
    }

    @objc private func testPlay() {
        applyMetadataFields()
        environment.sessionStore.currentChart = chart
        NotificationCenter.default.post(name: .navigateToTab, object: self, userInfo: ["tab": "Player"])
        statusLabel.stringValue = "현재 차트로 Player 탭을 열었습니다."
    }

    @objc private func handleSessionAudioChange() {
        guard let url = environment.sessionStore.currentAudioURL else { return }
        loadWaveform(for: url)
    }

    @objc private func handleSessionChartChange() {
        chart = environment.sessionStore.currentChart
        timelineView.chart = chart
        miniMapView.chart = chart
        populateMetadataFields()
        updateChartInfo()
    }

    private func updateChartInfo() {
        let normal = chart.notes.filter { $0.type == .normal }.count
        let long = chart.notes.filter { $0.type == .long }.count
        let special = chart.notes.filter { $0.type == .specialLeft || $0.type == .specialRight }.count
        let density = chart.totalBeats > 0 ? Double(chart.notes.count) / (chart.totalBeats / max(chart.bpm / 60, 0.001)) : 0
        chartInfoLabel.stringValue = String(format: "TOTAL NOTES %d • NORMAL %d • LONG %d • SPECIAL %d • DENSITY %.2f NPS", chart.notes.count, normal, long, special, density)
    }

    private func populateMetadataFields() {
        bpmField.stringValue = String(format: "%.2f", chart.bpm)
        totalBeatsField.stringValue = String(format: "%.2f", chart.totalBeats)
        offsetField.stringValue = String(format: "%.2f", chart.offset)
    }

    private func applyMetadataFields() {
        chart.bpm = Double(bpmField.stringValue) ?? chart.bpm
        chart.totalBeats = Double(totalBeatsField.stringValue) ?? chart.totalBeats
        chart.offset = Double(offsetField.stringValue) ?? chart.offset
        timelineView.chart = chart
        let issues = environment.chartValidator.validate(chart)
        statusLabel.stringValue = issues.isEmpty ? "Chart metadata updated" : issues.map(\.message).joined(separator: " • ")
        autosaveCurrentChart()
    }

    @objc private func stampAtPlayhead() {
        let lane = lanePopup.indexOfSelectedItem
        let beat = timelineView.playbackBeat
        timelineView.stampNote(at: beat, lane: lane, mode: timelineView.mode)
        statusLabel.stringValue = String(format: "Stamped note at beat %.2f lane %d", beat, lane + 1)
    }

    @objc private func undoChange() {
        guard let previous = undoStack.popLast() else { return }
        redoStack.append(chart)
        chart = previous
        timelineView.chart = chart
        miniMapView.chart = chart
        updateChartInfo()
        statusLabel.stringValue = "Undo applied"
    }

    @objc private func redoChange() {
        guard let next = redoStack.popLast() else { return }
        undoStack.append(chart)
        chart = next
        timelineView.chart = chart
        miniMapView.chart = chart
        updateChartInfo()
        statusLabel.stringValue = "Redo applied"
    }

    @objc private func copySelection() {
        clipboardNotes = timelineView.selectedNotes()
        statusLabel.stringValue = clipboardNotes.isEmpty ? "선택된 노트가 없습니다." : "\(clipboardNotes.count)개 노트를 복사했습니다."
    }

    @objc private func pasteSelection() {
        let beat = timelineView.playbackBeat
        timelineView.paste(notes: clipboardNotes, at: beat)
        statusLabel.stringValue = clipboardNotes.isEmpty ? "붙여넣을 노트가 없습니다." : "현재 재생 위치에 붙여넣었습니다."
    }

    @objc private func selectAllNotes() {
        timelineView.selectAllNotes()
        statusLabel.stringValue = "모든 노트를 선택했습니다."
    }

    @objc private func deleteSelection() {
        timelineView.deleteSelectedNotes()
        statusLabel.stringValue = "선택 노트를 삭제했습니다."
    }

    @objc private func showShortcutHelp() {
        let alert = NSAlert()
        alert.messageText = "Editor Shortcuts"
        alert.informativeText = "Q Normal\nW Long\nE Delete\nR Edit\nT Select\nSpace Play/Pause\n⌘Z Undo\n⌘⇧Z / ⌘Y Redo\n⌘C Copy\n⌘V Paste\n⌘A Select All\nDelete 선택 삭제\nShift+Click Seek\n1~5 Snap 변경"
        alert.addButton(withTitle: "확인")
        alert.beginSheetModal(for: view.window!) { _ in }
    }

    @objc private func openAudio() {
        let panel = NSOpenPanel()
        panel.beginSheetModal(for: view.window!) { [weak self] response in
            guard response == .OK, let url = panel.url, let self else { return }
            self.environment.sessionStore.currentAudioURL = url
            if self.chart != .empty {
                self.chart.audioFileName = url.lastPathComponent
                self.environment.sessionStore.currentChart = self.chart
            }
            do {
                try self.environment.audioPlaybackService.load(url: url)
                self.loadWaveform(for: url)
                self.statusLabel.stringValue = "Audio linked: \(url.lastPathComponent)"
                self.environment.recentProjectsStore.add(chartURL: self.environment.sessionStore.currentChartURL, audioURL: url)
            } catch {
                self.statusLabel.stringValue = error.localizedDescription
            }
        }
    }

    @objc private func toggleAudioPreview() {
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

    private func loadWaveform(for url: URL) {
        environment.waveformExtractor.extractSamples(from: url) { [weak self] samples in
            self?.waveformView.samples = samples
        }
    }

    private func autosaveCurrentChart() {
        let autosaveDirectory = environment.cacheManager.cacheDirectoryURL.appendingPathComponent("Autosave", isDirectory: true)
        try? FileManager.default.createDirectory(at: autosaveDirectory, withIntermediateDirectories: true)
        let autosaveURL = autosaveDirectory.appendingPathComponent("latest.rrchart.json")
        if let data = try? environment.chartExporter.exportInternal(chart) {
            try? data.write(to: autosaveURL)
        }
    }

    override func viewDidAppear() {
        super.viewDidAppear()
        view.window?.delegate = self
    }

    func windowShouldClose(_ sender: NSWindow) -> Bool {
        guard hasUnsavedChanges else { return true }
        let alert = NSAlert()
        alert.messageText = "저장되지 않은 변경 사항이 있습니다"
        alert.informativeText = "창을 닫으면 저장되지 않은 변경 사항이 사라집니다. 계속하시겠습니까?"
        alert.addButton(withTitle: "닫기")
        alert.addButton(withTitle: "취소")
        return alert.runModal() == .alertFirstButtonReturn
    }

    private func handleKey(_ event: NSEvent) {
        if event.modifierFlags.contains(.command), let key = event.charactersIgnoringModifiers?.lowercased() {
            switch key {
            case "z" where event.modifierFlags.contains(.shift): redoChange()
            case "z": undoChange()
            case "y": redoChange()
            case "c": copySelection()
            case "v": pasteSelection()
            case "a": selectAllNotes()
            default: break
            }
            return
        }

        switch event.keyCode {
        case 49: toggleAudioPreview()
        case 51, 117: deleteSelection()
        default:
            guard let key = event.charactersIgnoringModifiers?.lowercased() else { return }
            switch key {
            case "q": modeControl.selectedSegment = 0; updateMode()
            case "w": modeControl.selectedSegment = 1; updateMode()
            case "e": modeControl.selectedSegment = 2; updateMode()
            case "r": modeControl.selectedSegment = 3; updateMode()
            case "t": modeControl.selectedSegment = 4; updateMode()
            case "1": snapControl.selectedSegment = 0; updateSnap()
            case "2": snapControl.selectedSegment = 1; updateSnap()
            case "3": snapControl.selectedSegment = 2; updateSnap()
            case "4": snapControl.selectedSegment = 3; updateSnap()
            case "5": snapControl.selectedSegment = 4; updateSnap()
            default: break
            }
        }
    }

    private func labeledField(_ title: String, field: NSTextField) -> NSView {
        let label = NSTextField(labelWithString: title)
        label.textColor = RRColor.primaryText
        label.font = RRTypography.caption()
        let stack = NSStackView(views: [label, field])
        stack.orientation = .vertical
        stack.spacing = 4
        return stack
    }

    private func labeledView(_ title: String, _ view: NSView) -> NSView {
        let label = NSTextField(labelWithString: title)
        label.textColor = RRColor.primaryText
        label.font = RRTypography.caption()
        let stack = NSStackView(views: [label, view])
        stack.orientation = .vertical
        stack.spacing = 4
        return stack
    }
}

private final class EditorContainerView: NSView {
    var keyDownHandler: ((NSEvent) -> Void)?

    override var acceptsFirstResponder: Bool { true }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        window?.makeFirstResponder(self)
    }

    override func keyDown(with event: NSEvent) {
        keyDownHandler?(event)
    }
}
