// swift-tools-version: 5.6
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
	name: "XMTPiOS",
	platforms: [.iOS(.v14), .macOS(.v11)],
	products: [
		.library(
			name: "XMTPiOS",
			type: .static,
			targets: ["XMTPiOS"]
		),
		.library(
			name: "XMTPTestHelpers",
			targets: ["XMTPTestHelpers"]
		),
		.library(
			name: "XMTPiOS",
			type: .dynamic,
			targets: ["XMTPiOSDynamic"]
		)
	],
	dependencies: [
		.package(url: "https://github.com/bufbuild/connect-swift", exact: "1.0.0"),
		.package(url: "https://github.com/apple/swift-docc-plugin.git", from: "1.4.3"),
		.package(url: "https://github.com/krzyzanowskim/CryptoSwift.git", "1.8.4" ..< "2.0.0"),
		.package(url: "https://github.com/SimplyDanny/SwiftLintPlugins", from: "0.62.1"),
	],
	targets: [
		.binaryTarget(
			name: "LibXMTPSwiftFFI",
			url: "https://github.com/xmtp/libxmtp/releases/download/swift-bindings-1.6.1.4d46a4a/LibXMTPSwiftFFI.zip",
			checksum: "a3bc53c3bfec02fb52064c0576fa0633bf3bd60fc61d8fd5f6b80355763f91d4"
		),
		.target(
			name: "XMTPiOS",
			dependencies: [
				.product(name: "Connect", package: "connect-swift"),
				"LibXMTPSwiftFFI",
				.product(name: "CryptoSwift", package: "CryptoSwift"),
			]
		),
		.target(
			name: "XMTPiOSDynamic",
			dependencies: [
				.product(name: "Connect", package: "connect-swift"),
				"LibXMTPSwiftFFIDynamic",
				.product(name: "CryptoSwift", package: "CryptoSwift"),
			],
			path: "Sources/XMTPiOS"
		),
		.binaryTarget(
			name: "LibXMTPSwiftFFIDynamic",
			url:
			"https://github.com/xmtp/libxmtp/releases/download/swift-bindings-dynamic-1.6.0-dev.ca1e5bf/LibXMTPSwiftFFIDynamic.zip",
			checksum: "236a652f24b17a249328abb2029f4168e6dc298b6c6647bc9cba10cd5df15f7a"
		),
		.target(
			name: "XMTPTestHelpers",
			dependencies: ["XMTPiOS"]
		),
		.testTarget(
			name: "XMTPTests",
			dependencies: ["XMTPiOS", "XMTPTestHelpers"]
		),
	]
)
