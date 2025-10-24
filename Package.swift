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
			url:
			"https://github.com/xmtp/libxmtp/releases/download/swift-bindings-1.6.0-dev.9df3055/LibXMTPSwiftFFI.zip",
			checksum: "75403ad72347231227720ec1ab848fccce0c5d3db26cc198bbfafc04f4959e11"
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
			"https://github.com/xmtp/libxmtp/releases/download/swift-bindings-1.6.0-dev.9df3055/LibXMTPSwiftFFIDynamic.zip",
			checksum: "1f1b240e8707da864bce2ac05f0b0abdd21112781dc1975db61e773862755e96"
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
