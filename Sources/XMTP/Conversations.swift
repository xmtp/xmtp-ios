//
//  Conversations.swift
//
//
//  Created by Pat Nakajima on 11/26/22.
//

import Foundation
import XMTPProto

struct Conversations {
	var client: Client

	func sendInvitation(recipient: SignedPublicKeyBundle, invitation: InvitationV1, created: Date) async throws -> SealedInvitation {
		let sealed = try InvitationV1.createV1(
			sender: try client.privateKeyBundleV1.toV2(),
			recipient: recipient,
			created: Date(),
			invitation: invitation
		)

		let peerAddress = try recipient.identityKey.recoverWalletSignerPublicKey().walletAddress

		try await client.publish(envelopes: [
			Envelope(topic: .userInvite(peerAddress), timestamp: created, message: try sealed.serializedData()),
			Envelope(topic: .userInvite(client.address), timestamp: created, message: try sealed.serializedData()),
		])

		return sealed
	}
}
