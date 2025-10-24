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
			"https://github.com/xmtp/libxmtp/releases/download/swift-bindings-1.6.0-dev.3656d63/LibXMTPSwiftFFI.zip",
			checksum: "94c24c4623f5343454e3cd8533ec626cedd491ea97f6c06e93bb4fdff12772c5"
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
        ),
        .binaryTarget(
            name: "LibXMTPSwiftFFIDynamic",
			url:
			"https://github.com/xmtp/libxmtp/releases/download/swift-bindings-dynamic-1.6.0-dev.ca1e5bf/LibXMTPSwiftFFIDynamic.zip",
            checksum: "d7924e9f1c6e0afb1c8e46d6b5b03ae20c76bc991597b5ffda03f5372fcd4d99"
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
