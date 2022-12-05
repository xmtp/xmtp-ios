//
//  ConversationV2.swift
//
//
//  Created by Pat Nakajima on 11/26/22.
//

import CryptoKit
import Foundation
import XMTPProto

struct SendOptions {}

public struct ConversationV2 {
	var topic: String
	var keyMaterial: Data // MUST be kept secret
	var context: InvitationV1.Context
	var peerAddress: String
	var client: Client
	private var header: SealedInvitationHeaderV1

	static func create(client: Client, invitation: InvitationV1, header: SealedInvitationHeaderV1) throws -> ConversationV2 {
		let myKeys = client.keys.getPublicKeyBundle()

		let peer = try myKeys.walletAddress == (try header.sender.walletAddress) ? header.recipient : header.sender
		let peerAddress = try peer.walletAddress

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

	func messages() async throws -> [DecodedMessage] {
		let envelopes = try await client.apiClient.query(topics: [topic]).envelopes

		return envelopes.compactMap { envelope in
			do {
				let message = try Message(serializedData: envelope.message)

				return try decode(message.v2)
			} catch {
				print("Error decoding envelope \(error)")
				return nil
			}
		}
	}

	private func decode(_ message: MessageV2) throws -> DecodedMessage {
		print("client private key bundle: \(try client.privateKeyBundleV1.jsonString())")
		print("message: \(try message.jsonString())")

		do {
			let decrypted = try Crypto.decrypt(keyMaterial, message.ciphertext, additionalData: message.headerBytes)
			let signed = try SignedContent(serializedData: decrypted)
			let encodedMessage = try EncodedContent(serializedData: signed.payload)
			let decoder = TextCodec()
			let decoded = try decoder.decode(content: encodedMessage)

			return DecodedMessage(body: decoded)
		} catch {
			print("ERROR DECODING: \(error)")
			throw error
		}
	}

	// TODO: more types of content
	func send(content: String, options _: SendOptions? = nil) async throws {
		guard let contact = try await client.getUserContact(peerAddress: peerAddress) else {
			throw ContactBundleError.notFound
		}

		let signedPublicKeyBundle = try contact.toSignedPublicKeyBundle()
		let recipient = try PublicKeyBundle(signedPublicKeyBundle)

		let encoder = TextCodec()
		let encodedContent = try encoder.encode(content: content)
		let payload = try encodedContent.serializedData()

		let date = Date()
		let header = MessageHeaderV2(topic: topic, created: date)
		let headerBytes = try header.serializedData()

		let digest = SHA256.hash(data: headerBytes + payload)
		let preKey = client.keys.preKeys[0]
		let signature = try await preKey.sign(Data(digest))

		var bundle = try client.privateKeyBundleV1.toV2().getPublicKeyBundle()
		bundle.identityKey.signature.walletEcdsaCompact.bytes = bundle.identityKey.signature.ecdsaCompact.bytes
		bundle.identityKey.signature.walletEcdsaCompact.recovery = bundle.identityKey.signature.ecdsaCompact.recovery

		let signedContent = SignedContent(payload: payload, sender: bundle, signature: signature)
		let signedBytes = try signedContent.serializedData()

		let ciphertext = try Crypto.encrypt(keyMaterial, signedBytes, additionalData: headerBytes)

		let message = MessageV2(
			headerBytes: headerBytes,
			ciphertext: ciphertext
		)

		try await client.publish(envelopes: [
			Envelope(topic: topic, timestamp: date, message: try Message(v2: message).serializedData()),
		])
	}
}
