import SwiftUI

struct ConfettiView: View {
    @State private var confettiPieces: [ConfettiPiece] = []
    
    var body: some View {
        ZStack {
            ForEach(confettiPieces, id: \.id) { piece in
                Circle()
                    .fill(piece.color)
                    .frame(width: piece.size, height: piece.size)
                    .position(x: piece.x, y: piece.y)
                    .animation(
                        .linear(duration: piece.duration)
                        .repeatForever(autoreverses: false),
                        value: piece.y
                    )
            }
        }
        .onAppear {
            createConfetti()
        }
    }
    
    private func createConfetti() {
        withAnimation {
            for _ in 0..<50 {
                let piece = ConfettiPiece(
                    id: UUID(),
                    x: Double.random(in: 0...UIScreen.main.bounds.width),
                    y: -20,
                    size: Double.random(in: 4...12),
                    color: [.red, .blue, .green, .yellow, .purple, .orange].randomElement() ?? .red,
                    duration: Double.random(in: 2...4)
                )
                confettiPieces.append(piece)
            }
            
            // Animate confetti falling
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                for i in 0..<confettiPieces.count {
                    withAnimation(.linear(duration: confettiPieces[i].duration)) {
                        confettiPieces[i].y = UIScreen.main.bounds.height + 50
                    }
                }
            }
        }
    }
}

struct ConfettiPiece {
    let id: UUID
    let x: Double
    var y: Double
    let size: Double
    let color: Color
    let duration: Double
}