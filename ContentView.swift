import SwiftUI

struct ContentView: View {
    private let phases: [Phase] = [
        .init(name: "Breathe In", duration: 4, color: .green),
        .init(name: "Hold", duration: 7, color: .yellow),
        .init(name: "Breathe Out", duration: 8, color: .red)
    ]

    @State private var currentPhaseIndex = 0
    @State private var remainingSeconds = 4
    @State private var isRunning = false
    @State private var timer: Timer? = nil

    private var totalDuration: Int {
        phases.reduce(0) { $0 + $1.duration }
    }

    private var elapsedSeconds: Int {
        phases.prefix(currentPhaseIndex).reduce(0) { $0 + $1.duration } + (phases[currentPhaseIndex].duration - remainingSeconds)
    }

    var body: some View {
        VStack(spacing: 32) {
            Text("4-7-8 Breathing")
                .font(.largeTitle)
                .bold()

            breathingRing
                .frame(width: 300, height: 300)

            VStack(spacing: 12) {
                Text(phases[currentPhaseIndex].name)
                    .font(.title2)
                    .bold()

                Text("\(remainingSeconds) seconds")
                    .font(.title)
                    .monospacedDigit()
            }

            HStack(spacing: 24) {
                Button(action: startSession) {
                    Text(isRunning ? "Restart" : "Start")
                        .font(.headline)
                        .frame(minWidth: 120, minHeight: 44)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }

                Button(action: stopSession) {
                    Text("Stop")
                        .font(.headline)
                        .frame(minWidth: 120, minHeight: 44)
                        .background(Color.gray.opacity(0.2))
                        .foregroundColor(.primary)
                        .cornerRadius(12)
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                ForEach(phases.indices, id: \ .self) { index in
                    HStack {
                        Circle()
                            .fill(phases[index].color)
                            .frame(width: 16, height: 16)
                        Text(phaseDescription(for: phases[index]))
                    }
                }
            }
            .font(.subheadline)
            .padding(.top)
        }
        .padding()
        .onAppear(perform: resetSession)
    }

    private var breathingRing: some View {
        ZStack {
            Circle()
                .stroke(Color.secondary.opacity(0.2), lineWidth: 28)

            ForEach(phases.indices, id: \ .self) { index in
                CircleArc(startAngle: startAngle(for: index), endAngle: endAngle(for: index))
                    .stroke(phases[index].color.opacity(currentPhaseIndex == index ? 0.9 : 0.4), lineWidth: 28)
            }

            CircleArc(startAngle: progressStartAngle, endAngle: progressEndAngle)
                .stroke(Color.white, style: StrokeStyle(lineWidth: 32, lineCap: .round))
                .shadow(color: .black.opacity(0.2), radius: 3, x: 0, y: 1)

            Text(progressLabel)
                .font(.title2)
                .bold()
                .foregroundColor(.white)
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

    private func startSession() {
        stopSession()
        currentPhaseIndex = 0
        remainingSeconds = phases[0].duration
        isRunning = true
        SoundPlayer.shared.playTone()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            tick()
        }
    }

    private func stopSession() {
        timer?.invalidate()
        timer = nil
        isRunning = false
    }

    private func resetSession() {
        currentPhaseIndex = 0
        remainingSeconds = phases[0].duration
        isRunning = false
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
            stopSession()
        }
    }
}

private struct Phase {
    let name: String
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
