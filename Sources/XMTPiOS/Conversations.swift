import Foundation
import LibXMTP

public enum ConversationError: Error, CustomStringConvertible, LocalizedError {
	case recipientNotOnNetwork, recipientIsSender, v1NotSupported(String)

	public var description: String {
		switch self {
		case .recipientIsSender:
			return "ConversationError.recipientIsSender: Recipient cannot be sender"
		case .recipientNotOnNetwork:
			return "ConversationError.recipientNotOnNetwork: Recipient is not on network"
		case .v1NotSupported(let str):
			return "ConversationError.v1NotSupported: V1 does not support: \(str)"
		}
	}
	
	public var errorDescription: String? {
		return description
	}
}

public enum GroupError: Error, CustomStringConvertible, LocalizedError {
	case alphaMLSNotEnabled, memberCannotBeSelf, memberNotRegistered([String]), groupsRequireMessagePassed, notSupportedByGroups, streamingFailure

	public var description: String {
		switch self {
		case .alphaMLSNotEnabled:
			return "GroupError.alphaMLSNotEnabled"
		case .memberCannotBeSelf:
			return "GroupError.memberCannotBeSelf you cannot add yourself to a group"
		case .memberNotRegistered(let array):
			return "GroupError.memberNotRegistered members not registered: \(array.joined(separator: ", "))"
		case .groupsRequireMessagePassed:
			return "GroupError.groupsRequireMessagePassed you cannot call this method without passing a message instead of an envelope"
		case .notSupportedByGroups:
			return "GroupError.notSupportedByGroups this method is not supported by groups"
		case .streamingFailure:
			return "GroupError.streamingFailure a stream has failed"
		}
	}
	
	public var errorDescription: String? {
		return description
	}
}

final class GroupStreamCallback: FfiConversationCallback {
	let client: Client
	let callback: (Group) -> Void

	init(client: Client, callback: @escaping (Group) -> Void) {
		self.client = client
		self.callback = callback
	}

	func onConversation(conversation: FfiGroup) {
		self.callback(conversation.fromFFI(client: client))
	}
}

final class V2SubscriptionCallback: FfiV2SubscriptionCallback {
	let callback: (Envelope) -> Void

	init(callback: @escaping (Envelope) -> Void) {
		self.callback = callback
	}
	
	func onMessage(message: LibXMTP.FfiEnvelope) {
		self.callback(message.fromFFI)
	}
}

class StreamManager {
	var stream: FfiV2Subscription?

	func updateStream(with request: FfiV2SubscribeRequest) async throws {
		try await stream?.update(req: request)
	}

	func endStream() async throws {
		try await stream?.end()
	}

	func setStream(_ newStream: FfiV2Subscription?) {
		self.stream = newStream
	}
}

actor FfiStreamActor {
    private var ffiStream: FfiStreamCloser?

    func setFfiStream(_ stream: FfiStreamCloser?) {
        ffiStream = stream
    }

    func endStream() {
        ffiStream?.end()
    }
}

