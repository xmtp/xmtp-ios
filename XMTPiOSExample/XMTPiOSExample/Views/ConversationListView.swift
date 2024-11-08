import SwiftUI
import XMTPiOS

struct ConversationListView: View {
	var client: XMTPiOS.Client

	@EnvironmentObject var coordinator: EnvironmentCoordinator
	@State private var conversations: [XMTPiOS.Conversation] = []
	@State private var isShowingNewConversation = false

	var body: some View {
		List {
			ForEach(conversations.sorted(by: { $0.createdAt > $1.createdAt }), id: \.id) { item in
				NavigationLink(destination: destinationView(for: item)) {
					HStack {
						switch item {
						case .dm:
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
								if let abbreviatedAddress = try? Util.abbreviate(address: conversation.peerAddress) {
									Text(abbreviatedAddress)
								} else {
									Text("Unknown Address")
										.foregroundStyle(.secondary)
								}
							case .group(let group):
								let memberAddresses = try? group.members.map(\.inboxId).sorted().map { Util.abbreviate(address: $0) }
								if let addresses = memberAddresses {
									Text(addresses.joined(separator: ", "))
								} else {
									Text("Unknown Members")
										.foregroundStyle(.secondary)
								}
							}

							Text(item.createdAt.formatted())
								.font(.caption)
								.foregroundStyle(.secondary)
						}
					}
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
		.task {
			do {
				for try await conversation in try await client.conversations.stream() {
					await MainActor.run {
						conversations.insert(conversation, at: 0)
					}
					await add(conversations: [conversation])
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
				case .dm(let conversation):
					conversations.insert(.dm(conversation), at: 0)
					coordinator.path.append(conversationOrGroup)
				case .group(let group):
					conversations.insert(.group(group), at: 0)
					coordinator.path.append(conversationOrGroup)
				}
			}
		}
	}

	@ViewBuilder
	private func destinationView(for item: XMTPiOS.Conversation) -> some View {
		switch item {
		case .dm(let conversation):
			ConversationDetailView(client: client, conversation: .dm(conversation))
		case .group(let group):
			GroupDetailView(client: client, group: group)
		}
	}

	func loadConversations() async {
		do {
			try await client.conversations.sync()
			let loadedConversations = try await client.conversations.list()
			await MainActor.run {
				self.conversations = loadedConversations
			}
			await add(conversations: loadedConversations)
		} catch {
			print("Error loading conversations: \(error)")
		}
	}

	func add(conversations: [XMTPiOS.Conversation]) async {
		for conversationOrGroup in conversations {
			switch conversationOrGroup {
			case .dm, .group:
				return
			}
		}
	}
}

struct ConversationListView_Previews: PreviewProvider {
	static var previews: some View {
		PreviewClientProvider { client in
			NavigationStack {
				ConversationListView(client: client)
			}
		}
	}
}
