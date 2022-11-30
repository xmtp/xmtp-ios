//
//  ConversationV1.swift
//
//
//  Created by Pat Nakajima on 11/28/22.
//

import Foundation

struct ConversationV1 {
	var client: Client
	var peerAddress: String
	var sentAt: Date

	func messages() async throws -> [DecodedMessage] {
		let envelopes = try await client.apiClient.query(topics: [
			.directMessageV1(client.address, peerAddress),
		]).envelopes

		return envelopes.compactMap { envelope in
			do {
				let message = try Message(serializedData: envelope.message)

				let decrypted = try message.v1.decrypt(with: client.privateKeyBundleV1)

				let encodedMessage = try EncodedContent(serializedData: decrypted)
				let decoder = TextCodec()
				let decoded = try decoder.decode(content: encodedMessage)

				return DecodedMessage(body: decoded)
			} catch {
				print("ERROR DECODING CONVO V1 MESSAGE: \(error)")
				return nil
			}
		}
	}
}
