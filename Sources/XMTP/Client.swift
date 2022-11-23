//
//  Client.swift
//
//
//  Created by Pat Nakajima on 11/22/22.
//

import Foundation

struct ClientOptions {
	struct Api {
		var env: Environment = .production
		var isSecure: Bool = true
	}

	var api = Api()
}

class Client {
	var address: String
	var privateKeyBundleV1: PrivateKeyBundleV1
	var apiClient: ApiClient

	public static func create(wallet: SigningKey, options: ClientOptions = ClientOptions()) async throws -> Client {
		let apiClient = try ApiClient(
			environment: options.api.env,
			secure: options.api.isSecure
		)

		// TODO: Load existing bundle
		let privateKeyBundleV1 = try await PrivateKeyBundleV1.generate(wallet: wallet)

		return try Client(address: wallet.address, privateKeyBundleV1: privateKeyBundleV1, apiClient: apiClient)
	}

	init(address: String, privateKeyBundleV1: PrivateKeyBundleV1, apiClient: ApiClient) throws {
		self.address = address
		self.privateKeyBundleV1 = privateKeyBundleV1
		self.apiClient = apiClient
	}

	func publishUserContact() async throws {
		var keyBundle = privateKeyBundleV1.toPublicKeyBundle()
		var contactBundle = ContactBundle()
		contactBundle.v1.keyBundle = keyBundle

		var envelope = Envelope()
		envelope.contentTopic = Topic.contact(address).description
		envelope.timestampNs = UInt64(Date().millisecondsSinceEpoch * 1_000_000)
		envelope.message = try contactBundle.serializedData()

		_ = try await publish(envelopes: [envelope])
	}

	func publish(envelopes: [Envelope]) async throws -> PublishResponse {
		let authorized = AuthorizedIdentity(address: address, authorized: privateKeyBundleV1.identityKey.publicKey, identity: privateKeyBundleV1.identityKey)
		let authToken = try await authorized.createAuthToken()

		apiClient.setAuthToken(authToken)

		return try await apiClient.publish(envelopes: envelopes)
	}

	func getUserContact(peerAddress: String) async throws -> ContactBundle? {
		let response = try await apiClient.query(topics: [.contact(peerAddress)])

		for envelope in response.envelopes {
			if let contactBundle = try extractContactBundle(message: envelope.message) {
				return contactBundle
			}
		}

		return nil
	}

	private func extractContactBundle(message: Data) throws -> ContactBundle? {
		let contactBundle = try? ContactBundle(serializedData: message)

		return contactBundle
	}
}
