//
//  SigningKey.swift
//
//
//  Created by Pat Nakajima on 11/17/22.
//

import Foundation
import secp256k1

protocol SigningKey {
	func sign(_ data: Data) async throws -> Data
}

protocol PrivateKeySigner: SigningKey {
	var signingBytes: Data { get }
}

extension PrivateKeySigner {
	func sign(_ data: Data) async throws -> Data {
		try KeyUtil.sign(message: data, with: signingBytes, hashing: false)
	}

	func sign(digest: any DataProtocol) async throws -> Signature {
		let signingKey = try secp256k1.Signing.PrivateKey(rawRepresentation: signingBytes)
		let secpSignature = try signingKey.ecdsa.recoverableSignature(for: digest)

		let compactSignature: secp256k1.Recovery.ECDSACompactSignature = try secpSignature.compactRepresentation

		var signature = Signature()
		signature.ecdsaCompact.bytes = compactSignature.signature
		signature.ecdsaCompact.recovery = UInt32(compactSignature.recoveryId)

		return signature
	}
}
