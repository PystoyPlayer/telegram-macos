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
        TelegramEngine.EngineData.Item.Peer.Peer(id: peerId)
    ) |> deliverOnMainQueue |> map { state, group, peer -> ContextMenuItem? in
        guard group != nil, let peer else { return nil }
        if !state.isUnread && peer._asPeer().isForumOrMonoForum {
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
