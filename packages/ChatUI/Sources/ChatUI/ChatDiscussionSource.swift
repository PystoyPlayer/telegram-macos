import Postbox
import TelegramCore
import TelegramContext
import ChatModeTypes

func chatDiscussionSourceMessageId(mode: ChatMode, location: ChatLocation) -> MessageId? {
    guard case let .thread(.comments(origin)) = mode, case let .thread(thread) = location else {
        return nil
    }
    if let source = thread.channelMessageId, source.peerId != thread.peerId {
        return source
    }
    if origin.peerId != thread.peerId {
        return origin
    }
    return nil
}
