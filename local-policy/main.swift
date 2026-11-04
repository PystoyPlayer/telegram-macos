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

final class MainController_View: View {
    private let bgView: View = View()
    private let glassView: LiquidGlassView

    private static var containerCornerRadius: CGFloat {
        if #available(macOS 26.0, *) {
            return 20
        }
        return 8
    }

    var compactCorners: Bool = false {
        didSet {
            if compactCorners != oldValue {
#if compiler(>=6.4)
                if #available(macOS 27.0, *) { invalidateCornerConfiguration() }
#endif
                applyCornerRadius()
            }
        }
    }

    private var currentCornerRadius: CGFloat {
        if compactCorners {
            return 0
        }
#if compiler(>=6.4)
        if #available(macOS 27.0, *), let radii = effectiveCornerRadii {
            return radii.topLeft
        }
#endif
        return MainController_View.containerCornerRadius
    }

#if compiler(>=6.4)
    @available(macOS 27.0, *)
    override var cornerConfiguration: NSViewCornerConfiguration? {
        .uniformCorners(radius: compactCorners ? .fixed(0) : .containerConcentric(8))
    }

    @available(macOS 27.0, *)
    override func viewDidChangeEffectiveCornerRadii() {
        super.viewDidChangeEffectiveCornerRadii()
        applyCornerRadius()
    }
#endif

    private func applyCornerRadius() {
        let radius = currentCornerRadius
        bgView.layer?.cornerRadius = radius
        glassView.cornerRadius = radius
    }

    required init(frame frameRect: NSRect) {
        let cornerRadius = MainController_View.containerCornerRadius
        glassView = LiquidGlassView(frame: frameRect.size.bounds, cornerRadius: cornerRadius, hasShadow: true, hasBorder: true, tintAlpha: 0, customTint: presentation.colors.background, forceBlur: true)
        super.init(frame: frameRect)

        self.layer?.masksToBounds = false
        self.backgroundColor = .clear

        bgView.backgroundColor = presentation.colors.background
        bgView.layer?.cornerRadius = cornerRadius
        bgView.layer?.masksToBounds = true

        addSubview(bgView)
        addSubview(glassView)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func updateLocalizationAndTheme(theme: PresentationTheme) {
        super.updateLocalizationAndTheme(theme: theme)
        bgView.backgroundColor = theme.colors.background
        glassView.customTint = theme.colors.background
    }

    override func layout() {
        super.layout()
        updateLayout(size: bounds.size, transition: .immediate)
    }

    func updateLayout(size: NSSize, transition: ContainedViewLayoutTransition) {
        transition.updateFrame(view: bgView, frame: CGRect(origin: .zero, size: size))
        transition.updateFrame(view: glassView, frame: CGRect(origin: .zero, size: size))
        glassView.updateLayout(size: size, transition: transition)
    }
}
final class EntertainmentSidebarView: View {
    private let glassView: LiquidGlassView
    fileprivate let contentView = View()

    private static var cornerRadius: CGFloat {
        if #available(macOS 26.0, *) {
            return 20
        }
        return 8
    }

    private var currentCornerRadius: CGFloat {
#if compiler(>=6.4)
        if #available(macOS 27.0, *), let radii = effectiveCornerRadii {
            return radii.topLeft
        }
#endif
        return EntertainmentSidebarView.cornerRadius
    }

#if compiler(>=6.4)
    @available(macOS 27.0, *)
    override var cornerConfiguration: NSViewCornerConfiguration? {
        .uniformCorners(radius: .containerConcentric(8))
    }

    @available(macOS 27.0, *)
    override func viewDidChangeEffectiveCornerRadii() {
        super.viewDidChangeEffectiveCornerRadii()
        applyCornerRadius()
    }
#endif

    private func applyCornerRadius() {
        let radius = currentCornerRadius
        glassView.cornerRadius = radius
        contentView.layer?.cornerRadius = radius
    }

    required init(frame frameRect: NSRect) {
        let radius = EntertainmentSidebarView.cornerRadius
        glassView = LiquidGlassView(frame: frameRect.size.bounds, cornerRadius: radius, hasShadow: true, hasBorder: true, tintAlpha: 0, customTint: theme.colors.background.withAlphaComponent(EntertainmentView.glassTintAlpha), forceBlur: true)
        super.init(frame: frameRect)
        layer?.masksToBounds = false
        backgroundColor = .clear

        contentView.layer?.cornerRadius = radius
        contentView.layer?.masksToBounds = true

        addSubview(glassView)
        addSubview(contentView)
        updateLocalizationAndTheme(theme: theme)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func updateLocalizationAndTheme(theme: PresentationTheme) {
        super.updateLocalizationAndTheme(theme: theme)
        let theme = theme as! TelegramPresentationTheme
        glassView.customTint = theme.colors.background.withAlphaComponent(EntertainmentView.glassTintAlpha)
    }

    override func layout() {
        super.layout()
        applyCornerRadius()
        glassView.frame = bounds
        glassView.updateLayout(size: bounds.size, transition: .immediate)
        contentView.frame = bounds
        for subview in contentView.subviews {
            subview.frame = contentView.bounds
        }
    }

    fileprivate func attach(_ view: NSView) {
        if view.superview !== contentView {
            contentView.addSubview(view, positioned: .below, relativeTo: nil)
        }
        view.frame = contentView.bounds
    }
}
final class LeftSidebarViewProbe: LiquidGlassView {
    private static var glassCornerRadius: CGFloat {
        if #available(macOS 26.0, *) {
            return 20
        }
        return 8
    }
#if compiler(>=6.4)
    @available(macOS 27.0, *)
    override var cornerConfiguration: NSViewCornerConfiguration? {
        .uniformCorners(radius: .containerConcentric(8))
    }

    @available(macOS 27.0, *)
    override func viewDidChangeEffectiveCornerRadii() {
        super.viewDidChangeEffectiveCornerRadii()
        cornerRadius = effectiveCornerRadii?.topLeft ?? LeftSidebarViewProbe.glassCornerRadius
    }
#endif


required init(frame: NSRect) { super.init(frame: frame, cornerRadius: Self.glassCornerRadius) }
required init?(coder: NSCoder) { fatalError() }
}

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
