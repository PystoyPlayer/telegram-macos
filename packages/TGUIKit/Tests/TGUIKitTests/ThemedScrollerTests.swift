import XCTest
import AppKit
import ColorPalette
@testable import TGUIKit

final class ThemedScrollerTests: XCTestCase {
    override func setUp() {
        super.setUp()
        TGUIKitTestBootstrap.install()
    }

    func testVerticalOptInPreservesNativeScrollerIdentity() throws {
        let view = ScrollView(frame: NSRect(x: 0, y: 0, width: 320, height: 400))
        XCTAssertFalse(view.hasVerticalScroller)
        view.hasVerticalScroller = true
        let scroller = try XCTUnwrap(view.verticalScroller)
        XCTAssertTrue(scroller is ThemedScroller)
        XCTAssertEqual(scroller.scrollerStyle, .overlay)
        view.applyThemedVerticalScroller()
        XCTAssertTrue(view.verticalScroller === scroller)
        view.hasVerticalScroller = false
        view.hasVerticalScroller = true
        XCTAssertTrue(view.verticalScroller === scroller)
    }

    func testHorizontalOnlyViewDoesNotGainVerticalScroller() {
        let view = HorizontalScrollView(frame: NSRect(x: 0, y: 0, width: 320, height: 400))
        XCTAssertFalse(view.hasVerticalScroller)
    }
    func testHighContrastFollowsTelegramPaletteWithOppositeSystemAppearance() {
        let original = PresentationTheme.current
        defer { updateTheme(original) }
        let scroller = ThemedScroller(frame: NSRect(x: 0, y: 0, width: 16, height: 200))
        for palette in [nightAccentPalette, whitePalette] {
            updateTheme(PresentationTheme(colors: palette, search: original.search, inputTheme: original.inputTheme))
            for appearance in [NSAppearance.Name.aqua, .darkAqua] {
                scroller.appearance = NSAppearance(named: appearance)
                scroller.effectiveAppearance.performAsCurrentDrawingAppearance {
                    for expanded in [false, true] {
                        let color = scroller.knobColor(expanded: expanded, highContrast: true)
                        XCTAssertEqual(color, palette.text.withAlphaComponent(1))
                        XCTAssertEqual(color.alphaComponent, 1)
                    }
                }
            }
        }
    }

}
