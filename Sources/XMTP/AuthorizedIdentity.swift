//
//  AuthorizedIdentity.swift
//
//
//  Created by Pat Nakajima on 11/17/22.
//

import Foundation

struct AuthorizedIdentity {
	var address: String
	var authorized: PublicKey
	var identity: PrivateKey

	func createAuthToken() async throws -> String {
		var publicKey = authorized

		let authData = AuthData(walletAddress: address)
		let authDataBytes = try authData.serializedData()

		let signature = try await identity.sign(Util.keccak256(authDataBytes))

		print("PUBLIC KEY \(publicKey.secp256K1Uncompressed.bytes.toHex)")
		print("HASHED \(Util.keccak256(authDataBytes).toHex)")
		print("SIGNATURE \(signature.rawData.toHex)")

		let recoveredPublic = try KeyUtil.recoverPublicKey(message: Util.keccak256(authDataBytes), signature: signature.rawData)
		print("RECOVERED IS \(recoveredPublic.toHex)")

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
			bundle.v1.identityKey = identity
			bundle.v1.identityKey.publicKey = authorized
			return bundle
		}
	}
}
