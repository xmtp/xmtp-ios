//
//  Authenticator.swift
//
//
//  Created by Pat Nakajima on 11/17/22.
//

import Foundation

enum AuthenticatorError: Error, Equatable {
	case identityKeyNotSigned
}

struct Authenticator {
	private var identityKey: PrivateKey

	init(_ identityKey: PrivateKey) throws {
		if !identityKey.publicKey.hasSignature {
			throw AuthenticatorError.identityKeyNotSigned
		}

		self.identityKey = identityKey
	}
}
