private var codexEventLogHeaderScene: AnyObject?

private final class CodexEventLogContext {
    func get() -> Signal<([ChannelAdminEventLogEntry], Bool, ChannelAdminEventLogUpdateType, Bool), NoError> {
        return .single(([], false, .load, false))
    }
    func setFilter(_ filter: ChannelAdminEventLogFilter) {
        let url = URL(fileURLWithPath: NSTemporaryDirectory() + "TelegramEventLogHeaderQueries.json")
        var values = (try? Data(contentsOf: url)).flatMap { try? JSONSerialization.jsonObject(with: $0) as? [String] } ?? []
        values.append(filter.query ?? "")
        if let data = try? JSONSerialization.data(withJSONObject: values) { try? data.write(to: url) }
    }
    func loadMoreEntries() {}
}

private final class CodexHeaderScene<Context: AccountContextProtocol> {
    let window: Window
    let navigation: NavigationViewController
    init(context: Context) {
        window = Window(contentRect: NSMakeRect(0, 0, 920, 600), styleMask: [.titled, .closable, .resizable], backing: .buffered, defer: false)
        window.title = "Recent Actions header — neutral controller fixture"
        let id = PeerId(namespace: Namespaces.Peer.CloudChannel, id: ._internalFromInt64Value(777000123))
        let peer = TelegramChannel(id: id, accessHash: nil, title: "Example Channel", username: nil, photo: [], creationDate: 0, version: 0, participationStatus: .member, info: .broadcast(.init(flags: [])), flags: [.isCreator], restrictionInfo: nil, adminRights: nil, bannedRights: nil, defaultBannedRights: nil, usernames: [], storiesHidden: nil, nameColor: nil, backgroundEmojiId: nil, profileColor: nil, profileBackgroundEmojiId: nil, emojiStatus: nil, approximateBoostLevel: nil, subscriptionUntilDate: nil, verificationIconFileId: nil, sendPaidMessageStars: nil, linkedMonoforumId: nil)
        let controller = ChannelEventLogController(context, peer: EnginePeer(peer))
        navigation = NavigationViewController(ViewController(), window)
        navigation.loadViewIfNeeded(NSMakeRect(0, 0, 920, 600))
        navigation.view.autoresizingMask = [.width, .height]
        window.contentView = navigation.view
        navigation.viewDidAppear(false)
        navigation.push(controller, false)
        window.center()
        window.makeKeyAndOrderFront(nil)
    }
}

public func codexInstallEventLogHeaderScene<Context: AccountContextProtocol>(context: Context) {
    guard codexEventLogHeaderScene == nil, ProcessInfo.processInfo.environment["TELEGRAM_VALIDATION_ROOT"] != nil else { return }
    codexEventLogHeaderScene = CodexHeaderScene(context: context)
}
