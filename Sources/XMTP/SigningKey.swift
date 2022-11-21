//
//  SigningKey.swift
//
//
//  Created by Pat Nakajima on 11/17/22.
//

import Foundation
import secp256k1

// Anything that can sign should be a SigningKey (like a private key or a wallet).
protocol SigningKey {
	func sign(_ data: Data) async throws -> Signature
}

extension SigningKey {
	func sign(message: String) async throws -> Signature {
		let prefix = "\u{19}Ethereum Signed Message:\n\(message.count)"

		guard var data = prefix.data(using: .ascii) else {
			throw PrivateKeyError.invalidPrefix
		}

		data.append(message.data(using: .utf8)!)

		let digest = Util.keccak256(data)

		return try await sign(digest)
	}

	func createIdentity(_ identity: PrivateKey) async throws -> AuthorizedIdentity {
		let signatureText = Signature.createIdentityText(key: try identity.publicKey.serializedData())

		let signature = try await sign(message: signatureText)

		var publicKey = identity.publicKey
		publicKey.signature = signature

		let address = identity.walletAddress

		return AuthorizedIdentity(address: address, authorized: publicKey, identity: identity)
	}
}
