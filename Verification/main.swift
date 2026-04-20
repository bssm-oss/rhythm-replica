import Foundation
import RhythmReplicaKit

struct SelfCheckFailure: Error {
    let message: String
}

@discardableResult
func expect(_ condition: @autoclosure () -> Bool, _ message: String) throws -> Bool {
    if !condition() {
        throw SelfCheckFailure(message: message)
    }
    return true
}

func runChecks() throws {
    let beat = TimingConverter.beat(forTime: 2.5, bpm: 120, offset: 0.5)
    try expect(abs(TimingConverter.time(forBeat: beat, bpm: 120, offset: 0.5) - 2.5) < 0.0001, "Timing round-trip failed")

    let chart = Chart(
        schemaVersion: 1,
        title: "Test",
        artist: "Test",
        audioFileName: "song.m4a",
        bpm: 120,
        totalBeats: 8,
        offset: 0,
        difficulty: "Hard",
        notes: [
            Note(beat: 1, lane: 0, type: .long, durationBeats: 2),
            Note(beat: 2, lane: 0, type: .long, durationBeats: 2),
            Note(beat: 10, lane: 1, type: .normal)
        ]
    )
    let issues = ChartValidator().validate(chart)
    try expect(issues.contains { $0.message.contains("겹") }, "Expected long note overlap issue")
    try expect(issues.contains { $0.message.contains("초과") }, "Expected totalBeats overflow issue")

    let judgementEngine = JudgementEngine()
    try expect(judgementEngine.judgement(for: 0.05) == .perfect, "Perfect window failed")
    try expect(judgementEngine.judgement(for: 0.10) == .good, "Good window failed")
    try expect(judgementEngine.judgement(for: 0.17) == .bad, "Bad window failed")
    try expect(judgementEngine.judgement(for: 0.25) == .miss, "Miss window failed")

    var score = ScoreState()
    ScoreCalculator.apply(.perfect, to: &score)
    ScoreCalculator.apply(.good, to: &score)
    ScoreCalculator.apply(.bad, to: &score)
    try expect(score.score == 1600, "Score calculation failed")
    try expect(score.maxCombo == 2, "Max combo calculation failed")
    try expect(score.hp == 95, "HP calculation failed")

    let fixture = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
        .appendingPathComponent("RhythmReplicaTests")
        .appendingPathComponent("Fixtures")
        .appendingPathComponent("lumina-sample.json")
    let data = try Data(contentsOf: fixture)
    let importedChart = try ChartLoader().load(data: data, suggestedAudioFileName: "sample.m4a")
    try expect(importedChart.bpm == 60, "LUMINA import BPM preservation failed")
    try expect(importedChart.notes.count == 4, "LUMINA import note count failed")
    try expect(importedChart.notes[2].type == .specialLeft, "Special-left conversion failed")

    let exported = try ChartExporter().exportLumina(importedChart)
    let exportedString = String(decoding: exported, as: UTF8.self)
    try expect(exportedString.contains("special"), "LUMINA export missing special note")
    try expect(exportedString.contains("left"), "LUMINA export missing direction")
}

do {
    try runChecks()
    print("RhythmReplicaSelfCheck: PASS")
} catch {
    fputs("RhythmReplicaSelfCheck: FAIL - \(error)\n", stderr)
    exit(1)
}
