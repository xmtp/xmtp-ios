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

//	func newConversation(peerAddress: String, context: InvitationV1.Context?) async throws -> Conversation {
//		let contact = try await client.getUserContact(peerAddress: peerAddress)
//
//		if !contact.v2.hasKeyBundle {
//
//		}
//	}

	func getGetIntroductionPeers() async throws -> [String: Date] {
		return [:]
	}

	func sendInvitation(recipient: SignedPublicKeyBundle, invitation: InvitationV1, created: Date) async throws -> SealedInvitation {
		let sealed = try await InvitationV1.createV1(
			sender: try self.client.privateKeyBundleV1.toV2(),
			recipient: recipient,
			created: Date(),
			invitation: invitation
		)

		let peerAddress = try recipient.identityKey.recoverWalletSignerPublicKey().walletAddress

		try await client.publish(envelopes: [
			Envelope(topic: .userInvite(peerAddress), timestamp: created, message: try sealed.serializedData()),
			Envelope(topic: .userInvite(client.address), timestamp: created, message: try sealed.serializedData())
		])

		return sealed
	}
}


