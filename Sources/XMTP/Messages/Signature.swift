//
//  Signature.swift
//
//
//  Created by Pat Nakajima on 11/17/22.
//

import Foundation
import XMTPProto

typealias Signature = Xmtp_MessageContents_Signature

extension Signature {
	static func createIdentityText(key: Data) -> String {
		return (
			"XMTP : Create Identity\n" +
				"\(key.toHex)\n" +
				"\n" +
				"For more info: https://xmtp.org/signatures/"
		)
	}

	static func enableIdentityText(key: Data) -> String {
		return (
			"XMTP : Enable Identity\n" +
				"\(key.toHex)\n" +
				"\n" +
				"For more info: https://xmtp.org/signatures/"
		)
	}

	var rawData: Data {
		ecdsaCompact.bytes + [UInt8(Int(ecdsaCompact.recovery))]
	}
}
