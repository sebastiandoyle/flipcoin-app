import SwiftUI

struct ContentView: View {
    @State private var isFlipping = false
    @State private var rotation: Double = 0
    @State private var result: CoinSide? = nil
    @State private var showResult = false
    @State private var flipHistory: [CoinSide] = []
    @State private var particles: [Particle] = []

    enum CoinSide: String, CaseIterable {
        case heads = "Heads"
        case tails = "Tails"
    }

    var headsCount: Int { flipHistory.filter { $0 == .heads }.count }
    var tailsCount: Int { flipHistory.filter { $0 == .tails }.count }

    // Screenshot mode support
    init() {
        if let mode = ProcessInfo.processInfo.environment["SCREENSHOT_MODE"] {
            switch mode {
            case "heads":
                _result = State(initialValue: .heads)
                _showResult = State(initialValue: true)
                _flipHistory = State(initialValue: [.heads, .tails, .heads, .heads, .tails])
            case "tails":
                _result = State(initialValue: .tails)
                _showResult = State(initialValue: true)
                _flipHistory = State(initialValue: [.tails, .heads, .tails, .heads, .tails, .tails])
            case "history":
                _result = State(initialValue: .heads)
                _showResult = State(initialValue: true)
                _flipHistory = State(initialValue: [.heads, .tails, .heads, .heads, .tails, .tails, .heads, .tails, .heads, .heads])
            case "fresh":
                // Default state
                break
            default:
                break
            }
        }
    }

    var body: some View {
        ZStack {
            // Animated gradient background
            LinearGradient(
                colors: [
                    Color(red: 0.1, green: 0.1, blue: 0.2),
                    Color(red: 0.15, green: 0.1, blue: 0.25),
                    Color(red: 0.1, green: 0.15, blue: 0.3)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            // Particles
            ForEach(particles) { particle in
                Circle()
                    .fill(particle.color)
                    .frame(width: particle.size, height: particle.size)
                    .position(particle.position)
                    .opacity(particle.opacity)
            }

            VStack(spacing: 0) {
                // Stats bar
                HStack {
                    StatBubble(label: "Heads", count: headsCount, color: .orange)
                    Spacer()
                    StatBubble(label: "Tails", count: tailsCount, color: .blue)
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)

                Spacer()

                // Coin
                ZStack {
                    // Glow effect
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    (result == .heads ? Color.orange : Color.blue).opacity(0.3),
                                    Color.clear
                                ],
                                center: .center,
                                startRadius: 60,
                                endRadius: 150
                            )
                        )
                        .frame(width: 300, height: 300)
                        .opacity(showResult ? 1 : 0)

                    // Coin face
                    CoinView(side: showResult ? result : nil, rotation: rotation)
                        .frame(width: 200, height: 200)
                        .rotation3DEffect(
                            .degrees(rotation),
                            axis: (x: 0.1, y: 1, z: 0)
                        )
                        .shadow(color: .black.opacity(0.3), radius: 20, x: 0, y: 10)
                }

                // Result text
                Text(showResult ? (result?.rawValue ?? "") : "Tap to Flip")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .padding(.top, 40)
                    .opacity(showResult ? 1 : 0.6)

                Spacer()

                // Flip button
                Button(action: flipCoin) {
                    HStack(spacing: 12) {
                        Image(systemName: "arrow.triangle.2.circlepath")
                            .font(.system(size: 20, weight: .semibold))
                        Text("Flip Coin")
                            .font(.system(size: 18, weight: .semibold, design: .rounded))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 40)
                    .padding(.vertical, 18)
                    .background(
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [Color.purple, Color.blue],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                    )
                    .shadow(color: .purple.opacity(0.4), radius: 15, x: 0, y: 8)
                }
                .disabled(isFlipping)
                .opacity(isFlipping ? 0.6 : 1)
                .scaleEffect(isFlipping ? 0.95 : 1)
                .animation(.spring(response: 0.3), value: isFlipping)

                // History
                if !flipHistory.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(flipHistory.suffix(10).reversed().indices, id: \.self) { index in
                                let flip = flipHistory.suffix(10).reversed()[index]
                                Circle()
                                    .fill(flip == .heads ? Color.orange : Color.blue)
                                    .frame(width: 12, height: 12)
                                    .opacity(1 - Double(index) * 0.08)
                            }
                        }
                        .padding(.horizontal, 24)
                    }
                    .frame(height: 30)
                    .padding(.top, 20)
                }

                Spacer().frame(height: 40)
            }
        }
        .onTapGesture {
            if !isFlipping {
                flipCoin()
            }
        }
    }

    func flipCoin() {
        guard !isFlipping else { return }

        isFlipping = true
        showResult = false

        // Haptic feedback
        let impactMed = UIImpactFeedbackGenerator(style: .medium)
        impactMed.impactOccurred()

        // Determine result
        let newResult: CoinSide = Bool.random() ? .heads : .tails

        // Animate rotation
        let totalRotation = 1800.0 + (newResult == .heads ? 0 : 180)

        withAnimation(.easeInOut(duration: 0.1)) {
            rotation = 0
        }

        // Spinning animation with decreasing speed
        withAnimation(.easeOut(duration: 2.0)) {
            rotation = totalRotation
        }

        // Haptic during flip
        for i in 1...8 {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.15) {
                let light = UIImpactFeedbackGenerator(style: .light)
                light.impactOccurred()
            }
        }

        // Show result
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            result = newResult
            flipHistory.append(newResult)

            withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
                showResult = true
            }

            // Heavy haptic on land
            let heavy = UIImpactFeedbackGenerator(style: .heavy)
            heavy.impactOccurred()

            // Create particles
            createParticles(for: newResult)

            isFlipping = false
        }
    }

    func createParticles(for side: CoinSide) {
        let centerX = UIScreen.main.bounds.width / 2
        let centerY = UIScreen.main.bounds.height / 2 - 50
        let color = side == .heads ? Color.orange : Color.blue

        for _ in 0..<20 {
            let particle = Particle(
                position: CGPoint(x: centerX, y: centerY),
                color: color,
                size: CGFloat.random(in: 4...12),
                opacity: 1.0
            )
            particles.append(particle)

            // Animate particle outward
            let angle = Double.random(in: 0...360) * .pi / 180
            let distance = CGFloat.random(in: 100...200)
            let targetX = centerX + cos(angle) * distance
            let targetY = centerY + sin(angle) * distance

            withAnimation(.easeOut(duration: 0.8)) {
                if let index = particles.firstIndex(where: { $0.id == particle.id }) {
                    particles[index].position = CGPoint(x: targetX, y: targetY)
                    particles[index].opacity = 0
                }
            }

            // Remove particle after animation
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                particles.removeAll { $0.id == particle.id }
            }
        }
    }
}

