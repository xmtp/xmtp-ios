//
//  ConversationListView.swift
//  XMTPiOSExample
//
//  Created by Pat Nakajima on 12/2/22.
//

import SwiftUI
import XMTP

struct ConversationListView: View {
	var client: XMTP.Client
	@State private var conversations: [XMTP.Conversation] = []

	var body: some View {
		List {
			ForEach(conversations, id: \.peerAddress) { conversation in
				Text(conversation.peerAddress)
			}
		}
		.refreshable {
			await loadConversations()
		}
		.task {
			await loadConversations()
		}
	}

	func loadConversations() async {
		do {
			let conversations = try await client.conversations.list()

			await MainActor.run {
				self.conversations = conversations
			}
		} catch {
			print("Error loading conversations: \(error)")
		}
	}
}
