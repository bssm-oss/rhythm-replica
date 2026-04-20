import Foundation

public struct ScoreState: Equatable {
    public var score: Int = 0
    public var combo: Int = 0
    public var maxCombo: Int = 0
    public var hp: Int = 100
    public var counts: [Judgement: Int] = [.perfect: 0, .good: 0, .bad: 0, .miss: 0]

    public init(score: Int = 0, combo: Int = 0, maxCombo: Int = 0, hp: Int = 100, counts: [Judgement: Int] = [.perfect: 0, .good: 0, .bad: 0, .miss: 0]) {
        self.score = score
        self.combo = combo
        self.maxCombo = maxCombo
        self.hp = hp
        self.counts = counts
    }

    public var accuracy: Double {
        let total = counts.values.reduce(0, +)
        guard total > 0 else { return 0 }
        let perfect = counts[.perfect] ?? 0
        let good = counts[.good] ?? 0
        let bad = counts[.bad] ?? 0
        let weighted = Double((perfect * 100) + (good * 50) + (bad * 10))
        return weighted / Double(total * 100)
    }
}

public enum ScoreCalculator {
    public static func apply(_ judgement: Judgement, to state: inout ScoreState) {
        state.counts[judgement, default: 0] += 1
        switch judgement {
        case .perfect:
            state.score += 1000
            state.combo += 1
            state.hp = min(100, state.hp + 2)
        case .good:
            state.score += 500
            state.combo += 1
            state.hp = min(100, state.hp + 1)
        case .bad:
            state.score += 100
            state.combo = 0
            state.hp = max(0, state.hp - 5)
        case .miss:
            state.combo = 0
            state.hp = max(0, state.hp - 15)
        }
        state.maxCombo = max(state.maxCombo, state.combo)
    }
}
