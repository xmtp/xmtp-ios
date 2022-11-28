//
//  ConversationV2.swift
//
//
//  Created by Pat Nakajima on 11/26/22.
//

import Foundation
import XMTPProto

struct SendOptions {}

struct ConversationV2 {
	var topic: String
	var keyMaterial: Data // MUST be kept secret
	var context: InvitationV1.Context
	var peerAddress: String
	private var client: Client
	private var header: SealedInvitationHeaderV1

	static func create(client: Client, invitation: InvitationV1, header: SealedInvitationHeaderV1) throws -> ConversationV2 {
		let myKeys = client.keys.getPublicKeyBundle()
		let peer = myKeys.identityKey.keyBytes == header.sender.identityKey.keyBytes ? header.recipient : header.sender
		let peerAddress = try peer.identityKey.recoverWalletSignerPublicKey().walletAddress

		let keyMaterial = Data(invitation.aes256GcmHkdfSha256.keyMaterial.bytes)

		return ConversationV2(
			topic: invitation.topic,
			keyMaterial: keyMaterial,
			context: invitation.context,
			peerAddress: peerAddress,
			client: client,
			header: header
		)
	}

	init(topic: String, keyMaterial: Data, context: InvitationV1.Context, peerAddress: String, client: Client, header: SealedInvitationHeaderV1) {
		self.topic = topic
		self.keyMaterial = keyMaterial
		self.context = context
		self.peerAddress = peerAddress
		self.client = client
		self.header = header
	}

	// TODO: more types of content
	func send(content: String, options _: SendOptions? = nil) async throws {
		let contact = try await client.getUserContact(peerAddress: peerAddress)!

		var encodedContent = Xmtp_MessageContents_EncodedContent()
		encodedContent.content = Data(content.utf8)
		encodedContent.fallback = content

		var recipient = PublicKeyBundle()
		recipient.identityKey = try PublicKey(contact.v2.keyBundle.identityKey)
		recipient.preKey = try PublicKey(contact.v2.keyBundle.preKey)

		var message = try await MessageV1.encode(
			sender: client.privateKeyBundleV1,
			recipient: recipient,
			message: try encodedContent.serializedData(),
			timestamp: Date()
		)

		print("SENDING TO \(try recipient.identityKey.recoverWalletSignerPublicKey().walletAddress)")

		try await client.publish(envelopes: [
			Envelope(topic: .userIntro(try recipient.identityKey.recoverWalletSignerPublicKey().walletAddress), timestamp: Date(), message: try message.serializedData()),
			Envelope(topic: .userIntro(client.address), timestamp: Date(), message: try message.serializedData()),
			Envelope(topic: topic, timestamp: Date(), message: try message.serializedData()),
		])
	}
}
