import SwiftUI

// MARK: - Animated Button Styles

struct PulsingButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

struct BouncyButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.9 : 1.0)
            .animation(.spring(response: 0.4, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

struct GlowingButtonStyle: ButtonStyle {
    let color: Color

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .shadow(color: color.opacity(0.3), radius: configuration.isPressed ? 2 : 8, x: 0, y: 0)
            .animation(.easeInOut(duration: 0.2), value: configuration.isPressed)
    }
}

// MARK: - Loading Animations

struct PulsingDot: View {
    @State private var isAnimating = false
    let delay: Double

    var body: some View {
        Circle()
            .fill(Color.blue)
            .frame(width: 8, height: 8)
            .scaleEffect(isAnimating ? 1.5 : 0.5)
            .opacity(isAnimating ? 0.3 : 1.0)
            .animation(
                .easeInOut(duration: 0.8)
                .repeatForever()
                .delay(delay),
                value: isAnimating
            )
            .onAppear {
                isAnimating = true
            }
    }
}

struct ThreeDotLoading: View {
    var body: some View {
        HStack(spacing: 4) {
            PulsingDot(delay: 0)
            PulsingDot(delay: 0.2)
            PulsingDot(delay: 0.4)
        }
    }
}

struct WaveLoading: View {
    @State private var isAnimating = false

    var body: some View {
        HStack(spacing: 2) {
            ForEach(0..<5) { index in
                Rectangle()
                    .fill(Color.blue)
                    .frame(width: 3, height: isAnimating ? 20 : 4)
                    .animation(
                        .easeInOut(duration: 0.6)
                        .repeatForever()
                        .delay(Double(index) * 0.1),
                        value: isAnimating
                    )
            }
        }
        .onAppear {
            isAnimating = true
        }
    }
}

struct CircularProgressView: View {
    let progress: Double
    let lineWidth: CGFloat
    let size: CGFloat
    let color: Color

    init(progress: Double, lineWidth: CGFloat = 8, size: CGFloat = 60, color: Color = .blue) {
        self.progress = progress
        self.lineWidth = lineWidth
        self.size = size
        self.color = color
    }

    var body: some View {
        ZStack {
            Circle()
                .stroke(color.opacity(0.2), lineWidth: lineWidth)
                .frame(width: size, height: size)

            Circle()
                .trim(from: 0, to: progress)
                .stroke(color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .frame(width: size, height: size)
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.5), value: progress)
        }
    }
}

// MARK: - Task Animations

struct TaskCompletionAnimation: View {
    @State private var isAnimating = false
    let onComplete: () -> Void

    var body: some View {
        ZStack {
            Circle()
                .fill(Color.green.opacity(0.2))
                .scaleEffect(isAnimating ? 2.0 : 0)
                .opacity(isAnimating ? 0 : 1)

            Image(systemName: "checkmark")
                .font(.title)
                .foregroundColor(.green)
                .scaleEffect(isAnimating ? 1.2 : 0.8)
        }
        .frame(width: 60, height: 60)
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                isAnimating = true
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                onComplete()
            }
        }
    }
}

struct SlideInCard: View {
    let content: AnyView
    @State private var offset: CGFloat = 300
    @State private var opacity: Double = 0

    init<Content: View>(@ViewBuilder content: () -> Content) {
        self.content = AnyView(content())
    }

    var body: some View {
        content
            .offset(x: offset)
            .opacity(opacity)
            .onAppear {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                    offset = 0
                    opacity = 1
                }
            }
    }
}

struct FadeInView: View {
    let content: AnyView
    @State private var opacity: Double = 0
    let delay: Double

    init<Content: View>(delay: Double = 0, @ViewBuilder content: () -> Content) {
        self.content = AnyView(content())
        self.delay = delay
    }

    var body: some View {
        content
            .opacity(opacity)
            .onAppear {
                withAnimation(.easeIn(duration: 0.5).delay(delay)) {
                    opacity = 1
                }
            }
    }
}

// MARK: - Voice Recording Animation

struct VoiceWaveform: View {
    @Binding var audioLevel: Float
    @State private var isRecording = false

    var body: some View {
        HStack(spacing: 2) {
            ForEach(0..<10) { index in
                RoundedRectangle(cornerRadius: 1)
                    .fill(Color.blue)
                    .frame(
                        width: 3,
                        height: CGFloat.random(in: 4...(20 + CGFloat(audioLevel * 40)))
                    )
                    .animation(
                        .easeInOut(duration: Double.random(in: 0.3...0.8))
                        .repeatForever(autoreverses: true)
                        .delay(Double(index) * 0.1),
                        value: isRecording
                    )
            }
        }
        .onAppear {
            isRecording = true
        }
        .onChange(of: audioLevel) { _ in
            // Trigger animation update
            isRecording.toggle()
            isRecording.toggle()
        }
    }
}

struct PulsingMicButton: View {
    @Binding var isRecording: Bool
    let action: () -> Void

    @State private var scale: CGFloat = 1.0
    @State private var shadowRadius: CGFloat = 0

