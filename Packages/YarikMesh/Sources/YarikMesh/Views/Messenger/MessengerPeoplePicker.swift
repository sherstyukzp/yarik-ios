import BitFoundation
import SwiftUI

struct MessengerPeoplePicker: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var appChromeModel: AppChromeModel
    @EnvironmentObject private var privateConversationModel: PrivateConversationModel
    @EnvironmentObject private var conversationUIModel: ConversationUIModel
    @EnvironmentObject private var locationChannelsModel: LocationChannelsModel
    @EnvironmentObject private var peerListModel: PeerListModel
    @EnvironmentObject private var verificationModel: VerificationModel
    @ObservedObject private var bridgeService = BridgeService.shared

    let purpose: MessengerPeoplePurpose

    @State private var groupName = ""
    @State private var showVerification = false
    @State private var query = ""

    var body: some View {
        NavigationStack {
            List {
                if purpose == .newMessage {
                    groupSection
                }
                meshSection
                if !filteredGeohashPeople.isEmpty {
                    geohashSection
                }
                if !filteredBridgePeople.isEmpty {
                    bridgeSection
                }
            }
            .searchable(text: $query, prompt: Text("Пошук"))
            .navigationTitle(title)
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Закрити") { dismiss() }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showVerification = true
                    } label: {
                        Image(systemName: "qrcode")
                    }
                    .accessibilityLabel(
                        String(localized: "content.accessibility.verification", comment: "Accessibility label for the verification QR button")
                    )
                }
            }
        }
        .sheet(isPresented: $showVerification) {
            VerificationSheetView(isPresented: $showVerification)
                .environmentObject(verificationModel)
        }
    }

    private var title: String {
        switch purpose {
        case .newMessage:
            return String(localized: "yarik.people.new", defaultValue: "Нове повідомлення", comment: "Title of the sheet used to start a conversation")
        case .room:
            return String(localized: "yarik.people.room", defaultValue: "Люди", comment: "Title of the sheet listing people in the open room")
        }
    }

    @ViewBuilder
    private var groupSection: some View {
        Section {
            TextField("Назва групи", text: $groupName)
                #if os(iOS)
                .textInputAutocapitalization(.never)
                #endif
                .autocorrectionDisabled()
            Button("Створити групу") {
                createGroup()
            }
            .disabled(groupName.trimmed.isEmpty)
        } header: {
            Text("Група")
        } footer: {
            Text("Група шифрується для учасників. Запросити людину можна командою /group invite в чаті.")
        }
    }

    @ViewBuilder
    private var meshSection: some View {
        Section("Поруч") {
            if filteredMeshPeers.isEmpty {
                Text("Нікого в радіусі Bluetooth")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(filteredMeshPeers) { peer in
                    Button {
                        openMeshPeer(peer)
                    } label: {
                        MessengerPersonLabel(
                            title: peer.displayName,
                            subtitle: meshSubtitle(peer),
                            systemImage: "antenna.radiowaves.left.and.right"
                        )
                    }
                    .disabled(peer.isMe)
                    .swipeActions {
                        if !peer.isMe {
                            Button(peer.isFavorite ? "Прибрати" : "Обране") {
                                peerListModel.toggleFavorite(peerID: peer.peerID)
                            }
                            .tint(.yellow)
                            Button(peer.isBlocked ? "Розблокувати" : "Блок", role: .destructive) {
                                toggleBlock(peer)
                            }
                        }
                    }
                    .contextMenu {
                        if !peer.isMe {
                            Button("Перевірити") {
                                appChromeModel.showFingerprint(for: peer.peerID)
                            }
                            Button(peer.isFavorite ? "Прибрати з обраних" : "В обране") {
                                peerListModel.toggleFavorite(peerID: peer.peerID)
                            }
                            if peer.isBlocked {
                                Button("Розблокувати") {
                                    toggleBlock(peer)
                                }
                            } else {
                                Button("Заблокувати", role: .destructive) {
                                    toggleBlock(peer)
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    private var geohashSection: some View {
        Section("У цьому місці") {
            ForEach(filteredGeohashPeople) { person in
                Button {
                    guard !person.isMe else { return }
                    peerListModel.openGeohashDirectMessage(with: person.id)
                    dismiss()
                } label: {
                    MessengerPersonLabel(
                        title: person.displayName,
                        subtitle: person.isTeleported ? "Не з цього місця" : "Тут",
                        systemImage: person.isTeleported ? "globe" : "mappin.and.ellipse"
                    )
                }
                .disabled(person.isMe)
                .swipeActions {
                    if !person.isMe {
                        Button(person.isBlocked ? "Розблокувати" : "Блок", role: .destructive) {
                            toggleGeohashBlock(person)
                        }
                    }
                }
            }
        }
    }

    private var bridgeSection: some View {
        Section {
            ForEach(filteredBridgePeople) { person in
                MessengerPersonLabel(
                    title: person.displayName,
                    subtitle: "Видно через міст",
                    systemImage: "network"
                )
            }
        } header: {
            Text("Через міст")
        } footer: {
            Text("Ці люди в тій самій місцевості, але поза радіусом Bluetooth. Пряме повідомлення для них поки недоступне.")
        }
    }

    private var filteredMeshPeers: [MeshPeerRow] {
        peerListModel.meshRows.filter { peer in
            query.isEmpty || peer.displayName.localizedStandardContains(query)
        }
    }

    private var filteredGeohashPeople: [GeohashPersonRow] {
        peerListModel.geohashPeople.filter { person in
            query.isEmpty || person.displayName.localizedStandardContains(query)
        }
    }

    private var filteredBridgePeople: [BridgeService.BridgedParticipant] {
        bridgeService.bridgedParticipants.filter { person in
            query.isEmpty || person.displayName.localizedStandardContains(query)
        }
    }

    private func meshSubtitle(_ peer: MeshPeerRow) -> String {
        if peer.isMe { return "Ви" }
        if peer.isBlocked { return "Заблоковано" }
        if peer.hasUnread { return "Нові повідомлення" }
        if peer.isConnected { return "Поруч" }
        if peer.isReachable { return "У мережі" }
        return "Не в мережі"
    }

    private func openMeshPeer(_ peer: MeshPeerRow) {
        guard !peer.isMe else { return }
        peerListModel.startConversation(with: peer.peerID)
        dismiss()
    }

    private func toggleBlock(_ peer: MeshPeerRow) {
        if peer.isBlocked {
            conversationUIModel.unblock(peerID: peer.peerID, displayName: peer.displayName)
        } else {
            conversationUIModel.block(peerID: peer.peerID, displayName: peer.displayName)
        }
    }

    private func toggleGeohashBlock(_ person: GeohashPersonRow) {
        if person.isBlocked {
            peerListModel.unblockGeohashUser(
                pubkeyHexLowercased: person.id,
                displayName: person.displayName
            )
        } else {
            peerListModel.blockGeohashUser(
                pubkeyHexLowercased: person.id,
                displayName: person.displayName
            )
        }
    }

    private func createGroup() {
        let name = groupName.trimmed
        guard !name.isEmpty else { return }
        privateConversationModel.endConversation()
        locationChannelsModel.select(.mesh)
        conversationUIModel.sendMessage("/group create \(name)")
        groupName = ""
        dismiss()
    }
}

struct MessengerPersonLabel: View {
    let title: String
    let subtitle: String
    let systemImage: String

    var body: some View {
        Label {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        } icon: {
            Image(systemName: systemImage)
        }
    }
}
