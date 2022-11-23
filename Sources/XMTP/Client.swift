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

struct Client {
	var privateKeyBundleV1: PrivateKeyBundleV1
	var apiClient: ApiClient

	public static func create(wallet: SigningKey, options: ClientOptions = ClientOptions()) async throws -> Client {
		let apiClient = try ApiClient(
			environment: options.api.env,
			secure: options.api.isSecure
		)

		// TODO: Load existing bundle
		let privateKeyBundleV1 = try await PrivateKeyBundleV1.generate(wallet: wallet)

		return try Client(privateKeyBundleV1: privateKeyBundleV1, apiClient: apiClient)
	}

	init(privateKeyBundleV1: PrivateKeyBundleV1, apiClient: ApiClient) throws {
		self.privateKeyBundleV1 = privateKeyBundleV1
		self.apiClient = apiClient
	}
}
