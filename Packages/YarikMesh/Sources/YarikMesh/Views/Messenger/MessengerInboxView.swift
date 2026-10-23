import BitFoundation
import SwiftUI
#if os(iOS)
import UIKit
#endif

struct MessengerInboxView: View {
    @EnvironmentObject private var appChromeModel: AppChromeModel
    @EnvironmentObject private var privateConversationModel: PrivateConversationModel
    @EnvironmentObject private var verificationModel: VerificationModel
    @EnvironmentObject private var conversationUIModel: ConversationUIModel
    @EnvironmentObject private var locationChannelsModel: LocationChannelsModel
    @EnvironmentObject private var peerListModel: PeerListModel
    @EnvironmentObject private var publicChatModel: PublicChatModel
    @EnvironmentObject private var privateInboxModel: PrivateInboxModel
    @ObservedObject private var bridgeService = BridgeService.shared
    @State private var carriedMailCount = 0

    @Binding var path: [MessengerRoute]
    @Binding var messageText: String
    @Binding var selectedMessageSender: String?
    @Binding var selectedMessageSenderID: PeerID?
    @Binding var imagePreviewURL: URL?
    @Binding var windowCountPublic: Int
    @Binding var windowCountPrivate: [PeerID: Int]
    @Binding var isAtBottomPublic: Bool
    @Binding var isAtBottomPrivate: Bool
    @Binding var showSidebar: Bool
    var isTextFieldFocused: FocusState<Bool>.Binding
    @ObservedObject var voiceRecordingVM: VoiceRecordingViewModel
    @Binding var autocompleteDebounceTimer: Timer?
    let onSendMessage: () -> Void

    #if os(iOS)
    @Binding var showImagePicker: Bool
    @Binding var imagePickerSourceType: UIImagePickerController.SourceType
    #else
    @Binding var showMacImagePicker: Bool
    #endif

    @State private var query = ""
    @State private var showSettings = false
    @State private var showPeople = false
    @State private var showPlaces = false

