//
//  Group.swift
//
//
//  Created by Pat Nakajima on 2/1/24.
//

import Foundation
import LibXMTP

public struct Group: Identifiable, Equatable, Hashable {
	var ffiGroup: FfiGroup
	var client: Client

	public struct Member {
		var ffiGroupMember: FfiGroupMember

		public var accountAddress: String {
			ffiGroupMember.accountAddress
		}
	}

	public var id: Data {
		ffiGroup.id()
	}

	public static func == (lhs: Group, rhs: Group) -> Bool {
		lhs.id == rhs.id
	}

	public func hash(into hasher: inout Hasher) {
		id.hash(into: &hasher)
	}

	public func members() async throws -> [Member] {
		_ = try await ffiGroup.sync()
		return try ffiGroup.listMembers().map(\.fromFFI)
	}

	public var cachedMembers: [Member] {
		do {
			return try ffiGroup.listMembers().map(\.fromFFI)
		} catch {
			return []
		}
	}

	public func addMembers(addresses: [String]) async throws {
		try await ffiGroup.addMembers(accountAddresses: addresses)
		try await ffiGroup.sync()
	}

	public func removeMembers(addresses: [String]) async throws {
		try await ffiGroup.removeMembers(accountAddresses: addresses)
		try await ffiGroup.sync()
	}

	public func send<T>(content: T, options: SendOptions? = nil) async throws {
		func encode<Codec: ContentCodec>(codec: Codec, content: Any) throws -> EncodedContent {
			if let content = content as? Codec.T {
				return try codec.encode(content: content, client: client)
			} else {
				throw CodecError.invalidContent
			}
		}

		let codec = client.codecRegistry.find(for: options?.contentType)
		var encoded = try encode(codec: codec, content: content)

		func fallback<Codec: ContentCodec>(codec: Codec, content: Any) throws -> String? {
			if let content = content as? Codec.T {
				return try codec.fallback(content: content)
			} else {
				throw CodecError.invalidContent
			}
		}

		if let fallback = try fallback(codec: codec, content: content) {
			encoded.fallback = fallback
		}

		if let compression = options?.compression {
			encoded = try encoded.compress(compression)
		}

		try await ffiGroup.send(contentBytes: encoded.serializedData())
	}

	public func messages(before: Date? = nil, after: Date? = nil, limit: Int? = nil) async throws -> [DecodedMessage] {
		try await ffiGroup.sync()

		var options = FfiListMessagesOptions(sentBeforeNs: nil, sentAfterNs: nil, limit: nil)

		if let before {
			options.sentBeforeNs = Int64(before.millisecondsSinceEpoch)
		}

		if let after {
			options.sentAfterNs = Int64(after.millisecondsSinceEpoch)
		}

		if let limit {
			options.limit = Int64(limit)
		}

		let messages = try ffiGroup.findMessages(opts: options)

		return try messages.map { ffiMessage in
			let encodedContent = try EncodedContent(serializedData: ffiMessage.content)

			return DecodedMessage(
				client: client,
				topic: "",
				encodedContent: encodedContent,
				senderAddress: ffiMessage.addrFrom,
				sent: Date(timeIntervalSince1970: TimeInterval(ffiMessage.sentAtNs / 1_000_000_000))
			)
		}
	}
}
