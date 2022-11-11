//
//  Signature.swift
//  xmtp-ios example
//
//  Created by Pat Nakajima on 11/11/22.
//

import Foundation
import secp256k1

struct Signature {
	var ecdsaCompact: secp256k1.Recovery.ECDSASignature?
	var walletEcdsaCompact: secp256k1.Recovery.ECDSASignature?
}
