//
//  ApiClient.swift
//
//
//  Created by Pat Nakajima on 11/17/22.
//

import XMTPProto
import XMTPRust
import Foundation


typealias PublishResponse = Xmtp_MessageApi_V1_PublishResponse
typealias QueryResponse = Xmtp_MessageApi_V1_QueryResponse
typealias SubscribeRequest = Xmtp_MessageApi_V1_SubscribeRequest

protocol ApiClient {
	var environment: XMTPEnvironment { get }
	init(environment: XMTPEnvironment, secure: Bool) throws
	func setAuthToken(_ token: String)
	func query(topic: String, pagination: Pagination?, cursor: Xmtp_MessageApi_V1_Cursor?) async throws -> QueryResponse
	func query(topic: Topic, pagination: Pagination?) async throws -> QueryResponse
	func envelopes(topic: String, pagination: Pagination?) async throws -> [Envelope]
	func publish(envelopes: [Envelope]) async throws -> PublishResponse
	func subscribe(topics: [String]) -> AsyncThrowingStream<Envelope, Error>
}

class GRPCApiClient: ApiClient {
    
	let ClientVersionHeaderKey = "X-Client-Version"
	let AppVersionHeaderKey = "X-App-Version"

	var environment: XMTPEnvironment
	var authToken = ""

    private var rustClient: XMTPRust.RustClient!

	required init(environment: XMTPEnvironment, secure: Bool = true) throws {
		self.environment = environment
        // TODO: this is a hack to do an async thing in a synchronous way
        print("init client")
        Task {
            print("Initializing rustclient")
            self.rustClient = try await XMTPRust.create_client(envToUrl(env: environment))
            print("done initializing rustclient")

        }
        print("exit init client")
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
    
    func envToUrl(env: XMTPEnvironment) -> String {
        switch (env) {
        case XMTPEnvironment.local: return "http://localhost:5556";
        case XMTPEnvironment.dev: return "https://dev.xmtp.network:5556";
        case XMTPEnvironment.production: return "https://xmtp.network:5556";
        }
    }

	func setAuthToken(_ token: String) {
		authToken = token
	}

	func query(topic: String, pagination: Pagination? = nil, cursor: Xmtp_MessageApi_V1_Cursor? = nil) async throws -> QueryResponse {
        try await Task.sleep(nanoseconds: 1000_000_000)
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
        let response = try await self.rustClient.query(topic.intoRustString(), Optional.none, Optional.none, Optional.none)
        // response has .envelopes() and .paging_info() but the envelopes need to be mapped into Envelope objects that Swift understands
        print("RESPONSE \(response)")
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

    func subscribe(topics: [String])  -> AsyncThrowingStream<Envelope, Error> {
        var topicsVec = RustVec<RustString>()
        for topic in topics {
            topicsVec.push(value: topic.intoRustString())
        }
        // let subscription = try await self.rustClient.subscribe(topicsVec)
        // return AsyncThrowingStream { continuation in
        //     Task {
        // // Run a continuous for loop polling subscription.get_messages() and then waiting for 2 seconds
        // for await _ in 0... {
        //     let rustEnvelopes = try await subscription.get_messages()
        //     for rustEnvelope in rustEnvelopes {
        //         var swiftEnvelope = Envelope()
        //         swiftEnvelope.contentTopic = rustEnvelope.contentTopic
        //         swiftEnvelope.timestampNs = rustEnvelope.timestampNs
        //         swiftEnvelope.message = rustEnvelope.message
        //         continuation.yield(swiftEnvelope)
        //     }
        //         }
        //     }
        // }
        // Fix the code above to 1) return an AsyncThrowingStream and 2) initiate the subscription and call get_messages on it
        // It needs to run a for loop constantly calling get_messages and waiting a few seconds
        // Then it needs to yield the Envelope objects to the continuation
        // Then it needs to return the AsyncThrowingStream
        return AsyncThrowingStream { continuation in
            Task {
                    continuation.yield(Envelope())
                }
        }
    }

	@discardableResult func publish(envelopes: [Envelope]) async throws -> PublishResponse {
        try await Task.sleep(nanoseconds: 1000_000_000)

		var request = Xmtp_MessageApi_V1_PublishRequest()
		request.envelopes = envelopes
        
        let envelopesVec = RustVec<XMTPRust.Envelope>()
        
        envelopes.forEach( { envelope in
            let rustEnvelope = XMTPRust.create_envelope(envelope.contentTopic.intoRustString(), envelope.timestampNs, dataToRustVec(data: envelope.message))
            envelopesVec.push(value: rustEnvelope)
        })
        let response = try await self.rustClient.publish(self.authToken.intoRustString(), envelopesVec)
        let publishResponse = PublishResponse()
        return publishResponse
	}
    
    public static func runGrpcTest() async throws -> Int {
        return 0
//
//        let json = "{\"contentTopic\":\"/xmtp/0/privatestore-0x144a87F6dB31445B916BF4d896A425C91DbA7f84/key_bundle/proto\",\"timestampNs\":\"1681678277321011968\",\"message\":\"CvYDCiBPVY2cN8BNkvA2Ypoh0GvaMKNKmAtUsaPMNMwsRDRsmhLRAwrOAwogJ2zn2csOlNN6h2Llb9H4sAvp2Qs6x2L8Dra4ZTG9OvoSDIXSSqfFBhJgYMPSuxqbA68nOkGUPsV1WKjzs2LBuktCdGAEt3tWAbW1jNSF3KaA8XBkbhmM5zwSIbv69vszBzBp9/cYXxW4/rAJtkOuyNlsX04x/i+hswL4T6EkpTl/SGgzRfAHZs+SKbfhwsdcVC577r0u5mm7a9C/DOrsdo42zXDL1cKv8DGSmLzIMGQTrryo6bOH+6JhHUu0bVdXC8KF13zhQxnbdnjg5NMN7PRfUZWP5iz/bfv2H3FZC7fFfmkxIM+yn4y0XQCPjhrygAZyzMhiUC2cPWBj+iTX/lDRed3qy5RmvHhBiOVwumtzkSCy2kreZ2Kd6xMBk+mfKnjLU9cDd2QDmlyJDjZ8FZlk83AeJr7rPCdRDPVPCxUhFNET605QBrx90HoTr6o+EK8N9KUgCHGuijqLen1aARBpqsWkit2zn371Poi3zQvGL/gEQuR7yGd+0Gi+sx/A/08jxcqKNtNOSO0XbtWzASYnEc8gDup+1CsEkMpvKJ/F5CbmQN2yAV0ZIHhsCpdIQ9uUe3C8lwVkns5oWlfZNX/FWKrqRMk6Nlvobg==\"}"
//        let envelope = try Envelope(jsonString: json)
//        let service = XMTPRust.ApiService(environment: "http://localhost:5556", secure: false)
//        let response = try await service.query(topic: "test", json_paging_info: "")
//        // Try to parse the response JSON into a QueryResponse
//        let queryResponse = try QueryResponse(jsonString: response)
//        return queryResponse.envelopes.count
    }
}
