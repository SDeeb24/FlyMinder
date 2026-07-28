import AppKit
import QuartzCore
import SwiftUI

// Transparent, click-through panel that floats above every window (including fullscreen apps).
// Flight motion uses Core Animation on a rasterized layer — not SwiftUI `withAnimation` —
// so the banner stays smooth even on busy desktops.
final class AirplaneOverlayWindow: NSPanel {

    private let flightDuration: TimeInterval
    private weak var flyerView: NSView?

    init(message: String, flightDuration: Double, screen: NSScreen? = nil) {
        self.flightDuration = flightDuration

        let targetScreen = screen ?? NSScreen.main ?? NSScreen.screens.first
        let sf = targetScreen?.frame ?? .zero
        let height: CGFloat = 200
        let yPos = sf.minY + sf.height * 0.65
        let scale = targetScreen?.backingScaleFactor ?? 2

        super.init(
            contentRect: NSRect(x: sf.minX, y: yPos, width: sf.width, height: height),
            styleMask:   [.borderless, .nonactivatingPanel],
            backing:     .buffered,
            defer:       false
        )

        self.level                = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.maximumWindow)) + 1)
        self.backgroundColor      = .clear
        self.isOpaque             = false
        self.hasShadow            = false
        self.ignoresMouseEvents   = true
        self.collectionBehavior   = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
        self.isReleasedWhenClosed = false
        self.animationBehavior    = .none

        let container = NSView(frame: NSRect(x: 0, y: 0, width: sf.width, height: height))
        container.wantsLayer = true
        container.layer?.backgroundColor = .clear

        let hosting = NSHostingView(rootView: AirplaneView(message: message))
        hosting.wantsLayer = true
        // Give SwiftUI a generous proposed size so fittingSize reflects real content.
        hosting.setFrameSize(NSSize(width: 4_000, height: height))
        hosting.layoutSubtreeIfNeeded()
        var contentSize = hosting.fittingSize
        if contentSize.width < 2 || contentSize.height < 2 {
            contentSize = hosting.intrinsicContentSize
        }
        if contentSize.width < 2 || contentSize.height < 2 {
            // Last-resort estimate so we still animate something visible.
            contentSize = NSSize(width: 520, height: AirplaneView.planeSize)
        }
        contentSize = NSSize(
            width: max(contentSize.width, 1),
            height: min(max(contentSize.height, 1), height)
        )
        // Start fully off the left edge.
        hosting.frame = NSRect(
            x: -contentSize.width,
            y: (height - contentSize.height) / 2,
            width: contentSize.width,
            height: contentSize.height
        )

        if let layer = hosting.layer {
            layer.backgroundColor = .clear
            // Bake SwiftUI into a bitmap once; only the layer transform animates after that.
            layer.shouldRasterize = true
            layer.rasterizationScale = scale
            layer.drawsAsynchronously = true
        }

        container.addSubview(hosting)
        self.contentView = container
        self.flyerView = hosting

        // Kick off after the window is on-screen so the layer exists.
        DispatchQueue.main.async { [weak self] in
            self?.startFlight(
                flyer: hosting,
                contentWidth: contentSize.width,
                screenWidth: sf.width
            )
        }
    }

    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }

    private func startFlight(flyer: NSView, contentWidth: CGFloat, screenWidth: CGFloat) {
        guard let layer = flyer.layer else { return }

        let travel = screenWidth + contentWidth

        let move = CABasicAnimation(keyPath: "transform.translation.x")
        move.fromValue = 0
        move.toValue = travel
        move.duration = flightDuration
        move.timingFunction = CAMediaTimingFunction(name: .linear)
        move.fillMode = .forwards
        move.isRemovedOnCompletion = false

        let fade = CABasicAnimation(keyPath: "opacity")
        fade.fromValue = 1
        fade.toValue = 0
        fade.beginTime = CACurrentMediaTime() + max(0, flightDuration - 0.6)
        fade.duration = 0.6
        fade.fillMode = .forwards
        fade.isRemovedOnCompletion = false

        layer.add(move, forKey: "flyminder.move")
        layer.add(fade, forKey: "flyminder.fade")
    }
}
