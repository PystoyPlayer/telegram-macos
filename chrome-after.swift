import Cocoa
let app = NSApplication.shared
app.setActivationPolicy(.prohibited)
class AppWindow: Window {}
class Window: NSWindow {
 enum ChromeMode { case compact, standard }
 var isFullScreen: Bool { styleMask.contains(.fullScreen) }
 func setTrafficLightsInset(_ value: NSPoint?) {}
 public func applyChrome(_ mode: ChromeMode) {
        let windowFrame = frame
        switch mode {
        case .compact:
            self.toolbar = nil
            self.styleMask.remove(.fullSizeContentView)
            self.titlebarAppearsTransparent = false
            self.titleVisibility = .visible
            self.setTrafficLightsInset(nil)
        case .standard:
            self.styleMask.insert(.fullSizeContentView)
            self.titlebarAppearsTransparent = true
            self.titleVisibility = .hidden
            if #available(macOS 26, *) {
                let toolbar = NSToolbar(identifier: "window")
                toolbar.allowsUserCustomization = false
                toolbar.allowsDisplayModeCustomization = false
                toolbar.showsBaselineSeparator = false
                self.toolbar = toolbar
                toolbar.isVisible = !self.isFullScreen
                self.setTrafficLightsInset(nil)
            } else {
                self.toolbar = nil
                self.setTrafficLightsInset(self is AppWindow ? NSPoint(x: 15, y: 8) : NSPoint(x: 10, y: 6))
            }
        }
        setFrame(windowFrame, display: false)
        contentView?.setFrameSize(contentRect(forFrameRect: windowFrame).size)
    }
}
final class Delegate: NSObject, NSWindowDelegate {
 let window: Window
 var mode = false
 init(window: Window) { self.window=window; super.init() }
 func windowDidResize(_ notification: Notification) {
   let compact=window.frame.width < 650
   if compact != mode {
     mode=compact
     window.applyChrome(compact ? .compact : .standard)
   }
 }
}
let window=Window(contentRect:NSMakeRect(0,0,1100,800),styleMask:[.titled,.closable,.resizable,.miniaturizable],backing:.buffered,defer:false)
window.contentView = NSView()
window.contentView!.autoresizingMask = [.width,.height]
window.applyChrome(.standard)
let delegate=Delegate(window:window)
window.delegate=delegate
for size in [NSSize(width:560,height:700), NSSize(width:1100,height:800), NSSize(width:560,height:700), NSSize(width:1100,height:800)] {
 window.setFrame(NSRect(origin:.zero,size:size),display:false)
 window.layoutIfNeeded()
 print("requested=\(size) frame=\(window.frame.size) content=\(window.contentView!.frame.size)")
}
window.delegate=nil
window.close()
