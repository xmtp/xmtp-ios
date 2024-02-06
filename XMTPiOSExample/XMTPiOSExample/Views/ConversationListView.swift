//
//  ConversationListView.swift
//  XMTPiOSExample
//
//  Created by Pat Nakajima on 12/2/22.
//

import SwiftUI
import XMTPiOS

struct ConversationListView: View {
	var client: XMTPiOS.Client

	@EnvironmentObject var coordinator: EnvironmentCoordinator
	@State private var conversations: [ConversationOrGroup] = []
	@State private var isShowingNewConversation = false

	var body: some View {
		List {
			ForEach(conversations.sorted(by: { $0.createdAt > $1.createdAt }), id: \.id) { item in
				NavigationLink(value: item) {
					HStack {
						switch item {
						case .conversation:
							Image(systemName: "person.fill")
								.resizable()
								.scaledToFit()
								.frame(width: 16, height: 16)
								.foregroundStyle(.secondary)
						case .group:
							Image(systemName: "person.3.fill")
								.resizable()
								.scaledToFit()
								.frame(width: 16, height: 16)
								.foregroundStyle(.secondary)
						}

						VStack(alignment: .leading) {
							switch item {
							case .conversation(let conversation):
								Text(Util.abbreviate(address: conversation.peerAddress))
							case .group(let group):
								Text(group.members.sorted().map { Util.abbreviate(address: $0) }.joined(separator: ", "))
							}

							Text(item.createdAt.formatted())
								.font(.caption)
								.foregroundStyle(.secondary)
						}
					}
				}
			}
		}
		.navigationDestination(for: ConversationOrGroup.self) { item in
			switch item {
			case .conversation(let conversation):
				ConversationDetailView(client: client, conversation: conversation)
			case .group(let group):
				GroupDetailView(client: client, group: group)
			}
		}
		.navigationTitle("Conversations")
		.refreshable {
			await loadConversations()
		}
		.task {
			await loadConversations()
		}
		.task {
			do {
				for try await conversation in await client.conversations.stream() {
					conversations.insert(.conversation(conversation), at: 0)

					await add(conversations: [.conversation(conversation)])
				}

			} catch {
				print("Error streaming conversations: \(error)")
			}
		}
		.toolbar {
			ToolbarItem(placement: .navigationBarTrailing) {
				Button(action: {
					self.isShowingNewConversation = true
				}) {
					Label("New Conversation", systemImage: "plus")
				}
			}
		}
		.sheet(isPresented: $isShowingNewConversation) {
			NewConversationView(client: client) { conversationOrGroup in
				switch conversationOrGroup {
				case .conversation(let conversation):
					conversations.insert(.conversation(conversation), at: 0)
					coordinator.path.append(conversationOrGroup)
				case .group(let group):
					conversations.insert(.group(group), at: 0)
					coordinator.path.append(conversationOrGroup)
				}
			}
		}
	}

	func loadConversations() async {
		do {
			let conversations = try await client.conversations.list().map {
				ConversationOrGroup.conversation($0)
			}

			try await client.conversations.sync()

			let groups = try await client.conversations.groups().map {
				ConversationOrGroup.group($0)
			}

			await MainActor.run {
				self.conversations = conversations + groups
			}

			await add(conversations: conversations)
		} catch {
			print("Error loading conversations: \(error)")
		}
	}

	func add(conversations: [ConversationOrGroup]) async {
		for conversationOrGroup in conversations {
			switch conversationOrGroup {
			case .conversation(let conversation):
				// Ensure we're subscribed to push notifications on these conversations
				do {
					try await XMTPPush.shared.subscribe(topics: [conversation.topic])
				} catch {
					print("Error subscribing: \(error)")
				}

				do {
					try Persistence().save(conversation: conversation)
				} catch {
					print("Error saving \(conversation.topic): \(error)")
				}
			case .group:
				// TODO: handle
				return
			}
		}


	}
}

struct ConversationListView_Previews: PreviewProvider {
	static var previews: some View {
		VStack {
			PreviewClientProvider { client in
				NavigationView {
					ConversationListView(client: client)
				}
			}
		}
	}
}
