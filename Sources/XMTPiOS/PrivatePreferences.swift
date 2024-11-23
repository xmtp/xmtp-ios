import Foundation
import LibXMTP

public enum ConsentState: String, Codable {
	case allowed, denied, unknown
}
public enum EntryType: String, Codable {
	case address, conversation_id, inbox_id
}

public struct ConsentListEntry: Codable, Hashable {
	public init(value: String, entryType: EntryType, consentType: ConsentState)
	{
		self.value = value
		self.entryType = entryType
		self.consentType = consentType
	}

	static func address(_ address: String, type: ConsentState = .unknown)
		-> ConsentListEntry
	{
		ConsentListEntry(value: address, entryType: .address, consentType: type)
	}

	static func conversationId(
		conversationId: String, type: ConsentState = ConsentState.unknown
	) -> ConsentListEntry {
		ConsentListEntry(
			value: conversationId, entryType: .conversation_id,
			consentType: type)
	}

	static func inboxId(_ inboxId: String, type: ConsentState = .unknown)
		-> ConsentListEntry
	{
		ConsentListEntry(
			value: inboxId, entryType: .inbox_id, consentType: type)
	}

	public var value: String
	public var entryType: EntryType
	public var consentType: ConsentState

	var key: String {
		"\(entryType)-\(value)"
	}
}

/// Provides access to contact bundles.
public actor PrivatePreferences {
	var client: Client
	var ffiClient: FfiXmtpClient

	init(client: Client, ffiClient: FfiXmtpClient) {
		self.client = client
		self.ffiClient = ffiClient
	}

	public func setConsentState(entries: [ConsentListEntry]) async throws {
		try await ffiClient.setConsentStates(records: entries.map(\.toFFI))
	}

	public func addressState(address: String) async throws -> ConsentState {
		return try await ffiClient.getConsentState(
			entityType: .address,
			entity: address
		).fromFFI
	}

	public func conversationState(conversationId: String) async throws
		-> ConsentState
	{
		return try await ffiClient.getConsentState(
			entityType: .conversationId,
			entity: conversationId
		).fromFFI
	}

	public func inboxIdState(inboxId: String) async throws -> ConsentState {
		return try await ffiClient.getConsentState(
			entityType: .inboxId,
			entity: inboxId
		).fromFFI
	}

	public func syncConsent() async throws {
		try await ffiClient.sendSyncRequest(kind: .consent)
	}

	public func streamConsent()
		-> AsyncThrowingStream<ConsentListEntry, Error>
	{
		AsyncThrowingStream { continuation in
			let ffiStreamActor = FfiStreamActor()

			let consentCallback = ConsentCallback(client: self.client) {
				consent in
				guard !Task.isCancelled else {
					continuation.finish()
					Task {
						await ffiStreamActor.endStream()
					}
					return
				}
				continuation.yield(consent)
			}

			let task = Task {
				let stream = await ffiClient.conversations().streamConsent(
					callback: consentCallback)
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
}

final class ConsentCallback: FfiConsentCallback {
	let client: Client
	let callback: (ConsentListEntry) -> Void

	init(client: Client, _ callback: @escaping (ConsentListEntry) -> Void) {
		self.client = client
		self.callback = callback
	}

	func onConsentUpdate(consent: [LibXMTP.FfiConsent]) {
		for record in consent {
			callback(record.fromFfi)
		}
	}

	func onError(error: LibXMTP.FfiSubscribeError) {
		print("Error ConsentCallback \(error)")
	}
}
