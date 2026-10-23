import BitFoundation
import SwiftUI

struct MessengerSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var appChromeModel: AppChromeModel
    @EnvironmentObject private var locationChannelsModel: LocationChannelsModel
    @EnvironmentObject private var verificationModel: VerificationModel
    @ObservedObject private var bridgeService = BridgeService.shared
    @ObservedObject private var locationManager = LocationChannelManager.shared

    @State private var liveVoiceEnabled = PTTSettings.liveVoiceEnabled
    @State private var locationNotesEnabled = LocationNotesSettings.enabled
    @State private var hideMessagePreviews = NotificationPrivacySettings.hideMessagePreviews
    @State private var customRelays = NostrRelaySettings.customRelays()
    @State private var relayInput = ""
    @State private var relayError: String?
    @State private var showPanicConfirmation = false
    @State private var showVerification = false
    @FocusState private var nicknameFocused: Bool

    var body: some View {
        NavigationStack {
            Form {
                profileSection
                voiceSection
                connectivitySection
                relaysSection
                privacySection
                aboutSection
                dangerSection
            }
            .navigationTitle("Налаштування")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Готово") {
                        appChromeModel.validateAndSaveNickname()
                        dismiss()
                    }
                }
            }
        }
        .onDisappear {
            appChromeModel.validateAndSaveNickname()
        }
        .onReceive(NotificationCenter.default.publisher(for: NostrRelaySettings.didChangeNotification)) { _ in
            customRelays = NostrRelaySettings.customRelays()
        }
        .sheet(isPresented: $showVerification) {
            VerificationSheetView(isPresented: $showVerification)
                .environmentObject(verificationModel)
        }
        .confirmationDialog(
            String(localized: "app_info.settings.danger.panic_confirm_title", defaultValue: "wipe all data?", comment: "Title of the confirmation dialog before a panic wipe"),
            isPresented: $showPanicConfirmation,
            titleVisibility: .visible
        ) {
            Button(String(localized: "app_info.settings.danger.panic_confirm_action", defaultValue: "wipe everything", comment: "Destructive confirmation button that performs the panic wipe"), role: .destructive) {
                dismiss()
                appChromeModel.panicClearAllData()
            }
            Button("common.cancel", role: .cancel) {}
        }
    }

    private var profileSection: some View {
        Section {
            TextField("Імʼя", text: nicknameBinding)
                .focused($nicknameFocused)
                .autocorrectionDisabled()
                #if os(iOS)
                .textInputAutocapitalization(.never)
                #endif
                .onSubmit {
                    appChromeModel.validateAndSaveNickname()
                }
            Button {
                showVerification = true
            } label: {
                Label("Перевірка особи", systemImage: "qrcode")
            }
        } header: {
            Text("Профіль")
        } footer: {
            Text("Це імʼя бачать люди поруч. Перевірка показує ваш код, щоб співрозмовник звірив його особисто.")
        }
    }

    private var voiceSection: some View {
        Section {
            Toggle("Живий голос", isOn: liveVoiceBinding)
        } footer: {
            Text("Утримування мікрофона передає голос одразу, а не як окремий запис.")
        }
    }

    private var connectivitySection: some View {
        Section {
            Toggle("Міст", isOn: bridgeBinding)
            if bridgeService.isEnabled {
                Text(bridgeService.activeCell.map { "Зустріч: \($0)" } ?? "Міст увімкнено, але місце зустрічі ще не відоме.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            Toggle("Tor", isOn: torBinding)
            if !locationChannelsModel.userTorEnabled {
                Text("Tor вимкнено: ретранслятори бачать IP-адресу цього пристрою.")
                    .font(.footnote)
                    .foregroundStyle(.red)
            }
            Toggle("Нотатки місця", isOn: locationNotesBinding)
            locationPermissionControl
        } header: {
            Text("Звʼязок")
        } footer: {
            Text("Міст зʼєднує сусідні Bluetooth-острівці через інтернет. Tor ховає адресу пристрою від ретрансляторів приватних повідомлень.")
        }
    }

    private var relaysSection: some View {
        Section {
            ForEach(NostrRelayManager.builtInRelayURLs.sorted(), id: \.self) { relay in
                LabeledContent(relay) {
                    Text("Вбудований")
                        .foregroundStyle(.secondary)
                }
            }
            ForEach(customRelays, id: \.self) { relay in
                HStack {
                    Text(relay)
                        .lineLimit(1)
                        .truncationMode(.middle)
                    Spacer()
                    Button(role: .destructive) {
                        NostrRelaySettings.remove(relay)
                        customRelays = NostrRelaySettings.customRelays()
                    } label: {
                        Image(systemName: "minus.circle.fill")
                    }
                    .buttonStyle(.borderless)
                    .accessibilityLabel("Прибрати ретранслятор")
                }
            }
            if customRelays.count < NostrRelaySettings.maxCustomRelays {
                TextField("wss://relay.example.com", text: $relayInput)
                    .autocorrectionDisabled()
                    #if os(iOS)
                    .textInputAutocapitalization(.never)
                    .keyboardType(.URL)
                    #endif
                    .onSubmit(addRelay)
                Button("Додати ретранслятор", action: addRelay)
                    .disabled(relayInput.trimmed.isEmpty)
            }
            if let relayError {
                Text(relayError)
                    .font(.footnote)
                    .foregroundStyle(.red)
            }
        } header: {
            Text("Ретранслятори")
        } footer: {
            Text("Якщо Bluetooth не дістає людину, приватні повідомлення йдуть через ці адреси. Можна додати власну, зокрема .onion.")
        }
    }

    @ViewBuilder
    private var locationPermissionControl: some View {
        switch locationChannelsModel.permissionState {
        case .authorized:
            Button("Закрити доступ до місця", role: .destructive) {
                SystemSettings.location.open()
            }
        case .notDetermined:
            Button("Дозволити геолокацію") {
                locationChannelsModel.enableLocationChannels()
            }
        case .denied, .restricted:
            Button("Відкрити налаштування місця") {
                SystemSettings.location.open()
            }
        }
    }

    private var privacySection: some View {
        Section {
            Toggle("Ховати текст сповіщень", isOn: hidePreviewsBinding)
        } header: {
            Text("Приватність")
        } footer: {
            Text("На заблокованому екрані буде лише те, що щось прийшло, без тексту, імені та місця.")
        }
    }

    private var aboutSection: some View {
        Section {
            NavigationLink("Команди") {
                ScrollView {
                    Text(commandHelp)
                        .font(.body)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .textSelection(.enabled)
                }
                .navigationTitle("Команди")
            }
            NavigationLink {
                MeshTopologyView(provider: { appChromeModel.meshTopologyDisplayModel() })
            } label: {
                Label("Мережа поруч", systemImage: "point.3.connected.trianglepath.dotted")
            }
        } header: {
            Text("Про Yarik")
        } footer: {
            Text("Повідомлення ходять між телефонами поруч через Bluetooth. Інтернет потрібен лише для мосту, місць і доставки, коли людини немає в радіусі.")
        }
    }

    private var dangerSection: some View {
        Section {
            Button("Стерти всі дані", role: .destructive) {
                showPanicConfirmation = true
            }
        } footer: {
            Text("Стирає повідомлення, ключі й особу на цьому пристрої.")
        }
    }

    private var commandHelp: String {
        String(
            localized: "command.help.text",
            defaultValue: "commands:\n/msg @name [message] — start a private chat\n/who — list who's here\n/clear — clear this chat\n/hug @name — send a hug\n/slap @name — slap with a large trout\n/block @name · /unblock @name\n/fav @name · /unfav @name — favorites (mesh only)\n/group create <name> — start an encrypted group\n/group invite @name · /group remove @name — manage members (creator)\n/group leave · /group list — leave or list your groups\n/ping @name — measure round-trip time (mesh only)\n/trace @name — estimated mesh path (mesh only)\n/pay <token> — send a cashu ecash token in this chat\n/drop <message> — pin a note to this place for 24h (needs location)\n/help — this list",
            comment: "The /help reference list"
        )
    }

    private var nicknameBinding: Binding<String> {
        Binding(
            get: { appChromeModel.nickname },
            set: { appChromeModel.setNickname($0) }
        )
    }

    private var liveVoiceBinding: Binding<Bool> {
        Binding(
            get: { liveVoiceEnabled },
            set: { newValue in
                liveVoiceEnabled = newValue
                PTTSettings.liveVoiceEnabled = newValue
            }
        )
    }

    private var bridgeBinding: Binding<Bool> {
        Binding(
            get: { bridgeService.isEnabled },
            set: { bridgeService.setEnabled($0) }
        )
    }

    private var torBinding: Binding<Bool> {
        Binding(
            get: { locationChannelsModel.userTorEnabled },
            set: { locationChannelsModel.setUserTorEnabled($0) }
        )
    }

    private var locationNotesBinding: Binding<Bool> {
        Binding(
            get: { locationNotesEnabled },
            set: { newValue in
                locationNotesEnabled = newValue
                LocationNotesSettings.enabled = newValue
                if newValue {
                    locationManager.enableLocationChannels()
                }
            }
        )
    }

    private var hidePreviewsBinding: Binding<Bool> {
        Binding(
            get: { hideMessagePreviews },
            set: { newValue in
                hideMessagePreviews = newValue
                NotificationPrivacySettings.hideMessagePreviews = newValue
            }
        )
    }

    private func addRelay() {
        switch NostrRelaySettings.add(relayInput, builtIn: NostrRelayManager.builtInRelayURLs) {
        case .success:
            relayInput = ""
            relayError = nil
            customRelays = NostrRelaySettings.customRelays()
        case .failure(let failure):
            relayError = relayErrorText(failure)
        }
    }

    private func relayErrorText(_ failure: NostrRelaySettings.AddFailure) -> String {
        switch failure {
        case .malformed:
            return "Це не схоже на адресу ретранслятора. Спробуйте wss://host."
        case .alreadyPresent:
            return "Такий ретранслятор уже є в списку."
        case .limitReached:
            return "Можна додати не більше \(NostrRelaySettings.maxCustomRelays) ретрансляторів."
        }
    }
}
