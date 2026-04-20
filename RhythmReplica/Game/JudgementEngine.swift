import Foundation

public enum Judgement: String, CaseIterable {
    case perfect = "PERFECT"
    case good = "GOOD"
    case bad = "BAD"
    case miss = "MISS"
}

public struct JudgementWindows {
    public var perfect: Double = 0.060
    public var good: Double = 0.120
    public var bad: Double = 0.180

    public init(perfect: Double = 0.060, good: Double = 0.120, bad: Double = 0.180) {
        self.perfect = perfect
        self.good = good
        self.bad = bad
    }
}

public final class JudgementEngine {
    public let windows: JudgementWindows

    public init(windows: JudgementWindows = .init()) {
        self.windows = windows
    }

    public func judgement(for offset: Double) -> Judgement {
        let distance = abs(offset)
        if distance <= windows.perfect { return .perfect }
        if distance <= windows.good { return .good }
        if distance <= windows.bad { return .bad }
        return .miss
    }
}
