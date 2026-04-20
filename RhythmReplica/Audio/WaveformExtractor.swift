import AVFoundation
import Foundation

final class WaveformExtractor {
    func extractSamples(from url: URL, targetSampleCount: Int = 256, completion: @escaping ([Float]) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            let values = (try? self.readSamples(from: url, targetSampleCount: targetSampleCount)) ?? []
            DispatchQueue.main.async {
                completion(values)
            }
        }
    }

    private func readSamples(from url: URL, targetSampleCount: Int) throws -> [Float] {
        let audioFile = try AVAudioFile(forReading: url)
        let totalFrames = AVAudioFrameCount(audioFile.length)
        guard let buffer = AVAudioPCMBuffer(pcmFormat: audioFile.processingFormat, frameCapacity: totalFrames) else {
            return []
        }
        try audioFile.read(into: buffer)
        guard let channelData = buffer.floatChannelData?.pointee else {
            return []
        }

        let sampleStride = max(1, Int(buffer.frameLength) / targetSampleCount)
        var output: [Float] = []
        output.reserveCapacity(targetSampleCount)

        var index = 0
        while index < Int(buffer.frameLength) {
            let end = min(Int(buffer.frameLength), index + sampleStride)
            var peak: Float = 0
            for sampleIndex in index..<end {
                peak = max(peak, abs(channelData[sampleIndex]))
            }
            output.append(peak)
            index += sampleStride
        }

        return output
    }
}
