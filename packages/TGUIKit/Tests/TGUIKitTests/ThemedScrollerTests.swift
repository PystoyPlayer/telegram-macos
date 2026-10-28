import XCTest
import AppKit
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
}
