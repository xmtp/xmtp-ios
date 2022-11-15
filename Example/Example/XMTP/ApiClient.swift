//
//  ApiClient.swift
//  xmtp-ios example
//
//  Created by Pat Nakajima on 11/11/22.
//

import Foundation
import GRPC
import Logging
import XMTPProto

struct AuthCache {}

struct ApiClientOptions {
	var maxRetries: Int = 5
	var appVersion: String?
}

enum Direction {
	case unspecified, ascending, descending
}

struct QueryParams {
	var startTime: Date?
	var endTime: Date?
	var contentTopics: [String]
}

struct QueryStreamOptions {
	var direction: Direction? = .unspecified
	var limit: Int? = 10
}

enum ApiClientError: Error {
	case noTopics
}

struct ApiClient {
	let RetrySleepTime = 100
	let ERRCodeUnauthenticated = 16
	let DefaultMaxRetries = 5

	let ClientVersionHeaderKey = "X-Client-Version"
	let AppVersionHeaderKey = "X-App-Version"

	var pathPrefix: String
	var maxRetries: Int

	var appVersion: String?
	var version: String

	private var authCache: AuthCache?

	init(pathPrefix: String, options: ApiClientOptions? = nil) {
		self.pathPrefix = pathPrefix
		maxRetries = options?.maxRetries ?? DefaultMaxRetries
		appVersion = options?.appVersion
		version = "xmtp-js/" + Constants.version
	}

	func queryIteratePages(params: QueryParams, options: QueryStreamOptions? = nil) async throws -> Xmtp_MessageApi_V1_QueryResponse {
		let contentTopics = params.contentTopics

		if contentTopics.isEmpty {
			throw ApiClientError.noTopics
		}

		var request = Xmtp_MessageApi_V1_QueryRequest()

		request.contentTopics = contentTopics

		if let startTime = params.startTime {
			request.startTimeNs = UInt64(Int(startTime.timeIntervalSince1970) * 1_000_000)
		}

		if let endTime = params.endTime {
			request.endTimeNs = UInt64(Int(endTime.timeIntervalSince1970) * 1_000_000)
		}

		let cursor = Xmtp_MessageApi_V1_Cursor()

		request.pagingInfo.cursor = cursor

		let group = PlatformSupport.makeEventLoopGroup(loopCount: 1)
		defer {
			try? group.syncShutdownGracefully()
		}

		let config = GRPCTLSConfiguration.makeClientConfigurationBackedByNIOSSL()
		let channel = try GRPCChannelPool.with(
			target: .host(pathPrefix, port: 5556),
			transportSecurity: .tls(config),
			eventLoopGroup: group
		)

		let client = Xmtp_MessageApi_V1_MessageApiAsyncClient(channel: channel)

		var options = CallOptions()
		options.timeLimit = .timeout(.seconds(5))

		return try await client.query(request, callOptions: options)
	}
}
