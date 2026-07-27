import AppKit
import SwiftUI

enum BannerFont {
    private static let preferredName = "Comic Sans MS"

    static func font(size: CGFloat) -> Font {
        if NSFont(name: preferredName, size: size) != nil {
            return .custom(preferredName, size: size)
        }
        return .system(size: size, weight: .bold, design: .rounded)
    }
}
