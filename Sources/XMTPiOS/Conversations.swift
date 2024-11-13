import Foundation
import LibXMTP

public enum ConversationError: Error, CustomStringConvertible, LocalizedError {
	case memberCannotBeSelf
	case memberNotRegistered([String])
	case groupsRequireMessagePassed, notSupportedByGroups, streamingFailure

	public var description: String {
		switch self {
		case .memberCannotBeSelf:
			return
				"GroupError.memberCannotBeSelf you cannot add yourself to a group"
		case .memberNotRegistered(let array):
			return
				"GroupError.memberNotRegistered members not registered: \(array.joined(separator: ", "))"
		case .groupsRequireMessagePassed:
			return
				"GroupError.groupsRequireMessagePassed you cannot call this method without passing a message instead of an envelope"
		case .notSupportedByGroups:
			return
				"GroupError.notSupportedByGroups this method is not supported by groups"
		case .streamingFailure:
			return "GroupError.streamingFailure a stream has failed"
		}
	}

	public var errorDescription: String? {
		return description
	}
}

public enum ConversationOrder {
	case createdAt, lastMessage
}

public enum ConversationType {
	case all, groups, dms
}

final class ConversationStreamCallback: FfiConversationCallback {
	func onError(error: LibXMTP.FfiSubscribeError) {
		print("Error ConversationStreamCallback \(error)")
	}

	let callback: (FfiConversation) -> Void

	init(callback: @escaping (FfiConversation) -> Void) {
		self.callback = callback
	}

