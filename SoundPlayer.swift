import AudioToolbox

final class SoundPlayer {
    static let shared = SoundPlayer()

    func playTone() {
        AudioServicesPlaySystemSound(1057)
    }
}
