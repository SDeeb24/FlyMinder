import AppKit
import SwiftUI

// Transparent, click-through panel that floats above every window (including fullscreen apps).
final class AirplaneOverlayWindow: NSPanel {

    init(message: String, flightDuration: Double, screen: NSScreen? = nil) {
        let sf = (screen ?? NSScreen.main ?? NSScreen.screens.first)?.frame ?? .zero
        let height: CGFloat = 110
        let yPos = sf.minY + sf.height * 0.65

        super.init(
            contentRect: NSRect(x: sf.minX, y: yPos, width: sf.width, height: height),
            styleMask:   [.borderless, .nonactivatingPanel],
            backing:     .buffered,
            defer:       false
        )

        self.level               = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.maximumWindow)) + 1)
        self.backgroundColor     = .clear
        self.isOpaque            = false
        self.hasShadow           = false
        self.ignoresMouseEvents  = true
        self.collectionBehavior  = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
        self.isReleasedWhenClosed = false

        let rootView     = AirplaneView(message:         message,
                                        flightDuration:  flightDuration,
                                        screenWidth:     sf.width)
        let hostingView  = NSHostingView(rootView: rootView)
        hostingView.frame = NSRect(x: 0, y: 0, width: sf.width, height: height)
        hostingView.wantsLayer = true
        hostingView.layer?.backgroundColor = .clear
        self.contentView = hostingView
    }

    override var canBecomeKey:  Bool { false }
    override var canBecomeMain: Bool { false }
}
