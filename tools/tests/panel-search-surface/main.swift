import AppKit
import ColorPalette
import TGUIKit

typealias TelegramPresentationTheme = PresentationTheme
struct FixtureStrings {
  var requestJoinListSearchEmptyHeader: String { "No results" }
  var voiceOverCommonLoading: String { "Loading" }
  func requestJoinListSearchEmpty(_ query: String) -> String { "No results for \(query)" }
}
func strings() -> FixtureStrings { FixtureStrings() }

_ = NSApplication.shared
NSApp.setActivationPolicy(.accessory)
let assets = imagePaths.map { name, path -> NSImage in
  let image = NSImage(contentsOfFile: path)!
  image.setName(name)
  return image
}
var checks = 0
var failures: [String] = []
func check(_ value: @autoclosure () -> Bool, _ message: String) {
  checks += 1
  if !value() {
    failures.append(message)
    print("FAIL: \(message)")
  }
}
let window = NSWindow(contentRect: NSMakeRect(-4000, -4000, 350, 300), styleMask: .borderless, backing: .buffered, defer: false)
window.isReleasedWhenClosed = false
let parent = View(frame: NSMakeRect(0, 0, 350, 300))
window.contentView = parent
window.orderFront(nil)
let status = PanelSearchStatusView(frame: parent.bounds)
parent.addSubview(status)
let search = View(frame: NSMakeRect(0, 0, 350, 50))
let table = TableView(frame: parent.bounds)
let layouts = [layout_emoji, layout_stickers, layout_gifs]
for palette in [dayClassicPalette, nightAccentPalette] {
  let appearance = PresentationTheme(colors: palette, search: PresentationTheme.current.search, inputTheme: PresentationTheme.current.inputTheme)
  updateTheme(appearance)
  parent.backgroundColor = palette.background
  for kind in [PanelSearchPlaceholderKind.emoji, .stickers, .gifs] {
    status.updateSearchStatus(.loading, kind: kind, query: "unicorn", theme: appearance)
    status.layoutSubtreeIfNeeded()
    check(status.backgroundColor.alphaComponent == 0, "Loading surface is opaque")
    check(status.testMask.path?.isEmpty == false, "Loading placeholders are missing")
    check(status.testShimmer.frame == status.bounds, "Loading shimmer does not follow bounds")
    check(status.accessibilityRole() == .busyIndicator, "Loading status lost its accessible role")
    check(status.hitTest(NSMakePoint(10, 10)) == nil, "Loading status blocks picker interaction")
    for reduceMotion in [true, false] {
      status.update(status: .loading, kind: kind, title: "No results", detail: "", loadingLabel: "Loading", backgroundColor: status.backgroundColor, textColor: palette.text, detailColor: palette.grayText, reduceMotion: reduceMotion, makeAnimation: { nil })
      check((status.testShimmer.animation(forKey: "searchShimmer") == nil) == reduceMotion, "Loading animation ignores Reduce Motion")
    }
    status.updateSearchStatus(.empty, kind: kind, query: "unicorn", theme: appearance)
    check(status.testShimmer.animation(forKey: "searchShimmer") == nil, "Loading animation continues after an empty response")
    status.updateSearchStatus(.hidden, kind: kind, query: "", theme: appearance)
    check(status.isHidden, "Loading status remains visible after results arrive")
  }
}
for layout in layouts {
  for width: CGFloat in [280, 350, 520] {
    for height: CGFloat in [30, 180, 300, 500] {
      for bottom: CGFloat in [0, 56] {
        table.contentInsets = NSEdgeInsets(bottom: bottom)
        layout(NSMakeSize(width, height), search, table, status, .immediate)
        let expectedHeight = max(0, height - search.frame.maxY - bottom)
        check(status.frame.height == expectedHeight, "Status leaves a false footer gap: \(width)×\(height), inset \(bottom)")
        check(status.frame.width == width, "Status width does not follow picker resizing")
        check(status.frame.minY == search.frame.maxY, "Status overlaps the search field")
      }
    }
  }
}
status.updateSearchStatus(.loading, kind: .emoji, query: "unicorn", theme: PresentationTheme.current)
status.removeFromSuperview()
check(status.testShimmer.animation(forKey: "searchShimmer") == nil, "Loading animation survives closing the picker")
window.orderOut(nil)
if CommandLine.arguments.contains("--expect-regression") {
  let expected = failures.filter { $0 == "Loading surface is opaque" || $0.hasPrefix("Status leaves a false footer gap") }
  guard expected.count == failures.count, expected.count > 0 else { exit(1) }
  print("Baseline reproduced \(expected.count) opaque-surface/footer failures")
} else {
  guard failures.isEmpty else { exit(1) }
  print("Panel search: \(checks) native checks passed")
}
