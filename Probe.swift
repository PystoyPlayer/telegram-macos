import Cocoa

struct Colors { var background: NSColor = .windowBackgroundColor }
class PresentationTheme { var colors = Colors() }
class TelegramPresentationTheme: PresentationTheme {}
let presentation = TelegramPresentationTheme()
let theme = presentation
enum ContainedViewLayoutTransition {
    case immediate
    func updateFrame(view: NSView, frame: CGRect) { view.frame = frame }
}
extension CGSize { var bounds: CGRect { CGRect(origin: .zero, size: self) } }
class View: NSView {
    var backgroundColor: NSColor = .clear { didSet { layer?.backgroundColor = backgroundColor.cgColor } }
    required override init(frame: NSRect) { super.init(frame: frame); wantsLayer = true }
    required init?(coder: NSCoder) { fatalError() }
    func updateLocalizationAndTheme(theme: PresentationTheme) {}
}
class LiquidGlassView: View {
    var cornerRadius: CGFloat { didSet { layer?.cornerRadius = cornerRadius } }
    var customTint: NSColor?
    init(frame: NSRect, cornerRadius: CGFloat, hasShadow: Bool = false, hasBorder: Bool = false, tintAlpha: CGFloat = 0, customTint: NSColor? = nil, forceBlur: Bool = false) {
        self.cornerRadius = cornerRadius
        super.init(frame: frame)
        layer?.cornerRadius = cornerRadius
        backgroundColor = .controlBackgroundColor
    }
    required init(frame: NSRect) { cornerRadius = 0; super.init(frame: frame) }
    required init?(coder: NSCoder) { fatalError() }
    func updateLayout(size: NSSize, transition: ContainedViewLayoutTransition) {}
}
enum EntertainmentView { static let glassTintAlpha: CGFloat = 0.65 }

MAIN_SOURCE
ENT_SOURCE
LEFT_SOURCE

let app = NSApplication.shared
app.setActivationPolicy(.prohibited)
let destination = URL(fileURLWithPath: CommandLine.arguments[1])
var checks = 0
var failures: [String] = []
var records: [[String: Any]] = []
func check(_ message: String, _ actual: CGFloat, _ expected: CGFloat) {
    checks += 1
    if abs(actual - expected) > 0.01 { failures.append("\(message): \(actual) != \(expected)") }
}
let fallback: CGFloat
if #available(macOS 26, *) { fallback = 20 } else { fallback = 8 }
for appearance in [NSAppearance.Name.aqua, .darkAqua] {
    for folders in ["none", "horizontal", "vertical"] {
        let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 1100, height: 800), styleMask: [.titled, .closable, .resizable], backing: .buffered, defer: false)
        window.isReleasedWhenClosed = false
        window.appearance = NSAppearance(named: appearance)
        let root = View(frame: window.contentView!.bounds)
        window.contentView = root
        let main = MainController_View(frame: .zero)
        let left = LeftSidebarViewProbe(frame: .zero)
        let entertainment = EntertainmentSidebarView(frame: .zero)
        root.addSubview(main)
        if folders == "vertical" { root.addSubview(left) }
        root.addSubview(entertainment)
        window.orderFrontRegardless()
        for width: CGFloat in [1100, 560, 1100] {
            let compact = width < 650 && folders != "vertical"
            if compact {
                window.toolbar = nil
                window.styleMask.remove(.fullSizeContentView)
            } else {
                window.styleMask.insert(.fullSizeContentView)
                if #available(macOS 26, *) { window.toolbar = NSToolbar(identifier: "window") }
            }
            window.setContentSize(NSSize(width: width, height: 800))
            root.frame = window.contentView!.bounds
            let rail: CGFloat = folders == "vertical" ? 90 : 0
            main.compactCorners = compact
            main.frame = NSRect(x: compact ? 0 : 8 + rail, y: compact ? 0 : 8, width: compact ? width : 292, height: compact ? root.bounds.height : root.bounds.height - 16)
            left.frame = NSRect(x: 8, y: 8, width: 82, height: root.bounds.height - 16)
            entertainment.frame = NSRect(x: width - 366, y: 8, width: 358, height: root.bounds.height - 16)
            entertainment.isHidden = width < 1000
            root.layoutSubtreeIfNeeded()
            window.layoutIfNeeded()
            RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.1))
            var expected = compact ? 0 : fallback
            var expectedLeft = fallback
            var expectedEntertainment = fallback
#if compiler(>=6.4)
            if #available(macOS 27, *) {
                expected = main.effectiveCornerRadii?.topLeft ?? -1
                expectedLeft = left.effectiveCornerRadii?.topLeft ?? -1
                expectedEntertainment = entertainment.effectiveCornerRadii?.topLeft ?? -1
            }
#endif
            let mainBackground = main.subviews[0].layer?.cornerRadius ?? -1
            let mainGlass = (main.subviews[1] as! LiquidGlassView).cornerRadius
            let entertainmentGlass = (entertainment.subviews[0] as! LiquidGlassView).cornerRadius
            check("main background", mainBackground, expected)
            check("main glass", mainGlass, expected)
            if folders == "vertical" { check("folder rail", left.cornerRadius, expectedLeft) }
            if width > 1000 {
                check("entertainment glass", entertainmentGlass, expectedEntertainment)
                check("entertainment content", entertainment.subviews[1].layer?.cornerRadius ?? -1, expectedEntertainment)
            }
            records.append(["appearance": appearance.rawValue, "folders": folders, "width": width, "compact": compact, "mainBackground": mainBackground, "mainGlass": mainGlass, "folderRail": left.cornerRadius, "entertainmentGlass": entertainmentGlass, "expectedMain": expected])
        }
        window.close()
    }
}
let result: [String: Any] = ["os": ProcessInfo.processInfo.operatingSystemVersionString, "checks": checks, "failures": failures, "records": records, "scope": "Real AppKit with extracted production corner policy and controlled View/LiquidGlass dependencies; not the full Telegram client"]
try JSONSerialization.data(withJSONObject: result, options: [.prettyPrinted, .sortedKeys]).write(to: destination.appendingPathComponent("results.json"))
print("\(checks-failures.count)/\(checks) checks passed on \(ProcessInfo.processInfo.operatingSystemVersionString)")
for failure in failures { print("FAIL: \(failure)") }
exit(failures.isEmpty ? 0 : 1)
