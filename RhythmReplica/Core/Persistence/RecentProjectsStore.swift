import Foundation

struct RecentProject: Codable, Equatable {
    let chartPath: String
    let audioPath: String
    let updatedAt: Date
}

final class RecentProjectsStore {
    private let defaults: UserDefaults
    private let key = "RhythmReplica.RecentProjects"

    init(defaults: UserDefaults) {
        self.defaults = defaults
    }

    func load() -> [RecentProject] {
        guard let data = defaults.data(forKey: key), let value = try? JSONDecoder().decode([RecentProject].self, from: data) else {
            return []
        }
        return value.sorted { $0.updatedAt > $1.updatedAt }
    }

    func add(chartURL: URL?, audioURL: URL?) {
        guard let chartURL, let audioURL else { return }
        var items = load().filter { $0.chartPath != chartURL.path || $0.audioPath != audioURL.path }
        items.insert(RecentProject(chartPath: chartURL.path, audioPath: audioURL.path, updatedAt: Date()), at: 0)
        items = Array(items.prefix(12))
        if let data = try? JSONEncoder().encode(items) {
            defaults.set(data, forKey: key)
        }
    }
}
