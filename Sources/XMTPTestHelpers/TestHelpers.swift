//
//  TestHelpers.swift
//
//
//  Created by Pat Nakajima on 12/6/22.
//

#if canImport(XCTest)
import Combine
import XCTest
@testable import XMTPiOS
import LibXMTP

public struct TestConfig {
    static let TEST_SERVER_ENABLED = _env("TEST_SERVER_ENABLED") == "true"
    // TODO: change Client constructor to accept these explicitly (so we can config CI):
    // static let TEST_SERVER_HOST = _env("TEST_SERVER_HOST") ?? "127.0.0.1"
    // static let TEST_SERVER_PORT = Int(_env("TEST_SERVER_PORT")) ?? 5556
    // static let TEST_SERVER_IS_SECURE = _env("TEST_SERVER_IS_SECURE") == "true"

    static private func _env(_ key: String) -> String? {
        ProcessInfo.processInfo.environment[key]
    }

    static public func skipIfNotRunningLocalNodeTests() throws {
        try XCTSkipIf(!TEST_SERVER_ENABLED, "requires local node")
    }

    static public func skip(because: String) throws {
        try XCTSkipIf(true, because)
    }
}

// Helper for tests gathering transcripts in a background task.
public actor TestTranscript {
    public var messages: [String] = []
    public init() {}
    public func add(_ message: String) {
        messages.append(message)
    }
}

public struct FakeWallet: SigningKey {
	public static func generate() throws -> FakeWallet {
		let key = try PrivateKey.generate()
		return FakeWallet(key)
	}

	public var address: String {
		key.walletAddress
	}

	public func sign(_ data: Data) async throws -> XMTPiOS.Signature {
		let signature = try await key.sign(data)
		return signature
	}

	public func sign(message: String) async throws -> XMTPiOS.Signature {
		let signature = try await key.sign(message: message)
		return signature
	}

	public var key: PrivateKey

	public init(_ key: PrivateKey) {
		self.key = key
	}
}

enum FakeApiClientError: String, Error {
	case noResponses, queryAssertionFailure
}

class FakeStreamHolder: ObservableObject {
	@Published var envelope: XMTPiOS.Envelope?

	func send(envelope: XMTPiOS.Envelope) {
		self.envelope = envelope
	}
}

@available(iOS 15, *)
public class FakeApiClient: ApiClient {
	public func subscribe(topics: [String]) -> AsyncThrowingStream<(envelope: XMTPiOS.Envelope, subscription: LibXMTP.FfiV2Subscription), Error> {
		AsyncThrowingStream { continuation in
			self.cancellable = stream.$envelope.sink(receiveValue: { env in
				if let env, topics.contains(env.contentTopic) {
					Task {
						let request = SubscribeRequest.with { $0.contentTopics = topics }
						try continuation.yield((env, await self.subscribe2(request: request)))
					}
				}
			})
		}
	}

	public func subscribe2(request: XMTPiOS.SubscribeRequest) async throws -> LibXMTP.FfiV2Subscription {
		return try await rustClient.subscribe(request: request.toFFI)
	}
	
	public func makeSubscribeRequest(topics: [String]) -> XMTPiOS.SubscribeRequest {
		return SubscribeRequest.with { $0.contentTopics = topics }
	}
	
	public func envelopes(topic: String, pagination: XMTPiOS.Pagination?) async throws -> [XMTPiOS.Envelope] {
		try await query(topic: topic, pagination: pagination).envelopes
	}

	public var environment: XMTPEnvironment
	public var authToken: String = ""
    public var appVersion: String
	public var rustClient: LibXMTP.FfiV2ApiClient
	private var responses: [String: [XMTPiOS.Envelope]] = [:]
	private var stream = FakeStreamHolder()
	public var published: [XMTPiOS.Envelope] = []
	var cancellable: AnyCancellable?
	var forbiddingQueries = false

	deinit {
		cancellable?.cancel()
	}

	public func assertNoPublish(callback: () async throws -> Void) async throws {
		let oldCount = published.count
		try await callback()
		// swiftlint:disable no_optional_try
		XCTAssertEqual(oldCount, published.count, "Published messages: \(String(describing: try? published[oldCount - 1 ..< published.count].map { try $0.jsonString() }))")
		// swiftlint:enable no_optional_try
	}

	public func assertNoQuery(callback: () async throws -> Void) async throws {
		forbiddingQueries = true
		try await callback()
		forbiddingQueries = false
	}

	public func register(message: [XMTPiOS.Envelope], for topic: Topic) {
		var responsesForTopic = responses[topic.description] ?? []
		responsesForTopic.append(contentsOf: message)
		responses[topic.description] = responsesForTopic
	}

	public init() async throws {
		environment = .local
        appVersion = "test/0.0.0"
		rustClient = try await LibXMTP.createV2Client(host: GRPCApiClient.envToUrl(env: .local), isSecure: false)
	}

	public func send(envelope: XMTPiOS.Envelope) {
		stream.send(envelope: envelope)
	}

	public func findPublishedEnvelope(_ topic: Topic) -> XMTPiOS.Envelope? {
		return findPublishedEnvelope(topic.description)
	}