    var body: some View {
        NavigationStack(path: $path) {
            List {
                if appChromeModel.panicWipeBlocked {
                    Section {
                        PanicWipeBlockedBanner()
                    }
                }
                if let issue = ConnectivityIssue.resolve(
                    bluetoothState: appChromeModel.bluetoothState,
                    torBlocked: appChromeModel.torBlocked
                ) {
                    Section {
                        ConnectivityStatusBanner(issue: issue)
                    }
                }

                Section("Місця") {
                    if matches(query, "Поруч") {
                        NavigationLink(value: MessengerRoute.mesh) {
                            chatLabel(
                                title: "Поруч",
                                preview: meshPreview,
                                symbol: "antenna.radiowaves.left.and.right",
                                date: meshLastDate,
                                unread: false
                            )
                        }
                    }
                    ForEach(placeRows) { place in
                        NavigationLink(value: MessengerRoute.location(place.geohash)) {
                            chatLabel(
                                title: place.title,
                                preview: place.subtitle,
                                symbol: "mappin.and.ellipse",
                                date: nil,
                                unread: false
                            )
                        }
                    }
                    Button {
                        appChromeModel.presentNotices()
                    } label: {
                        Label("Оголошення", systemImage: "pin")
                    }
                    Button {
                        showPlaces = true
                    } label: {
                        Label("Інші місця", systemImage: "map")
                    }
                }

                if !filteredGroups.isEmpty {
                    Section("Групи") {
                        ForEach(filteredGroups) { group in
                            NavigationLink(value: MessengerRoute.direct(group.peerID)) {
                                chatLabel(
                                    title: group.name,
                                    preview: preview(for: group.peerID) ?? "\(group.memberCount) учасників",
                                    symbol: "person.3",
                                    date: lastDate(for: group.peerID),
                                    unread: group.hasUnread
                                )
                            }
                        }
                    }
                }

                Section("Повідомлення") {
                    if filteredDirectChats.isEmpty {
                        Text("Приватні розмови зʼявляться тут")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(filteredDirectChats) { chat in
                            NavigationLink(value: MessengerRoute.direct(chat.peerID)) {
                                chatLabel(
                                    title: chat.title,
                                    preview: chat.preview,
                                    symbol: chat.isFavorite ? "star.fill" : "person",
                                    date: chat.date,
                                    unread: chat.hasUnread
                                )
                            }
                        }
                    }
                }

                if carriedMailCount > 0 {
                    Section {
                        Label("Несете \(carriedMailCount) запечатаних повідомлень", systemImage: "figure.walk")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("Yarik")
            .searchable(text: $query, prompt: Text("Пошук"))
            .navigationDestination(for: MessengerRoute.self) { route in
                conversation(route)
            }
            .toolbar {
                ToolbarItem(placement: leadingPlacement) {
                    Button {
                        showSettings = true
                    } label: {
                        Text("Налаштування")
                    }
                    .accessibilityHint("Відкриває профіль, звʼязок і приватність")
                }
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showPeople = true
                    } label: {
                        Image(systemName: "square.and.pencil")
                    }
                    .accessibilityLabel("Нове повідомлення")
                }
            }
        }
        .onAppear {
            carriedMailCount = CourierStore.shared.carriedCount
            locationChannelsModel.refreshMeshChannelsIfNeeded()
            if let peerID = privateConversationModel.selectedPeerID {
                let route = MessengerRoute.direct(peerID)
                if path.last != route {
                    path = [route]
                }
            }
        }
        .onChange(of: path) { newPath in
            activate(newPath.last)
        }
        .onChange(of: privateConversationModel.selectedPeerID) { peerID in
            guard let peerID else { return }
            let route = MessengerRoute.direct(peerID)
            if path.last != route {
                path = [route]
            }
        }
        .onChange(of: locationChannelsModel.permissionState) { _ in
            locationChannelsModel.refreshMeshChannelsIfNeeded()
        }
        .onReceive(CourierStore.shared.$carriedCount) { count in
            carriedMailCount = count
        }
        .sheet(isPresented: $showSettings) {
            MessengerSettingsView()
                .environmentObject(appChromeModel)
                .environmentObject(locationChannelsModel)
                .environmentObject(verificationModel)
        }
        .sheet(isPresented: $showPeople) {
            MessengerPeoplePicker(purpose: .newMessage)
                .environmentObject(appChromeModel)
                .environmentObject(privateConversationModel)
                .environmentObject(conversationUIModel)
                .environmentObject(locationChannelsModel)
                .environmentObject(peerListModel)
                .environmentObject(verificationModel)
        }
        .sheet(isPresented: $showPlaces) {
            LocationChannelsSheet(isPresented: $showPlaces)
                .environmentObject(locationChannelsModel)
                .environmentObject(peerListModel)
        }
        .sheet(isPresented: $appChromeModel.isNoticesSheetPresented, onDismiss: {
            appChromeModel.noticesSheetPrefersGeoTab = false
        }) {
            NoticesView(
                senderNickname: appChromeModel.nickname,
                board: appChromeModel.boardManager,
                initialTab: appChromeModel.noticesSheetPrefersGeoTab ? .geo : noticesTab
            )
            .environmentObject(locationChannelsModel)
        }
        .confirmationDialog(
            String(localized: "app_info.settings.danger.panic_confirm_title", defaultValue: "wipe all data?", comment: "Title of the confirmation dialog before a panic wipe"),
            isPresented: $appChromeModel.showPanicConfirmation,
            titleVisibility: .visible
        ) {
            Button(String(localized: "app_info.settings.danger.panic_confirm_action", defaultValue: "wipe everything", comment: "Destructive confirmation button that performs the panic wipe"), role: .destructive) {
                appChromeModel.panicClearAllData()
            }
            Button("common.cancel", role: .cancel) {}
        }
        .alert("content.alert.screenshot.title", isPresented: $appChromeModel.showScreenshotPrivacyWarning) {
            Button("common.ok", role: .cancel) {}
        } message: {
            Text("content.alert.screenshot.message")
        }
    }

    private var leadingPlacement: ToolbarItemPlacement {
        #if os(iOS)
        .topBarLeading
        #else
        .navigation
        #endif
    }

    private var noticesTab: NoticesView.Tab {
        if case .location = locationChannelsModel.selectedChannel {
            return .geo
        }
        return .mesh
    }

    @ViewBuilder
    private func conversation(_ route: MessengerRoute) -> some View {
        #if os(iOS)
        MessengerConversationView(
            route: route,
            messageText: $messageText,
            selectedMessageSender: $selectedMessageSender,
            selectedMessageSenderID: $selectedMessageSenderID,
            imagePreviewURL: $imagePreviewURL,
            windowCountPublic: $windowCountPublic,
            windowCountPrivate: $windowCountPrivate,
            isAtBottomPublic: $isAtBottomPublic,
            isAtBottomPrivate: $isAtBottomPrivate,
            showSidebar: $showSidebar,
            isTextFieldFocused: isTextFieldFocused,
            voiceRecordingVM: voiceRecordingVM,
            autocompleteDebounceTimer: $autocompleteDebounceTimer,
            onSendMessage: onSendMessage,
            showImagePicker: $showImagePicker,
            imagePickerSourceType: $imagePickerSourceType
        )
        #else
        MessengerConversationView(
            route: route,
            messageText: $messageText,
            selectedMessageSender: $selectedMessageSender,
            selectedMessageSenderID: $selectedMessageSenderID,
            imagePreviewURL: $imagePreviewURL,
            windowCountPublic: $windowCountPublic,
            windowCountPrivate: $windowCountPrivate,
            isAtBottomPublic: $isAtBottomPublic,
            isAtBottomPrivate: $isAtBottomPrivate,
            showSidebar: $showSidebar,
            isTextFieldFocused: isTextFieldFocused,
            voiceRecordingVM: voiceRecordingVM,
            autocompleteDebounceTimer: $autocompleteDebounceTimer,
            onSendMessage: onSendMessage,
            showMacImagePicker: $showMacImagePicker
        )
        #endif
    }

    private func activate(_ route: MessengerRoute?) {
        guard let route else {
            if privateConversationModel.selectedPeerID != nil {
                privateConversationModel.endConversation()
            }
            return
        }
        switch route {
        case .mesh:
            if privateConversationModel.selectedPeerID != nil {
                privateConversationModel.endConversation()
            }
            if locationChannelsModel.selectedChannel != .mesh {
                locationChannelsModel.select(.mesh)
            }
        case .location(let geohash):
            if privateConversationModel.selectedPeerID != nil {
                privateConversationModel.endConversation()
            }
            if case .location(let channel) = locationChannelsModel.selectedChannel,
               channel.geohash.lowercased() == geohash.lowercased() {
                break
            }
            locationChannelsModel.openLocationChannel(for: geohash)
        case .direct(let peerID):
            if privateConversationModel.selectedPeerID != peerID {
                peerListModel.startConversation(with: peerID)
            }
        }
    }

    private struct PlaceRow: Identifiable {
        let geohash: String
        let title: String
        let subtitle: String
        var id: String { geohash }
    }

    private struct DirectChat: Identifiable {
        let peerID: PeerID
        let title: String
        let preview: String
        let date: Date?
        let hasUnread: Bool
        let isFavorite: Bool
        var id: String { peerID.id }
    }

    private var placeRows: [PlaceRow] {
        var rows: [PlaceRow] = []
        var seen = Set<String>()
        func append(_ geohash: String, title: String, subtitle: String) {
            let key = geohash.lowercased()
            guard seen.insert(key).inserted else { return }
            guard matches(query, title) || matches(query, key) else { return }
            rows.append(PlaceRow(geohash: key, title: title, subtitle: subtitle))
        }

        for channel in locationChannelsModel.availableChannels {
            let title = placeTitle(channel)
            append(channel.geohash, title: title, subtitle: channel.level.displayName)
        }
        if case .location(let channel) = locationChannelsModel.selectedChannel {
            append(channel.geohash, title: placeTitle(channel), subtitle: "Відкрите місце")
        }
        for geohash in locationChannelsModel.bookmarks {
            let name = locationChannelsModel.bookmarkNames[geohash.lowercased()]
            append(geohash, title: name?.isEmpty == false ? name! : "#\(geohash.lowercased())", subtitle: "Збережене")
        }
        return rows
    }

    private var filteredGroups: [GroupChatRow] {
        peerListModel.groupRows.filter { group in
            matches(query, group.name)
        }
    }

    private var filteredDirectChats: [DirectChat] {
        var byPeer: [String: DirectChat] = [:]
        for chat in peerListModel.recentChatRows {
            let preview = preview(for: chat.peerID) ?? ""
            byPeer[chat.peerID.id] = DirectChat(
                peerID: chat.peerID,
                title: chat.displayName,
                preview: preview,
                date: chat.lastActivity,
                hasUnread: chat.hasUnread,
                isFavorite: false
            )
        }
        for peer in peerListModel.meshRows where !peer.isMe {
            let messages = privateInboxModel.messages(for: peer.peerID)
            guard peer.hasUnread || !messages.isEmpty else { continue }
            let existing = byPeer[peer.peerID.id]
            byPeer[peer.peerID.id] = DirectChat(
                peerID: peer.peerID,
                title: peer.displayName,
                preview: messages.last.map { previewText($0) } ?? existing?.preview ?? "",
                date: messages.last?.timestamp ?? existing?.date,
                hasUnread: peer.hasUnread || (existing?.hasUnread ?? false),
                isFavorite: peer.isFavorite
            )
        }
        for person in peerListModel.geohashPeople where !person.isMe {
            let peerID = PeerID(nostr_: person.id)
            let messages = privateInboxModel.messages(for: peerID)
            let unread = privateInboxModel.unreadPeerIDs.contains(peerID)
            guard unread || !messages.isEmpty else { continue }
            byPeer[peerID.id] = DirectChat(
                peerID: peerID,
                title: person.displayName,
                preview: messages.last.map { previewText($0) } ?? "",
                date: messages.last?.timestamp,
                hasUnread: unread,
                isFavorite: false
            )
        }
        return byPeer.values
            .filter { matches(query, $0.title) || matches(query, $0.preview) }
            .sorted { ($0.date ?? .distantPast) > ($1.date ?? .distantPast) }
    }

    private var meshPreview: String {
        guard case .mesh = locationChannelsModel.selectedChannel,
              let message = publicChatModel.messages.last(where: { !$0.content.trimmed.isEmpty && $0.sender != "system" }) else {
            if bridgeService.isEnabled {
                return "Повідомлення людям у радіусі Bluetooth і через міст"
            }
            return "Повідомлення людям у радіусі Bluetooth"
        }
        return "\(message.sender.splitSuffix().0): \(previewText(message))"
    }

    private var meshLastDate: Date? {
        guard case .mesh = locationChannelsModel.selectedChannel else { return nil }
        return publicChatModel.messages.last?.timestamp
    }

    private func preview(for peerID: PeerID) -> String? {
        guard let message = privateInboxModel.messages(for: peerID).last(where: { !$0.content.trimmed.isEmpty }) else {
            return nil
        }
        return previewText(message)
    }

    private func lastDate(for peerID: PeerID) -> Date? {
        privateInboxModel.messages(for: peerID).last?.timestamp
    }

    private func previewText(_ message: BitchatMessage) -> String {
        let flat = message.content.replacingOccurrences(of: "\n", with: " ")
        if message.sender == "system" { return flat }
        if conversationUIModel.mediaAttachment(for: message) != nil {
            return "Вкладення"
        }
        return flat
    }

    private func placeTitle(_ channel: GeohashChannel) -> String {
        if let name = locationChannelsModel.bookmarkNames[channel.geohash.lowercased()], !name.isEmpty {
            return name
        }
        if let name = locationChannelsModel.locationName(for: channel.level), !name.isEmpty {
            return name
        }
        return channel.level.displayName
    }

    private func matches(_ query: String, _ text: String) -> Bool {
        let trimmed = query.trimmed
        if trimmed.isEmpty { return true }
        return text.localizedStandardContains(trimmed)
    }

    private func chatLabel(
        title: String,
        preview: String,
        symbol: String,
        date: Date?,
        unread: Bool
    ) -> some View {
        HStack(spacing: 12) {
            Image(systemName: symbol)
                .font(.body)
                .frame(width: 36, height: 36)
                .background(Color.accentColor.opacity(0.15), in: Circle())
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.body.weight(unread ? .semibold : .regular))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                Text(preview)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            Spacer(minLength: 8)
            VStack(alignment: .trailing, spacing: 6) {
                if let date {
                    Text(date, style: .relative)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                if unread {
                    Circle()
                        .fill(Color.blue)
                        .frame(width: 10, height: 10)
                        .accessibilityLabel("Непрочитане")
                }
            }
        }
        .padding(.vertical, 4)
    }
}
