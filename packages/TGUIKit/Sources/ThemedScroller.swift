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
        let color = highContrast ? NSColor.labelColor : presentation.colors.grayText.withAlphaComponent(expanded ? 0.85 : 0.55)
        color.setFill()
        NSBezierPath(roundedRect: rect, xRadius: width / 2, yRadius: width / 2).fill()
    }

    override func drawKnobSlot(in slotRect: NSRect, highlight flag: Bool) {
        super.drawKnobSlot(in: slotRect, highlight: flag)
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
