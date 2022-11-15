//
//  SignedPublicKey.swift
//  Example
//
//  Created by Pat Nakajima on 11/14/22.
//

import Foundation
import secp256k1

struct SignedPublicKey: UnsignedPublicKey {
	var createdNs: Int
	var secp256k1UncompressedBytes: [UInt8]

	var keyBytes: [UInt8]
	var signature: Signature
}
