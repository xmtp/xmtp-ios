//
//  File.swift
//
//
//  Created by Pat Nakajima on 11/17/22.
//

import XMTPProto

typealias PrivateKeyBundle = Xmtp_MessageContents_PrivateKeyBundle

extension PrivateKeyBundle {
	func encrypted(with key: SigningKey) async throws -> EncryptedPrivateKeyBundle {
		let bundleBytes = try serializedData()
		let walletPreKey = try Crypto.secureRandomBytes(count: 32)

		guard let input = Signature.enableIdentityText(key: walletPreKey).data(using: .utf8) else {
			throw PrivateKeyError.invalidSignatureText
		}

		let signature = try await key.sign(input)
		let cipherText = try Crypto.encrypt(signature.ecdsaCompact.bytes, bundleBytes)

		var encryptedBundle = EncryptedPrivateKeyBundle()
		encryptedBundle.v1.walletPreKey = signature.ecdsaCompact.bytes
		encryptedBundle.v1.ciphertext = cipherText

		return encryptedBundle
	}
}
