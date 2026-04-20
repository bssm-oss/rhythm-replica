import XCTest
@testable import RhythmReplica

final class CoreLogicTests: XCTestCase {
    func testTimingConverterRoundTrip() {
        let beat = TimingConverter.beat(forTime: 2.5, bpm: 120, offset: 0.5)
        XCTAssertEqual(TimingConverter.time(forBeat: beat, bpm: 120, offset: 0.5), 2.5, accuracy: 0.0001)
    }

    func testChartValidatorDetectsOverlapAndOutOfRange() {
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
        XCTAssertTrue(issues.contains { $0.message.contains("겹") })
        XCTAssertTrue(issues.contains { $0.message.contains("초과") })
    }

    func testJudgementWindowsMatchLuminaSpec() {
        let engine = JudgementEngine()
        XCTAssertEqual(engine.judgement(for: 0.05), .perfect)
        XCTAssertEqual(engine.judgement(for: 0.10), .good)
        XCTAssertEqual(engine.judgement(for: 0.17), .bad)
        XCTAssertEqual(engine.judgement(for: 0.25), .miss)
    }

    func testScoreCalculatorUpdatesComboAndHp() {
        var state = ScoreState()
        ScoreCalculator.apply(.perfect, to: &state)
        ScoreCalculator.apply(.good, to: &state)
        ScoreCalculator.apply(.bad, to: &state)

        XCTAssertEqual(state.score, 1600)
        XCTAssertEqual(state.maxCombo, 2)
        XCTAssertEqual(state.combo, 0)
        XCTAssertEqual(state.hp, 95)
    }

    func testChartLoaderConvertsLuminaFormat() throws {
        let fixture = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .appendingPathComponent("Fixtures")
            .appendingPathComponent("lumina-sample.json")
        let data = try Data(contentsOf: fixture)
        let chart = try ChartLoader().load(data: data, suggestedAudioFileName: "sample.m4a")

        XCTAssertEqual(chart.audioFileName, "sample.m4a")
        XCTAssertEqual(chart.notes.count, 4)
        XCTAssertEqual(chart.notes[0].type, .normal)
        XCTAssertEqual(chart.notes[1].type, .long)
        XCTAssertEqual(chart.notes[2].type, .specialLeft)
        XCTAssertEqual(chart.notes[3].type, .specialRight)
    }

    func testChartExporterRoundTripPreservesInternalData() throws {
        let original = Chart(
            schemaVersion: 1,
            title: "Round Trip",
            artist: "Tester",
            audioFileName: "song.m4a",
            bpm: 128,
            totalBeats: 32,
            offset: 0.25,
            difficulty: "Normal",
            notes: [
                Note(beat: 4, lane: 0, type: .normal),
                Note(beat: 8, lane: 1, type: .long, durationBeats: 2),
                Note(beat: 12, lane: 0, type: .specialLeft),
                Note(beat: 16, lane: 3, type: .specialRight)
            ]
        )

        let exporter = ChartExporter()
        let data = try exporter.exportInternal(original)
        let decoded = try JSONDecoder().decode(Chart.self, from: data)

        XCTAssertEqual(decoded.title, original.title)
        XCTAssertEqual(decoded.artist, original.artist)
        XCTAssertEqual(decoded.audioFileName, original.audioFileName)
        XCTAssertEqual(decoded.bpm, original.bpm)
        XCTAssertEqual(decoded.totalBeats, original.totalBeats)
        XCTAssertEqual(decoded.offset, original.offset)
        XCTAssertEqual(decoded.notes, original.notes)
    }
}
