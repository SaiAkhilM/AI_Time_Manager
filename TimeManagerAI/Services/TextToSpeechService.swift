import Foundation
import AVFoundation
import Combine

class TextToSpeechService: NSObject, ObservableObject {
    @Published var isPlaying = false
    @Published var errorMessage: String?

    private var audioPlayer: AVAudioPlayer?
    private let audioSession = AVAudioSession.sharedInstance()

    override init() {
        super.init()
        setupAudioSession()
    }

    private func setupAudioSession() {
        do {
            try audioSession.setCategory(.playback, mode: .default, options: [.defaultToSpeaker])
            try audioSession.setActive(true)
        } catch {
            print("Failed to setup audio session for playback: \(error)")
            errorMessage = "Failed to setup audio playback"
        }
    }

    func speak(text: String) async {
        guard !text.isEmpty else { return }

        guard let elevenlabsKey = Bundle.main.object(forInfoDictionaryKey: "ELEVENLABS_API_KEY") as? String,
              !elevenlabsKey.isEmpty else {
            await fallbackToSystemTTS(text: text)
            return
        }

        await generateAndPlayElevenLabsAudio(text: text, apiKey: elevenlabsKey)
    }

    private func generateAndPlayElevenLabsAudio(text: String, apiKey: String) async {
        let voiceId = "21m00Tcm4TlvDq8ikWAM" // Rachel voice ID - clear, professional
        let url = URL(string: "https://api.elevenlabs.io/v1/text-to-speech/\(voiceId)")!

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "xi-api-key")

        let requestBody: [String: Any] = [
            "text": text,
            "model_id": "eleven_monolingual_v1",
            "voice_settings": [
                "stability": 0.5,
                "similarity_boost": 0.5,
                "style": 0.5,
                "use_speaker_boost": true
            ]
        ]

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)

            let (data, response) = try await URLSession.shared.data(for: request)

            if let httpResponse = response as? HTTPURLResponse,
               httpResponse.statusCode == 200 {
                await MainActor.run {
                    playAudioData(data)
                }
            } else {
                print("ElevenLabs request failed with status: \((response as? HTTPURLResponse)?.statusCode ?? 0)")
                await fallbackToSystemTTS(text: text)
            }
        } catch {
            print("ElevenLabs request error: \(error)")
            await fallbackToSystemTTS(text: text)
        }
    }

    private func playAudioData(_ data: Data) {
        do {
            audioPlayer = try AVAudioPlayer(data: data)
            audioPlayer?.delegate = self

            if audioPlayer?.play() == true {
                isPlaying = true
                errorMessage = nil
            } else {
                errorMessage = "Failed to play audio"
            }
        } catch {
            print("Failed to create audio player: \(error)")
            errorMessage = "Audio playback error"
        }
    }

    private func fallbackToSystemTTS(text: String) async {
        await MainActor.run {
            let utterance = AVSpeechUtterance(string: text)
            utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
            utterance.rate = 0.5
            utterance.pitchMultiplier = 1.0
            utterance.volume = 0.8

            let synthesizer = AVSpeechSynthesizer()
            synthesizer.speak(utterance)

            isPlaying = true

            DispatchQueue.main.asyncAfter(deadline: .now() + Double(text.count) * 0.05) {
                self.isPlaying = false
            }
        }
    }

    func stopSpeaking() {
        audioPlayer?.stop()
        isPlaying = false
    }
}

extension TextToSpeechService: AVAudioPlayerDelegate {
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        DispatchQueue.main.async {
            self.isPlaying = false
            if !flag {
                self.errorMessage = "Audio playback completed with error"
            }
        }
    }

    func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        DispatchQueue.main.async {
            self.isPlaying = false
            if let error = error {
                print("Audio player decode error: \(error)")
                self.errorMessage = "Audio decode error"
            }
        }
    }
}