struct Particle: Identifiable {
    let id = UUID()
    var position: CGPoint
    var color: Color
    var size: CGFloat
    var opacity: Double
}

struct CoinView: View {
    let side: ContentView.CoinSide?
    let rotation: Double

    var body: some View {
        ZStack {
            // Coin base
            Circle()
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 1.0, green: 0.85, blue: 0.4),
                            Color(red: 0.9, green: 0.7, blue: 0.2),
                            Color(red: 0.8, green: 0.6, blue: 0.1)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            // Coin rim
            Circle()
                .strokeBorder(
                    LinearGradient(
                        colors: [
                            Color(red: 1.0, green: 0.9, blue: 0.5),
                            Color(red: 0.7, green: 0.5, blue: 0.1)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 8
                )

            // Inner circle
            Circle()
                .strokeBorder(Color(red: 0.8, green: 0.65, blue: 0.2), lineWidth: 2)
                .padding(20)

            // Face content
            if let side = side {
                VStack(spacing: 4) {
                    Text(side == .heads ? "H" : "T")
                        .font(.system(size: 60, weight: .bold, design: .serif))
                        .foregroundColor(Color(red: 0.5, green: 0.35, blue: 0.1))
                }
            } else {
                Text("?")
                    .font(.system(size: 60, weight: .bold, design: .serif))
                    .foregroundColor(Color(red: 0.5, green: 0.35, blue: 0.1).opacity(0.5))
            }
        }
    }
}

struct StatBubble: View {
    let label: String
    let count: Int
    let color: Color

    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(color)
                .frame(width: 10, height: 10)
            Text("\(label): \(count)")
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundColor(.white.opacity(0.8))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(
            Capsule()
                .fill(Color.white.opacity(0.1))
        )
    }
}
