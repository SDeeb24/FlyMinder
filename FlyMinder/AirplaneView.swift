import SwiftUI

/// Static banner + airplane artwork. Motion is driven by Core Animation in
/// `AirplaneOverlayWindow` so the flight stays smooth.
struct AirplaneView: View {
    let message: String

    /// Display size of the plane — kept modest so the rasterized layer stays cheap.
    static let planeSize: CGFloat = 160

    var body: some View {
        HStack(spacing: -8) {
            Text(message)
                .font(BannerFont.font(size: 28))
                .foregroundStyle(.white)
                .lineLimit(1)
                .padding(.horizontal, 44)
                .padding(.vertical, 18)
                .background(
                    Image("banner")
                        .resizable()
                        .interpolation(.medium)
                )

            Image("airplane")
                .resizable()
                .interpolation(.medium)
                .scaledToFit()
                .frame(width: Self.planeSize, height: Self.planeSize)
                .zIndex(-1)
        }
        .fixedSize()
    }
}

#Preview {
    AirplaneView(message: "Get up and stretch!")
        .frame(width: 1000, height: 100)
        .background(Color.gray.opacity(0.2))
}
