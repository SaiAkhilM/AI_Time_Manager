# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

AI_Time_Manager is a sophisticated iOS app built with SwiftUI that serves as a personal AI assistant for managing schedules, tasks, and time-blocking. The app is designed for high-performing students and founders who want to maximize execution time while minimizing planning overhead.

## Development Status

### ✅ Phase 1 Complete (Foundation)
- [x] Xcode project setup with iOS 17+ target
- [x] Core Data models (Task, Event, Goal, Settings, ConversationContext, RecurrencePattern)
- [x] Basic TabView navigation with 4 main pages
- [x] Settings persistence system

### ✅ Phase 2 Complete (Voice Agent Core)
- [x] VoiceService for audio recording and speech-to-text
- [x] AIService for GPT-4 integration and conversation handling
- [x] VoiceAgentViewModel for complete state management
- [x] TextToSpeechService with ElevenLabs integration + system fallback
- [x] Enhanced VoiceAgentView with real-time audio levels and full pipeline
- [x] API key configuration in Info.plist

### ✅ Phase 3 Complete (Calendar System)
- [x] CalendarViewModel for Core Data integration and state management
- [x] Updated DailyCalendarView to display real tasks from Core Data
- [x] Voice command task creation with regex parsing
- [x] Real-time calendar updates via NotificationCenter
- [x] Color-coded time blocks with proper priority system
- [x] Sample data manager for testing and demonstration

### 🔄 Phase 4 Starting (Rich Text Editor)
- [ ] Enhance DocEditorView with real-time editing
- [ ] Connect document to Core Data for persistence
- [ ] Implement voice-to-doc synchronization
- [ ] Add rich formatting features (links, colors, lists)

### 📋 Upcoming Phases
- Phase 3: Calendar System (4 calendar views with color-coded time blocks)
- Phase 4: Rich Text Editor (Document editor with formatting and links)
- Phase 5: Data Synchronization (Real-time sync between voice/calendar/doc)
- Phase 6: Advanced iOS Features (Live Activities, Push Notifications)
- Phase 7: AI Intelligence (Smart scheduling and conflict resolution)
- Phase 8: Onboarding & Polish

## Project Architecture

### Technology Stack
- **Framework**: SwiftUI + iOS 17+
- **Architecture**: MVVM + Repository Pattern
- **Data**: Core Data with CloudKit sync
- **APIs**: OpenAI (GPT-4 + Whisper), ElevenLabs (TTS)
- **iOS Features**: Live Activities, Push Notifications, Background Processing

### File Structure
```
TimeManagerAI/
├── App/
│   ├── TimeManagerAIApp.swift          # App entry point with Core Data
│   └── ContentView.swift               # Main TabView navigation
├── Models/
│   ├── TaskModel.swift                 # Task entity extensions
│   ├── EventModel.swift               # Event entity extensions
│   └── SettingsModel.swift            # Settings entity extensions
├── Views/
│   ├── VoiceAgentView.swift           # Voice interface with mic button
│   ├── DocEditorView.swift            # Rich text document editor
│   ├── CalendarViews/
│   │   ├── CalendarContainerView.swift # Calendar view switcher
│   │   ├── DailyCalendarView.swift    # Day view with time slots
│   │   ├── WeeklyCalendarView.swift   # Week view with columns
│   │   ├── MonthlyCalendarView.swift  # Month grid with event dots
│   │   └── YearlyCalendarView.swift   # Year overview
│   └── SettingsView.swift             # Configuration interface
├── ViewModels/
│   ├── VoiceAgentViewModel.swift      # Voice agent state management
│   └── CalendarViewModel.swift       # Calendar Core Data integration
├── Services/
│   ├── VoiceService.swift             # Audio recording + Whisper API
│   ├── AIService.swift                # GPT-4 conversation handling
│   └── TextToSpeechService.swift     # ElevenLabs TTS + system fallback
├── Utilities/
│   └── SampleDataManager.swift       # Sample data creation for testing
└── DataModel.xcdatamodeld/            # Core Data schema
```

## Development Commands

### Building and Running
```bash
# Open in Xcode
open TimeManagerAI.xcodeproj

# Build for simulator
xcodebuild -project TimeManagerAI.xcodeproj -scheme TimeManagerAI -destination 'platform=iOS Simulator,name=iPhone 15' build

# Run tests
xcodebuild test -project TimeManagerAI.xcodeproj -scheme TimeManagerAI -destination 'platform=iOS Simulator,name=iPhone 15'
```

