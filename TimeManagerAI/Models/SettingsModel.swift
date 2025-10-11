import Foundation
import CoreData

extension Settings {
    enum SleepPriority: String, CaseIterable {
        case unmovable = "unmovable"
        case flexible = "flexible"

        var displayName: String {
            switch self {
            case .unmovable: return "Unmovable"
            case .flexible: return "Flexible"
            }
        }
    }

    enum AIPersonality: String, CaseIterable {
        case professional = "professional"
        case casual = "casual"
        case motivational = "motivational"

        var displayName: String {
            switch self {
            case .professional: return "Professional"
            case .casual: return "Casual"
            case .motivational: return "Motivational"
            }
        }
    }

    enum AutoReschedule: String, CaseIterable {
        case alwaysAsk = "always_ask"
        case smart = "smart"

        var displayName: String {
            switch self {
            case .alwaysAsk: return "Always Ask"
            case .smart: return "Smart (Recommended)"
            }
        }
    }

    enum ColorTheme: String, CaseIterable {
        case light = "light"
        case dark = "dark"
        case auto = "auto"

        var displayName: String {
            switch self {
            case .light: return "Light"
            case .dark: return "Dark"
            case .auto: return "Auto"
            }
        }
    }

    var sleepPriorityEnum: SleepPriority {
        get { SleepPriority(rawValue: sleepPriority ?? "unmovable") ?? .unmovable }
        set { sleepPriority = newValue.rawValue }
    }

    var aiPersonalityEnum: AIPersonality {
        get { AIPersonality(rawValue: aiPersonality ?? "professional") ?? .professional }
        set { aiPersonality = newValue.rawValue }
    }

    var autoRescheduleEnum: AutoReschedule {
        get { AutoReschedule(rawValue: autoReschedule ?? "smart") ?? .smart }
        set { autoReschedule = newValue.rawValue }
    }

    var colorThemeEnum: ColorTheme {
        get { ColorTheme(rawValue: colorTheme ?? "auto") ?? .auto }
        set { colorTheme = newValue.rawValue }
    }

    static func getOrCreate(in context: NSManagedObjectContext) -> Settings {
        let request: NSFetchRequest<Settings> = Settings.fetchRequest()
        request.fetchLimit = 1

        if let existingSettings = try? context.fetch(request).first {
            return existingSettings
        }

        let settings = Settings(context: context)
        settings.id = UUID()
        settings.sleepStartTime = Calendar.current.date(from: DateComponents(hour: 23, minute: 0)) ?? Date()
        settings.sleepEndTime = Calendar.current.date(from: DateComponents(hour: 7, minute: 0)) ?? Date()
        settings.updatedAt = Date()

        return settings
    }

    func updateTimestamp() {
        self.updatedAt = Date()
    }
}