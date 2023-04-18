//
//  ApiClient.swift
//
//
//  Created by Pat Nakajima on 11/17/22.
//

import XMTPRust

public typealias PublishResponse = Xmtp_MessageApi_V1_PublishResponse
public typealias QueryResponse = Xmtp_MessageApi_V1_QueryResponse
public typealias SubscribeRequest = Xmtp_MessageApi_V1_SubscribeRequest

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

    private var rustClient: XMTPRust.ApiService!

	required init(environment: XMTPEnvironment, secure: Bool = true) throws {
		self.environment = environment
        // Secure flag is useless for now, XMTPRust checks the URL scheme to see if it's https
        rustClient = XMTPRust.ApiService(environment:envToUrl(env: environment), secure:true)
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

        var encodedPaging = ""
        if request.hasPagingInfo {
            encodedPaging = try request.pagingInfo.jsonString()
        }
        let responseJson = try await rustClient.query(topic: topic, json_paging_info: encodedPaging)
        // Decode the response as a QueryResponse
        let decodedQueryResponse = try QueryResponse(jsonString: responseJson)
        return decodedQueryResponse
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
                for try await envelopeJson in self.rustClient.subscribe(topics: topics) {
                    let envelope = try Envelope(jsonString: envelopeJson)
					continuation.yield(envelope)
				}
			}
		}
	}

	@discardableResult func publish(envelopes: [Envelope]) async throws -> PublishResponse {
		var request = Xmtp_MessageApi_V1_PublishRequest()
		request.envelopes = envelopes

		// return try await client.publish(request, callOptions: options)
        // Use the JSON encoding api for rustClient to publish
        let encodedEnvelopes = try envelopes.map { try $0.jsonString() }
        let responseJson = try await rustClient.publish(token: authToken, envelopes: encodedEnvelopes)
        // Decode the response as a PublishResponse
        let decodedPublishResponse = try PublishResponse(jsonString: responseJson)
        return decodedPublishResponse
	}
    
    public static func runGrpcTest() async throws -> Int {
        
        let json = "{\"contentTopic\":\"/xmtp/0/privatestore-0x144a87F6dB31445B916BF4d896A425C91DbA7f84/key_bundle/proto\",\"timestampNs\":\"1681678277321011968\",\"message\":\"CvYDCiBPVY2cN8BNkvA2Ypoh0GvaMKNKmAtUsaPMNMwsRDRsmhLRAwrOAwogJ2zn2csOlNN6h2Llb9H4sAvp2Qs6x2L8Dra4ZTG9OvoSDIXSSqfFBhJgYMPSuxqbA68nOkGUPsV1WKjzs2LBuktCdGAEt3tWAbW1jNSF3KaA8XBkbhmM5zwSIbv69vszBzBp9/cYXxW4/rAJtkOuyNlsX04x/i+hswL4T6EkpTl/SGgzRfAHZs+SKbfhwsdcVC577r0u5mm7a9C/DOrsdo42zXDL1cKv8DGSmLzIMGQTrryo6bOH+6JhHUu0bVdXC8KF13zhQxnbdnjg5NMN7PRfUZWP5iz/bfv2H3FZC7fFfmkxIM+yn4y0XQCPjhrygAZyzMhiUC2cPWBj+iTX/lDRed3qy5RmvHhBiOVwumtzkSCy2kreZ2Kd6xMBk+mfKnjLU9cDd2QDmlyJDjZ8FZlk83AeJr7rPCdRDPVPCxUhFNET605QBrx90HoTr6o+EK8N9KUgCHGuijqLen1aARBpqsWkit2zn371Poi3zQvGL/gEQuR7yGd+0Gi+sx/A/08jxcqKNtNOSO0XbtWzASYnEc8gDup+1CsEkMpvKJ/F5CbmQN2yAV0ZIHhsCpdIQ9uUe3C8lwVkns5oWlfZNX/FWKrqRMk6Nlvobg==\"}"
        let envelope = try Envelope(jsonString: json)
        let service = XMTPRust.ApiService(environment: "http://localhost:5556", secure: false)
        let response = try await service.query(topic: "test", json_paging_info: "")
        // Try to parse the response JSON into a QueryResponse
        let queryResponse = try QueryResponse(jsonString: response)
        return queryResponse.envelopes.count
    }
}
