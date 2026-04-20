import Foundation

struct YouTubeMetadata: Decodable {
    let title: String?
    let duration: Double?
    let thumbnail: String?
}

final class YouTubeImportTask {
    private let process: Process
    private let outputPipe: Pipe
    private let errorPipe: Pipe
    var onProgress: ((String) -> Void)?
    var onCompletion: ((Result<URL, Error>) -> Void)?

    init(process: Process, outputPipe: Pipe, errorPipe: Pipe) {
        self.process = process
        self.outputPipe = outputPipe
        self.errorPipe = errorPipe
    }

    func start() throws {
        outputPipe.fileHandleForReading.readabilityHandler = { [weak self] handle in
            let data = handle.availableData
            guard !data.isEmpty, let text = String(data: data, encoding: .utf8) else { return }
            DispatchQueue.main.async {
                self?.onProgress?(text.trimmingCharacters(in: .whitespacesAndNewlines))
            }
        }

        process.terminationHandler = { [weak self] process in
            guard let self else { return }
            let errorData = self.errorPipe.fileHandleForReading.readDataToEndOfFile()
            let errorText = String(data: errorData, encoding: .utf8) ?? ""
            DispatchQueue.main.async {
                if process.terminationStatus == 0,
                   let destination = process.arguments?.dropLast().last {
                    self.onCompletion?(.success(URL(fileURLWithPath: destination)))
                } else {
                    let message = errorText.isEmpty ? "YouTube 가져오기에 실패했습니다." : errorText
                    self.onCompletion?(.failure(NSError(domain: "YouTubeImportTask", code: Int(process.terminationStatus), userInfo: [NSLocalizedDescriptionKey: message])))
                }
            }
        }

        try process.run()
    }

    func cancel() {
        if process.isRunning {
            process.terminate()
        }
    }
}

final class YouTubeImportService {
    private let detector: ExternalToolDetector
    private let cacheManager: CacheManager

    init(detector: ExternalToolDetector, cacheManager: CacheManager) {
        self.detector = detector
        self.cacheManager = cacheManager
    }

    func legalNotice() -> String {
        "사용자가 권리를 가진 영상, 본인이 업로드한 영상, Creative Commons 등 사용이 허용된 영상만 가져오세요. 앱은 우회 기능을 제공하지 않으며, yt-dlp와 ffmpeg가 별도 설치되어 있을 때만 선택적으로 사용합니다."
    }

    func detectTools() -> ExternalToolDetectionResult {
        detector.detect()
    }

    func fetchMetadata(for url: String) throws -> YouTubeMetadata {
        let tools = detector.detect()
        guard let ytDlp = tools.ytDlpPath else {
            throw NSError(domain: "YouTubeImportService", code: 1, userInfo: [NSLocalizedDescriptionKey: "yt-dlp가 설치되어 있지 않습니다. Homebrew 설치 안내를 확인해 주세요."])
        }

        let process = Process()
        process.executableURL = ytDlp
        process.arguments = ["--dump-single-json", "--skip-download", url]
        let pipe = Pipe()
        process.standardOutput = pipe
        try process.run()
        process.waitUntilExit()
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        return try JSONDecoder().decode(YouTubeMetadata.self, from: data)
    }

    func defaultOutputDirectory() -> URL {
        let directory = cacheManager.cacheDirectoryURL.appendingPathComponent("ImportedAudio", isDirectory: true)
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory
    }

    func startImport(from url: String, destinationDirectory: URL? = nil) throws -> YouTubeImportTask {
        let tools = detector.detect()
        guard let ytDlp = tools.ytDlpPath else {
            throw NSError(domain: "YouTubeImportService", code: 2, userInfo: [NSLocalizedDescriptionKey: "yt-dlp가 설치되어 있지 않습니다. `brew install yt-dlp ffmpeg` 안내를 확인해 주세요."])
        }
        guard tools.ffmpegPath != nil else {
            throw NSError(domain: "YouTubeImportService", code: 3, userInfo: [NSLocalizedDescriptionKey: "ffmpeg가 설치되어 있지 않습니다. `brew install ffmpeg` 후 다시 시도해 주세요."])
        }

        let outputDirectory = destinationDirectory ?? defaultOutputDirectory()
        try FileManager.default.createDirectory(at: outputDirectory, withIntermediateDirectories: true)
        let outputTemplate = outputDirectory.appendingPathComponent("%(title)s.%(ext)s").path

        let process = Process()
        process.executableURL = ytDlp
        process.currentDirectoryURL = outputDirectory
        process.arguments = [
            "--newline",
            "--extract-audio",
            "--audio-format", "m4a",
            "--audio-quality", "0",
            "-o", outputTemplate,
            url,
            outputDirectory.path
        ]
        let outputPipe = Pipe()
        let errorPipe = Pipe()
        process.standardOutput = outputPipe
        process.standardError = errorPipe
        return YouTubeImportTask(process: process, outputPipe: outputPipe, errorPipe: errorPipe)
    }
}