### Git Operations
```bash
# Initialize repository (if not done)
git init
git add .
git commit -m "Initial commit: Phase 1 complete"

# Create and push to GitHub
git remote add origin [your-repo-url]
git branch -M main
git push -u origin main

# Phase updates
git add .
git commit -m "Phase 2: Voice Agent core implementation"
git push origin main
```

## API Configuration

### Required API Keys
Add these keys to your project's Info.plist or environment:

```xml
<key>OPENAI_API_KEY</key>
<string>your_openai_api_key_here</string>
<key>ELEVENLABS_API_KEY</key>
<string>your_elevenlabs_api_key_here</string>
```

### Core Data Models

**Key Entities:**
- `Task`: Tasks with priority, time slots, subtasks, and recurrence
- `Event`: Calendar events (classes, meetings, appointments)
- `Goal`: Weekly goals with target hours
- `Settings`: User preferences for sleep, notifications, AI behavior
- `ConversationContext`: Chat history for weekly context memory
- `RecurrencePattern`: Recurring event patterns

**Priority System:**
- Red (high): Critical, urgent tasks
- Orange (medium): Important but flexible
- Yellow (events): Classes, meetings (usually immovable)
- None (normal): Low priority, most flexible

## Key Features

### Voice Agent
- Tap-to-talk with visual waveform
- Speech-to-text via OpenAI Whisper
- GPT-4 conversation with context awareness
- Text-to-speech responses via ElevenLabs
- Quick action buttons for common requests

### Calendar System
- 4 views: Daily (time slots), Weekly (columns), Monthly (grid), Yearly (overview)
- Color-coded time blocks by priority
- 15-minute increments (6 AM - 12 AM default)
- Tap blocks to edit via voice agent

### Smart Scheduling
- Priority-based conflict resolution
- Automatic rescheduling with user confirmation
- Time estimation learning
- Recurring event handling
- Sleep schedule protection

### Data Synchronization
- Real-time sync between Voice ↔ Calendar ↔ Doc
- Core Data with CloudKit backup
- Weekly context reset (Sunday midnight)
- Conversation memory within current week

## Development Guidelines

### Code Style
- No comments unless absolutely necessary
- Follow Apple's Swift style guide
- Use SwiftUI best practices
- Implement proper error handling
- Maintain consistent naming conventions

### Testing Strategy
- Unit tests for Core Data models
- Integration tests for API services
- UI tests for critical user flows
- Device testing for voice and notifications

### Deployment
- Target: iOS 17+ (required for Live Activities)
- Device: iPhone only (no iPad optimization needed)
- Code signing required for device deployment
- Background capabilities: audio, notifications, background-fetch

## Common Issues & Solutions

### Audio Recording
- Requires microphone permission in Info.plist
- Test on physical device (simulator limitations)
- Handle audio session conflicts

### Core Data
- Use batch operations for performance
- Implement proper relationship cascading
- Handle merge conflicts from CloudKit

### API Rate Limits
- Implement exponential backoff
- Cache responses when appropriate
- Provide offline fallbacks

## Phase 3 Achievements

✅ **Complete Calendar Integration**:
- CalendarViewModel with full Core Data integration
- Real tasks and events displayed in daily calendar view
- Color-coded time blocks by priority (red/orange/yellow/gray)
- Voice commands create actual tasks in database
- Real-time calendar updates via NotificationCenter

✅ **Voice-to-Calendar Pipeline**:
- "Add workout to tomorrow at 6 AM" creates real tasks
- Regex parsing for natural language time/date commands
- Automatic task scheduling with start/end times
- Proper date calculation (today, tomorrow, weekdays)
- Tasks immediately appear in calendar view

✅ **Data Management**:
- Sample data manager for testing and demos
- Proper Core Data relationships and cascading
- Task/Event creation, updating, and deletion
- Unscheduled task management
- Automatic data refresh on changes

## Current Functionality

🎯 **Working End-to-End Flow**:
1. **Say**: "Add workout to tomorrow at 6 AM"
2. **AI Processes**: Creates task in Core Data with proper date/time
3. **Calendar Updates**: Task immediately appears in calendar view
4. **Visual Feedback**: Color-coded block shows on correct day/time

## Next Steps

1. **Phase 4**: Rich text document editor with Core Data persistence
2. **Voice-to-Doc Sync**: Update document when tasks are created via voice
3. **Enhanced Parsing**: Support more complex voice commands
4. **API Key Testing**: Test with real OpenAI/ElevenLabs keys
5. **Weekly View Integration**: Extend calendar integration to all views