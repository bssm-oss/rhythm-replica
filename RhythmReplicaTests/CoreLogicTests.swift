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
}