	public func findPublishedEnvelope(_ topic: String) -> XMTPiOS.Envelope? {
		return published.reversed().first { $0.contentTopic == topic.description }
	}

	// MARK: ApiClient conformance

	public required init(environment: XMTPiOS.XMTPEnvironment, secure _: Bool, rustClient: LibXMTP.FfiV2ApiClient, appVersion: String?) throws {
		self.environment = environment
        self.appVersion = appVersion ?? "0.0.0"
		self.rustClient = rustClient
	}

	public func subscribe(topics: [String]) -> AsyncThrowingStream<XMTPiOS.Envelope, Error> {
		AsyncThrowingStream { continuation in
			self.cancellable = stream.$envelope.sink(receiveValue: { env in
				if let env, topics.contains(env.contentTopic) {
					continuation.yield(env)
				}
			})
		}
	}

	public func setAuthToken(_ token: String) {
		authToken = token
	}

	public func query(topic: String, pagination: Pagination? = nil, cursor _: Xmtp_MessageApi_V1_Cursor? = nil) async throws -> XMTPiOS.QueryResponse {
		if forbiddingQueries {
			XCTFail("Attempted to query \(topic)")
			throw FakeApiClientError.queryAssertionFailure
		}

		var result: [XMTPiOS.Envelope] = []

		if let response = responses.removeValue(forKey: topic) {
			result.append(contentsOf: response)
		}

		result.append(contentsOf: published.filter { $0.contentTopic == topic }.reversed())

		if let startAt = pagination?.after {
			result = result
				.filter { $0.timestampNs > UInt64(startAt.millisecondsSinceEpoch * 1_000_000) }
		}

		if let endAt = pagination?.before {
			result = result
				.filter { $0.timestampNs < UInt64(endAt.millisecondsSinceEpoch * 1_000_000) }
		}

		if let limit = pagination?.limit {
			if limit == 1 {
				if let first = result.first {
					result = [first]
				} else {
					result = []
				}
			} else {
				let maxBound = min(result.count, limit) - 1

				if maxBound <= 0 {
					result = []
				} else {
					result = Array(result[0 ... maxBound])
				}
			}
		}

        if let direction = pagination?.direction {
            switch direction {
            case .ascending:
                result = Array(result.reversed())
            default:
                break
            }
        }

		var queryResponse = QueryResponse()
		queryResponse.envelopes = result

		return queryResponse
	}

	public func query(topic: XMTPiOS.Topic, pagination: Pagination? = nil) async throws -> XMTPiOS.QueryResponse {
		return try await query(topic: topic.description, pagination: pagination, cursor: nil)
	}

	public func publish(envelopes: [XMTPiOS.Envelope]) async throws {
		for envelope in envelopes {
			send(envelope: envelope)
		}

		published.append(contentsOf: envelopes)
	}

	public func batchQuery(request: XMTPiOS.BatchQueryRequest) async throws -> XMTPiOS.BatchQueryResponse {
        let responses = try await withThrowingTaskGroup(of: QueryResponse.self) { group in
            for r in request.requests {
                group.addTask {
                    try await self.query(topic: r.contentTopics[0], pagination: Pagination(after: Date(timeIntervalSince1970: Double(r.startTimeNs / 1_000_000) / 1000)))
                }
            }

          var results: [QueryResponse] = []
          for try await response in group {
            results.append(response)
          }

          return results
        }

		var queryResponse = XMTPiOS.BatchQueryResponse()
        queryResponse.responses = responses
        return queryResponse
    }

	public func query(request: XMTPiOS.QueryRequest) async throws -> XMTPiOS.QueryResponse {
        abort() // Not supported on Fake
    }

	public func publish(request: XMTPiOS.PublishRequest) async throws {
        abort() // Not supported on Fake
    }
}

@available(iOS 15, *)
public struct Fixtures {
	public var fakeApiClient: FakeApiClient!

	public var alice: PrivateKey!
	public var aliceClient: Client!

	public var bob: PrivateKey!
	public var bobClient: Client!

	init() async throws {
		alice = try PrivateKey.generate()
		bob = try PrivateKey.generate()

		fakeApiClient = try await FakeApiClient()

		aliceClient = try await Client.create(account: alice, apiClient: fakeApiClient)
		bobClient = try await Client.create(account: bob, apiClient: fakeApiClient)
	}

	public func publishLegacyContact(client: Client) async throws {
		var contactBundle = ContactBundle()
		contactBundle.v1.keyBundle = client.privateKeyBundleV1.toPublicKeyBundle()

		var envelope = Envelope()
		envelope.contentTopic = Topic.contact(client.address).description
		envelope.timestampNs = UInt64(Date().millisecondsSinceEpoch * 1_000_000)
		envelope.message = try contactBundle.serializedData()

		try await client.publish(envelopes: [envelope])
	}
}

public extension XCTestCase {
	@available(iOS 15, *)
	func fixtures() async -> Fixtures {
		// swiftlint:disable force_try
		return try! await Fixtures()
		// swiftlint:enable force_try
	}
}
#endif
