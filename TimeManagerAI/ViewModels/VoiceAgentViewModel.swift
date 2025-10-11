import Foundation
import CoreData
import Combine
import AVFoundation

extension Notification.Name {
    static let taskCreated = Notification.Name("taskCreated")
    static let taskUpdated = Notification.Name("taskUpdated")
}

@MainActor
class VoiceAgentViewModel: ObservableObject {
    @Published var isRecording = false
    @Published var isProcessing = false
    @Published var isPlayingResponse = false
    @Published var userTranscript = ""
    @Published var aiResponse = ""
    @Published var currentTopic = "Ready to help"
    @Published var errorMessage: String?
    @Published var audioLevel: Float = 0.0

    private let voiceService = VoiceService()
    private let aiService = AIService()
    private let textToSpeechService = TextToSpeechService()
    private var recordingURL: URL?
    private var cancellables = Set<AnyCancellable>()

    init() {
        setupBindings()
    }

    private func setupBindings() {
        voiceService.$isRecording
            .receive(on: DispatchQueue.main)
            .assign(to: \.isRecording, on: self)
            .store(in: &cancellables)

        voiceService.$audioLevel
            .receive(on: DispatchQueue.main)
            .assign(to: \.audioLevel, on: self)
            .store(in: &cancellables)

        voiceService.$errorMessage
            .receive(on: DispatchQueue.main)
            .assign(to: \.errorMessage, on: self)
            .store(in: &cancellables)

        aiService.$errorMessage
            .receive(on: DispatchQueue.main)
            .assign(to: \.errorMessage, on: self)
            .store(in: &cancellables)

        textToSpeechService.$isPlaying
            .receive(on: DispatchQueue.main)
            .assign(to: \.isPlayingResponse, on: self)
            .store(in: &cancellables)

        textToSpeechService.$errorMessage
            .receive(on: DispatchQueue.main)
            .assign(to: \.errorMessage, on: self)
            .store(in: &cancellables)
    }

    func toggleRecording(context: NSManagedObjectContext) {
        if isRecording {
            stopRecording(context: context)
        } else {
            startRecording()
        }
    }

    private func startRecording() {
        Task {
            currentTopic = "Listening..."
            userTranscript = ""
            aiResponse = ""
            errorMessage = nil

            let success = await voiceService.startRecording()
            if !success {
                currentTopic = "Failed to start recording"
            }
        }
    }

    private func stopRecording(context: NSManagedObjectContext) {
        currentTopic = "Processing..."
        recordingURL = voiceService.stopRecording()

        Task {
            await processRecording(context: context)
        }
    }

    private func processRecording(context: NSManagedObjectContext) async {
        guard let url = recordingURL else {
            currentTopic = "Recording failed"
            return
        }

        isProcessing = true

        do {
            if let transcript = await voiceService.transcribeAudio(url: url) {
                userTranscript = transcript
                currentTopic = "Understanding your request..."

                if let response = await aiService.sendMessage(transcript, context: context) {
                    aiResponse = response
                    currentTopic = "Response ready"

                    await textToSpeechService.speak(text: response)
                    currentTopic = "Ready to help"
                } else {
                    currentTopic = "Failed to get AI response"
                }
            } else {
                currentTopic = "Failed to transcribe audio"
            }
        }

        isProcessing = false

        try? FileManager.default.removeItem(at: url)
    }

    func handleQuickAction(_ action: QuickAction, context: NSManagedObjectContext) {
        let message: String

        switch action {
        case .whatsNext:
            message = "What's next on my schedule?"
        case .showToday:
            message = "Show me today's schedule"
        case .moveTask:
            message = "I need to reschedule a task"
        case .addNewTask:
            message = "I want to add a new task"
        }

        Task {
            currentTopic = "Processing quick action..."
            userTranscript = message

            if let response = await aiService.sendMessage(message, context: context) {
                aiResponse = response
                currentTopic = "Response ready"

                await textToSpeechService.speak(text: response)
                currentTopic = "Ready to help"
            } else {
                currentTopic = "Failed to process quick action"
            }
        }
    }

    func clearConversation() {
        userTranscript = ""
        aiResponse = ""
        currentTopic = "Ready to help"
        aiService.clearConversationHistory()
    }
}

enum QuickAction {
    case whatsNext
    case showToday
    case moveTask
    case addNewTask
}