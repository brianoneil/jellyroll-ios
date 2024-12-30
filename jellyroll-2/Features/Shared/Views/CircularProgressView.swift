import SwiftUI

struct CircularProgressView: View {
    let progress: Double
    let lineWidth: CGFloat
    let size: CGFloat
    let color: Color
    
    init(
        progress: Double,
        lineWidth: CGFloat = 2,
        size: CGFloat = 24,
        color: Color = .white
    ) {
        self.progress = progress
        self.lineWidth = lineWidth
        self.size = size
        self.color = color
    }
    
    var body: some View {
        ZStack {
            // Background circle
            Circle()
                .stroke(
                    color.opacity(0.3),
                    lineWidth: lineWidth
                )
            
            // Progress circle
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    color,
                    style: StrokeStyle(
                        lineWidth: lineWidth,
                        lineCap: .round
                    )
                )
                .rotationEffect(.degrees(-90))
        }
        .frame(width: size, height: size)
    }
} 