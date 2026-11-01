private var codexAdminLogEvidence: CodexAdminLogEvidence?

private final class CodexAdminLogButton: NSButton {
    var invoke: (() -> Void)?
    @objc func run() { invoke?() }
}

private final class CodexAdminLogEvidence {
    let context: any AccountContextProtocol
    let window: Window
    let table: TableView
    let status: NSTextField
    let interaction: ChatInteraction
    let message: Message
    var state = State()
    var baseline = true
    var taps = 0

    init(context: any AccountContextProtocol) {
        self.context = context
        window = Window(contentRect: NSMakeRect(0, 0, 620, 610), styleMask: [.titled, .closable], backing: .buffered, defer: false)
        window.title = "Recent Actions — local media reveal check"
        let host = View(frame: NSMakeRect(0, 0, 620, 610))
        host.backgroundColor = theme.colors.background
        window.contentView = host
        status = NSTextField(labelWithString: "")
        status.frame = NSMakeRect(20, 575, 590, 22)
        status.textColor = theme.colors.text
        host.addSubview(status)
        let disclosure = NSTextField(labelWithString: "Production photo view and reveal callback · generated local image · no server events")
        disclosure.frame = NSMakeRect(20, 550, 590, 20)
        disclosure.font = .systemFont(ofSize: 11)
        disclosure.textColor = theme.colors.grayText
        host.addSubview(disclosure)
        table = TableView(frame: NSMakeRect(0, 75, 620, 460), isFlipped: false)
        table.getBackgroundColor = { .clear }
        host.addSubview(table)
        let peerId = PeerId(namespace: Namespaces.Peer.CloudChannel, id: ._internalFromInt64Value(777000123))
        let peer = TelegramChannel(id: peerId, accessHash: nil, title: "Media Test Channel", username: nil, photo: [], creationDate: 0, version: 0, participationStatus: .member, info: .broadcast(.init(flags: [])), flags: [.isCreator], restrictionInfo: nil, adminRights: nil, bannedRights: nil, defaultBannedRights: nil, usernames: [], storiesHidden: nil, nameColor: nil, backgroundEmojiId: nil, profileColor: nil, profileBackgroundEmojiId: nil, emojiStatus: nil, approximateBoostLevel: nil, subscriptionUntilDate: nil, verificationIconFileId: nil, sendPaidMessageStars: nil, linkedMonoforumId: nil)
        interaction = ChatInteraction(chatLocation: .peer(peerId), context: context, isLogInteraction: true)
        interaction.update(animated: false) { $0.updatedPeer { _ in peer }.updatedMainPeer(peer) }
        let resource = LocalFileMediaResource(fileId: 777000123)
        let thumb = LocalFileMediaResource(fileId: 777000124)
        context.account.postbox.mediaBox.storeResourceData(resource.id, data: Self.checker(size: 512))
        context.account.postbox.mediaBox.storeResourceData(thumb.id, data: Self.checker(size: 32))
        let image = TelegramMediaImage(imageId: MediaId(namespace: 0, id: resource.fileId), representations: [
            TelegramMediaImageRepresentation(dimensions: PixelDimensions(width: 32, height: 32), resource: thumb, progressiveSizes: [], immediateThumbnailData: nil, hasVideo: false, isPersonal: false),
            TelegramMediaImageRepresentation(dimensions: PixelDimensions(width: 512, height: 512), resource: resource, progressiveSizes: [], immediateThumbnailData: nil, hasVideo: false, isPersonal: false)
        ], immediateThumbnailData: nil, reference: nil, partialReference: nil, flags: [])
        message = Message(stableId: 777, stableVersion: 0, id: MessageId(peerId: peerId, namespace: Namespaces.Message.Cloud, id: 777), globallyUniqueId: nil, groupingKey: nil, groupInfo: nil, threadId: nil, timestamp: 1782388800, flags: [.Incoming], tags: [], globalTags: [], localTags: [], customTags: [], forwardInfo: nil, author: peer, text: "", attributes: [MediaSpoilerMessageAttribute()], media: [image], peers: SimpleDictionary([peerId: peer]), associatedMessages: .init(), associatedMessageIds: [], associatedMedia: [:], associatedThreadInfo: nil, associatedStories: [:])
        let open = CodexAdminLogButton(frame: NSMakeRect(20, 23, 200, 32))
        open.title = "Click test photo"
        open.bezelStyle = .rounded
        open.target = open
        open.action = #selector(CodexAdminLogButton.run)
        open.invoke = { [weak self] in
            guard let self else { return }
            self.taps += 1
            (self.table.viewNecessary(at: 0) as? ChatMediaView)?.contentNode?.open()
            self.updateStatus()
        }
        host.addSubview(open)
        let toggle = CodexAdminLogButton(frame: NSMakeRect(245, 23, 350, 32))
        toggle.title = "Switch before / fixed implementation"
        toggle.bezelStyle = .rounded
        toggle.target = toggle
        toggle.action = #selector(CodexAdminLogButton.run)
        toggle.invoke = { [weak self] in
            guard let self else { return }
            self.baseline.toggle()
            self.state = State()
            self.taps = 0
            self.configure()
            self.render()
        }
        host.addSubview(toggle)
        configure()
        render()
        window.center()
        window.makeKeyAndOrderFront(nil)
    }

    func configure() {
        interaction.revealMedia = { _ in }
        guard !baseline else { return }
        let context = self.context
        let chatInteraction = self.interaction
        let updateState: ((State) -> State) -> Void = { [weak self] f in
            guard let self else { return }
            self.state = f(self.state)
            self.render()
        }
        CALLBACK_SOURCE
    }

    func render() {
        let data = MessageEntryAdditionalData(isRevealed: baseline ? false : state.mediaRevealed.contains(message.id))
        let entry = ChatHistoryEntry.MessageEntry(message, MessageIndex(message), true, .bubble, .Full(rank: nil, rankType: .none, header: .normal), nil, ChatHistoryEntryData(nil, data, AutoplayMediaPreferences.defaultSettings))
        let row = ChatRowItem.item(table.frame.size, from: entry, interaction: interaction, theme: theme)
        _ = row.makeSize(table.frame.width)
        table.removeAll()
        _ = table.addItem(item: row)
        updateStatus()
    }

    func updateStatus() {
        status.stringValue = "\(baseline ? "Before" : "Fixed") · photo taps: \(taps) · revealed: \(state.mediaRevealed.contains(message.id) ? "yes" : "no")"
    }

    static func checker(size: Int) -> Data {
        let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: size, pixelsHigh: size, bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: size * 4, bitsPerPixel: 32)!
        let bytes = rep.bitmapData!
        for y in 0..<size {
            for x in 0..<size {
                let first = (x / max(1, size / 8) + y / max(1, size / 8)) % 2 == 0
                let offset = (y * size + x) * 4
                bytes[offset] = first ? 24 : 235
                bytes[offset + 1] = first ? 140 : 220
                bytes[offset + 2] = first ? 220 : 65
                bytes[offset + 3] = 255
            }
        }
        return rep.representation(using: .png, properties: [:])!
    }
}

public func codexInstallAdminLogEvidence(context: any AccountContextProtocol) {
    guard codexAdminLogEvidence == nil, ProcessInfo.processInfo.environment["TELEGRAM_VALIDATION_ROOT"] != nil else { return }
    codexAdminLogEvidence = CodexAdminLogEvidence(context: context)
}
