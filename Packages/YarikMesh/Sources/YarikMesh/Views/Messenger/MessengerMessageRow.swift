import BitFoundation
import SwiftUI

struct MessengerMessageRow: View {
    @EnvironmentObject private var conversationUIModel: ConversationUIModel

    let message: BitchatMessage
    let showsSenderName: Bool
    @Binding var imagePreviewURL: URL?

    @State private var isExpanded = false
    @State private var showDeliveryDetail = false

    private var isMine: Bool {
        conversationUIModel.isSentByCurrentUser(message)
            || conversationUIModel.isMediaMessageFromCurrentUser(message)
    }

    private var senderName: String {
        message.sender.splitSuffix().0
    }

    var body: some View {
        if message.sender == "system" {
            Text(message.content)
                .font(.footnote)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 6)
                .padding(.horizontal, 24)
        } else if let media = conversationUIModel.mediaAttachment(for: message) {
            mediaRow(media)
        } else {
            textRow
        }
    }

    private var textRow: some View {
        HStack(alignment: .bottom, spacing: 0) {
            if isMine {
                Spacer(minLength: 48)
            }
            VStack(alignment: isMine ? .trailing : .leading, spacing: 4) {
                bubble
                statusLine
            }
            if !isMine {
                Spacer(minLength: 48)
            }
        }
        .padding(.vertical, 2)
    }

    private var bubble: some View {
        VStack(alignment: .leading, spacing: 4) {
            if showsSenderName && !isMine {
                HStack(spacing: 4) {
                    Text(senderName)
                        .font(.caption.weight(.semibold))
                    if message.isBridged {
                        Image(systemName: "network")
                            .font(.caption2)
                    }
                    if conversationUIModel.showsVerifiedSeal(for: message) {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.caption2)
                    }
                }
                .foregroundStyle(isMine ? Color.white.opacity(0.9) : Color.secondary)
            }

            Text(message.content)
                .font(.body)
                .foregroundStyle(isMine ? Color.white : Color.primary)
                .lineLimit(isExpanded || !message.content.isLongForDisplay() ? nil : 8)
                .textSelection(.enabled)

            if message.content.isLongForDisplay() {
                Button(isExpanded ? "Менше" : "Більше") {
                    isExpanded.toggle()
                }
                .font(.caption.weight(.semibold))
                .foregroundStyle(isMine ? Color.white.opacity(0.9) : Color.accentColor)
                .buttonStyle(.borderless)
            }

            Text(message.timestamp, format: .dateTime.hour().minute())
                .font(.caption2)
                .foregroundStyle(isMine ? Color.white.opacity(0.75) : Color.secondary)
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            isMine ? Color.blue : Color.secondary.opacity(0.15),
            in: RoundedRectangle(cornerRadius: 18, style: .continuous)
        )
    }

    @ViewBuilder
    private var statusLine: some View {
        let links = (message.content.extractLightningLinks(), message.content.extractCashuLinks())
        if message.isPrivate && isMine && message.deliveryStatus != .notSentYet {
            Button {
                showDeliveryDetail.toggle()
            } label: {
                HStack(spacing: 4) {
                    DeliveryStatusView(status: message.deliveryStatus)
                    if showDeliveryDetail || isFailed {
                        Text(message.deliveryStatus.bitchatDescription)
                            .font(.caption2)
                            .foregroundStyle(isFailed ? Color.red : Color.secondary)
                    }
                }
            }
            .buttonStyle(.borderless)
        }
        if !links.0.isEmpty || !links.1.isEmpty {
            HStack(spacing: 8) {
                ForEach(links.0, id: \.self) { link in
                    PaymentChipView(paymentType: .lightning(link))
                }
                ForEach(links.1, id: \.self) { link in
                    PaymentChipView(paymentType: .cashu(link))
                }
            }
        }
    }

    private var isFailed: Bool {
        if case .failed = message.deliveryStatus { return true }
        return false
    }

    private func mediaRow(_ media: BitchatMessage.Media) -> some View {
        HStack {
            if isMine { Spacer(minLength: 48) }
            MediaMessageView(message: message, media: media, imagePreviewURL: $imagePreviewURL)
                .frame(maxWidth: 280, alignment: isMine ? .trailing : .leading)
            if !isMine { Spacer(minLength: 48) }
        }
        .padding(.vertical, 2)
    }
}
