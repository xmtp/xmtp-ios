//
//  PrivateKeyBundleTests.swift
//
//
//  Created by Pat Nakajima on 11/29/22.
//

import XCTest
@testable import XMTP

class PrivateKeyBundleTests: XCTestCase {
	func testConversion() async throws {
		let wallet = try PrivateKey.generate()
		let v1 = try await PrivateKeyBundleV1.generate(wallet: wallet)

		let v2 = try v1.toV2()

		let v2PreKeyPublic = try UnsignedPublicKey(serializedData: v2.preKeys[0].publicKey.keyBytes)
		XCTAssertEqual(v1.preKeys[0].publicKey.secp256K1Uncompressed.bytes, v2PreKeyPublic.secp256K1Uncompressed.bytes)
	}

	func testSharedSecret() async throws {
		let alice = try PrivateKey.generate()
		let alicePrivateBundle = try await PrivateKeyBundleV1.generate(wallet: alice).toV2()
		let alicePublicBundle = await alicePrivateBundle.getPublicKeyBundle()

		let bob = try PrivateKey.generate()
		let bobPrivateBundle = try await PrivateKeyBundleV1.generate(wallet: bob).toV2()
		let bobPublicBundle = bobPrivateBundle.getPublicKeyBundle()

		let aliceSharedSecret = try alicePrivateBundle.sharedSecret(peer: bobPublicBundle, myPreKey: alicePublicBundle.preKey, isRecipient: true)

		let bobSharedSecret = try bobPrivateBundle.sharedSecret(peer: alicePublicBundle, myPreKey: bobPublicBundle.preKey, isRecipient: false)

		XCTAssertEqual(aliceSharedSecret, bobSharedSecret)
	}

	func testSharedSecretMatchesWhatJSGenerates() throws {
		let meBundleData = Data("0a8a030ac20108e2bcb0d1cc3012220a20b5f4e54752504afbc03f71399a8e64d885ee7132417cc34a6811e1bd1171391d1a940108e2bcb0d1cc3012460a440a40088e254d47a7c49fbf156e353bccc41a15ab14a6d5900d2de080a60ca13bc2e633e25f214fac943f548e22387184242d892e4362ce50a2733b71a5343ef1e03210011a430a41044c7bae3486607d734429f3536d420e4ea1e5a1b7d84f557cd86ccbc8cf38642a3ac67d420789bcf33324c62d406ee8252ab6bf2a680a840ef0a67903398d9d1712c20108f5bcb0d1cc3012220a20da02c188fbd6aca59517012344301f21fa4ce0c7ab30021cffb292114176ce621a940108f5bcb0d1cc3012460a440a40c8cc03e5db9652b41806b2834c6bd5ed64420c61b9c5ebec857c545b139ae9800770832d1d5e57b3a77ceaf4610be1aab2acca7ad097ce9f2c8cff6d09b4e13c10011a430a4104e01f2f96fbc501f6459bb6bb9a8e19805c21f3a389739a04c33a97508bd52812ef18cdd7334dd3ba36ce2c9d039aa848baeaecdc9748527b8a1bd0ca857cfa15".web3.bytesFromHex!)

		let youBundleData = Data("0a94010880bdb0d1cc3012460a440a4026980253ce6938f6dfcbd351d01df60fea00b2a27f1bff2c35fc8cc0758d71e571801e2a24e17db9a57c9950932c4193c5beff52175bad9e79c7a2ce4e5dd82210011a430a410464604974254b0127a328e4fa04ead2eca689bb7ba9010126dabb86091293ffb3fc41db03f4d59004844e5afa42beca91a6a6d5eebdedee809b4064e91d80820f1292010888bdb0d1cc3012440a420a400375bfd6208e41d244844d1996e3e0328d0d1f46dd280c1992593d223fad12630751f464d72929c0b7e2b66c3260f4f22edd844eb330a996a0e250052cd4c0db1a430a4104fa0d3af86706cfc22f3ecdccf0ff237a8f816447cd7a01eb800c2c06be67476f4448c5cac07aedbad4d1d13b0be760ec0005e3561f87b20921af76643b0224bf".web3.bytesFromHex!)

		let secretData = Data("04061effe20462e5e5a936ffe17c17613269c353c8a4fb67b8f4411ef0cdd7f5e1e87af92c4d22fc34399092b0ce65b7062bd4541a9d6c6e4504a4f5e8d2df9d3104ed38597a7e4665877ce40a0638985867e831213a11be8463208eba7be065f8794070ec9289bf7914f6f1143303ed62a83d4cc9bd1655610306024845b77420ba04d3bff2f662b3137fc145b7dd827ddc6b5ea422922dca62cd986bcb03b91ff635df1460b3c8a13f248f08798f8b3e1810f750cf53bcee436f6aa04b08d00c2585".web3.bytesFromHex!)

		let meBundle = try PrivateKeyBundle(serializedData: meBundleData).v1.toV2()
		let youBundlePublic = try SignedPublicKeyBundle(try PublicKeyBundle(serializedData: youBundleData))

		let secret = try meBundle.sharedSecret(peer: youBundlePublic, myPreKey: meBundle.preKeys[0].publicKey, isRecipient: true)

		XCTAssertEqual(secretData, secret)
	}
}
