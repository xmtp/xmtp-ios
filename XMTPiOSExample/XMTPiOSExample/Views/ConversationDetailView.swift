//
//  ConversationDetailView.swift
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
		VStack {
			List {
				// TODO: Expose more on message so it can be identifiable
				ForEach(Array(messages.enumerated()), id: \.0) { _, message in
					Text(message.body)
				}
			}
			.refreshable {
				await loadMessages()
			}
			.task {
				await loadMessages()
			}

			MessageComposerView { text in
				do {
					try await conversation.send(text: text)
				} catch {
					print("Error sending message: \(error)")
				}
			}
		}
		.navigationTitle(conversation.peerAddress)
	}

	func loadMessages() async {
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
