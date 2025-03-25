//
//  Environment.swift
//
//
//  Created by Pat Nakajima on 11/17/22.
//

import Foundation

/// Contains hosts an `ApiClient` can connect to
public enum XMTPEnvironment: String, Sendable {
	case dev = "grpc.dev.xmtp.network:443"
	case production = "grpc.production.xmtp.network:443"
	case local = "localhost:5556"

	// Optional override for the local environment
	public static var customLocalAddress: String?

	var url: String {
		switch self {
		case .dev, .production:
			return "https://\(rawValue)"
		case .local:
			let address = XMTPEnvironment.customLocalAddress ?? rawValue
			return "http://\(address)"
		}
	}

	public var isSecure: Bool {
		url.starts(with: "https")
	}
}
