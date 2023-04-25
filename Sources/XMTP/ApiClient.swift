//
//  ApiClient.swift
//
//
//  Created by Pat Nakajima on 11/17/22.
//

import Foundation
import XMTPRust

typealias PublishResponse = Xmtp_MessageApi_V1_PublishResponse
typealias QueryResponse = Xmtp_MessageApi_V1_QueryResponse
typealias SubscribeRequest = Xmtp_MessageApi_V1_SubscribeRequest

protocol ApiClient {
	var environment: XMTPEnvironment { get }
	init(environment: XMTPEnvironment, secure: Bool, rustClient: XMTPRust.RustClient) throws
	func setAuthToken(_ token: String)
	func query(topic: String, pagination: Pagination?, cursor: Xmtp_MessageApi_V1_Cursor?) async throws -> QueryResponse
	func query(topic: Topic, pagination: Pagination?) async throws -> QueryResponse
	func envelopes(topic: String, pagination: Pagination?) async throws -> [Envelope]
	func publish(envelopes: [Envelope]) async throws -> PublishResponse
	func subscribe(topics: [String]) -> AsyncThrowingStream<Envelope, Error>
}

extension Data {
	func dataToRustVec() -> RustVec<UInt8> {
		let rustVec = RustVec<UInt8>()
		for byte in self {
			rustVec.push(value: byte)
		}
		return rustVec
	}

	func dataFromRustVec(rustVec: RustVec<UInt8>) -> Data {
		var listBytes: [UInt8] = []
		for byte in rustVec {
			listBytes.append(byte)
		}
		return Data(listBytes)
	}
}

class GRPCApiClient: ApiClient {
	let ClientVersionHeaderKey = "X-Client-Version"
	let AppVersionHeaderKey = "X-App-Version"

	var environment: XMTPEnvironment
	var authToken = ""

	var rustClient: XMTPRust.RustClient

	required init(environment: XMTPEnvironment, secure _: Bool = true, rustClient: XMTPRust.RustClient) throws {
		self.environment = environment
		// TODO: this is a hack to do an async thing in a synchronous way
		self.rustClient = rustClient
	}

	func dataToRustVec(data: Data) -> RustVec<UInt8> {
		let rustVec = RustVec<UInt8>()
		for byte in data {
			rustVec.push(value: byte)
		}
		return rustVec
	}

	func dataFromRustVec(rustVec: RustVec<UInt8>) -> Data {
		var listBytes: [UInt8] = []
		for byte in rustVec {
			listBytes.append(byte)
		}
		return Data(listBytes)
	}

	static func envToUrl(env: XMTPEnvironment) -> String {
		switch env {
		case XMTPEnvironment.local: return "http://localhost:5556"
		case XMTPEnvironment.dev: return "https://dev.xmtp.network:5556"
		case XMTPEnvironment.production: return "https://xmtp.network:5556"
		}
	}

	func setAuthToken(_ token: String) {
		authToken = token
	}

	func query(topic: String, pagination: Pagination? = nil, cursor: Xmtp_MessageApi_V1_Cursor? = nil) async throws -> QueryResponse {
		var request = Xmtp_MessageApi_V1_QueryRequest()
		request.contentTopics = [topic]

		if let pagination {
			request.pagingInfo = pagination.pagingInfo
		}

		if let startAt = pagination?.startTime {
			request.endTimeNs = UInt64(startAt.millisecondsSinceEpoch) * 1_000_000
			request.pagingInfo.direction = .descending
		}

		if let endAt = pagination?.endTime {
			request.startTimeNs = UInt64(endAt.millisecondsSinceEpoch) * 1_000_000
			request.pagingInfo.direction = .descending
		}

		if let cursor {
			request.pagingInfo.cursor = cursor
		}

		let paging = XMTPRust.PagingInfo(limit: 0, cursor: nil, direction: XMTPRust.SortDirection.Ascending)
		let response = try await rustClient.query(topic.intoRustString(), Optional.none, Optional.none, Optional.none)
		// response has .envelopes() and .paging_info() but the envelopes need to be mapped into Envelope objects that Swift understands
		var queryResponse = QueryResponse()
		// Build the query response from response fields
		queryResponse.envelopes = response.envelopes().map { rustEnvelope in
			var envelope = Envelope()
			envelope.contentTopic = rustEnvelope.get_topic().toString()
			envelope.timestampNs = rustEnvelope.get_sender_time_ns()
			envelope.message = dataFromRustVec(rustVec: rustEnvelope.get_payload())
			return envelope
		}
		// Decode the response as a QueryResponse
		return queryResponse
	}

	func envelopes(topic: String, pagination: Pagination? = nil) async throws -> [Envelope] {
		var envelopes: [Envelope] = []
		var hasNextPage = true
		var cursor: Xmtp_MessageApi_V1_Cursor?

		while hasNextPage {
			let response = try await query(topic: topic, pagination: pagination, cursor: cursor)

			envelopes.append(contentsOf: response.envelopes)

			cursor = response.pagingInfo.cursor
			hasNextPage = !response.envelopes.isEmpty && response.pagingInfo.hasCursor
		}

		return envelopes
	}

	func query(topic: Topic, pagination: Pagination? = nil) async throws -> Xmtp_MessageApi_V1_QueryResponse {
		return try await query(topic: topic.description, pagination: pagination)
	}

	func subscribe(topics: [String]) -> AsyncThrowingStream<Envelope, Error> {
		return AsyncThrowingStream { continuation in
			Task {
				let topicsVec = RustVec<RustString>()
				for topic in topics {
					topicsVec.push(value: topic.intoRustString())
				}
				let subscription = try await self.rustClient.subscribe(topicsVec)
				// Run a continuous for loop polling subscription.get_messages() and then waiting for 2 seconds
				while true {
					let rustEnvelopes = try subscription.get_messages()
					for rustEnvelope in rustEnvelopes {
						var swiftEnvelope = Envelope()
						swiftEnvelope.contentTopic = rustEnvelope.get_topic().toString()
						swiftEnvelope.timestampNs = rustEnvelope.get_sender_time_ns()
						swiftEnvelope.message = Data().dataFromRustVec(rustVec: rustEnvelope.get_payload())
						continuation.yield(swiftEnvelope)
					}
					try await Task.sleep(nanoseconds: 50_000_000) // 50ms
				}
			}
		}
	}

	@discardableResult func publish(envelopes: [Envelope]) async throws -> PublishResponse {
		var request = Xmtp_MessageApi_V1_PublishRequest()
		request.envelopes = envelopes

		let envelopesVec = RustVec<XMTPRust.Envelope>()

		envelopes.forEach { envelope in
			let rustEnvelope = XMTPRust.create_envelope(envelope.contentTopic.intoRustString(), envelope.timestampNs, dataToRustVec(data: envelope.message))
			envelopesVec.push(value: rustEnvelope)
		}
		let response = try await rustClient.publish(authToken.intoRustString(), envelopesVec)
		let publishResponse = PublishResponse()
		return publishResponse
	}

	public static func runGrpcTest() async throws -> Int {
		return 0
	}
}
