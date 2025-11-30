// swift-tools-version: 5.6
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
	name: "XMTPiOS",
	platforms: [.iOS(.v14), .macOS(.v11)],
	products: [
		.library(
			name: "XMTPiOS",
			type: .dynamic,
			targets: ["XMTPiOS"]
		),
		.library(
			name: "XMTPTestHelpers",
			targets: ["XMTPTestHelpers"]
		),
	],
	dependencies: [
		.package(url: "https://github.com/bufbuild/connect-swift", exact: "1.0.0"),
		.package(url: "https://github.com/apple/swift-docc-plugin.git", from: "1.4.3"),
		.package(url: "https://github.com/krzyzanowskim/CryptoSwift.git", "1.8.4" ..< "2.0.0"),
		.package(url: "https://github.com/SimplyDanny/SwiftLintPlugins", from: "0.62.1"),
	],
	targets: [
		.binaryTarget(
			name: "LibXMTPSwiftFFIDynamic",
			url: "https://github.com/xmtp/libxmtp/releases/download/swift-bindings-1.6.3.ab0df09/LibXMTPSwiftFFIDynamic.zip",
			checksum: "66ea16f78499a60b99e33e6f09f75411bca7d3c3a41e3a6621144f78047fc1d3"
		),
		.target(
			name: "XMTPiOS",
			dependencies: [
				.product(name: "Connect", package: "connect-swift"),
				"LibXMTPSwiftFFIDynamic",
				.product(name: "CryptoSwift", package: "CryptoSwift"),
			]
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
