//
//  MessageV1.swift
//
//
//  Created by Pat Nakajima on 11/26/22.
//

import Foundation
import XMTPProto

typealias MessageV1 = Xmtp_MessageContents_MessageV1

extension MessageV1 {
	static func encode(sender: PrivateKeyBundleV1, recipient: PublicKeyBundle, message: Data, timestamp: Date) throws -> Message {
		let secret = try sender.sharedSecret(
			peer: recipient,
			myPreKey: sender.preKeys[0].publicKey,
			isRecipient: false
		)

		let header = MessageHeaderV1(
			sender: sender.toPublicKeyBundle(),
			recipient: recipient,
			timestamp: UInt64(timestamp.millisecondsSinceEpoch * 1_000_000)
		)

		let headerBytes = try header.serializedData()
		let ciphertext = try Crypto.encrypt(secret, message, additionalData: headerBytes)
		let message = Message(v1: MessageV1(headerBytes: headerBytes, ciphertext: ciphertext))

		return message
	}

	init(headerBytes: Data, ciphertext: CipherText) {
		self.init()
		self.headerBytes = headerBytes
		self.ciphertext = ciphertext
	}

	var senderAddress: String? {
		do {
			let header = try MessageHeaderV1(serializedData: headerBytes)
			let senderKey = try header.sender.identityKey.recoverWalletSignerPublicKey()
			return senderKey.walletAddress
		} catch {
			print("Error getting sender address: \(error)")
			return nil
		}
	}

	var recipientAddress: String? {
		do {
			let header = try MessageHeaderV1(serializedData: headerBytes)
			let recipientKey = try header.recipient.identityKey.recoverWalletSignerPublicKey()
			return recipientKey.walletAddress
		} catch {
			print("Error getting recipient address: \(error)")
			return nil
		}
	}

	func decrypt(with viewer: PrivateKeyBundleV1) throws -> Data {
		let header = try MessageHeaderV1(serializedData: headerBytes)

		var recipient = PublicKeyBundle()
		recipient.identityKey = header.recipient.identityKey
		recipient.preKey = header.recipient.preKey

		var sender = PublicKeyBundle()
		sender.identityKey = header.sender.identityKey
		sender.preKey = header.sender.preKey

		var secret: Data
		if viewer.identityKey.publicKey == sender.identityKey {
			secret = try viewer.sharedSecret(peer: recipient, myPreKey: sender.preKey, isRecipient: false)
		} else {
			secret = try viewer.sharedSecret(peer: sender, myPreKey: recipient.preKey, isRecipient: true)
		}

		return try Crypto.decrypt(secret, ciphertext, additionalData: headerBytes)
	}
}
