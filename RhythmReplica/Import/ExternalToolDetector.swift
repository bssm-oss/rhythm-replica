import Foundation

struct ExternalToolDetectionResult {
    let ytDlpPath: URL?
    let ffmpegPath: URL?
}

final class ExternalToolDetector {
    private let fileManager = FileManager.default
    private let candidates = [
        "/opt/homebrew/bin",
        "/usr/local/bin",
        "/usr/bin"
    ]

    func detect() -> ExternalToolDetectionResult {
        ExternalToolDetectionResult(
            ytDlpPath: executable(named: "yt-dlp"),
            ffmpegPath: executable(named: "ffmpeg")
        )
    }

    private func executable(named name: String) -> URL? {
        for directory in candidates {
            let path = URL(fileURLWithPath: directory).appendingPathComponent(name).path
            if fileManager.isExecutableFile(atPath: path) {
                return URL(fileURLWithPath: path)
            }
        }
        return nil
    }
}