    var body: some View {
        Button(action: action) {
            Image(systemName: isRecording ? "stop.circle.fill" : "mic.fill")
                .font(.system(size: 40))
                .foregroundColor(.white)
                .frame(width: 80, height: 80)
                .background(
                    Circle()
                        .fill(isRecording ? Color.red : Color.blue)
                )
                .scaleEffect(scale)
                .shadow(color: isRecording ? .red : .blue, radius: shadowRadius)
        }
        .buttonStyle(PlainButtonStyle())
        .onChange(of: isRecording) { recording in
            if recording {
                withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                    scale = 1.1
                    shadowRadius = 15
                }
            } else {
                withAnimation(.easeInOut(duration: 0.3)) {
                    scale = 1.0
                    shadowRadius = 0
                }
            }
        }
    }
}

// MARK: - Calendar Animations

struct CalendarTransition: View {
    let fromDate: Date
    let toDate: Date
    @State private var progress: Double = 0

    var body: some View {
        HStack {
            Text(fromDate.formatted(.dateTime.month().day()))
                .opacity(1 - progress)
                .offset(x: -50 * progress)

            Text(toDate.formatted(.dateTime.month().day()))
                .opacity(progress)
                .offset(x: 50 * (1 - progress))
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 0.5)) {
                progress = 1.0
            }
        }
    }
}

struct TaskAppearAnimation: ViewModifier {
    @State private var scale: CGFloat = 0
    @State private var opacity: Double = 0
    let delay: Double

    func body(content: Content) -> some View {
        content
            .scaleEffect(scale)
            .opacity(opacity)
            .onAppear {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.7).delay(delay)) {
                    scale = 1.0
                    opacity = 1.0
                }
            }
    }
}

extension View {
    func taskAppearAnimation(delay: Double = 0) -> some View {
        self.modifier(TaskAppearAnimation(delay: delay))
    }
}

// MARK: - Success Celebrations

struct ConfettiView: View {
    @State private var animate = false
    let colors: [Color] = [.red, .blue, .green, .yellow, .orange, .purple, .pink]

    var body: some View {
        ZStack {
            ForEach(0..<20) { index in
                Rectangle()
                    .fill(colors.randomElement() ?? .blue)
                    .frame(width: 8, height: 8)
                    .offset(
                        x: animate ? CGFloat.random(in: -200...200) : 0,
                        y: animate ? CGFloat.random(in: -300...100) : -50
                    )
                    .rotationEffect(.degrees(animate ? Double.random(in: 0...360) : 0))
                    .opacity(animate ? 0 : 1)
                    .animation(
                        .easeOut(duration: Double.random(in: 1.0...2.0))
                        .delay(Double.random(in: 0...0.5)),
                        value: animate
                    )
            }
        }
        .onAppear {
            animate = true
        }
    }
}

struct CelebrationOverlay: View {
    @State private var showConfetti = false
    @State private var showCheckmark = false
    let message: String
    let onComplete: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()

            if showConfetti {
                ConfettiView()
            }

            VStack(spacing: 20) {
                if showCheckmark {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 80))
                        .foregroundColor(.green)
                        .scaleEffect(showCheckmark ? 1.0 : 0.3)
                        .animation(.spring(response: 0.5, dampingFraction: 0.6), value: showCheckmark)
                }

                Text(message)
                    .font(.title2)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                    .opacity(showCheckmark ? 1 : 0)
                    .animation(.easeIn(duration: 0.5).delay(0.3), value: showCheckmark)
            }
        }
        .onAppear {
            showConfetti = true

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                showCheckmark = true
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                onComplete()
            }
        }
    }
}

// MARK: - Floating Action Button

struct FloatingActionButton: View {
    let icon: String
    let action: () -> Void
    @State private var scale: CGFloat = 1.0

    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                scale = 0.9
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    scale = 1.0
                }
                action()
            }
        }) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.white)
                .frame(width: 56, height: 56)
                .background(
                    Circle()
                        .fill(Color.blue)
                        .shadow(color: .blue.opacity(0.3), radius: 8, x: 0, y: 4)
                )
        }
        .scaleEffect(scale)
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Shimmer Effect

struct ShimmerEffect: ViewModifier {
    @State private var phase: CGFloat = 0

    func body(content: Content) -> some View {
        content
            .overlay(
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [.clear, .white.opacity(0.4), .clear],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .rotationEffect(.degrees(30))
                    .offset(x: phase)
                    .clipped()
            )
            .onAppear {
                withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                    phase = 400
                }
            }
    }
}

extension View {
    func shimmer() -> some View {
        self.modifier(ShimmerEffect())
    }
}

// MARK: - Skeleton Loading

struct SkeletonView: View {
    @State private var isAnimating = false

    var body: some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(Color.gray.opacity(0.3))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .fill(
                        LinearGradient(
                            colors: [.clear, .white.opacity(0.4), .clear],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .offset(x: isAnimating ? 200 : -200)
                    .animation(.linear(duration: 1.0).repeatForever(autoreverses: false), value: isAnimating)
            )
            .clipped()
            .onAppear {
                isAnimating = true
            }
    }
}

#Preview {
    VStack(spacing: 20) {
        ThreeDotLoading()
        WaveLoading()
        CircularProgressView(progress: 0.7)
        PulsingMicButton(isRecording: .constant(false)) {}
        FloatingActionButton(icon: "plus") {}
    }
    .padding()
}