import Cocoa

struct NSEvent {
    let scrollingDeltaX: CGFloat
    let scrollingDeltaY: CGFloat
    let hasPreciseScrollingDeltas: Bool
}

class Parent {
    var forwarded = 0
    func scrollWheel(with event: NSEvent) { forwarded += 1 }
}

final class Content {
    var frame = NSMakeRect(0, 0, 0, 0)
    func setFrameOrigin(_ point: CGPoint) { frame.origin = point }
}

final class Tabs: Parent {
    let clipView = Content()
    let contentView = Content()
    var contentWidth: CGFloat = 800
    var scrollOffset: CGFloat = 0
    init(visibleWidth: CGFloat = 300) {
        clipView.frame.size.width = visibleWidth
    }
    CLAMP
    HANDLER
}

var failures = 0
var checks = 0
func check(_ name: String, _ condition: Bool) {
    checks += 1
    if !condition { failures += 1 }
    print("\(condition ? "PASS" : "FAIL") \(name)")
}
func wheel(_ x: CGFloat, _ y: CGFloat, precise: Bool = false) -> NSEvent {
    NSEvent(scrollingDeltaX: x, scrollingDeltaY: y, hasPreciseScrollingDeltas: precise)
}
let tabs = Tabs()
tabs.scrollWheel(with: wheel(0, -3))
check("ordinary vertical mouse wheel reveals later tabs", tabs.scrollOffset == 30 && tabs.contentView.frame.minX == -30)
check("overflowing tab strip consumes mouse wheel", tabs.forwarded == 0)
tabs.scrollWheel(with: wheel(0, 1))
check("reverse mouse wheel returns toward first tab", tabs.scrollOffset == 20)
let horizontal = Tabs()
horizontal.scrollWheel(with: wheel(-2, 0))
check("horizontal mouse wheel remains supported", horizontal.scrollOffset == 20)
let trackpad = Tabs()
trackpad.scrollWheel(with: wheel(-12, -1, precise: true))
check("trackpad horizontal movement retains pixel precision", trackpad.scrollOffset == 12)
trackpad.scrollWheel(with: wheel(0, -25, precise: true))
check("vertical trackpad gesture scrolls the profile", trackpad.forwarded == 1 && trackpad.scrollOffset == 12)
tabs.scrollWheel(with: wheel(0, -100))
check("last tab remains bounded", tabs.scrollOffset == 500)
tabs.scrollOffset = 500
tabs.scrollWheel(with: wheel(0, 100))
check("first tab remains bounded", tabs.scrollOffset == 0)
let fitting = Tabs(visibleWidth: 900)
fitting.scrollWheel(with: wheel(0, -3))
check("fitting strip forwards mouse wheel to profile", fitting.forwarded == 1 && fitting.scrollOffset == 0)
fitting.scrollWheel(with: wheel(-12, 0, precise: true))
check("fitting strip forwards horizontal trackpad movement", fitting.forwarded == 2)
print("\(checks - failures)/\(checks) checks passed")
exit(failures == 0 ? 0 : 1)
