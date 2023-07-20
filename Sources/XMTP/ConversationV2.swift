//
//  ConversationV2.swift
//
//
//  Created by Pat Nakajima on 11/26/22.
//

import CryptoKit
import Foundation

// Save the non-client parts for a v2 conversation
public struct ConversationV2Container: Codable {
	var topic: String
	var keyMaterial: Data
	var conversationID: String?
	var metadata: [String: String] = [:]
	var peerAddress: String
	var header: SealedInvitationHeaderV1

	public func decode(with client: Client) -> ConversationV2 {
		let context = InvitationV1.Context(conversationID: conversationID ?? "", metadata: metadata)
		return ConversationV2(topic: topic, keyMaterial: keyMaterial, context: context, peerAddress: peerAddress, client: client, header: header)
	}
}

/// Handles V2 Message conversations.
public struct ConversationV2 {
	public var topic: String
	public var keyMaterial: Data // MUST be kept secret
	public var context: InvitationV1.Context
	public var peerAddress: String
	public var client: Client
	public var isGroup = false
	private var header: SealedInvitationHeaderV1

	static func create(client: Client, invitation: InvitationV1, header: SealedInvitationHeaderV1, isGroup: Bool = false) throws -> ConversationV2 {
		let myKeys = client.keys.getPublicKeyBundle()

		let peer = try myKeys.walletAddress == (try header.sender.walletAddress) ? header.recipient : header.sender
		let peerAddress = try peer.walletAddress

		let keyMaterial = Data(invitation.aes256GcmHkdfSha256.keyMaterial)

		return ConversationV2(
			topic: invitation.topic,
			keyMaterial: keyMaterial,
			context: invitation.context,
			peerAddress: peerAddress,
			client: client,
			header: header,
			isGroup: isGroup
		)
	}

	public init(topic: String, keyMaterial: Data, context: InvitationV1.Context, peerAddress: String, client: Client) {
		self.topic = topic
		self.keyMaterial = keyMaterial
		self.context = context
		self.peerAddress = peerAddress
		self.client = client
		header = SealedInvitationHeaderV1()
	}

	public init(topic: String, keyMaterial: Data, context: InvitationV1.Context, peerAddress: String, client: Client, header: SealedInvitationHeaderV1, isGroup: Bool = false) {
		self.topic = topic
		self.keyMaterial = keyMaterial
		self.context = context
		self.peerAddress = peerAddress
		self.client = client
		self.header = header
		self.isGroup = isGroup
	}

	public var encodedContainer: ConversationV2Container {
		ConversationV2Container(topic: topic, keyMaterial: keyMaterial, conversationID: context.conversationID, metadata: context.metadata, peerAddress: peerAddress, header: header)
	}

	func prepareMessage(encodedContent: EncodedContent) async throws -> PreparedMessage {
		let message = try await MessageV2.encode(
			client: client,
			content: encodedContent,
			topic: topic,
			keyMaterial: keyMaterial
		)

		let envelope = Envelope(topic: topic, timestamp: Date(), message: try Message(v2: message).serializedData())
		return PreparedMessage(messageEnvelope: envelope, conversation: .v2(self)) {
			try await client.publish(envelopes: [envelope])
		}
	}

	func prepareMessage<T>(content: T, options: SendOptions?) async throws -> PreparedMessage {
		let codec = Client.codecRegistry.find(for: options?.contentType)

		func encode<Codec: ContentCodec>(codec: Codec, content: Any) throws -> EncodedContent {
			if let content = content as? Codec.T {
				return try codec.encode(content: content)
			} else {
				throw CodecError.invalidContent
			}
		}

		var encoded = try encode(codec: codec, content: content)
		encoded.fallback = options?.contentFallback ?? ""

		if let compression = options?.compression {
			encoded = try encoded.compress(compression)
		}

		return try await prepareMessage(encodedContent: encoded)
	}

	func messages(limit: Int? = nil, before: Date? = nil, after: Date? = nil) async throws -> [DecodedMessage] {
		let pagination = Pagination(limit: limit, before: before, after: after)
		let envelopes = try await client.apiClient.envelopes(topic: topic.description, pagination: pagination)

		return envelopes.compactMap { envelope in
			do {
            return try decode(envelope: envelope)
			} catch {
				print("Error decoding envelope \(error)")
				return nil
			}
		}
	}

	public func streamMessages() -> AsyncThrowingStream<DecodedMessage, Error> {
		AsyncThrowingStream { continuation in
			Task {
				for try await envelope in client.subscribe(topics: [topic.description]) {
					let decoded = try decode(envelope: envelope)

					continuation.yield(decoded)
				}
			}
		}
	}

	public var createdAt: Date {
		Date(timeIntervalSince1970: Double(header.createdNs / 1_000_000) / 1000)
	}

	public func decode(envelope: Envelope) throws -> DecodedMessage {
		let message = try Message(serializedData: envelope.message)
		var decoded = try decode(message.v2)

		decoded.id = generateID(from: envelope)

		return decoded
	}

	private func decode(_ message: MessageV2) throws -> DecodedMessage {
		try MessageV2.decode(message, keyMaterial: keyMaterial)
	}

	@discardableResult func send<T>(content: T, options: SendOptions? = nil) async throws -> String {
		let preparedMessage = try await prepareMessage(content: content, options: options)
		try await preparedMessage.send()
		return preparedMessage.messageID
	}

	@discardableResult func send(content: String, options: SendOptions? = nil, sentAt _: Date) async throws -> String {
		let preparedMessage = try await prepareMessage(content: content, options: options)
		try await preparedMessage.send()
		return preparedMessage.messageID
	}

	@discardableResult func send(encodedContent: EncodedContent) async throws -> String {
		let preparedMessage = try await prepareMessage(encodedContent: encodedContent)
		try await preparedMessage.send()
		return preparedMessage.messageID
	}

	public func encode<Codec: ContentCodec, T>(codec: Codec, content: T) async throws -> Data where Codec.T == T {
		let content = try codec.encode(content: content)

		let message = try await MessageV2.encode(
			client: client,
			content: content,
			topic: topic,
			keyMaterial: keyMaterial
		)

		let envelope = Envelope(
			topic: topic,
			timestamp: Date(),
			message: try Message(v2: message).serializedData()
		)

		return try envelope.serializedData()
	}

	@discardableResult func send(content: String, options: SendOptions? = nil) async throws -> String {
		return try await send(content: content, options: options, sentAt: Date())
	}

	private func generateID(from envelope: Envelope) -> String {
		Data(SHA256.hash(data: envelope.message)).toHex
	}
}
