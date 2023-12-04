//
//  EncryptedPrivateKeyBundle.swift
//
//
//  Created by Pat Nakajima on 11/17/22.
//

typealias EncryptedPrivateKeyBundle = Xmtp_MessageContents_EncryptedPrivateKeyBundle

extension EncryptedPrivateKeyBundle {
  func decrypted(with key: SigningKey, preEnableIdentityCallback: (() async throws -> Void)? = nil) async throws -> PrivateKeyBundle {
    try await preEnableIdentityCallback?()
		let signature = try await key.sign(message: Signature.enableIdentityText(key: v1.walletPreKey))
		let message = try Crypto.decrypt(signature.rawDataWithNormalizedRecovery, v1.ciphertext)

		return try PrivateKeyBundle(serializedData: message)
	}
}
