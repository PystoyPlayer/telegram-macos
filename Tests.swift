import Foundation

struct MessageId: Hashable { let peer: Int; let id: Int }
struct Message {
    let id: MessageId
    var sensitive = false
    func isSensitiveContent(platform: String) -> Bool { sensitive }
}
struct Config { var sensitiveContentEnabled = false; var canAdjustSensitiveContent = true }
struct AppConfig {
    var needsAge = false
    func getBoolValue(_ key: String, orElse: Bool) -> Bool { needsAge }
}
final class Context { var contentConfig = Config(); var appConfiguration = AppConfig(); let window = 0 }
final class Interaction { var revealMedia: (Message) -> Void = { _ in } }
struct Highlight { init(query: String, isMessage: Bool) {} }
struct Entry { let event = 0 }
struct MessageEntryAdditionalData {
    var isRevealed: Bool?
    init(highlightFoundText: Highlight, eventLog: Int, isRevealed: Bool? = nil) { self.isRevealed = isRevealed }
}
struct Strings { let chatSensitiveContent = "Warning"; let chatSensitiveContentConfirm = "Confirm"; let chatSensitiveContentConfirmOk = "Show" }
func strings() -> Strings { Strings() }
var confirmation: ((Int) -> Void)?
var agePrompts = 0
func verifyAlert(for window: Int, header: String, information: String, ok: String, successHandler: @escaping (Int) -> Void) { confirmation = successHandler }
struct ChatNavigationHooks {
    static let shared = ChatNavigationHooks()
    func showVerifyAgeAlert(_ context: Context, _ window: Int) { agePrompts += 1 }
}

STATE_SOURCE

private func flags(_ state: State, _ message: Message) -> [Bool] {
    let new = message
    let searchQuery = "test"
    let entry = Entry()
    return [ROW_SOURCE].map { $0.isRevealed ?? false }
}

private final class Scene {
    var state = State()
    var emissions = 0
    let context = Context()
    let chatInteraction = Interaction()
    init() {
        let context = self.context
        let chatInteraction = self.chatInteraction
        let updateState: (@escaping (State) -> State) -> Void = { [unowned self] f in
            let next = f(self.state)
            if next != self.state { self.emissions += 1 }
            self.state = next
        }
        CALLBACK_SOURCE
    }
}

var total = 0
var failed = 0
func check(_ name: String, _ value: Bool) {
    total += 1
    if !value { failed += 1; print("FAIL: \(name)") }
}
let a = Message(id: MessageId(peer: 1, id: 10))
let b = Message(id: MessageId(peer: 1, id: 11))
let otherPeer = Message(id: MessageId(peer: 2, id: 10))
private let scene = Scene()
check("all log row types concealed initially", flags(scene.state, a) == [false, false, false, false])
scene.chatInteraction.revealMedia(a)
for (index, value) in flags(scene.state, a).enumerated() { check("row type \(index) reveals after callback", value) }
check("callback emits a distinct state", scene.emissions == 1)
check("other deleted photo stays concealed", flags(scene.state, b).allSatisfy { !$0 })
check("message ids are scoped to peer", flags(scene.state, otherPeer).allSatisfy { !$0 })
check("media reveal does not expand deletion group", scene.state.revealed.isEmpty)
scene.state.revealed.insert(b.id)
check("group expansion does not reveal its media", flags(scene.state, b).allSatisfy { !$0 })
check("revealed media survives group expansion", flags(scene.state, a).allSatisfy { $0 })
scene.chatInteraction.revealMedia(a)
check("repeat reveal is idempotent", scene.emissions == 1)
check("new controller starts concealed", flags(Scene().state, a).allSatisfy { !$0 })
var sensitive = a
sensitive.sensitive = true
private let gated = Scene()
gated.chatInteraction.revealMedia(sensitive)
check("sensitive content asks confirmation", confirmation != nil)
check("sensitive content remains concealed pending confirmation", flags(gated.state, a).allSatisfy { !$0 })
let confirm = confirmation
confirmation = nil
confirm?(0)
check("confirmed sensitive content reveals", flags(gated.state, a).allSatisfy { $0 })
private let cancelled = Scene()
cancelled.chatInteraction.revealMedia(sensitive)
confirmation = nil
check("cancel leaves media concealed", flags(cancelled.state, a).allSatisfy { !$0 })
private let enabled = Scene()
enabled.context.contentConfig.sensitiveContentEnabled = true
enabled.chatInteraction.revealMedia(sensitive)
check("enabled sensitive content reveals without prompt", flags(enabled.state, a).allSatisfy { $0 } && confirmation == nil)
private let age = Scene()
age.context.appConfiguration.needsAge = true
age.chatInteraction.revealMedia(sensitive)
check("required age verification is retained", agePrompts == 1)
check("age gate does not reveal media", flags(age.state, a).allSatisfy { !$0 })
check("age gate does not offer bypass confirmation", confirmation == nil)
print("\(total-failed)/\(total) checks passed")
exit(failed == 0 ? 0 : 1)
