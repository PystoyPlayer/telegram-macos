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

func openChatDiscussionSource(_ source: MessageId, interaction: ChatInteraction) {
    let navigation = interaction.interactionContext.bindings.rootNavigation()
    var existing: (ChatController, Int)?
    navigation.enumerateControllers { controller, index in
        guard let chat = controller as? ChatController,
              chat.chatInteraction.mode == .history,
              chat.chatInteraction.peerId == source.peerId else { return false }
        existing = (chat, index)
        return true
    }
    if let (chat, index) = existing {
        navigation.to(index: index)
        chat.chatInteraction.focusMessageId(nil, .init(messageId: source, string: nil), .CenterEmpty)
    } else {
        interaction.openInfoObserved(source.peerId, true, source, nil)
    }
}
