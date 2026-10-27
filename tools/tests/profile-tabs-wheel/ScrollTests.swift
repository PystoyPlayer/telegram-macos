import Cocoa

struct NSEvent: Equatable {
    let scrollingDeltaX: CGFloat
    let scrollingDeltaY: CGFloat
    let hasPreciseScrollingDeltas: Bool
}
class Parent {
    var forwarded: [NSEvent] = []
    func scrollWheel(with event: NSEvent) { forwarded.append(event) }
}
final class Content {
    var frame = NSMakeRect(0, 0, 300, 34)
    func setFrameOrigin(_ point: CGPoint) { frame.origin = point }
}
final class ScrollSpy {
    var frame = NSMakeRect(0, 0, 300, 34)
    var events: [NSEvent] = []
    func scrollWheel(with event: NSEvent) { events.append(event) }
}
final class Tabs: Parent {
    let scrollView = ScrollSpy()
    let clipView = Content()
    let contentView = Content()
    var contentWidth: CGFloat = 800
    var scrollOffset: CGFloat = 0
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
let inputs: [(String, NSEvent)] = [
    ("ordinary mouse wheel", NSEvent(scrollingDeltaX: 0, scrollingDeltaY: -3, hasPreciseScrollingDeltas: false)),
    ("immediate reversal", NSEvent(scrollingDeltaX: 0, scrollingDeltaY: 3, hasPreciseScrollingDeltas: false)),
    ("precise vertical input", NSEvent(scrollingDeltaX: 0, scrollingDeltaY: -25, hasPreciseScrollingDeltas: true)),
    ("horizontal trackpad input", NSEvent(scrollingDeltaX: -12, scrollingDeltaY: 0, hasPreciseScrollingDeltas: true)),
    ("diagonal input", NSEvent(scrollingDeltaX: 4, scrollingDeltaY: -10, hasPreciseScrollingDeltas: true)),
    ("zero end event", NSEvent(scrollingDeltaX: 0, scrollingDeltaY: 0, hasPreciseScrollingDeltas: true))
]
let tabs = Tabs()
for (name, event) in inputs {
    tabs.scrollWheel(with: event)
    check("\(name) reaches the shared folder scroller unchanged", tabs.scrollView.events.last == event && tabs.forwarded.isEmpty)
}
check("all events retain their sequence", tabs.scrollView.events == inputs.map { $0.1 })
let fitting = Tabs()
fitting.contentWidth = 200
for (_, event) in inputs { fitting.scrollWheel(with: event) }
check("fitting strip forwards events without recursion", fitting.forwarded == inputs.map { $0.1 } && fitting.scrollView.events.isEmpty)
print("\(checks - failures)/\(checks) checks passed")
exit(failures == 0 ? 0 : 1)
