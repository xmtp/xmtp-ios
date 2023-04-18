//
//  MessageV2.swift
//
//
//  Created by Pat Nakajima on 12/5/22.
//

import CryptoKit
import Foundation
import XMTPProto
import XMTPRust
import web3

typealias MessageV2 = Xmtp_MessageContents_MessageV2

enum MessageV2Error: Error {
	case invalidSignature, decodeError(String)
}

extension MessageV2 {
	init(headerBytes: Data, ciphertext: CipherText) {
		self.init()
		self.headerBytes = headerBytes
		self.ciphertext = ciphertext
	}

	static func decode(_ message: MessageV2, keyMaterial: Data) throws -> DecodedMessage {
		do {
			let decrypted = try Crypto.decrypt(keyMaterial, message.ciphertext, additionalData: message.headerBytes)
			let signed = try SignedContent(serializedData: decrypted)

			guard signed.sender.hasPreKey, signed.sender.hasIdentityKey else {
				throw MessageV2Error.decodeError("missing sender pre-key or identity key")
			}

			let senderPreKey = try PublicKey(signed.sender.preKey)
			let senderIdentityKey = try PublicKey(signed.sender.identityKey)

			// This is a bit confusing since we're passing keyBytes as the digest instead of a SHA256 hash.
			// That's because our underlying crypto library always SHA256's whatever data is sent to it for this.
			if !(try senderPreKey.signature.verify(signedBy: senderIdentityKey, digest: signed.sender.preKey.keyBytes)) {
				throw MessageV2Error.decodeError("pre-key not signed by identity key")
			}

			// Verify content signature
			let digest = SHA256.hash(data: message.headerBytes + signed.payload)

			let key = try PublicKey.with { key in
				guard let bytes = try KeyUtil.recoverPublicKey(message: Data(digest), signature: signed.signature.rawData).web3.bytesFromHex else {
					throw MessageV2Error.decodeError("invalid bytes")
				}

				key.secp256K1Uncompressed.bytes = Data(bytes)
			}

			if key.walletAddress != (try PublicKey(signed.sender.preKey).walletAddress) {
				throw MessageV2Error.invalidSignature
			}

			let encodedMessage = try EncodedContent(serializedData: signed.payload)
			let header = try MessageHeaderV2(serializedData: message.headerBytes)

			return DecodedMessage(
				encodedContent: encodedMessage,
				senderAddress: try signed.sender.walletAddress,
				sent: Date(timeIntervalSince1970: Double(header.createdNs / 1_000_000) / 1000)
			)
		} catch {
			print("ERROR DECODING: \(error)")
			throw error
		}
	}

	static func encode(client: Client, content encodedContent: EncodedContent, topic: String, keyMaterial: Data) async throws -> MessageV2 {
		let payload = try encodedContent.serializedData()

		let date = Date()
		let header = MessageHeaderV2(topic: topic, created: date)
		let headerBytes = try header.serializedData()

		let digest = SHA256.hash(data: headerBytes + payload)
		let preKey = client.keys.preKeys[0]
		let signature = try await preKey.sign(Data(digest))

		let bundle = client.privateKeyBundleV1.toV2().getPublicKeyBundle()

		let signedContent = SignedContent(payload: payload, sender: bundle, signature: signature)
		let signedBytes = try signedContent.serializedData()

		let ciphertext = try Crypto.encrypt(keyMaterial, signedBytes, additionalData: headerBytes)

		return MessageV2(
			headerBytes: headerBytes,
			ciphertext: ciphertext
		)
	}
}
