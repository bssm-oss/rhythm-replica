import AppKit

final class ResultViewController: NSViewController {
    private let scoreState: ScoreState
    private let rank: String
    private let retryHandler: () -> Void

    init(scoreState: ScoreState, rank: String, retryHandler: @escaping () -> Void) {
        self.scoreState = scoreState
        self.rank = rank
        self.retryHandler = retryHandler
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

        let labels = [
            "RANK \(rank)",
            "SCORE \(scoreState.score)",
            "MAX COMBO \(scoreState.maxCombo)",
            "PERFECT \(scoreState.counts[.perfect] ?? 0)",
            "GOOD \(scoreState.counts[.good] ?? 0)",
            "BAD \(scoreState.counts[.bad] ?? 0)",
            "MISS \(scoreState.counts[.miss] ?? 0)",
            "ACCURACY \(Int(scoreState.accuracy * 100))%"
        ].map {
            let label = NSTextField(labelWithString: $0)
            label.font = RRTypography.section()
            label.textColor = RRColor.primaryText
            return label
        }

        let retryButton = NSButton(title: "Retry", target: self, action: #selector(retry))
        let stack = NSStackView(views: labels + [retryButton])
        stack.orientation = .vertical
        stack.spacing = 12
        stack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            stack.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }

    @objc private func retry() {
        retryHandler()
        view.window?.close()
    }
}
