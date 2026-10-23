import BitFoundation

enum MessengerRoute: Hashable {
    case mesh
    case location(String)
    case direct(PeerID)
}

enum MessengerPeoplePurpose: Hashable {
    case newMessage
    case room
}

enum InboxFilter: String, CaseIterable, Identifiable {
    case all
    case places
    case groups
    case messages

    var id: String { rawValue }

    var title: String {
        switch self {
        case .all:
            return String(localized: "yarik.filter.all", defaultValue: "Усі", comment: "Inbox filter that shows every chat type")
        case .places:
            return String(localized: "yarik.filter.places", defaultValue: "Місця", comment: "Inbox filter for place channels")
        case .groups:
            return String(localized: "yarik.filter.groups", defaultValue: "Групи", comment: "Inbox filter for group chats")
        case .messages:
            return String(localized: "yarik.filter.messages", defaultValue: "Повідомлення", comment: "Inbox filter for private chats")
        }
    }
}
