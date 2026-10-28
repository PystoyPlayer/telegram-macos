import TGUIKit
import Postbox
import SwiftSignalKit
import TelegramCore
import TelegramContext
import Localization
import LocalAnimations

func searchPeerReadMenuItem(context: any AccountContextProtocol, peerId: PeerId) -> Signal<ContextMenuItem?, NoError> {
    guard peerId.namespace != Namespaces.Peer.SecretChat else {
        return .single(nil)
    }
    return context.engine.data.get(
        TelegramEngine.EngineData.Item.Messages.PeerReadCounters(id: peerId),
        TelegramEngine.EngineData.Item.Messages.ChatListGroup(id: peerId),
        TelegramEngine.EngineData.Item.Peer.Peer(id: peerId),
        TelegramEngine.EngineData.Item.Peer.CachedData(id: peerId)
    ) |> deliverOnMainQueue |> map { state, group, peer, cachedData -> ContextMenuItem? in
        guard group != nil, let peer else { return nil }
        let displaysAsMessages = (peer._asPeer() as? TelegramChannel)?.flags.contains(.displayForumAsTabs) == true || (cachedData as? CachedChannelData)?.viewForumAsMessages.knownValue == true
        if !state.isUnread && peer._asPeer().isForumOrMonoForum && !displaysAsMessages {
            return nil
        }
        if state.isUnread {
            return ContextMenuItem(strings().chatListContextMaskAsRead, handler: {
                ChatListRowItem.markAsRead(context: context, peerId: peerId)
            }, itemImage: MenuAnimation.menu_read.value)
        } else {
            return ContextMenuItem(strings().chatListContextMaskAsUnread, handler: {
                ChatListRowItem.markAsUnread(context: context, peerId: peerId)
            }, itemImage: MenuAnimation.menu_unread.value)
        }
    }
}
