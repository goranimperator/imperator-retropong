import AVFoundation

class SoundManager {
    static let shared = SoundManager()

    var isEnabled: Bool {
        get { UserDefaults.standard.bool(forKey: "soundEnabled") }
        set { UserDefaults.standard.set(newValue, forKey: "soundEnabled") }
    }

    private let engine = AVAudioEngine()
    private let playerNode = AVAudioPlayerNode()
    private let sampleRate: Double = 44100
    private let format: AVAudioFormat

    private let paddleHitBuffer: AVAudioPCMBuffer
    private let wallHitBuffer: AVAudioPCMBuffer
    private let scoreBuffer: AVAudioPCMBuffer

    private init() {
        format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)!

        paddleHitBuffer = SoundManager.generateSquareWave(frequency: 480, duration: 0.05, sampleRate: sampleRate, format: format)
        wallHitBuffer = SoundManager.generateSquareWave(frequency: 240, duration: 0.05, sampleRate: sampleRate, format: format)
        scoreBuffer = SoundManager.generateSquareWave(frequency: 120, duration: 0.25, sampleRate: sampleRate, format: format)

        engine.attach(playerNode)
        engine.connect(playerNode, to: engine.mainMixerNode, format: format)
    }

    private func ensureRunning() {
        guard !engine.isRunning else { return }
        try? engine.start()
    }

    func playPaddleHit() {
        guard isEnabled else { return }
        play(paddleHitBuffer)
    }

    func playWallHit() {
        guard isEnabled else { return }
        play(wallHitBuffer)
    }

    func playScore() {
        guard isEnabled else { return }
        play(scoreBuffer)
    }

    private func play(_ buffer: AVAudioPCMBuffer) {
        ensureRunning()
        playerNode.stop()
        playerNode.scheduleBuffer(buffer, completionHandler: nil)
        playerNode.play()
    }

    private static func generateSquareWave(frequency: Double, duration: Double, sampleRate: Double, format: AVAudioFormat) -> AVAudioPCMBuffer {
        let frameCount = AVAudioFrameCount(duration * sampleRate)
        let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount)!
        buffer.frameLength = frameCount
        let data = buffer.floatChannelData![0]
        let amplitude: Float = 0.25
        let fadeFrames = min(Int(0.005 * sampleRate), Int(frameCount) / 4)

        for i in 0..<Int(frameCount) {
            let t = Double(i) / sampleRate
            let square: Float = sin(2.0 * .pi * frequency * t) >= 0 ? amplitude : -amplitude

            let remaining = Int(frameCount) - i
            let fade: Float = remaining < fadeFrames ? Float(remaining) / Float(fadeFrames) : 1.0
            data[i] = square * fade
        }

        return buffer
    }
}
