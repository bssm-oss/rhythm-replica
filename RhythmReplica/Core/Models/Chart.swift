import Foundation

public enum NoteType: String, Codable, CaseIterable {
    case normal
    case long
    case specialLeft
    case specialRight
}

public struct Note: Codable, Hashable, Identifiable {
    public var id: UUID
    public var beat: Double
    public var lane: Int
    public var type: NoteType
    public var durationBeats: Double

    public init(id: UUID = UUID(), beat: Double, lane: Int, type: NoteType, durationBeats: Double = 0) {
        self.id = id
        self.beat = beat
        self.lane = lane
        self.type = type
        self.durationBeats = durationBeats
    }

    public var endBeat: Double {
        beat + max(durationBeats, 0)
    }
}

public struct Chart: Codable, Hashable {
    public var schemaVersion: Int
    public var title: String
    public var artist: String
    public var audioFileName: String
    public var bpm: Double
    public var totalBeats: Double
    public var offset: Double
    public var difficulty: String
    public var notes: [Note]

    public init(schemaVersion: Int, title: String, artist: String, audioFileName: String, bpm: Double, totalBeats: Double, offset: Double, difficulty: String, notes: [Note]) {
        self.schemaVersion = schemaVersion
        self.title = title
        self.artist = artist
        self.audioFileName = audioFileName
        self.bpm = bpm
        self.totalBeats = totalBeats
        self.offset = offset
        self.difficulty = difficulty
        self.notes = notes
    }

    public static let empty = Chart(
        schemaVersion: 1,
        title: "Untitled",
        artist: "Unknown",
        audioFileName: "",
        bpm: 120,
        totalBeats: 64,
        offset: 0,
        difficulty: "Normal",
        notes: []
    )
}

extension Notification.Name {
    static let sessionChartDidChange = Notification.Name("RhythmReplica.sessionChartDidChange")
    static let sessionAudioDidChange = Notification.Name("RhythmReplica.sessionAudioDidChange")
}

public final class SessionStore {
    var currentChart: Chart = .empty {
        didSet {
            NotificationCenter.default.post(name: .sessionChartDidChange, object: self)
        }
    }
    var currentAudioURL: URL? {
        didSet {
            NotificationCenter.default.post(name: .sessionAudioDidChange, object: self)
        }
    }
    var currentChartURL: URL?
}
