//
//  Client.swift
//
//
//  Created by Pat Nakajima on 11/22/22.
//

import Foundation
import GRPC
import XMTPProto

public struct ClientOptions {
	public struct Api {
		public var env: XMTPEnvironment = .dev
		public var isSecure: Bool = true

		public init(env: XMTPEnvironment = .dev, isSecure: Bool = true) {
			self.env = env
			self.isSecure = isSecure
		}
	}

	public var api = Api()

	public init(api: Api = Api()) {
		self.api = api
	}
}

public class Client {
	public var address: String
	var privateKeyBundleV1: PrivateKeyBundleV1
	var apiClient: ApiClient

	public lazy var conversations: Conversations = .init(client: self)
	public lazy var contacts: Contacts = .init(client: self)

	public var environment: XMTPEnvironment {
		apiClient.environment
	}

	public static func create(account: SigningKey, options: ClientOptions? = nil) async throws -> Client {
		let options = options ?? ClientOptions()

		let apiClient = try GRPCApiClient(
			environment: options.api.env,
			secure: options.api.isSecure
		)

		return try await create(account: account, apiClient: apiClient)
	}

	static func create(account: SigningKey, apiClient: ApiClient) async throws -> Client {
		let privateKeyBundleV1 = try await loadOrCreateKeys(for: account, apiClient: apiClient)

		let client = try Client(address: account.address, privateKeyBundleV1: privateKeyBundleV1, apiClient: apiClient)
		try await client.ensureUserContactPublished()

		return client
	}

	static func loadOrCreateKeys(for account: SigningKey, apiClient: ApiClient) async throws -> PrivateKeyBundleV1 {
		// swiftlint:disable no_optional_try
		if let keys = try? await loadPrivateKeys(for: account, apiClient: apiClient) {
			// swiftlint:enable no_optional_try
			return keys
		} else {
			let keys = try await PrivateKeyBundleV1.generate(wallet: account)
			let keyBundle = PrivateKeyBundle(v1: keys)
			let encryptedKeys = try await keyBundle.encrypted(with: account)

			var authorizedIdentity = AuthorizedIdentity(privateKeyBundleV1: keys)
			authorizedIdentity.address = account.address
			let authToken = try await authorizedIdentity.createAuthToken()

			let apiClient = apiClient
			apiClient.setAuthToken(authToken)

			try await apiClient.publish(envelopes: [
				Envelope(topic: .userPrivateStoreKeyBundle(account.address), timestamp: Date(), message: try encryptedKeys.serializedData()),
			])

			return keys
		}
	}

	static func loadPrivateKeys(for account: SigningKey, apiClient: ApiClient) async throws -> PrivateKeyBundleV1? {
		let topics: [Topic] = [.userPrivateStoreKeyBundle(account.address)]
		let res = try await apiClient.query(topics: topics)

		for envelope in res.envelopes {
			do {
				let encryptedBundle = try EncryptedPrivateKeyBundle(serializedData: envelope.message)
				let bundle = try await encryptedBundle.decrypted(with: account)

				return bundle.v1
			} catch {
				print("Error decoding encrypted private key bundle: \(error)")
				continue
			}
		}

		return nil
	}

	init(address: String, privateKeyBundleV1: PrivateKeyBundleV1, apiClient: ApiClient) throws {
		self.address = address
		self.privateKeyBundleV1 = privateKeyBundleV1
		self.apiClient = apiClient
	}

	var keys: PrivateKeyBundleV2 {
		do {
			return try privateKeyBundleV1.toV2()
		} catch {
			fatalError("Error getting keys \(error)")
		}
	}

	func ensureUserContactPublished() async throws {
		if let contact = try await getUserContact(peerAddress: address),
		   case .v2 = contact.version,
		   keys.getPublicKeyBundle().equals(contact.v2.keyBundle)
		{
			return
		}

		try await publishUserContact(legacy: true)
	}

	func publishUserContact(legacy: Bool = false) async throws {
		var envelopes: [Envelope] = []

		if legacy {
			var contactBundle = ContactBundle()
			contactBundle.v1.keyBundle = privateKeyBundleV1.toPublicKeyBundle()

			var envelope = Envelope()
			envelope.contentTopic = Topic.contact(address).description
			envelope.timestampNs = UInt64(Date().millisecondsSinceEpoch * 1_000_000)
			envelope.message = try contactBundle.serializedData()

			envelopes.append(envelope)
		}

		var contactBundle = ContactBundle()
		contactBundle.v2.keyBundle = keys.getPublicKeyBundle()
		contactBundle.v2.keyBundle.identityKey.signature.ensureWalletSignature()
		contactBundle.v2.keyBundle.preKey.signature.ensureWalletSignature()

		var envelope = Envelope()
		envelope.contentTopic = Topic.contact(address).description
		envelope.timestampNs = UInt64(Date().millisecondsSinceEpoch * 1_000_000)
		envelope.message = try contactBundle.serializedData()
		envelopes.append(envelope)

		_ = try await publish(envelopes: envelopes)
	}

	func query(topics: [Topic]) async throws -> QueryResponse {
		return try await apiClient.query(topics: topics)
	}

	@discardableResult func publish(envelopes: [Envelope]) async throws -> PublishResponse {
		var authorized = AuthorizedIdentity(address: address, authorized: privateKeyBundleV1.identityKey.publicKey, identity: privateKeyBundleV1.identityKey)
		let authToken = try await authorized.createAuthToken()

		apiClient.setAuthToken(authToken)

		return try await apiClient.publish(envelopes: envelopes)
	}

	func subscribe(topics: [String]) -> AsyncThrowingStream<Envelope, Error> {
		return apiClient.subscribe(topics: topics)
	}

	func subscribe(topics: [Topic]) -> AsyncThrowingStream<Envelope, Error> {
		return subscribe(topics: topics.map(\.description))
	}

	func getUserContact(peerAddress: String) async throws -> ContactBundle? {
		return try await contacts.find(peerAddress)
	}
}

public extension Client {
	static var preview: Client {
		get async {
			// swiftlint:disable force_try
			let wallet = try! PrivateKey.generate()
			let client = try! await Client.create(account: wallet)
			// swiftlint:enable force_try
			return client
		}
	}
}
