import BitFoundation
import SwiftUI
#if os(iOS)
import UIKit
#endif

struct MessengerConversationView: View {
    @EnvironmentObject private var appChromeModel: AppChromeModel
    @EnvironmentObject private var privateConversationModel: PrivateConversationModel
    @EnvironmentObject private var conversationUIModel: ConversationUIModel
    @EnvironmentObject private var locationChannelsModel: LocationChannelsModel
    @EnvironmentObject private var peerListModel: PeerListModel
    @ObservedObject private var bridgeService = BridgeService.shared

    let route: MessengerRoute

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

    @State private var showPeople = false
    @State private var showClearConfirmation = false
    @State private var pendingShareGeohash: String?
    @State private var showSharePrecisionWarning = false
    @State private var activeSharePayload: ChannelSharePayload?

    private var privatePeer: PeerID? {
        if case .direct(let peerID) = route { return peerID }
        return nil
    }

    private var isAtBottom: Binding<Bool> {
        if privatePeer != nil {
            return $isAtBottomPrivate
        }
        return $isAtBottomPublic
    }

    var body: some View {
        VStack(spacing: 0) {
            MessageListView(
                privatePeer: privatePeer,
                isAtBottom: isAtBottom,
                messageText: $messageText,
                selectedMessageSender: $selectedMessageSender,
                selectedMessageSenderID: $selectedMessageSenderID,
                imagePreviewURL: $imagePreviewURL,
                windowCountPublic: $windowCountPublic,
                windowCountPrivate: $windowCountPrivate,
                showSidebar: $showSidebar,
                isTextFieldFocused: isTextFieldFocused
            )
            .background(conversationBackground)

            if let caption = privacyCaption {
                Label(caption, systemImage: "lock.fill")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.top, 6)
            }

            composer
        }
        .navigationTitle(title)
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .toolbar {
            ToolbarItem(placement: .principal) {
                VStack(spacing: 0) {
                    Text(title)
                        .font(.headline)
                        .lineLimit(1)
                    if let subtitle {
                        Text(subtitle)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }
                .accessibilityElement(children: .combine)
            }
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    conversationMenu
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
                .accessibilityLabel(
                    String(localized: "yarik.conversation.actions", defaultValue: "Дії чату", comment: "Accessibility label for the conversation actions menu")
                )
            }
        }
        .sheet(isPresented: $showPeople) {
            MessengerPeoplePicker(purpose: .room)
                .environmentObject(appChromeModel)
                .environmentObject(privateConversationModel)
                .environmentObject(conversationUIModel)
                .environmentObject(locationChannelsModel)
                .environmentObject(peerListModel)
                .environmentObject(verificationModelPlaceholder)
        }
        .confirmationDialog(
            String(localized: "content.clear.confirm_title", comment: "Title of the confirmation before clearing the open conversation"),
            isPresented: $showClearConfirmation,
            titleVisibility: .visible
        ) {
            Button("content.clear.confirm_action", role: .destructive) {
                conversationUIModel.clearCurrentConversation()
            }
            Button("common.cancel", role: .cancel) {}
        }
        .confirmationDialog(
            String(localized: "channel.share.precision_warning.title", defaultValue: "share a precise location channel?", comment: "Title of the confirmation before sharing a neighborhood-or-finer geohash invite"),
            isPresented: $showSharePrecisionWarning,
            titleVisibility: .visible
        ) {
            Button(String(localized: "channel.share.precision_warning.confirm", defaultValue: "share anyway", comment: "Confirms sharing a fine-precision location channel after the warning")) {
                if let geohash = pendingShareGeohash {
                    activeSharePayload = ChannelSharePayload(text: ChannelShare.payload(forGeohash: geohash))
                }
                pendingShareGeohash = nil
            }
            Button("common.cancel", role: .cancel) {
                pendingShareGeohash = nil
            }
        } message: {
            Text(String(localized: "yarik.channel.share.precision_warning.message", defaultValue: "Цей канал охоплює невелику територію. Запрошення в SMS чи iMessage бачить оператор і обидва телефони.", comment: "Body of the confirmation before sharing a fine-precision place invite"))
        }
        .sheet(item: $activeSharePayload) { payload in
            ShareActivityView(text: payload.text)
        }
    }

    @ViewBuilder
    private var composer: some View {
        #if os(iOS)
        ContentComposerView(
            messageText: $messageText,
            isTextFieldFocused: isTextFieldFocused,
            voiceRecordingVM: voiceRecordingVM,
            autocompleteDebounceTimer: $autocompleteDebounceTimer,
            onSendMessage: onSendMessage,
            showImagePicker: $showImagePicker,
            imagePickerSourceType: $imagePickerSourceType
        )
        #else
        ContentComposerView(
            messageText: $messageText,
            isTextFieldFocused: isTextFieldFocused,
            voiceRecordingVM: voiceRecordingVM,
            autocompleteDebounceTimer: $autocompleteDebounceTimer,
            onSendMessage: onSendMessage,
            showMacImagePicker: $showMacImagePicker
        )
        #endif
    }

    @ViewBuilder
    private var conversationMenu: some View {
        switch route {
        case .mesh, .location:
            Button {
                let prefersGeoTab: Bool
                if case .location = route {
                    prefersGeoTab = true
                } else {
                    prefersGeoTab = false
                }
                appChromeModel.presentNotices(geoTab: prefersGeoTab)
            } label: {
                Label("Оголошення", systemImage: "pin")
            }
            Button {
                showPeople = true
            } label: {
                Label("Люди", systemImage: "person.2")
            }
            if case .location(let geohash) = route {
                Button {
                    locationChannelsModel.toggleBookmark(geohash)
                } label: {
                    Label(
                        locationChannelsModel.isBookmarked(geohash) ? "Прибрати зі збережених" : "Зберегти місце",
                        systemImage: locationChannelsModel.isBookmarked(geohash) ? "bookmark.fill" : "bookmark"
                    )
                }
                Button {
                    requestShare(forGeohash: geohash)
                } label: {
                    Label("Поділитися", systemImage: "square.and.arrow.up")
                }
            }
        case .direct:
            if let header = privateConversationModel.selectedHeaderState {
                if header.supportsFavoriteToggle {
                    Button {
                        privateConversationModel.toggleFavoriteForSelectedConversation()
                    } label: {
                        Label(
                            header.isFavorite ? "Прибрати з обраних" : "В обране",
                            systemImage: header.isFavorite ? "star.fill" : "star"
                        )
                    }
                }
                if !header.isGroupConversation {
                    Button {
                        appChromeModel.showFingerprint(for: header.headerPeerID)
                    } label: {
                        Label("Перевірити", systemImage: "checkmark.seal")
                    }
                    Button(role: .destructive) {
                        conversationUIModel.block(peerID: header.headerPeerID, displayName: header.displayName)
                    } label: {
                        Label("Заблокувати", systemImage: "hand.raised")
                    }
                }
            }
        }
        Button("Очистити чат", role: .destructive) {
            showClearConfirmation = true
        }
    }

    private var title: String {
        switch route {
        case .mesh:
            return String(localized: "yarik.chat.nearby", defaultValue: "Поруч", comment: "Title of the local Bluetooth mesh conversation")
        case .location(let geohash):
            return placeTitle(for: geohash)
        case .direct:
            return privateConversationModel.selectedHeaderState?.displayName
                ?? String(localized: "common.unknown", comment: "Fallback label for unknown peer")
        }
    }

    private var subtitle: String? {
        switch route {
        case .mesh:
            let nearby = peerListModel.reachableMeshPeerCount
            let bridged = bridgeService.bridgedPeerCount
            if nearby == 0 && bridged == 0 {
                return String(localized: "yarik.chat.nearby.empty", defaultValue: "Нікого поруч", comment: "Subtitle when the mesh conversation has no reachable people")
            }
            if bridged > 0 {
                return "\(nearby) поруч · \(bridged) через міст"
            }
            return "\(nearby) поруч"
        case .location(let geohash):
            let count = peerListModel.visibleGeohashPeerCount
            return "#\(geohash) · \(count)"
        case .direct:
            guard let header = privateConversationModel.selectedHeaderState else { return nil }
            if header.isGroupConversation {
                return String(localized: "yarik.chat.group", defaultValue: "Група", comment: "Subtitle under a group conversation title")
            }
            if let encryption = header.encryptionStatus {
                return encryption.description
            }
            return availabilityTitle(header.availability)
        }
    }

    private var privacyCaption: String? {
        guard privatePeer != nil else { return nil }
        if privatePeer?.isGroup == true {
            return String(localized: "content.private.caption_group", comment: "Caption above the group chat composer noting messages are encrypted to group members")
        }
        let noiseSecured: Bool = {
            switch privateConversationModel.selectedHeaderState?.encryptionStatus {
            case .noiseSecured, .noiseVerified:
                return true
            default:
                return false
            }
        }()
        let nostrTransport = privateConversationModel.selectedHeaderState?.availability == .nostrAvailable
        if privatePeer?.isGeoDM == true || noiseSecured || nostrTransport {
            return String(localized: "content.private.caption_encrypted", comment: "Caption above the private chat composer once the session is end-to-end encrypted")
        }
        return String(localized: "content.private.caption", comment: "Caption above the private chat composer before encryption is established")
    }

    private var conversationBackground: Color {
        #if os(iOS)
        Color(uiColor: .systemBackground)
        #else
        Color(nsColor: .textBackgroundColor)
        #endif
    }

    /// Sheets created from this view still need VerificationModel when the
    /// people picker asks for it. The object is already in the environment;
    /// this lookup keeps the injection explicit for the sheet.
    @EnvironmentObject private var verificationModelPlaceholder: VerificationModel

    private func placeTitle(for geohash: String) -> String {
        let normalized = geohash.lowercased()
        if let name = locationChannelsModel.bookmarkNames[normalized], !name.isEmpty {
            return name
        }
        if let channel = locationChannelsModel.availableChannels.first(where: { $0.geohash.lowercased() == normalized }) {
            if let name = locationChannelsModel.locationName(for: channel.level), !name.isEmpty {
                return name
            }
            return channel.level.displayName
        }
        return "#\(normalized)"
    }

    private func availabilityTitle(_ availability: PrivateConversationAvailability) -> String {
        switch availability {
        case .bluetoothConnected:
            return String(localized: "yarik.presence.bluetooth", defaultValue: "Поруч", comment: "Presence subtitle when a person is connected over Bluetooth")
        case .meshReachable:
            return String(localized: "yarik.presence.mesh", defaultValue: "У мережі", comment: "Presence subtitle when a person is reachable through the mesh")
        case .nostrAvailable:
            return String(localized: "yarik.presence.internet", defaultValue: "Через інтернет", comment: "Presence subtitle when a person is reachable only over the internet")
        case .offline:
            return String(localized: "yarik.presence.offline", defaultValue: "Не в мережі", comment: "Presence subtitle when a person is offline")
        }
    }

    private func requestShare(forGeohash geohash: String) {
        if ChannelShare.shouldWarn(forGeohash: geohash) {
            pendingShareGeohash = geohash
            showSharePrecisionWarning = true
        } else {
            activeSharePayload = ChannelSharePayload(text: ChannelShare.payload(forGeohash: geohash))
        }
    }
}
