//
//  Authenticator.swift
//  xmtp-ios example
//
//  Created by Pat Nakajima on 11/11/22.
//

import Foundation

enum AuthenticatorError: Error {
	case unsignedKey
}

struct Token {
	var identityKey: PublicKey
	var authDataBytes: [UInt8]
	var authDataSignature: Signature
}

struct Authenticator {
	private var identityKey: PrivateKey

	init(identityKey: PrivateKey) throws {
		if identityKey.publicKey.signature == nil {
			throw AuthenticatorError.unsignedKey
		}

		self.identityKey = identityKey
	}

//	func createToken(timestamp: Date?) async -> Token {
//
//	}
}
