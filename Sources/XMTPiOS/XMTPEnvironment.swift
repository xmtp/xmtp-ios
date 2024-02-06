//
//  Environment.swift
//
//
//  Created by Pat Nakajima on 11/17/22.
//

import Foundation

/// Contains hosts an `ApiClient` can connect to
public enum XMTPEnvironment: String, Sendable {
	case dev = "grpc.dev.xmtp.network:443",
	     production = "grpc.production.xmtp.network:443",
	     local = "localhost"
}
