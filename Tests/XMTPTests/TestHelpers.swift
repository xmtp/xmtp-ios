//
//  TestHelpers.swift
//
//
//  Created by Pat Nakajima on 12/6/22.
//

@testable import XMTP

enum FakeApiClientError: String, Error {
	case noResponses
}

class FakeApiClient: ApiClient {
	var environment: Environment
	var authToken: String = ""
	private var responses: [String: [Envelope]] = [:]
	private var published: [Envelope] = []

	func register(message: [Envelope], for topic: Topic) {
		var responsesForTopic = responses[topic.description] ?? []
		responsesForTopic.append(contentsOf: message)
		responses[topic.description] = responsesForTopic
	}

	init() {
		environment = .local
	}

	// MARK: ApiClient conformance

	required init(environment: XMTP.Environment, secure _: Bool) throws {
		self.environment = environment
	}

	func setAuthToken(_ token: String) {
		authToken = token
	}

	func query(topics: [String]) async throws -> XMTP.QueryResponse {
		var result: [Envelope] = []

		for topic in topics {
			if let response = responses.removeValue(forKey: topic) {
				result.append(contentsOf: response)
			}
		}

		var queryResponse = QueryResponse()
		queryResponse.envelopes = result

		return queryResponse
	}

	func query(topics: [XMTP.Topic]) async throws -> XMTP.QueryResponse {
		return try await query(topics: topics.map(\.description))
	}

	func publish(envelopes: [XMTP.Envelope]) async throws -> XMTP.PublishResponse {
		published.append(contentsOf: envelopes)

		return PublishResponse()
	}
}
