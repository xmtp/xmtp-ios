import Foundation

public enum ConversationError: Error {
	case recipientNotOnNetwork, recipientIsSender, v1NotSupported(String)
}

public extension Sequence {
	func asyncCompactMap<T>(
		_ transform: (Element) async throws -> T?
	) async rethrows -> [T] {
		var values = [T]()

		for element in self {
			guard let value = try await transform(element) else {
				continue
			}

			values.append(value)
		}

		return values
	}
	func asyncFlatMap<T: Sequence>(
		_ transform: (Element) async throws -> T
	) async rethrows -> [T.Element] {
		var values = [T.Element]()

		for element in self {
			try await values.append(contentsOf: transform(element))
		}

		return values
	}
}

actor ConversationActor {
	static let shared = ConversationActor()
	private init() {}
	var conversationsByTopic: [String: Conversation] = [:]
	
	func set(_ key: String, _ object: Conversation) {
		conversationsByTopic[key] = object
	}
	
	func get(_ key: String) -> Conversation? {
		conversationsByTopic[key]
	}
	
	func findExistingConversation(with peerAddress: String, conversationID: String?) -> Conversation? {
		return conversationsByTopic.first(where: { $0.value.peerAddress == peerAddress &&
				(($0.value.conversationID ?? "") == (conversationID ?? ""))
		})?.value
	}
	
	func getConversationsSorted() -> [Conversation] {
		conversationsByTopic.values.sorted { a, b in
			a.createdAt < b.createdAt
		}
	}
	
	func getMostRecent() -> Conversation? {
		conversationsByTopic.values.max { a, b in
			a.createdAt < b.createdAt
		}
	}
}

