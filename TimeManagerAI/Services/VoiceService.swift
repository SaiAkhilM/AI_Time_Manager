import Foundation
import AVFoundation
import Combine

class VoiceService: NSObject, ObservableObject {
    @Published var isRecording = false
    @Published var audioLevel: Float = 0.0
    @Published var errorMessage: String?

    private var audioRecorder: AVAudioRecorder?
    private var audioSession: AVAudioSession
    private var levelTimer: Timer?

    override init() {
        self.audioSession = AVAudioSession.sharedInstance()
        super.init()
        setupAudioSession()
    }

    private func setupAudioSession() {
        do {
            try audioSession.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker])
            try audioSession.setActive(true)
        } catch {
            print("Failed to setup audio session: \(error)")
            errorMessage = "Failed to setup audio session"
        }
    }

    func requestMicrophonePermission() async -> Bool {
        return await withCheckedContinuation { continuation in
            audioSession.requestRecordPermission { granted in
                DispatchQueue.main.async {
                    continuation.resume(returning: granted)
                }
            }
        }
    }

    func startRecording() async -> Bool {
        guard !isRecording else { return false }

        let hasPermission = await requestMicrophonePermission()
        guard hasPermission else {
            errorMessage = "Microphone permission denied"
            return false
        }

        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let audioURL = documentsPath.appendingPathComponent("recording_\(Date().timeIntervalSince1970).m4a")

        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44100,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]

        do {
            audioRecorder = try AVAudioRecorder(url: audioURL, settings: settings)
            audioRecorder?.delegate = self
            audioRecorder?.isMeteringEnabled = true

            if audioRecorder?.record() == true {
                isRecording = true
                startLevelMonitoring()
                errorMessage = nil
                return true
            } else {
                errorMessage = "Failed to start recording"
                return false
            }
        } catch {
            print("Failed to create audio recorder: \(error)")
            errorMessage = "Failed to create audio recorder"
            return false
        }
    }

    func stopRecording() -> URL? {
        guard isRecording, let recorder = audioRecorder else { return nil }

        recorder.stop()
        isRecording = false
        stopLevelMonitoring()

        return recorder.url
    }

    private func startLevelMonitoring() {
        levelTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self = self, let recorder = self.audioRecorder else { return }

            recorder.updateMeters()
            let power = recorder.averagePower(forChannel: 0)
            let normalizedLevel = max(0.0, (power + 80) / 80)

            DispatchQueue.main.async {
                self.audioLevel = normalizedLevel
            }
        }
    }

    private func stopLevelMonitoring() {
        levelTimer?.invalidate()
        levelTimer = nil
        audioLevel = 0.0
    }

    func transcribeAudio(url: URL) async -> String? {
        guard let openAIKey = Bundle.main.object(forInfoDictionaryKey: "OPENAI_API_KEY") as? String,
              !openAIKey.isEmpty else {
            errorMessage = "OpenAI API key not configured"
            return nil
        }

        var request = URLRequest(url: URL(string: "https://api.openai.com/v1/audio/transcriptions")!)
        request.httpMethod = "POST"
        request.setValue("Bearer \(openAIKey)", forHTTPHeaderField: "Authorization")

        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        var body = Data()

        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"audio.m4a\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: audio/m4a\r\n\r\n".data(using: .utf8)!)

        do {
            let audioData = try Data(contentsOf: url)
            body.append(audioData)
        } catch {
            print("Failed to read audio file: \(error)")
            errorMessage = "Failed to read audio file"
            return nil
        }

        body.append("\r\n--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"model\"\r\n\r\n".data(using: .utf8)!)
        body.append("whisper-1".data(using: .utf8)!)
        body.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)

        request.httpBody = body

        do {
            let (data, response) = try await URLSession.shared.data(for: request)

            if let httpResponse = response as? HTTPURLResponse,
               httpResponse.statusCode == 200 {
                let decoder = JSONDecoder()
                let transcriptionResponse = try decoder.decode(TranscriptionResponse.self, from: data)
                return transcriptionResponse.text
            } else {
                print("Transcription failed with status: \((response as? HTTPURLResponse)?.statusCode ?? 0)")
                errorMessage = "Transcription failed"
                return nil
            }
        } catch {
            print("Transcription error: \(error)")
            errorMessage = "Transcription error: \(error.localizedDescription)"
            return nil
        }
    }

    deinit {
        stopLevelMonitoring()
    }
}

extension VoiceService: AVAudioRecorderDelegate {
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        if !flag {
            errorMessage = "Recording failed"
        }
    }

    func audioRecorderEncodeErrorDidOccur(_ recorder: AVAudioRecorder, error: Error?) {
        if let error = error {
            print("Recording encode error: \(error)")
            errorMessage = "Recording error: \(error.localizedDescription)"
        }
    }
}

struct TranscriptionResponse: Codable {
    let text: String
}