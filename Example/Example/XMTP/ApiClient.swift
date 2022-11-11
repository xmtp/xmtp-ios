//
//  ApiClient.swift
//  xmtp-ios example
//
//  Created by Pat Nakajima on 11/11/22.
//

import Foundation

struct AuthCache {

}

struct ApiClientOptions {
	var maxRetries: Int = 5
	var appVersion: String?
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
		self.maxRetries = options?.maxRetries ?? DefaultMaxRetries
		self.appVersion = options?.appVersion
		self.version = "xmtp-js/" + Constants.version
	}
}