	func onConversation(conversation: FfiConversation) {
		self.callback(conversation)
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
	var ffiConversations: FfiConversations

	init(client: Client, ffiConversations: FfiConversations) {
		self.client = client
		self.ffiConversations = ffiConversations
	}

	public func sync() async throws {
		try await ffiConversations.sync()
	}
	public func syncAllConversations() async throws -> UInt32 {
		return try await ffiConversations.syncAllConversations()
	}

	public func listGroups(
		createdAfter: Date? = nil, createdBefore: Date? = nil,
		limit: Int? = nil, order: ConversationOrder = .createdAt,
		consentState: ConsentState? = nil
	) async throws -> [Group] {
		var options = FfiListConversationsOptions(
			createdAfterNs: nil, createdBeforeNs: nil, limit: nil,
			consentState: consentState?.toFFI)
		if let createdAfter {
			options.createdAfterNs = Int64(createdAfter.millisecondsSinceEpoch)
		}
		if let createdBefore {
			options.createdBeforeNs = Int64(
				createdBefore.millisecondsSinceEpoch)
		}
		if let limit {
			options.limit = Int64(limit)
		}
		let conversations = try await ffiConversations.listGroups(
			opts: options)

		let sortedConversations = try sortConversations(
			conversations, order: order)

		return sortedConversations.map {
			$0.groupFromFFI(client: client)
		}
	}

	public func listDms(
		createdAfter: Date? = nil, createdBefore: Date? = nil,
		limit: Int? = nil, order: ConversationOrder = .createdAt,
		consentState: ConsentState? = nil
	) async throws -> [Dm] {
		var options = FfiListConversationsOptions(
			createdAfterNs: nil, createdBeforeNs: nil, limit: nil,
			consentState: consentState?.toFFI)
		if let createdAfter {
			options.createdAfterNs = Int64(createdAfter.millisecondsSinceEpoch)
		}
		if let createdBefore {
			options.createdBeforeNs = Int64(
				createdBefore.millisecondsSinceEpoch)
		}
		if let limit {
			options.limit = Int64(limit)
		}
		let conversations = try await ffiConversations.listDms(
			opts: options)

		let sortedConversations = try sortConversations(
			conversations, order: order)

		return sortedConversations.map {
			$0.dmFromFFI(client: client)
		}
	}

	public func list(
		createdAfter: Date? = nil, createdBefore: Date? = nil,
		limit: Int? = nil, order: ConversationOrder = .createdAt,
		consentState: ConsentState? = nil
	) async throws -> [Conversation] {
		var options = FfiListConversationsOptions(
			createdAfterNs: nil, createdBeforeNs: nil, limit: nil,
			consentState: consentState?.toFFI)
		if let createdAfter {
			options.createdAfterNs = Int64(createdAfter.millisecondsSinceEpoch)
		}
		if let createdBefore {
			options.createdBeforeNs = Int64(
				createdBefore.millisecondsSinceEpoch)
		}
		if let limit {
			options.limit = Int64(limit)
		}
		let conversations = try await ffiConversations.list(
			opts: options)

		let sortedConversations = try sortConversations(
			conversations, order: order)

		return try sortedConversations.map {
			try $0.toConversation(client: client)
		}
	}

	private func sortConversations(
		_ conversations: [FfiConversation],
		order: ConversationOrder
	) throws -> [FfiConversation] {
		switch order {
		case .lastMessage:
			let conversationWithTimestamp: [(FfiConversation, Int64?)] =
				try conversations.map { conversation in
					let message = try conversation.findMessages(
						opts: FfiListMessagesOptions(
							sentBeforeNs: nil,
							sentAfterNs: nil,
							limit: 1,
							deliveryStatus: nil,
							direction: .descending
						)
					).first
					return (conversation, message?.sentAtNs)
				}

			let sortedTuples = conversationWithTimestamp.sorted { (lhs, rhs) in
				(lhs.1 ?? 0) > (rhs.1 ?? 0)
			}
			return sortedTuples.map { $0.0 }
		case .createdAt:
			return conversations
		}
	}

	public func stream(type: ConversationType = .all) -> AsyncThrowingStream<
		Conversation, Error
	> {
		AsyncThrowingStream { continuation in
			let ffiStreamActor = FfiStreamActor()
			let conversationCallback = ConversationStreamCallback {
				conversation in
				guard !Task.isCancelled else {
					continuation.finish()
					return
				}
				do {
					let conversationType = try conversation.groupMetadata()
						.conversationType()
					if conversationType == "dm" {
						continuation.yield(
							Conversation.dm(
								conversation.dmFromFFI(client: self.client))
						)
					} else if conversationType == "group" {
						continuation.yield(
							Conversation.group(
								conversation.groupFromFFI(client: self.client))
						)
					}
				} catch {
					// Do nothing if the conversation type is neither a group or dm
				}
			}

			let task = Task {
				let stream: FfiStreamCloser
					switch type {
					case .groups:
						stream = await ffiConversations.streamGroups(
							callback: conversationCallback)
					case .all:
						stream = await ffiConversations.stream(
							callback: conversationCallback)
					case .dms:
						stream = await ffiConversations.streamDms(
							callback: conversationCallback)
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

	public func findOrCreateDm(with peerAddress: String) async throws -> Dm {
		if peerAddress.lowercased() == client.address.lowercased() {
			throw ConversationError.memberCannotBeSelf
		}
		let canMessage = try await self.client.canMessage(
			address: peerAddress)
		if !canMessage {
			throw ConversationError.memberNotRegistered([peerAddress])
		}
		if let existingDm = try await client.findDmByAddress(address: peerAddress) {
			return existingDm
		}

		let newDm =
			try await ffiConversations
			.createDm(accountAddress: peerAddress.lowercased())
			.dmFromFFI(client: client)
		return newDm
	}

	public func newGroup(
		with addresses: [String],
		permissions: GroupPermissionPreconfiguration = .allMembers,
		name: String = "",
		imageUrlSquare: String = "",
		description: String = "",
		pinnedFrameUrl: String = ""
	) async throws -> Group {
		return try await newGroupInternal(
			with: addresses,
			permissions:
				GroupPermissionPreconfiguration.toFfiGroupPermissionOptions(
					option: permissions),
			name: name,
			imageUrlSquare: imageUrlSquare,
			description: description,
			pinnedFrameUrl: pinnedFrameUrl,
			permissionPolicySet: nil
		)
	}

	public func newGroupCustomPermissions(
		with addresses: [String],
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
			permissionPolicySet: PermissionPolicySet.toFfiPermissionPolicySet(
				permissionPolicySet)
		)
	}

	private func newGroupInternal(
		with addresses: [String],
		permissions: FfiGroupPermissionsOptions = .allMembers,
		name: String = "",
		imageUrlSquare: String = "",
		description: String = "",
		pinnedFrameUrl: String = "",
		permissionPolicySet: FfiPermissionPolicySet? = nil
	) async throws -> Group {
		if addresses.first(where: {
			$0.lowercased() == client.address.lowercased()
		}) != nil {
			throw ConversationError.memberCannotBeSelf
		}
		let addressMap = try await self.client.canMessage(addresses: addresses)
		let unregisteredAddresses =
			addressMap
			.filter { !$0.value }
			.map { $0.key }

		if !unregisteredAddresses.isEmpty {
			throw ConversationError.memberNotRegistered(unregisteredAddresses)
		}

		let group = try await ffiConversations.createGroup(
			accountAddresses: addresses,
			opts: FfiCreateGroupOptions(
				permissions: permissions,
				groupName: name,
				groupImageUrlSquare: imageUrlSquare,
				groupDescription: description,
				groupPinnedFrameUrl: pinnedFrameUrl,
				customPermissionPolicySet: permissionPolicySet
			)
		).groupFromFFI(client: client)
		return group
	}

	public func streamAllMessages(type: ConversationType = .all)
		-> AsyncThrowingStream<DecodedMessage, Error>
	{
		AsyncThrowingStream { continuation in
			let ffiStreamActor = FfiStreamActor()

			let messageCallback = MessageCallback(client: self.client) {
				message in
				guard !Task.isCancelled else {
					continuation.finish()
					Task {
						await ffiStreamActor.endStream()
					}
					return
				}
				do {
					continuation.yield(
						try Message(client: self.client, ffiMessage: message)
							.decode()
					)
				} catch {
					print("Error onMessage \(error)")
				}
			}

			let task = Task {
				let stream: FfiStreamCloser
					switch type {
					case .groups:
						stream = await ffiConversations.streamAllGroupMessages(
							messageCallback: messageCallback
						)
					case .dms:
						stream = await ffiConversations.streamAllDmMessages(
							messageCallback: messageCallback
						)
					case .all:
						stream = await ffiConversations.streamAllMessages(
							messageCallback: messageCallback
						)
					}
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

	public func fromWelcome(envelopeBytes: Data) async throws
		-> Conversation?
	{
		let conversation =
			try await ffiConversations
			.processStreamedWelcomeMessage(envelopeBytes: envelopeBytes)
		return try conversation.toConversation(client: client)
	}

	public func newConversation(
		with peerAddress: String
	) async throws -> Conversation {
		let dm = try await findOrCreateDm(with: peerAddress)
		return Conversation.dm(dm)
	}
}
