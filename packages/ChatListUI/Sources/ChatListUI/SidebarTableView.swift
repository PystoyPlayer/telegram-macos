import AppKit
import TGUIKit

final class SidebarScroller: NSScroller {
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

final class SidebarTableView: TableView {
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        configureScroller()
    }

    override init(frame frameRect: NSRect, isFlipped: Bool = true, bottomInset: CGFloat = 0, drawBorder: Bool = false) {
        super.init(frame: frameRect, isFlipped: isFlipped, bottomInset: bottomInset, drawBorder: drawBorder)
        configureScroller()
    }

    private func configureScroller() {
        let width = NSScroller.scrollerWidth(for: .regular, scrollerStyle: .overlay)
        verticalScroller = SidebarScroller(frame: NSMakeRect(0, 0, width, max(frame.height, width + 1)))
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func updateLocalizationAndTheme(theme: PresentationTheme) {
        super.updateLocalizationAndTheme(theme: theme)
        verticalScroller?.needsDisplay = true
    }
}
