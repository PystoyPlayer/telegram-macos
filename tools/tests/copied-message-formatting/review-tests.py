from pathlib import Path
import subprocess
import tempfile

root = Path(__file__).resolve().parents[3]
source = (root / 'packages/InputView/Sources/InputView/ChatTextInputState.swift').read_text()
start = source.index('    public func makeAttributeString(')
end = source.index('    public func subInputState(', start)
method = source[start:end].replace('public func', 'func')
interaction = (root / 'packages/ChatUI/Sources/ChatUI/ChatInterfaceInteraction.swift').read_text()
start = interaction.index('        if selectedRange.lowerBound - 1 >= 0')
end = interaction.index('//        if selectedRange.lowerBound', start)
inherit = interaction[start:end]
fixture = '''import Cocoa
extension String { var length: Int { (self as NSString).length }; var nsstring: NSString { self as NSString } }
extension NSAttributedString { static func initialize(string: String) -> NSAttributedString { NSAttributedString(string: string) }; var range: NSRange { NSRange(location: 0, length: length) } }
enum TextInputAttributes { static let code = NSAttributedString.Key("code"); static let quote = NSAttributedString.Key("quote"); static let bold = NSAttributedString.Key("bold") }
class TextInputTextCustomEmojiAttribute: NSObject {}
enum Attribute { case pre(Range<Int>, String?), other }
class Input { let text: NSAttributedString; let attributes: [Attribute]; init(_ text: NSAttributedString, _ attributes: [Attribute]) { self.text = text; self.attributes = attributes }; func textInputState() -> (inputText: NSAttributedString, unused: Int) { (text, 0) }
__METHOD__
}
func chatTextAttributes(from text: NSAttributedString) -> [String] {
    var result: [String] = []
    text.enumerateAttributes(in: text.range) { attrs, _, _ in if attrs.keys.contains(where: { [TextInputAttributes.code, TextInputAttributes.quote, TextInputAttributes.bold].contains($0) }) { result.append("format") } }
    return result
}
func inherited(_ incoming: NSAttributedString, after inputText: NSAttributedString) -> NSAttributedString {
    let text = NSMutableAttributedString(attributedString: incoming)
    let selectedRange = inputText.length..<inputText.length
__INHERIT__
    return text
}
var failures = 0
func check(_ value: Bool, _ title: String) { print("\\(value ? "PASS" : "FAIL"): \\(title)"); if !value { failures += 1 } }
let source = NSAttributedString(string: "print(1)", attributes: [TextInputAttributes.code: "swift"])
let input = Input(source, [.pre(0..<8, "swift")])
let legacy = input.makeAttributeString(addPreAsBlock: true)
check(legacy.string == "```swift\\nprint(1)```", "legacy editor keeps its existing fenced representation")
check(legacy.attribute(TextInputAttributes.code, at: 10, effectiveRange: nil) == nil, "fenced edit text has no overlapping code run that blocks markdown parsing")
check(input.makeAttributeString().isEqual(to: source), "ordinary attributed state preserves structured code")
let previous = NSAttributedString(string: "x", attributes: [TextInputAttributes.quote: "old quote", TextInputAttributes.code: "old language"])
let pasted = inherited(source, after: previous)
check(pasted.attribute(TextInputAttributes.code, at: 0, effectiveRange: nil) as? String == "swift", "paste keeps its own code language")
check(pasted.attribute(TextInputAttributes.quote, at: 0, effectiveRange: nil) == nil, "paste does not inherit preceding quote")
let plain = inherited(NSAttributedString(string: "plain"), after: previous)
check(plain.attribute(TextInputAttributes.quote, at: 0, effectiveRange: nil) as? String == "old quote", "plain typing retains surrounding formatting")
exit(failures == 0 ? 0 : 1)
'''.replace('__METHOD__', method).replace('__INHERIT__', inherit)
with tempfile.TemporaryDirectory(prefix='copy-review-') as temp:
    temp = Path(temp)
    (temp/'main.swift').write_text(fixture)
    subprocess.run(['swiftc', str(temp/'main.swift'), '-o', str(temp/'tests')], check=True)
    raise SystemExit(subprocess.run([str(temp/'tests')]).returncode)
