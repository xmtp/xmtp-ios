//
//  ApiClientTests.swift
//
//
//  Created by Pat Nakajima on 11/17/22.
//

import Foundation

import secp256k1
import XCTest
@testable import XMTP

final class AuthenticatorTests: XCTestCase {
	func testRequiresSignedPrivateKey() throws {
		let unsignedPrivateKey = try PrivateKey.generate()
		XCTAssertThrowsError(try Authenticator(unsignedPrivateKey)) { error in
			XCTAssertEqual(AuthenticatorError.identityKeyNotSigned, error as! AuthenticatorError)
		}
	}

	func testCreateToken() async throws {
		let key = try PrivateKey.generate()
		let identity = try PrivateKey.generate()

		let authorized = try await key.createIdentity(identity)
		let authToken = try await authorized.createAuthToken()

		guard let tokenData = Data(base64Encoded: authToken.data(using: .utf8) ?? Data()) else {
			XCTFail("could not get token data")
			return
		}

		let token = try Token(serializedData: tokenData)
		let authData = try AuthData(serializedData: token.authDataBytes)

		XCTAssertEqual(authData.walletAddr, authorized.address)
	}

	func testEnablingSavingAndLoadingOfStoredKeys() async throws {
		let key = try PrivateKey.generate()
		let identity = try PrivateKey.generate()

		let authorized = try! await key.createIdentity(identity)
		let bundle = try authorized.toBundle
		let encryptedBundle = try! await bundle.encrypted(with: key)

		let decrypted = try! await encryptedBundle.decrypted(with: key)
		XCTAssertEqual(decrypted.v1.identityKey.secp256K1.bytes, identity.signingBytes)
		XCTAssertEqual(decrypted.v1.identityKey.publicKey, try PublicKey(authorized.publicKey))
	}
}
