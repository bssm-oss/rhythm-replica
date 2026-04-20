import Foundation

struct VisibleNote {
    let note: Note
    let normalizedY: Double
}

final class GameEngine {
    private let audioService: AudioPlaybackService
    private let judgementEngine: JudgementEngine
    private let preferencesStore: PreferencesStore
    private(set) var chart: Chart = .empty
    private(set) var scoreState = ScoreState()
    private var hitNotes: Set<UUID> = []
    private var activeLongNotes: [Int: (noteID: UUID, endTime: Double)] = [:]

    var speed: Double {
        didSet {
            speed = min(max(0.5, speed), 5.0)
        }
    }

    init(audioService: AudioPlaybackService, judgementEngine: JudgementEngine = .init(), preferencesStore: PreferencesStore) {
        self.audioService = audioService
        self.judgementEngine = judgementEngine
        self.preferencesStore = preferencesStore
        self.speed = preferencesStore.load().defaultSpeed
    }

    var currentTime: Double {
        audioService.currentTime - (preferencesStore.load().inputDelayMilliseconds / 1000)
    }

    func load(chart: Chart) {
        self.chart = chart
        resetState()
    }

    func resetState() {
        scoreState = ScoreState()
        hitNotes.removeAll()
        activeLongNotes.removeAll()
    }

    func visibleNotes(window: Double = 2.0) -> [VisibleNote] {
        chart.notes.compactMap { note in
            guard !hitNotes.contains(note.id) else { return nil }
            let noteTime = TimingConverter.time(forBeat: note.beat, bpm: chart.bpm, offset: chart.offset)
            let distance = noteTime - currentTime
            guard distance >= -0.2, distance <= window else { return nil }
            let normalizedY = 0.85 - (distance * 0.35 * speed)
            return VisibleNote(note: note, normalizedY: normalizedY)
        }
    }

    @discardableResult
    func handleInput(lane: Int) -> Judgement {
        updateMisses()

        if activeLongNotes[lane] != nil {
            return .miss
        }

        let pending = chart.notes
            .filter { !hitNotes.contains($0.id) }
            .sorted { $0.beat < $1.beat }

        let now = currentTime
        for note in pending {
            if !matches(lane: lane, note: note) { continue }
            let noteTime = TimingConverter.time(forBeat: note.beat, bpm: chart.bpm, offset: chart.offset)
            let judgement = judgementEngine.judgement(for: now - noteTime)
            if judgement != .miss {
                if note.type == .long {
                    activeLongNotes[lane] = (note.id, TimingConverter.time(forBeat: note.endBeat, bpm: chart.bpm, offset: chart.offset))
                } else {
                    hitNotes.insert(note.id)
                }
                ScoreCalculator.apply(judgement, to: &scoreState)
                return judgement
            }
            break
        }

        ScoreCalculator.apply(.miss, to: &scoreState)
        return .miss
    }

    func handleRelease(lane: Int) -> Judgement? {
        guard let active = activeLongNotes.removeValue(forKey: lane) else {
            return nil
        }
        let judgement = judgementEngine.judgement(for: currentTime - active.endTime)
        hitNotes.insert(active.noteID)
        ScoreCalculator.apply(judgement, to: &scoreState)
        return judgement
    }

    func updateMisses() {
        let now = currentTime
        for (lane, active) in activeLongNotes where now > active.endTime + judgementEngine.windows.bad {
            activeLongNotes.removeValue(forKey: lane)
            hitNotes.insert(active.noteID)
            ScoreCalculator.apply(.miss, to: &scoreState)
        }
        for note in chart.notes where !hitNotes.contains(note.id) {
            if activeLongNotes.values.contains(where: { $0.noteID == note.id }) {
                continue
            }
            let noteTime = TimingConverter.time(forBeat: note.beat, bpm: chart.bpm, offset: chart.offset)
            let judgement = judgementEngine.judgement(for: now - noteTime)
            if judgement == .miss, now > noteTime {
                hitNotes.insert(note.id)
                ScoreCalculator.apply(.miss, to: &scoreState)
            }
        }
    }

    func rank() -> String {
        let accuracy = scoreState.accuracy
        switch accuracy {
        case 0.98...: return "S"
        case 0.90...: return "A"
        case 0.80...: return "B"
        case 0.70...: return "C"
        default: return "D"
        }
    }

    private func matches(lane: Int, note: Note) -> Bool {
        switch note.type {
        case .normal, .long:
            return note.lane == lane
        case .specialLeft:
            return lane == 0 || lane == 1
        case .specialRight:
            return lane == 2 || lane == 3
        }
    }
}
