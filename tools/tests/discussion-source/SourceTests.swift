import Foundation

struct PeerId: Equatable { let raw: Int; init(_ raw: Int) { self.raw = raw }; init(_ raw: Int64) { self.raw = Int(raw) } }
struct MessageId: Equatable { let peerId: PeerId; let id: Int }
struct Thread { let peerId: PeerId; let channelMessageId: MessageId?; var isMonoforumPost = false; var threadId: Int64 = 0 }
enum ChatLocation { case peer(PeerId); case thread(Thread); var threadId: Int64? { if case let .thread(thread) = self { return thread.threadId }; return nil } }
enum ReplyThreadMode { case comments(origin: MessageId); case replies(origin: MessageId); case topic(origin: MessageId); case savedMessages(origin: MessageId) }
enum ChatMode: Equatable {
    case history, other, thread(ReplyThreadMode)
    static func == (lhs: ChatMode, rhs: ChatMode) -> Bool { if case .history = lhs, case .history = rhs { return true }; return false }
    var isSavedMessagesThread: Bool { if case .thread(.savedMessages) = self { return true }; return false }
}
let repliesPeerId = PeerId(99)
final class Navigation { var pushes = 0; func push(_ value: Int) { pushes += 1 } }
final class Bindings { let navigation = Navigation(); func rootNavigation() -> Navigation { navigation } }
final class Context { let peerId = PeerId(1); let bindings = Bindings() }
struct Presentation { var reportMode: Int?; var isTopicMode = false }
struct Hook { func makePeerMediaController(_ context: Context, _ id: PeerId, _ value: Bool) -> Int { 0 } }
struct ChatUIHooks { static let shared = Hook() }
final class ChatInteraction {
    let interactionContext = Context()
    var mode: ChatMode
    var chatLocation: ChatLocation
    var peerId: PeerId
    var presentation = Presentation()
    var calls: [(PeerId, Bool, MessageId?)] = []
    init(_ mode: ChatMode, _ location: ChatLocation, _ peerId: PeerId) { self.mode = mode; self.chatLocation = location; self.peerId = peerId }
    func openInfo(_ peer: PeerId, _ toChat: Bool, _ post: MessageId?, _ action: Int?) { calls.append((peer, toChat, post)) }
}

__SOURCE__

func click(_ chatInteraction: ChatInteraction) {
__HEADER_ACTION__
    openInfo(chatInteraction)
}
var checked = 0
var failed = 0
func check(_ label: String, _ condition: Bool) {
    checked += 1
    if !condition { print("FAIL: " + label); failed += 1 }
}
let channel = PeerId(10)
let group = PeerId(20)
let other = PeerId(30)
let post = MessageId(peerId: channel, id: 123)
let comment = MessageId(peerId: group, id: 456)
let wrongOrigin = MessageId(peerId: other, id: 789)
let thread = ChatLocation.thread(Thread(peerId: group, channelMessageId: post))
let linked = ChatInteraction(.thread(.comments(origin: post)), thread, group)
click(linked)
check("comment link opens channel", linked.calls.first?.0 == channel)
check("opens chat rather than profile", linked.calls.first?.1 == true)
check("focuses source post", linked.calls.first?.2 == post)
let fromComment = ChatInteraction(.thread(.comments(origin: comment)), thread, group)
click(fromComment)
check("resolved source wins over comment origin", fromComment.calls.first?.2 == post)
let staleOrigin = ChatInteraction(.thread(.comments(origin: wrongOrigin)), thread, group)
click(staleOrigin)
check("thread source wins over navigation origin", staleOrigin.calls.first?.2 == post)
let fallback = ChatInteraction(.thread(.comments(origin: post)), .thread(Thread(peerId: group, channelMessageId: nil)), group)
click(fallback)
check("channel origin works before source cache", fallback.calls.first?.2 == post)
let unknown = ChatInteraction(.thread(.comments(origin: comment)), .thread(Thread(peerId: group, channelMessageId: nil)), group)
click(unknown)
check("does not jump into discussion group without source", unknown.calls.isEmpty)
for mode: ChatMode in [.thread(.replies(origin: comment)), .thread(.topic(origin: comment)), .thread(.savedMessages(origin: comment)), .other, .history] {
    check("source helper limited to comments", chatDiscussionSourceMessageId(mode: mode, location: thread) == nil)
}
check("not a thread", chatDiscussionSourceMessageId(mode: .thread(.comments(origin: post)), location: .peer(channel)) == nil)
let history = ChatInteraction(.history, .peer(channel), channel)
click(history)
check("ordinary channel opens profile", history.calls.first?.0 == channel && history.calls.first?.1 == false)
let topic = ChatInteraction(.thread(.topic(origin: comment)), thread, group)
topic.presentation.isTopicMode = true
click(topic)
check("forum topic retains profile action", topic.calls.first?.0 == group && topic.calls.first?.1 == false)
check("no root navigation mutation", linked.interactionContext.bindings.navigation.pushes == 0)
print("\(checked - failed)/\(checked) discussion navigation checks passed")
exit(failed == 0 ? 0 : 1)