/// Handles listing and creating Conversations.
public actor Conversations {
	var client: Client

	init(client: Client) {
		self.client = client
	}

	/// Import a previously seen conversation.
	/// See Conversation.toTopicData()
	public func importTopicData(data: Xmtp_KeystoreApi_V1_TopicMap.TopicData) -> Conversation {
		let conversation: Conversation
		if !data.hasInvitation {
			let sentAt = Date(timeIntervalSince1970: TimeInterval(data.createdNs / 1_000_000_000))
			conversation = .v1(ConversationV1(client: client, peerAddress: data.peerAddress, sentAt: sentAt))
		} else {
			conversation = .v2(ConversationV2(
				topic: data.invitation.topic,
				keyMaterial: data.invitation.aes256GcmHkdfSha256.keyMaterial,
				context: data.invitation.context,
				peerAddress: data.peerAddress,
				client: client
			))
		}
		Task {
			await ConversationActor.shared.set(conversation.topic, conversation)
		}
		return conversation
	}

	public func listBatchMessages(topics: [String: Pagination?]) async throws -> [DecodedMessage] {
		let requests = topics.map { topic, page in
			makeQueryRequest(topic: topic, pagination: page)
		}
		/// The maximum number of requests permitted in a single batch call.
		let maxQueryRequestsPerBatch = 50
		let batches = requests.chunks(maxQueryRequestsPerBatch)
			.map { requests in BatchQueryRequest.with { $0.requests = requests } }
		var messages: [DecodedMessage] = []
		// TODO: consider using a task group here for parallel batch calls
		for batch in batches {
			messages += try await client.apiClient.batchQuery(request: batch)
				.responses.asyncFlatMap { res in
					await res.envelopes.asyncCompactMap { envelope in
						let conversation = await ConversationActor.shared.get(envelope.contentTopic)
						if conversation == nil {
							print("discarding message, unknown conversation \(envelope)")
							return nil
						}
						do {
							return try conversation?.decode(envelope)
						} catch {
							print("discarding message, unable to decode \(envelope)")
							return nil
						}
					}
				}
		}
		return messages
	}

	public func listBatchDecryptedMessages(topics: [String: Pagination?]) async throws -> [DecryptedMessage] {
		let requests = topics.map { topic, page in
			makeQueryRequest(topic: topic, pagination: page)
		}
		/// The maximum number of requests permitted in a single batch call.
		let maxQueryRequestsPerBatch = 50
		let batches = requests.chunks(maxQueryRequestsPerBatch)
			.map { requests in BatchQueryRequest.with { $0.requests = requests } }
		var messages: [DecryptedMessage] = []
		// TODO: consider using a task group here for parallel batch calls
		for batch in batches {
			messages += try await client.apiClient.batchQuery(request: batch)
				.responses.asyncFlatMap { res in
					await res.envelopes.asyncCompactMap { envelope in
						let conversation = await ConversationActor.shared.get(envelope.contentTopic)
						if conversation == nil {
							print("discarding message, unknown conversation \(envelope)")
							return nil
						}
						do {
							return try conversation?.decrypt(envelope)
						} catch {
							print("discarding message, unable to decode \(envelope)")
							return nil
						}
					}
				}
		}
		return messages
	}

	public func streamAllMessages() async throws -> AsyncThrowingStream<DecodedMessage, Error> {
		return AsyncThrowingStream { continuation in
			Task {
				while true {
					var topics: [String] = [
						Topic.userInvite(client.address).description,
						Topic.userIntro(client.address).description,
					]

					for conversation in try await list() {
						topics.append(conversation.topic)
					}

					do {
						for try await envelope in client.subscribe(topics: topics) {
							if let conversation = await ConversationActor.shared.get(envelope.contentTopic) {
								let decoded = try conversation.decode(envelope)
								continuation.yield(decoded)
							} else if envelope.contentTopic.hasPrefix("/xmtp/0/invite-") {
								let conversation = try fromInvite(envelope: envelope)
								Task {
									await ConversationActor.shared.set(conversation.topic, conversation)
								}
								break // Break so we can resubscribe with the new conversation
							} else if envelope.contentTopic.hasPrefix("/xmtp/0/intro-") {
								let conversation = try fromIntro(envelope: envelope)
								Task {
									await ConversationActor.shared.set(conversation.topic, conversation)
								}
								let decoded = try conversation.decode(envelope)
								continuation.yield(decoded)
								break // Break so we can resubscribe with the new conversation
							} else {
								print("huh \(envelope)")
							}
						}
					} catch {
						continuation.finish(throwing: error)
					}
				}
			}
		}
	}

	public func streamAllDecryptedMessages() async throws -> AsyncThrowingStream<DecryptedMessage, Error> {
		return AsyncThrowingStream { continuation in
			Task {
				while true {
					var topics: [String] = [
						Topic.userInvite(client.address).description,
						Topic.userIntro(client.address).description,
					]

					for conversation in try await list() {
						topics.append(conversation.topic)
					}

					do {
						for try await envelope in client.subscribe(topics: topics) {
							if let conversation = await ConversationActor.shared.get(envelope.contentTopic) {
								let decoded = try conversation.decrypt(envelope)
								continuation.yield(decoded)
							} else if envelope.contentTopic.hasPrefix("/xmtp/0/invite-") {
								let conversation = try fromInvite(envelope: envelope)
								Task {
									await ConversationActor.shared.set(conversation.topic, conversation)
								}
								break // Break so we can resubscribe with the new conversation
							} else if envelope.contentTopic.hasPrefix("/xmtp/0/intro-") {
								let conversation = try fromIntro(envelope: envelope)
								Task {
									await ConversationActor.shared.set(conversation.topic, conversation)
								}
								let decoded = try conversation.decrypt(envelope)
								continuation.yield(decoded)
								break // Break so we can resubscribe with the new conversation
							} else {
								print("huh \(envelope)")
							}
						}
					} catch {
						continuation.finish(throwing: error)
					}
				}
			}
		}
	}

	public func fromInvite(envelope: Envelope) throws -> Conversation {
		let sealedInvitation = try SealedInvitation(serializedData: envelope.message)
		let unsealed = try sealedInvitation.v1.getInvitation(viewer: client.keys)

		return try .v2(ConversationV2.create(client: client, invitation: unsealed, header: sealedInvitation.v1.header))
	}

	public func fromIntro(envelope: Envelope) throws -> Conversation {
		let messageV1 = try MessageV1.fromBytes(envelope.message)
		let senderAddress = try messageV1.header.sender.walletAddress
		let recipientAddress = try messageV1.header.recipient.walletAddress

		let peerAddress = client.address == senderAddress ? recipientAddress : senderAddress
		let conversationV1 = ConversationV1(client: client, peerAddress: peerAddress, sentAt: messageV1.sentAt)

		return .v1(conversationV1)
	}

	public func newConversation(with peerAddress: String, context: InvitationV1.Context? = nil) async throws -> Conversation {
		if peerAddress.lowercased() == client.address.lowercased() {
			throw ConversationError.recipientIsSender
		}
		print("\(client.address) starting conversation with \(peerAddress)")
		if let existing = await ConversationActor.shared.findExistingConversation(with: peerAddress, conversationID: context?.conversationID) {
			return existing
		}

		guard let contact = try await client.contacts.find(peerAddress) else {
			throw ConversationError.recipientNotOnNetwork
		}

		_ = try await list() // cache old conversations and check again
		if let existing = await ConversationActor.shared.findExistingConversation(with: peerAddress, conversationID: context?.conversationID) {
			return existing
		}

		// We don't have an existing conversation, make a v2 one
		let recipient = try contact.toSignedPublicKeyBundle()
		let invitation = try InvitationV1.createDeterministic(
			sender: client.keys,
			recipient: recipient,
			context: context
		)
		let sealedInvitation = try await sendInvitation(recipient: recipient, invitation: invitation, created: Date())
		let conversationV2 = try ConversationV2.create(client: client, invitation: invitation, header: sealedInvitation.v1.header)

		try await client.contacts.allow(addresses: [peerAddress])

		let conversation: Conversation = .v2(conversationV2)
		Task {
			await ConversationActor.shared.set(conversation.topic, conversation)
		}
		return conversation
	}

	public func stream() -> AsyncThrowingStream<Conversation, Error> {
		AsyncThrowingStream { continuation in
			Task {
				var streamedConversationTopics: Set<String> = []

				for try await envelope in client.subscribe(topics: [.userIntro(client.address), .userInvite(client.address)]) {
					if envelope.contentTopic == Topic.userIntro(client.address).description {
						let conversationV1 = try fromIntro(envelope: envelope)

						if streamedConversationTopics.contains(conversationV1.topic.description) {
							continue
						}

						streamedConversationTopics.insert(conversationV1.topic.description)
						continuation.yield(conversationV1)
					}

					if envelope.contentTopic == Topic.userInvite(client.address).description {
						let conversationV2 = try fromInvite(envelope: envelope)

						if streamedConversationTopics.contains(conversationV2.topic) {
							continue
						}

						streamedConversationTopics.insert(conversationV2.topic)
						continuation.yield(conversationV2)
					}
				}
			}
		}
	}

	private func makeConversation(from sealedInvitation: SealedInvitation) throws -> ConversationV2 {
		let unsealed = try sealedInvitation.v1.getInvitation(viewer: client.keys)
		let conversation = try ConversationV2.create(client: client, invitation: unsealed, header: sealedInvitation.v1.header)

		return conversation
	}

	public func list() async throws -> [Conversation] {
		Task {
			var newConversations: [Conversation] = []
			let mostRecent = await ConversationActor.shared.getMostRecent()
			let pagination = Pagination(after: mostRecent?.createdAt)
			do {
				let seenPeers = try await listIntroductionPeers(pagination: pagination)
				for (peerAddress, sentAt) in seenPeers {
					newConversations.append(
						Conversation.v1(
							ConversationV1(
								client: client,
								peerAddress: peerAddress,
								sentAt: sentAt
							)
						)
					)
				}
				
			} catch {
				print("Error loading introduction peers: \(error)")
			}
			for sealedInvitation in try await listInvitations(pagination: pagination) {
				do {
					try newConversations.append(
							Conversation.v2(makeConversation(from:sealedInvitation))
					)
				} catch {
					print("Error loading invitations: \(error)")
				}
			}
			
			newConversations
				.filter { $0.peerAddress != client.address && Topic.isValidTopic(topic: $0.topic) }
				.forEach { conversation in
					Task {
						await ConversationActor.shared.set(conversation.topic, conversation)
					}
				}
			// TODO(perf): use DB to persist + sort
		}
		return await ConversationActor.shared.getConversationsSorted()
		
	}

	private func listIntroductionPeers(pagination: Pagination?) async throws -> [String: Date] {
		let envelopes = try await client.apiClient.query(
			topic: .userIntro(client.address),
			pagination: pagination
		).envelopes

		let messages = envelopes.compactMap { envelope in
			do {
				let message = try MessageV1.fromBytes(envelope.message)

				// Attempt to decrypt, just to make sure we can
				_ = try message.decrypt(with: client.privateKeyBundleV1)

				return message
			} catch {
				return nil
			}
		}

		var seenPeers: [String: Date] = [:]
		for message in messages {
			guard let recipientAddress = message.recipientAddress,
			      let senderAddress = message.senderAddress
			else {
				continue
			}

			let sentAt = message.sentAt
			let peerAddress = recipientAddress == client.address ? senderAddress : recipientAddress

			guard let existing = seenPeers[peerAddress] else {
				seenPeers[peerAddress] = sentAt
				continue
			}

			if existing > sentAt {
				seenPeers[peerAddress] = sentAt
			}
		}

		return seenPeers
	}

	private func listInvitations(pagination: Pagination?) async throws -> [SealedInvitation] {
		var envelopes = try await client.apiClient.envelopes(
			topic: Topic.userInvite(client.address).description,
			pagination: pagination
		)

		return envelopes.compactMap { envelope in
			// swiftlint:disable no_optional_try
			try? SealedInvitation(serializedData: envelope.message)
			// swiftlint:enable no_optional_try
		}
	}

	func sendInvitation(recipient: SignedPublicKeyBundle, invitation: InvitationV1, created: Date) async throws -> SealedInvitation {
		let sealed = try SealedInvitation.createV1(
			sender: client.keys,
			recipient: recipient,
			created: created,
			invitation: invitation
		)

		let peerAddress = try recipient.walletAddress

		try await client.publish(envelopes: [
			Envelope(topic: .userInvite(client.address), timestamp: created, message: sealed.serializedData()),
			Envelope(topic: .userInvite(peerAddress), timestamp: created, message: sealed.serializedData()),
		])

		return sealed
	}
}
