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
