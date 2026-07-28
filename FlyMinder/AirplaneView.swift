import SwiftUI

struct AirplaneView: View {
    let message: String
    let flightDuration: Double
    let screenWidth: CGFloat

    @State private var xOffset: CGFloat = 0
    @State private var opacity: Double = 1.0
    @State private var contentWidth: CGFloat = 0

    init(message: String, flightDuration: Double, screenWidth: CGFloat = NSScreen.main?.frame.width ?? 1_440) {
        self.message        = message
        self.flightDuration = flightDuration
        self.screenWidth    = screenWidth
    }

    var body: some View {
        HStack(spacing: -10) {
            Text(message)
                .font(BannerFont.font(size: 28))
                .foregroundStyle(.white)
                .lineLimit(1)
                .padding(.horizontal, 50)
                .padding(.vertical, 22)
                .background(
                    Image("banner")
                        .resizable()
                        .interpolation(.high)
                )

            Image("airplane")
                .resizable()
                .interpolation(.high)
                .scaledToFit()
                .frame(width: 220, height: 220)
                .zIndex(-1)
        }
        .fixedSize()
        .background(
            GeometryReader { geo in
                Color.clear.preference(key: ContentWidthKey.self, value: geo.size.width)
            }
        )
        .onPreferenceChange(ContentWidthKey.self) { contentWidth = $0 }
        // Rasterize once so SwiftUI animates a single texture instead of
        // re-compositing large bitmaps every frame (was the main source of hitching).
        .drawingGroup(opaque: false)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .offset(x: xOffset)
        .opacity(opacity)
        .onChange(of: contentWidth) { _, width in
            guard width > 0, xOffset == 0 else { return }
            xOffset = -width
            withAnimation(.linear(duration: flightDuration)) {
                xOffset = screenWidth + width
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + flightDuration - 0.6) {
                withAnimation(.easeIn(duration: 0.6)) {
                    opacity = 0
                }
            }
        }
    }
}

private struct ContentWidthKey: PreferenceKey {
    static let defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

#Preview {
    AirplaneView(message: "Get up and stretch!", flightDuration: 14)
        .frame(width: 1000, height: 100)
        .background(Color.gray.opacity(0.2))
}
