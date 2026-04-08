import SwiftUI

struct ContentView: View {
    private let phases: [Phase] = [
        .init(name: "INHALE", subtitle: "Breathe In", duration: 4, color: Color(hex: "38bdf8")),    // Sky blue
        .init(name: "HOLD", subtitle: "Hold", duration: 7, color: Color(hex: "facc15")),           // Yellow
        .init(name: "EXHALE", subtitle: "Breathe Out", duration: 8, color: Color(hex: "4ade80"))   // Green
    ]
    
    // Custom color extension for hex support
    private extension Color {
        init(hex: String) {
            let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
            var int: UInt64 = 0
            Scanner(string: hex).scanHexInt64(&int)
            let a, r, g, b: UInt64
            switch hex.count {
            case 3: // RGB (12-bit)
                (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
            case 6: // RGB (24-bit)
                (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
            case 8: // ARGB (32-bit)
                (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
            default:
                (a, r, g, b) = (1, 1, 1, 0)
            }
            self.init(
                .sRGB,
                red: Double(r) / 255,
                green: Double(g) / 255,
                blue:  Double(b) / 255,
                opacity: Double(a) / 255
            )
        }
    }

    @State private var currentPhaseIndex = 0
    @State private var remainingSeconds = 4
    @State private var isRunning = false
    @State private var timer: Timer? = nil
    @State private var cyclesCompleted = 0

    private var totalDuration: Int {
        phases.reduce(0) { $0 + $1.duration }
    }

    private var elapsedSeconds: Int {
        phases.prefix(currentPhaseIndex).reduce(0) { $0 + $1.duration } + (phases[currentPhaseIndex].duration - remainingSeconds)
    }

    var body: some View {
        ZStack {
            // Gradient background
            LinearGradient(
                colors: [Color(hex: "0f172a"), Color(hex: "1e293b"), Color(hex: "0f172a")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 28) {
                // Title with gradient text
                Text("4-7-8 Breathing")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color(hex: "60a5fa"), Color(hex: "a78bfa")],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )

                breathingRing
                    .frame(width: 280, height: 280)

                VStack(spacing: 4) {
                    Text(phases[currentPhaseIndex].name)
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(phases[currentPhaseIndex].color)
                        .textCase(.uppercase)
                        .tracking(3)
                    
                    Text(phases[currentPhaseIndex].subtitle)
                        .font(.subheadline)
                        .foregroundColor(Color(hex: "64748b"))

                    Text("\(remainingSeconds)")
                        .font(.system(size: 56, weight: .bold, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color.white, Color(hex: "cbd5e1")],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .monospacedDigit()
                    
                    Text("seconds")
                        .font(.subheadline)
                        .foregroundColor(Color(hex: "64748b"))
                    
                    Text("Cycles: \(cyclesCompleted)")
                        .font(.caption)
                        .foregroundColor(Color(hex: "64748b"))
                        .padding(.top, 4)
                }

                // Single toggle button
                Button(action: toggleSession) {
                    Text(isRunning ? "Stop" : "Start")
                        .font(.headline())
                        .frame(width: 180, height: 54)
                        .background(
                            LinearGradient(
                                colors: isRunning 
                                    ? [Color(hex: "ef4444"), Color(hex: "dc2626")]
                                    : [Color(hex: "3b82f6"), Color(hex: "2563eb")],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .foregroundColor(.white)
                        .cornerRadius(16)
                        .shadow(
                            color: isRunning 
                                ? Color(hex: "ef4444").opacity(0.4)
                                : Color(hex: "3b82f6").opacity(0.4),
                            radius: 8, x: 0, y: 4
                        )
                }
                .padding(.top, 8)

                // Phase legend
                HStack(spacing: 16) {
                    ForEach(phases.indices, id: \ .self) { index in
                        HStack(spacing: 6) {
                            Circle()
                                .fill(phases[index].color)
                                .frame(width: 10, height: 10)
                            Text(phases[index].name)
                                .font(.caption2)
                                .foregroundColor(Color(hex: "94a3b8"))
                        }
                    }
                }
                .padding(.top, 8)
            }
            .padding()
        }
        .onAppear(perform: resetSession)
    }

    private var breathingRing: some View {
        ZStack {
            Circle()
                .stroke(Color.secondary.opacity(0.15), lineWidth: 24)

            // Phase colored arcs
            ForEach(phases.indices, id: \ .self) { index in
                CircleArc(startAngle: startAngle(for: index), endAngle: endAngle(for: index))
                    .stroke(phases[index].color.opacity(currentPhaseIndex == index ? 0.8 : 0.3), lineWidth: 24)
            }

            // Golden progress arc
            CircleArc(startAngle: progressStartAngle, endAngle: progressEndAngle)
                .stroke(
                    LinearGradient(
                        colors: [Color(hex: "fbbf24"), Color(hex: "f59e0b")],
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    style: StrokeStyle(lineWidth: 28, lineCap: .round)
                )
                .shadow(color: Color(hex: "fbbf24").opacity(0.5), radius: 8)

            // Dot at current position - matches current phase color with white center
            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color.white, phases[currentPhaseIndex].color],
                        center: .center,
                        startRadius: 0,
                        endRadius: 12
                    )
                )
                .frame(width: 24, height: 24)
                .shadow(color: phases[currentPhaseIndex].color.opacity(0.8), radius: 10)
                .offset(y: -126)
                .rotationEffect(.degrees(progressFraction * 360))

            Text(progressLabel)
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color.white, Color(hex: "cbd5e1")],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
        }
    }

    private var progressFraction: Double {
        Double(elapsedSeconds) / Double(totalDuration)
    }

    private var progressStartAngle: Angle { .degrees(-90) }
    private var progressEndAngle: Angle { .degrees(-90 + 360 * progressFraction) }

    private var progressLabel: String {
        String(format: "%.0f%%", progressFraction * 100)
    }

    private func startAngle(for index: Int) -> Angle {
        let start = phases.prefix(index).reduce(0) { $0 + $1.duration }
        return .degrees(-90 + Double(start) / Double(totalDuration) * 360)
    }

    private func endAngle(for index: Int) -> Angle {
        let end = phases.prefix(index + 1).reduce(0) { $0 + $1.duration }
        return .degrees(-90 + Double(end) / Double(totalDuration) * 360)
    }

    private func phaseDescription(for phase: Phase) -> String {
        "\(phase.name): \(phase.duration) seconds"
    }

    private func toggleSession() {
        if isRunning {
            // Stop the session
            stopSession()
            resetSession()
        } else {
            // Start the session
            currentPhaseIndex = 0
            remainingSeconds = phases[0].duration
            cyclesCompleted = 0
            isRunning = true
            SoundPlayer.shared.playTone()
            timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
                tick()
            }
        }
    }

    private func stopSession() {
        timer?.invalidate()
        timer = nil
    }

    private func resetSession() {
        currentPhaseIndex = 0
        remainingSeconds = phases[0].duration
        cyclesCompleted = 0
    }

    private func tick() {
        guard isRunning else { return }

        if remainingSeconds > 1 {
            remainingSeconds -= 1
            return
        }

        let nextIndex = currentPhaseIndex + 1
        if nextIndex < phases.count {
            currentPhaseIndex = nextIndex
            remainingSeconds = phases[nextIndex].duration
            SoundPlayer.shared.playTone()
        } else {
            // Cycle complete - increment count and restart from beginning
            cyclesCompleted += 1
            currentPhaseIndex = 0
            remainingSeconds = phases[0].duration
            SoundPlayer.shared.playTone()
        }
    }
}

private struct Phase {
    let name: String
    let subtitle: String
    let duration: Int
    let color: Color
}

private struct CircleArc: Shape {
    let startAngle: Angle
    let endAngle: Angle

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2
        path.addArc(center: center,
                    radius: radius,
                    startAngle: startAngle,
                    endAngle: endAngle,
                    clockwise: false)
        return path
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
