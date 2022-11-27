//
//  MessageV1.swift
//  
//
//  Created by Pat Nakajima on 11/26/22.
//

import XMTPProto
import Foundation

typealias MessageV1 = Xmtp_MessageContents_MessageV1

extension MessageV1 {
	static func encode(sender: PrivateKeyBundleV1, recipient: PublicKeyBundle, message: Data, timestamp: Date) async throws -> MessageV1 {

		var signedPublicKeyBundle = SignedPublicKeyBundle()

		signedPublicKeyBundle.identityKey = try SignedPublicKey(recipient.identityKey, signature: recipient.identityKey.signature)

		signedPublicKeyBundle.preKey = try SignedPublicKey(recipient.preKey, signature: recipient.preKey.signature)

		var secret = try sender.toV2().sharedSecret(
			peer: signedPublicKeyBundle,
			myPreKey: SignedPublicKey.fromLegacy(sender.preKeys[0].publicKey),
			isRecipient: false
		)

		var header = Xmtp_MessageContents_MessageHeaderV1()
		header.sender = sender.toPublicKeyBundle()
		header.recipient = recipient
		header.timestamp = UInt64(Date().millisecondsSinceEpoch)

		let headerBytes = try header.serializedData()
		let ciphertext = try Crypto.encrypt(secret, message, additionalData: headerBytes)

		var messageV1 = MessageV1()
		messageV1.headerBytes = headerBytes
		messageV1.ciphertext = ciphertext

		var message = Xmtp_MessageContents_Message()
		message.v1 = messageV1

		return messageV1
	}
}
