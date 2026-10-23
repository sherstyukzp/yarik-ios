import SwiftUI
import UserNotifications
#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

/// Process identity used by the keychain and the shared app group.
/// The type name stays so existing keychain service identifiers keep resolving.
enum BitchatApp {
    static var bundleID: String {
        Bundle.main.bundleIdentifier ?? "com.ukropsoft.yarik"
    }

    static var groupID: String {
        if let configured = Bundle.main.object(forInfoDictionaryKey: "AppGroupID") as? String,
           !configured.isEmpty {
            return configured
        }
        return "group.\(bundleID)"
    }
}

final class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationDelegate()
    weak var runtime: AppRuntime?

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let identifier = response.notification.request.identifier
        let actionIdentifier = response.actionIdentifier
        let userInfo = response.notification.request.content.userInfo

        Task { @MainActor in
            self.runtime?.handleNotificationResponse(
                identifier: identifier,
                actionIdentifier: actionIdentifier,
                userInfo: userInfo
            )
            completionHandler()
        }
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        let identifier = notification.request.identifier
        let userInfo = notification.request.content.userInfo

        Task {
            let options = await self.runtime?.presentationOptions(
                forNotificationIdentifier: identifier,
                userInfo: userInfo
            ) ?? [.banner, .sound]
            completionHandler(options)
        }
    }
}

/// App entry the Yarik target presents. Owns the mesh runtime and the chat UI.
public struct YarikRootView: View {
    @StateObject private var runtime: AppRuntime
    @AppStorage(AppTheme.storageKey) private var appThemeRawValue = AppTheme.matrix.rawValue
    @Environment(\.scenePhase) private var scenePhase

    public init() {
        let runtime = AppRuntime()
        _runtime = StateObject(wrappedValue: runtime)
        NotificationDelegate.shared.runtime = runtime
        UNUserNotificationCenter.current().delegate = NotificationDelegate.shared
    }

    public var body: some View {
        ContentView()
            .environment(\.appTheme, AppTheme(rawValue: appThemeRawValue) ?? .matrix)
            .environmentObject(runtime.publicChatModel)
            .environmentObject(runtime.privateInboxModel)
            .environmentObject(runtime.privateConversationModel)
            .environmentObject(runtime.verificationModel)
            .environmentObject(runtime.conversationUIModel)
            .environmentObject(runtime.locationChannelsModel)
            .environmentObject(runtime.peerListModel)
            .environmentObject(runtime.appChromeModel)
            .environmentObject(runtime.boardAlertsModel)
            .environmentObject(runtime.sharedContentImportModel)
            .onAppear {
                NotificationDelegate.shared.runtime = runtime
                #if os(iOS)
                PrivacyScreen.shared.install()
                #endif
                runtime.start()
            }
            .onOpenURL { url in
                runtime.handleOpenURL(url)
            }
            #if os(iOS)
            .onChange(of: scenePhase) { newPhase in
                runtime.handleScenePhaseChange(newPhase)
            }
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
                runtime.handleDidBecomeActiveNotification()
            }
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.willTerminateNotification)) { _ in
                runtime.applicationWillTerminate()
            }
            #elseif os(macOS)
            .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
                runtime.handleMacDidBecomeActiveNotification()
            }
            .onReceive(NotificationCenter.default.publisher(for: NSApplication.willTerminateNotification)) { _ in
                runtime.applicationWillTerminate()
            }
            #endif
    }
}
