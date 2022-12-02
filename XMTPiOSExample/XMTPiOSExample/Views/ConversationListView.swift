//
//  ConversationListView.swift
//  XMTPiOSExample
//
//  Created by Pat Nakajima on 12/2/22.
//

import SwiftUI
import XMTP

struct ConversationDetailView: View {
	var client: XMTP.Client
	var conversation: XMTP.Conversation

	@State private var messages: [DecodedMessage] = []

	var body: some View {
		List {
			// TODO: Expose more on message so it can be identifiable
			ForEach(Array(messages.enumerated()), id: \.0) { _, message in
				Text(message.body)
			}
		}
		.navigationTitle(conversation.peerAddress)
		.task {
			do {
				let messages = try await conversation.messages()
				await MainActor.run {
					self.messages = messages
				}
			} catch {
				print("Error loading messages for \(conversation.peerAddress)")
			}
		}
	}
}

struct ConversationListView: View {
	var client: XMTP.Client
	@State private var conversations: [XMTP.Conversation] = []

	var body: some View {
		List {
			ForEach(conversations, id: \.peerAddress) { conversation in
				NavigationLink(destination: ConversationDetailView(client: client, conversation: conversation)) {
					Text(conversation.peerAddress)
				}
			}
		}
		.navigationTitle("Conversations")
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
