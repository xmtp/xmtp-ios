//
//  AuthorizedIdentity.swift
//
//
//  Created by Pat Nakajima on 11/17/22.
//

import Foundation

struct AuthorizedIdentity {
	var address: String
	var publicKey: SignedPublicKey
	var privateKey: PrivateKey

	func createAuthToken() async throws -> String {
		var publicKey = try PublicKey(publicKey)
		let authData = AuthData(walletAddress: KeyUtil.generateAddress(from: publicKey.secp256K1Uncompressed.bytes).toChecksumAddress())
		let authDataBytes = try authData.serializedData()

		let signature = try await privateKey.sign(digest: authDataBytes.web3.keccak256)

		var token = Token()
		publicKey.signature = signature

		token.identityKey = publicKey
		token.authDataBytes = authDataBytes
		token.authDataSignature = signature

		return try token.serializedData().base64EncodedString()
	}

	var toBundle: PrivateKeyBundle {
		get throws {
			var bundle = PrivateKeyBundle()
			bundle.v1.identityKey = privateKey
			bundle.v1.identityKey.publicKey = try PublicKey(publicKey)
			return bundle
		}
	}
}
