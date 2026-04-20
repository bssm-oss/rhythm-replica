import AppKit

final class YouTubeImportViewController: NSViewController {
    private let service: YouTubeImportService
    private let preferencesStore: PreferencesStore
    private let urlField = NSTextField(string: "")
    private let statusLabel = NSTextField(labelWithString: "")
    private let metadataLabel = NSTextField(wrappingLabelWithString: "")
    private let progressIndicator = NSProgressIndicator()
    private var currentTask: YouTubeImportTask?

    init(service: YouTubeImportService, preferencesStore: PreferencesStore) {
        self.service = service
        self.preferencesStore = preferencesStore
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

        let noticeLabel = NSTextField(wrappingLabelWithString: service.legalNotice())
        noticeLabel.textColor = RRColor.warning
        noticeLabel.font = RRTypography.body()

        let detection = service.detectTools()
        let toolLabel = NSTextField(wrappingLabelWithString: "yt-dlp: \(detection.ytDlpPath?.path ?? "없음")\nffmpeg: \(detection.ffmpegPath?.path ?? "없음")\n저장 위치: \(service.defaultOutputDirectory().path)")
        toolLabel.textColor = RRColor.secondaryText
        toolLabel.font = RRTypography.caption()

        urlField.placeholderString = "https://www.youtube.com/watch?v=..."

        let metadataButton = NSButton(title: "Fetch Metadata", target: self, action: #selector(fetchMetadata))
        let importButton = NSButton(title: "Start Import", target: self, action: #selector(startImport))
        let cancelButton = NSButton(title: "Cancel", target: self, action: #selector(cancelImport))

        progressIndicator.isIndeterminate = true
        progressIndicator.style = .bar
        progressIndicator.controlTint = .blueControlTint
        progressIndicator.isDisplayedWhenStopped = false

        [statusLabel, metadataLabel].forEach {
            $0.textColor = RRColor.primaryText
            $0.font = RRTypography.body()
        }

        let buttonRow = NSStackView(views: [metadataButton, importButton, cancelButton])
        buttonRow.orientation = .horizontal
        buttonRow.spacing = 8

        let stack = NSStackView(views: [noticeLabel, toolLabel, urlField, buttonRow, progressIndicator, metadataLabel, statusLabel])
        stack.orientation = .vertical
        stack.spacing = 12
        stack.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: view.topAnchor, constant: 16),
            stack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            stack.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -16),
            view.widthAnchor.constraint(equalToConstant: 540)
        ])
    }

    @objc private func fetchMetadata() {
        do {
            let metadata = try service.fetchMetadata(for: urlField.stringValue)
            metadataLabel.stringValue = "제목: \(metadata.title ?? "알 수 없음")\n길이: \(metadata.duration.map { String(format: "%.1f초", $0) } ?? "알 수 없음")\n썸네일: \(metadata.thumbnail ?? "없음")"
            statusLabel.stringValue = "메타데이터를 불러왔습니다."
        } catch {
            statusLabel.stringValue = error.localizedDescription
        }
    }

    @objc private func startImport() {
        do {
            let preferences = preferencesStore.load()
            let destination: URL?
            switch preferences.youtubeImportBehavior {
            case .cacheFolder:
                destination = nil
            case .askEveryTime:
                let panel = NSOpenPanel()
                panel.canChooseDirectories = true
                panel.canChooseFiles = false
                panel.allowsMultipleSelection = false
                guard panel.runModal() == .OK else {
                    statusLabel.stringValue = "가져오기 저장 위치 선택이 취소되었습니다."
                    return
                }
                destination = panel.url
            }
            let task = try service.startImport(from: urlField.stringValue, destinationDirectory: destination)
            currentTask = task
            progressIndicator.startAnimation(nil)
            statusLabel.stringValue = "가져오기를 시작했습니다."
            task.onProgress = { [weak self] line in
                self?.statusLabel.stringValue = line.isEmpty ? "진행 중..." : line
            }
            task.onCompletion = { [weak self] result in
                self?.progressIndicator.stopAnimation(nil)
                switch result {
                case .success(let url):
                    self?.statusLabel.stringValue = "가져오기 완료: \(url.lastPathComponent)"
                case .failure(let error):
                    self?.statusLabel.stringValue = error.localizedDescription
                }
                self?.currentTask = nil
            }
            try task.start()
        } catch {
            statusLabel.stringValue = error.localizedDescription
        }
    }

    @objc private func cancelImport() {
        currentTask?.cancel()
        progressIndicator.stopAnimation(nil)
        statusLabel.stringValue = "가져오기를 취소했습니다."
        currentTask = nil
    }
}
