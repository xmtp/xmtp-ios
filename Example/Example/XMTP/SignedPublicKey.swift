//
//  SignedPublicKey.swift
//  Example
//
//  Created by Pat Nakajima on 11/14/22.
//

import Foundation
import secp256k1
import XMTPProto

struct SignedPublicKey: UnsignedPublicKey {
	var createdNs: Int
	var secp256k1UncompressedBytes: [UInt8]

	var keyBytes: [UInt8]
	var signature: Signature

	init(_ key: Xmtp_MessageContents_SignedPublicKey) throws {
		signature = try Signature(key.signature)
		createdNs = 0
		keyBytes = key.keyBytes.bytes
		secp256k1UncompressedBytes = key.keyBytes.bytes
	}

	func walletSignatureAddress() async -> String? {
		if signature.walletEcdsaCompact == nil {
			return nil
		}

		let pk = WalletSigner.signerKey(signature: signature)
		return pk?.getEthereumAddress()
	}
}
