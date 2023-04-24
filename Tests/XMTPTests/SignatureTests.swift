//
//  SignatureTests.swift
//
//
//  Created by Pat Nakajima on 11/27/22.
//

import CryptoKit
import XCTest
@testable import XMTP

class SignatureTests: XCTestCase {
	func testVerify() async throws {
		let digest = SHA256.hash(data: Data("Hello world".utf8))
		print("Message Bytes: \(Data("Hello world".utf8).toHex)")
		let signingKey = try PrivateKey.generate()
		let signature = try await signingKey.sign(Data(digest))

		print("Digest: \(digest.description)")
		print("Signature: \(signature.rawData.toHex)")
		print("Expected public: \(signingKey.publicKey.secp256K1Uncompressed.bytes.toHex)")
		print("Recovered public: \(try KeyUtilx.recoverPublicKey(message: Data(digest), signature: signature.rawData).toHex)")

		XCTAssert(try signature.verify(signedBy: signingKey.publicKey, digest: Data("Hello world".utf8)))
	}
}
