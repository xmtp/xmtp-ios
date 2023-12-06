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
	@State private var streamTask: Task<(), Error>? = nil

	@State private var messages: [DecodedMessage] = []
	
	func startStream() {
		streamTask = Task {
			do {
				for try await message in conversation.streamMessages() {
					let content: String = try message.content()
					print("Received message: \(content)")
					await MainActor.run {
						messages.append(message)
					}
				}
			} catch {
				print("Error in message stream: \(error)")
			}
   	 }	
	}

	var body: some View {
		VStack {
			MessageListView(myAddress: client.address, messages: messages)
				.refreshable {
					await loadMessages()
				}
				.task {
					await loadMessages()
					startStream()
				}
				.onReceive(NotificationCenter.default.publisher(for: UIApplication.willResignActiveNotification)) { _ in
					streamTask?.cancel()
				}
				.onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
					Task{
						await loadMessages()
						startStream()
					}
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
		.navigationBarTitleDisplayMode(.inline)
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
