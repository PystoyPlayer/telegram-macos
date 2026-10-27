import AppKit

final class ThemedScroller: NSScroller {
    override class var isCompatibleWithOverlayScrollers: Bool { true }

    override func drawKnob() {
        let knob = rect(for: .knob)
        guard !knob.isEmpty else { return }
        let expanded = knob.width > 6 || hitPart == .knob
        let highContrast = NSWorkspace.shared.accessibilityDisplayShouldIncreaseContrast
        let width: CGFloat = expanded || highContrast ? 5 : 3
        let rect = NSMakeRect(knob.midX - width / 2, knob.minY, width, knob.height)
        presentation.colors.grayText.withAlphaComponent(expanded || highContrast ? 0.85 : 0.55).setFill()
        NSBezierPath(roundedRect: rect, xRadius: width / 2, yRadius: width / 2).fill()
    }

    override func drawKnobSlot(in slotRect: NSRect, highlight flag: Bool) {
    }
}

public extension NSScrollView {
    func applyThemedVerticalScroller() {
        guard hasVerticalScroller, !(verticalScroller is ThemedScroller) else { return }
        let size = verticalScroller?.controlSize ?? .regular
        let width = NSScroller.scrollerWidth(for: size, scrollerStyle: scrollerStyle)
        let scroller = ThemedScroller(frame: NSMakeRect(0, 0, width, max(frame.height, width + 1)))
        scroller.controlSize = size
        verticalScroller = scroller
    }
}
