//
//  SignedPrivateKey.swift
//
//
//  Created by Pat Nakajima on 11/17/22.
//

import Foundation
import XMTPProto

typealias SignedPrivateKey = Xmtp_MessageContents_SignedPrivateKey

extension SignedPrivateKey {
	static func generate(signer: PrivateKey) async throws -> SignedPrivateKey {
		var privateKey = try PrivateKey.generate()
		let unsigned = UnsignedPublicKey(privateKey.publicKey)
		let signedPublicKey = try await signer.sign(key: unsigned)

		var signedPrivateKey = SignedPrivateKey()
		signedPrivateKey.publicKey = signedPublicKey
		signedPrivateKey.secp256K1.bytes = privateKey.secp256K1.bytes

		return signedPrivateKey
	}
}

extension SignedPrivateKey: PrivateKeySigner {
	var signingBytes: Data {
		secp256K1.bytes
	}
}