/// Handles listing and creating Conversations.
public actor Conversations {
	var client: Client
	var conversationsByTopic: [String: Conversation] = [:]

	init(client: Client) {
		self.client = client
	}

	public func sync() async throws {
		guard let v3Client = client.v3Client else {
			return
		}
		try await v3Client.conversations().sync()
	}
	
	public func syncAllGroups() async throws ->  UInt32 {
		guard let v3Client = client.v3Client else {
			return 0
		}
		return try await v3Client.conversations().syncAllGroups()
	}

	public func groups(createdAfter: Date? = nil, createdBefore: Date? = nil, limit: Int? = nil) async throws -> [Group] {
		guard let v3Client = client.v3Client else {
			return []
		}
		var options = FfiListConversationsOptions(createdAfterNs: nil, createdBeforeNs: nil, limit: nil)
		if let createdAfter {
			options.createdAfterNs = Int64(createdAfter.millisecondsSinceEpoch)
		}
		if let createdBefore {
			options.createdBeforeNs = Int64(createdBefore.millisecondsSinceEpoch)
		}
		if let limit {
			options.limit = Int64(limit)
		}
		return try await v3Client.conversations().list(opts: options).map { $0.fromFFI(client: client) }
	}

	public func streamGroups() async throws -> AsyncThrowingStream<Group, Error> {
		AsyncThrowingStream { continuation in
            let ffiStreamActor = FfiStreamActor()
            let task = Task {
				let groupCallback = GroupStreamCallback(client: self.client) { group in
					guard !Task.isCancelled else {
						continuation.finish()
						return
					}
					continuation.yield(group)
				}
				guard let stream = await self.client.v3Client?.conversations().stream(callback: groupCallback) else {
					continuation.finish(throwing: GroupError.streamingFailure)
					return
				}
                await ffiStreamActor.setFfiStream(stream)
				continuation.onTermination = { @Sendable reason in
                    Task {
                      await ffiStreamActor.endStream()
                    }
				}
			}

			continuation.onTermination = { @Sendable reason in
				task.cancel()
                Task {
                  await ffiStreamActor.endStream()
                }
			}
		}
	}

	private func streamGroupConversations() -> AsyncThrowingStream<Conversation, Error> {
		AsyncThrowingStream { continuation in
            let ffiStreamActor = FfiStreamActor()
			let task = Task {
				let stream = await self.client.v3Client?.conversations().stream(
					callback: GroupStreamCallback(client: self.client) { group in
						guard !Task.isCancelled else {
							continuation.finish()
							return
						}
						continuation.yield(Conversation.group(group))
					}
				)
                await ffiStreamActor.setFfiStream(stream)
				continuation.onTermination = { @Sendable reason in
                    Task {
                        await ffiStreamActor.endStream()
                    }
				}
			}

			continuation.onTermination = { @Sendable reason in
				task.cancel()
                Task {
                    await ffiStreamActor.endStream()
                }
			}
		}
	}
    
    public func newGroup(with addresses: [String],
                         permissions: GroupPermissionPreconfiguration = .allMembers,
                         name: String = "",
                         imageUrlSquare: String = "",
                         description: String = "",
                         pinnedFrameUrl: String = ""
    ) async throws -> Group {
        return try await newGroupInternal(
            with: addresses,
            permissions: GroupPermissionPreconfiguration.toFfiGroupPermissionOptions(option: permissions),
            name: name,
            imageUrlSquare: imageUrlSquare,
            description: description,
            pinnedFrameUrl: pinnedFrameUrl,
            permissionPolicySet: nil
        )
    }
    
    public func newGroupCustomPermissions(with addresses: [String],
                                          permissionPolicySet: PermissionPolicySet,
                                         name: String = "",
                                         imageUrlSquare: String = "",
                                         description: String = "",
                                         pinnedFrameUrl: String = ""
    ) async throws -> Group {
        return try await newGroupInternal(
            with: addresses,
            permissions: FfiGroupPermissionsOptions.customPolicy,
            name: name,
            imageUrlSquare: imageUrlSquare,
            description: description,
            pinnedFrameUrl: pinnedFrameUrl,
            permissionPolicySet: PermissionPolicySet.toFfiPermissionPolicySet(permissionPolicySet)
        )
    }

	private func newGroupInternal(with addresses: [String],
						 permissions: FfiGroupPermissionsOptions = .allMembers,
						 name: String = "",
						 imageUrlSquare: String = "",
                         description: String = "",
						 pinnedFrameUrl: String = "",
                         permissionPolicySet: FfiPermissionPolicySet? = nil
	) async throws -> Group {
		guard let v3Client = client.v3Client else {
			throw GroupError.alphaMLSNotEnabled
		}
		if addresses.first(where: { $0.lowercased() == client.address.lowercased() }) != nil {
			throw GroupError.memberCannotBeSelf
		}
		let erroredAddresses = try await withThrowingTaskGroup(of: (String?).self) { group in
			for address in addresses {
				group.addTask {
					if try await self.client.canMessageV3(address: address) {
						return nil
					} else {
						return address
					}
				}
			}
			var results: [String] = []
			for try await result in group {
				if let result {
					results.append(result)
				}
			}
			return results
		}
		if !erroredAddresses.isEmpty {
			throw GroupError.memberNotRegistered(erroredAddresses)
		}
		let group = try await v3Client.conversations().createGroup(accountAddresses: addresses,
                                                                   opts: FfiCreateGroupOptions(permissions: permissions,
																							   groupName: name,
																							   groupImageUrlSquare: imageUrlSquare,
                                                                                               groupDescription: description,
																							   groupPinnedFrameUrl: pinnedFrameUrl,
                                                                                               customPermissionPolicySet: permissionPolicySet
																   )).fromFFI(client: client)
		try await client.contacts.allowGroups(groupIds: [group.id])
		return group
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
				client: client,
				createdAtNs: data.createdNs
			))
		}
		Task {
			await self.addConversation(conversation)
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
		guard let apiClient = client.apiClient else {
			throw ClientError.noV2Client("Error no V2 client initialized")
		}
		for batch in batches {
			messages += try await apiClient.batchQuery(request: batch)
				.responses.flatMap { res in
					res.envelopes.compactMap { envelope in
						let conversation = conversationsByTopic[envelope.contentTopic]
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
		guard let apiClient = client.apiClient else {
			throw ClientError.noV2Client("Error no V2 client initialized")
		}
		for batch in batches {
			messages += try await apiClient.batchQuery(request: batch)
				.responses.flatMap { res in
					res.envelopes.compactMap { envelope in
						let conversation = conversationsByTopic[envelope.contentTopic]
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

	func streamAllV2Messages() -> AsyncThrowingStream<DecodedMessage, Error> {
		AsyncThrowingStream { continuation in
			let streamManager = StreamManager()
			
			Task {
				var topics: [String] = [
					Topic.userInvite(client.address).description,
					Topic.userIntro(client.address).description
				]

				for conversation in try await list() {
					topics.append(conversation.topic)
				}

				var subscriptionRequest = FfiV2SubscribeRequest(contentTopics: topics)

				let subscriptionCallback = V2SubscriptionCallback { envelope in
					Task {
						do {
							if let conversation = self.conversationsByTopic[envelope.contentTopic] {
								let decoded = try conversation.decode(envelope)
								continuation.yield(decoded)
							} else if envelope.contentTopic.hasPrefix("/xmtp/0/invite-") {
								let conversation = try self.fromInvite(envelope: envelope)
								await self.addConversation(conversation)
								topics.append(conversation.topic)
								subscriptionRequest = FfiV2SubscribeRequest(contentTopics: topics)
								try await streamManager.updateStream(with: subscriptionRequest)
							} else if envelope.contentTopic.hasPrefix("/xmtp/0/intro-") {
								let conversation = try self.fromIntro(envelope: envelope)
								await self.addConversation(conversation)
								let decoded = try conversation.decode(envelope)
								continuation.yield(decoded)
								topics.append(conversation.topic)
								subscriptionRequest = FfiV2SubscribeRequest(contentTopics: topics)
								try await streamManager.updateStream(with: subscriptionRequest)
							} else {
								print("huh \(envelope)")
							}
						} catch {
							continuation.finish(throwing: error)
						}
					}
				}
				let newStream = try await client.subscribe2(request: subscriptionRequest, callback: subscriptionCallback)
				streamManager.setStream(newStream)
				
				continuation.onTermination = { @Sendable reason in
					Task {
						try await streamManager.endStream()
					}
				}
			}
		}
	}

	public func streamAllGroupMessages() -> AsyncThrowingStream<DecodedMessage, Error> {
		AsyncThrowingStream { continuation in
            let ffiStreamActor = FfiStreamActor()
			let task = Task {
				let stream = await self.client.v3Client?.conversations().streamAllMessages(
					messageCallback: MessageCallback(client: self.client) { message in
						guard !Task.isCancelled else {
							continuation.finish()
                            Task {
                                await ffiStreamActor.endStream() // End the stream upon cancellation
                            }
							return
						}
						do {
							continuation.yield(try MessageV3(client: self.client, ffiMessage: message).decode())
						} catch {
							print("Error onMessage \(error)")
						}
					}
				)
                await ffiStreamActor.setFfiStream(stream)
			}

			continuation.onTermination = { _ in
				task.cancel()
                Task {
                    await ffiStreamActor.endStream()
                }
			}
		}
	}

	public func streamAllMessages(includeGroups: Bool = false) -> AsyncThrowingStream<DecodedMessage, Error> {
		AsyncThrowingStream<DecodedMessage, Error> { continuation in
            @Sendable func forwardStreamToMerged(stream: AsyncThrowingStream<DecodedMessage, Error>) async {
				do {
					var iterator = stream.makeAsyncIterator()
					while let element = try await iterator.next() {
						guard !Task.isCancelled else {
							continuation.finish()
							return
						}
						continuation.yield(element)
					}
					continuation.finish()
				} catch {
					continuation.finish(throwing: error)
				}
			}

			let task = Task {
                await forwardStreamToMerged(stream: streamAllV2Messages())
			}
            
            let groupTask = includeGroups ? Task {
                await forwardStreamToMerged(stream: streamAllGroupMessages())
            } : nil

			continuation.onTermination = { _ in
				task.cancel()
                groupTask?.cancel()
			}
		}
	}

	public func streamAllGroupDecryptedMessages() -> AsyncThrowingStream<DecryptedMessage, Error> {
		AsyncThrowingStream { continuation in
            let ffiStreamActor = FfiStreamActor()
			let task = Task {
				let stream = await self.client.v3Client?.conversations().streamAllMessages(
					messageCallback: MessageCallback(client: self.client) { message in
						guard !Task.isCancelled else {
							continuation.finish()
                            Task {
                                await ffiStreamActor.endStream() // End the stream upon cancellation
                            }
							return
						}
						do {
							continuation.yield(try MessageV3(client: self.client, ffiMessage: message).decrypt())
						} catch {
							print("Error onMessage \(error)")
						}
					}
				)
                await ffiStreamActor.setFfiStream(stream)
			}

			continuation.onTermination = { _ in
				task.cancel()
                Task {
                    await ffiStreamActor.endStream()
                }
			}
		}
	}

	public func streamAllDecryptedMessages(includeGroups: Bool = false) -> AsyncThrowingStream<DecryptedMessage, Error> {
		AsyncThrowingStream<DecryptedMessage, Error> { continuation in
            @Sendable func forwardStreamToMerged(stream: AsyncThrowingStream<DecryptedMessage, Error>) async {
				do {
					var iterator = stream.makeAsyncIterator()
					while let element = try await iterator.next() {
						guard !Task.isCancelled else {
							continuation.finish()
							return
						}
						continuation.yield(element)
					}
					continuation.finish()
				} catch {
					continuation.finish(throwing: error)
				}
			}

			let task = Task {
				await forwardStreamToMerged(stream: streamAllV2DecryptedMessages())
			}
            
            let groupTask = includeGroups ? Task {
                await forwardStreamToMerged(stream: streamAllGroupDecryptedMessages())
            } : nil

			continuation.onTermination = { _ in
                task.cancel()
                groupTask?.cancel()
			}
		}
	}


	
	
	func streamAllV2DecryptedMessages() -> AsyncThrowingStream<DecryptedMessage, Error> {
		AsyncThrowingStream { continuation in
			let streamManager = StreamManager()
			
			Task {
				var topics: [String] = [
					Topic.userInvite(client.address).description,
					Topic.userIntro(client.address).description
				]

				for conversation in try await list() {
					topics.append(conversation.topic)
				}

				var subscriptionRequest = FfiV2SubscribeRequest(contentTopics: topics)

				let subscriptionCallback = V2SubscriptionCallback { envelope in
					Task {
						do {
							if let conversation = self.conversationsByTopic[envelope.contentTopic] {
								let decrypted = try conversation.decrypt(envelope)
								continuation.yield(decrypted)
							} else if envelope.contentTopic.hasPrefix("/xmtp/0/invite-") {
								let conversation = try self.fromInvite(envelope: envelope)
								await self.addConversation(conversation)
								topics.append(conversation.topic)
								subscriptionRequest = FfiV2SubscribeRequest(contentTopics: topics)
								try await streamManager.updateStream(with: subscriptionRequest)
							} else if envelope.contentTopic.hasPrefix("/xmtp/0/intro-") {
								let conversation = try self.fromIntro(envelope: envelope)
								await self.addConversation(conversation)
								let decrypted = try conversation.decrypt(envelope)
								continuation.yield(decrypted)
								topics.append(conversation.topic)
								subscriptionRequest = FfiV2SubscribeRequest(contentTopics: topics)
								try await streamManager.updateStream(with: subscriptionRequest)
							} else {
								print("huh \(envelope)")
							}
						} catch {
							continuation.finish(throwing: error)
						}
					}
				}
				let newStream = try await client.subscribe2(request: subscriptionRequest, callback: subscriptionCallback)
				streamManager.setStream(newStream)
				
				continuation.onTermination = { @Sendable reason in
					Task {
						try await streamManager.endStream()
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

	private func findExistingConversation(with peerAddress: String, conversationID: String?) throws -> Conversation? {
		return try conversationsByTopic.first(where: { try $0.value.peerAddress == peerAddress &&
				(($0.value.conversationID ?? "") == (conversationID ?? ""))
		})?.value
	}

	public func fromWelcome(envelopeBytes: Data) async throws -> Group? {
		guard let v3Client = client.v3Client else {
			return nil
		}
		let group = try await v3Client.conversations().processStreamedWelcomeMessage(envelopeBytes: envelopeBytes)
		return Group(ffiGroup: group, client: client)
	}

	public func newConversation(with peerAddress: String, context: InvitationV1.Context? = nil, consentProofPayload: ConsentProofPayload? = nil) async throws -> Conversation {
		if peerAddress.lowercased() == client.address.lowercased() {
			throw ConversationError.recipientIsSender
		}
		print("\(client.address) starting conversation with \(peerAddress)")
		if let existing = try findExistingConversation(with: peerAddress, conversationID: context?.conversationID) {
			return existing
		}
		guard let contact = try await client.contacts.find(peerAddress) else {
			throw ConversationError.recipientNotOnNetwork
		}
		_ = try await list() // cache old conversations and check again
		if let existing = try findExistingConversation(with: peerAddress, conversationID: context?.conversationID) {
			return existing
		}
		// We don't have an existing conversation, make a v2 one
		let recipient = try contact.toSignedPublicKeyBundle()
		let invitation = try InvitationV1.createDeterministic(
			sender: client.keys,
			recipient: recipient,
			context: context,
			consentProofPayload: consentProofPayload
		)
		let sealedInvitation = try await sendInvitation(recipient: recipient, invitation: invitation, created: Date())
		let conversationV2 = try ConversationV2.create(client: client, invitation: invitation, header: sealedInvitation.v1.header)
		try await client.contacts.allow(addresses: [peerAddress])
		let conversation: Conversation = .v2(conversationV2)
		Task {
			await self.addConversation(conversation)
		}
		return conversation
	}

	public func stream() async throws -> AsyncThrowingStream<Conversation, Error> {
		AsyncThrowingStream { continuation in
			Task {
				var streamedConversationTopics: Set<String> = []
				let subscriptionCallback = V2SubscriptionCallback { envelope in
					Task {
						if envelope.contentTopic == Topic.userIntro(self.client.address).description {
							let conversationV1 = try self.fromIntro(envelope: envelope)
							if !streamedConversationTopics.contains(conversationV1.topic.description) {
								streamedConversationTopics.insert(conversationV1.topic.description)
								continuation.yield(conversationV1)
							}
						}
						if envelope.contentTopic == Topic.userInvite(self.client.address).description {
							let conversationV2 = try self.fromInvite(envelope: envelope)
							if !streamedConversationTopics.contains(conversationV2.topic) {
								streamedConversationTopics.insert(conversationV2.topic)
								continuation.yield(conversationV2)
							}
						}
					}
				}
				
				let stream = try await client.subscribe(topics: [Topic.userIntro(client.address).description, Topic.userInvite(client.address).description], callback: subscriptionCallback)
					
				continuation.onTermination = { @Sendable reason in
					Task {
						try await stream.end()
					}
				}
			}
		}
	}

	public func streamAll() -> AsyncThrowingStream<Conversation, Error> {
		AsyncThrowingStream<Conversation, Error> { continuation in
			@Sendable func forwardStreamToMerged(stream: AsyncThrowingStream<Conversation, Error>) async {
				do {
					var iterator = stream.makeAsyncIterator()
					while let element = try await iterator.next() {
						continuation.yield(element)
					}
					continuation.finish()
				} catch {
					continuation.finish(throwing: error)
				}
			}
			Task {
				await forwardStreamToMerged(stream: try stream())
			}
			Task {
				await forwardStreamToMerged(stream: streamGroupConversations())
			}
		}
	}

	private func makeConversation(from sealedInvitation: SealedInvitation) throws -> ConversationV2 {
		let unsealed = try sealedInvitation.v1.getInvitation(viewer: client.keys)
		return try ConversationV2.create(client: client, invitation: unsealed, header: sealedInvitation.v1.header)
	}

	private func validateConsentSignature(signature: String, clientAddress: String, peerAddress: String, timestamp: UInt64) -> Bool {
		// timestamp should be in the past
		if timestamp > UInt64(Date().timeIntervalSince1970 * 1000) {
			return false
		}
		let thirtyDaysAgo = Date().addingTimeInterval(-30 * 24 * 60 * 60)
		let thirtyDaysAgoTimestamp = UInt64(thirtyDaysAgo.timeIntervalSince1970 * 1000)
		if timestamp < thirtyDaysAgoTimestamp {
			return false
		}
		let message = Signature.consentProofText(peerAddress: peerAddress, timestamp: timestamp)
		guard let signatureData = Data(hex: signature) else {
			print("Invalid signature format")
			return false
		}
		do {
			let ethMessage = try Signature.ethHash(message)
			let recoveredKey = try KeyUtilx.recoverPublicKey(message: ethMessage, signature: signatureData)
			let address = KeyUtilx.generateAddress(from: recoveredKey).toChecksumAddress()
			return clientAddress == address
		} catch {
			return false
		}
	}

	private func handleConsentProof(consentProof: ConsentProofPayload, peerAddress: String) async throws {
		let signature = consentProof.signature
		if (signature == "") {
			return
		}
		if (!validateConsentSignature(signature: signature, clientAddress: client.address, peerAddress: peerAddress, timestamp: consentProof.timestamp)) {
			return
		}
		let contacts = client.contacts
		_ = try await contacts.refreshConsentList()
		if try await (contacts.consentList.state(address: peerAddress) == .unknown) {
			try await contacts.allow(addresses: [peerAddress])
		}
	}

	public func list(includeGroups: Bool = false) async throws -> [Conversation] {
		if includeGroups {
			try await sync()
			let groups = try await groups()
			for group in groups {
				await self.addConversation(.group(group))
			}
		}
		var newConversations: [Conversation] = []
		let mostRecent = await self.getMostRecentConversation()
		let pagination = Pagination(after: mostRecent?.createdAt)
		do {
			let seenPeers = try await listIntroductionPeers(pagination: pagination)
			for (peerAddress, sentAt) in seenPeers {
				let newConversation = Conversation.v1(ConversationV1(client: client, peerAddress: peerAddress, sentAt: sentAt))
				newConversations.append(newConversation)
			}
		} catch {
			print("Error loading introduction peers: \(error)")
		}
		for sealedInvitation in try await listInvitations(pagination: pagination) {
			do {
				let newConversation = Conversation.v2(try makeConversation(from: sealedInvitation))
				newConversations.append(newConversation)
				if let consentProof = newConversation.consentProof, consentProof.signature != "" {
					try await self.handleConsentProof(consentProof: consentProof, peerAddress: newConversation.peerAddress)
				}
			} catch {
				print("Error loading invitations: \(error)")
			}
		}
		for conversation in newConversations {
			if try conversation.peerAddress != client.address && Topic.isValidTopic(topic: conversation.topic) {
				await self.addConversation(conversation)
			}
		}
		return await self.getSortedConversations()
	}

	private func addConversation(_ conversation: Conversation) async {
		conversationsByTopic[conversation.topic] = conversation
	}

	private func getMostRecentConversation() async -> Conversation? {
		return conversationsByTopic.values.max { a, b in
			a.createdAt < b.createdAt
		}
	}

	private func getSortedConversations() async -> [Conversation] {
		return conversationsByTopic.values.sorted { a, b in
			a.createdAt < b.createdAt
		}
	}

	public func getHmacKeys(request: Xmtp_KeystoreApi_V1_GetConversationHmacKeysRequest? = nil) -> Xmtp_KeystoreApi_V1_GetConversationHmacKeysResponse {
		let thirtyDayPeriodsSinceEpoch = Int(Date().timeIntervalSince1970) / (60 * 60 * 24 * 30)
		var hmacKeysResponse = Xmtp_KeystoreApi_V1_GetConversationHmacKeysResponse()
		var topics = conversationsByTopic
		if let requestTopics = request?.topics, !requestTopics.isEmpty {
			topics = topics.filter { requestTopics.contains($0.key) }
		}
		for (topic, conversation) in topics {
			guard let keyMaterial = conversation.keyMaterial else { continue }
			var hmacKeys = Xmtp_KeystoreApi_V1_GetConversationHmacKeysResponse.HmacKeys()
			for period in (thirtyDayPeriodsSinceEpoch - 1)...(thirtyDayPeriodsSinceEpoch + 1) {
				let info = "\(period)-\(client.address)"
				do {
					let hmacKey = try Crypto.deriveKey(secret: keyMaterial, nonce: Data(), info: Data(info.utf8))
					var hmacKeyData = Xmtp_KeystoreApi_V1_GetConversationHmacKeysResponse.HmacKeyData()
					hmacKeyData.hmacKey = hmacKey
					hmacKeyData.thirtyDayPeriodsSinceEpoch = Int32(period)
					hmacKeys.values.append(hmacKeyData)
				} catch {
					print("Error calculating HMAC key for topic \(topic): \(error)")
				}
			}
			hmacKeysResponse.hmacKeys[topic] = hmacKeys
		}
		return hmacKeysResponse
	}

	private func listIntroductionPeers(pagination: Pagination?) async throws -> [String: Date] {
		guard let apiClient = client.apiClient else {
			throw ClientError.noV2Client("Error no V2 client initialized")
		}
		let envelopes = try await apiClient.query(
			topic: .userIntro(client.address),
			pagination: pagination
		).envelopes
		let messages = envelopes.compactMap { envelope in
			do {
				let message = try MessageV1.fromBytes(envelope.message)
				// Attempt to decrypt, just to make sure we can
				_ = try message.decrypt(with: client.v1keys)
				return message
			} catch {
				return nil
			}
		}
		var seenPeers: [String: Date] = [:]
		for message in messages {
			guard let recipientAddress = message.recipientAddress,
				  let senderAddress = message.senderAddress else {
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
		guard let apiClient = client.apiClient else {
			throw ClientError.noV2Client("Error no V2 client initialized")
		}
		var envelopes = try await apiClient.envelopes(
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
