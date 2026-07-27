import SwiftUI

#if canImport(UIKit)
import UIKit
#endif

struct BalloonReminderView: View {
    let message: String
    var onFinished: () -> Void

    @State private var riseProgress: CGFloat = 0
    @State private var contentOpacity: Double = 0

    var body: some View {
        GeometryReader { geo in
            let restY = geo.size.height * 0.58
            let startY = geo.size.height + 120
            let y = startY + (restY - startY) * riseProgress

            ZStack {
                Color.black.opacity(0.25 * contentOpacity)
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    balloon
                    string(height: 52)
                    verticalBanner
                }
                .position(x: geo.size.width / 2, y: y)
                .opacity(contentOpacity)
            }
            .onAppear {
                withAnimation(.spring(response: 0.95, dampingFraction: 0.72)) {
                    riseProgress = 1
                    contentOpacity = 1
                }

                DispatchQueue.main.asyncAfter(deadline: .now() + 0.85) {
                    triggerBumpHaptic()
                }

                DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
                    withAnimation(.easeIn(duration: 0.5)) {
                        contentOpacity = 0
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.55) {
                        onFinished()
                    }
                }
            }
        }
        .ignoresSafeArea()
    }

    private var balloon: some View {
        ZStack {
            Ellipse()
                .fill(
                    LinearGradient(
                        colors: [Color(red: 0.45, green: 0.72, blue: 0.98), Color(red: 0.28, green: 0.55, blue: 0.92)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 96, height: 110)
                .overlay(
                    Ellipse()
                        .stroke(Color(red: 0.15, green: 0.35, blue: 0.62), lineWidth: 3)
                )

            Ellipse()
                .fill(Color.white.opacity(0.35))
                .frame(width: 28, height: 18)
                .offset(x: -18, y: -24)

            RoundedRectangle(cornerRadius: 6)
                .fill(Color(red: 0.55, green: 0.36, blue: 0.22))
                .frame(width: 44, height: 28)
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(Color(red: 0.35, green: 0.22, blue: 0.12), lineWidth: 2)
                )
                .offset(y: 66)
        }
        .frame(height: 150)
    }

    private func string(height: CGFloat) -> some View {
        Rectangle()
            .fill(Color(red: 0.35, green: 0.28, blue: 0.22))
            .frame(width: 3, height: height)
    }

    private var verticalBanner: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10)
                .fill(
                    LinearGradient(
                        colors: [Color(red: 0.55, green: 0.78, blue: 0.98), Color(red: 0.38, green: 0.64, blue: 0.94)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color(red: 0.14, green: 0.34, blue: 0.58), lineWidth: 2.5)
                )

            Text(message)
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundStyle(Color(red: 0.06, green: 0.16, blue: 0.34))
                .rotationEffect(.degrees(-90))
                .fixedSize()
                .frame(width: 180, height: 52)
        }
        .frame(width: 58, height: 190)
    }

    private func triggerBumpHaptic() {
#if canImport(UIKit)
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
#endif
    }
}

#Preview {
    BalloonReminderView(message: "Get up and stretch!", onFinished: {})
}
