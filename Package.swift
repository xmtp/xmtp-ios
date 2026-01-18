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
		.package(url: "https://github.com/bufbuild/connect-swift", exact: "1.2.0"),
		.package(url: "https://github.com/apple/swift-docc-plugin.git", from: "1.4.3"),
		.package(url: "https://github.com/krzyzanowskim/CryptoSwift.git", "1.8.4" ..< "2.0.0"),
		.package(url: "https://github.com/SimplyDanny/SwiftLintPlugins", from: "0.62.1"),
	],
	targets: [
		.binaryTarget(
			name: "LibXMTPSwiftFFI",
			url: "https://github.com/xmtp/libxmtp/releases/download/swift-bindings-1.9.0.d206831/LibXMTPSwiftFFI.zip",
			checksum: "b42e620b01000aa3e94ccd53a9874ed2a00b2ff5a9a5c38c2d4e4963a858d60f"
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
