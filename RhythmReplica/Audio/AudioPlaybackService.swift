import AVFoundation
import Foundation

final class AudioPlaybackService {
    private let engine = AVAudioEngine()
    private let playerNode = AVAudioPlayerNode()
    private var audioFile: AVAudioFile?
    private var pausedTime: Double = 0
    private var scheduledStartTime: Double = 0

    init() {
        engine.attach(playerNode)
        engine.connect(playerNode, to: engine.mainMixerNode, format: nil)
        try? engine.start()
    }

    var isPlaying: Bool {
        playerNode.isPlaying
    }

    var duration: Double {
        guard let audioFile else { return 0 }
        return Double(audioFile.length) / audioFile.processingFormat.sampleRate
    }

    var currentTime: Double {
        guard let renderTime = playerNode.lastRenderTime,
              let playerTime = playerNode.playerTime(forNodeTime: renderTime) else {
            return pausedTime
        }

        let rawTime = Double(playerTime.sampleTime) / playerTime.sampleRate + scheduledStartTime
        return min(duration, max(0, rawTime + engine.outputNode.presentationLatency))
    }

    func load(url: URL) throws {
        stop()
        audioFile = try AVAudioFile(forReading: url)
        pausedTime = 0
        scheduledStartTime = 0
    }

    func play() throws {
        try play(from: pausedTime)
    }

    func play(from time: Double) throws {
        guard let audioFile else { return }
        if !engine.isRunning {
            try engine.start()
        }
        playerNode.stop()
        let clampedTime = min(max(0, time), duration)
        let startFrame = AVAudioFramePosition(clampedTime * audioFile.processingFormat.sampleRate)
        let frameCount = AVAudioFrameCount(max(0, Int(audioFile.length - startFrame)))
        playerNode.scheduleSegment(audioFile, startingFrame: startFrame, frameCount: frameCount, at: nil)
        scheduledStartTime = clampedTime
        pausedTime = clampedTime
        playerNode.play()
    }

    func pause() {
        pausedTime = currentTime
        playerNode.pause()
    }

    func stop() {
        playerNode.stop()
        pausedTime = 0
        scheduledStartTime = 0
    }

    func seek(to time: Double) throws {
        if isPlaying {
            try play(from: time)
        } else {
            pausedTime = min(max(0, time), duration)
            scheduledStartTime = pausedTime
        }
    }
}
