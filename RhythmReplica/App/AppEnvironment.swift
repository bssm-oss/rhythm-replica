import Foundation

final class AppEnvironment {
    let preferencesStore: PreferencesStore
    let recentProjectsStore: RecentProjectsStore
    let cacheManager: CacheManager
    let keyBindingManager: KeyBindingManager
    let chartLoader: ChartLoader
    let chartExporter: ChartExporter
    let chartValidator: ChartValidator
    let audioPlaybackService: AudioPlaybackService
    let waveformExtractor: WaveformExtractor
    let externalToolDetector: ExternalToolDetector
    let youtubeImportService: YouTubeImportService
    let inputManager: InputManager
    let sessionStore: SessionStore

    init(
        preferencesStore: PreferencesStore,
        recentProjectsStore: RecentProjectsStore,
        cacheManager: CacheManager,
        keyBindingManager: KeyBindingManager,
        chartLoader: ChartLoader,
        chartExporter: ChartExporter,
        chartValidator: ChartValidator,
        audioPlaybackService: AudioPlaybackService,
        waveformExtractor: WaveformExtractor,
        externalToolDetector: ExternalToolDetector,
        youtubeImportService: YouTubeImportService,
        inputManager: InputManager,
        sessionStore: SessionStore
    ) {
        self.preferencesStore = preferencesStore
        self.recentProjectsStore = recentProjectsStore
        self.cacheManager = cacheManager
        self.keyBindingManager = keyBindingManager
        self.chartLoader = chartLoader
        self.chartExporter = chartExporter
        self.chartValidator = chartValidator
        self.audioPlaybackService = audioPlaybackService
        self.waveformExtractor = waveformExtractor
        self.externalToolDetector = externalToolDetector
        self.youtubeImportService = youtubeImportService
        self.inputManager = inputManager
        self.sessionStore = sessionStore
    }

    static func live() -> AppEnvironment {
        let preferencesStore = PreferencesStore()
        let cacheManager = CacheManager(fileManager: .default)
        let sessionStore = SessionStore()
        let externalToolDetector = ExternalToolDetector()
        let keyBindingManager = KeyBindingManager(preferencesStore: preferencesStore)
        return AppEnvironment(
            preferencesStore: preferencesStore,
            recentProjectsStore: RecentProjectsStore(defaults: .standard),
            cacheManager: cacheManager,
            keyBindingManager: keyBindingManager,
            chartLoader: ChartLoader(),
            chartExporter: ChartExporter(),
            chartValidator: ChartValidator(),
            audioPlaybackService: AudioPlaybackService(),
            waveformExtractor: WaveformExtractor(),
            externalToolDetector: externalToolDetector,
            youtubeImportService: YouTubeImportService(detector: externalToolDetector, cacheManager: cacheManager),
            inputManager: InputManager(keyBindingManager: keyBindingManager),
            sessionStore: sessionStore
        )
    }
}
