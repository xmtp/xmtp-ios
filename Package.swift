// swift-tools-version: 5.6
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
	name: "XMTPiOS",
	platforms: [.iOS(.v14), .macOS(.v11)],
	products: [
		.library(
			name: "XMTPiOS",
			targets: ["XMTPiOS"]
		),
		.library(
			name: "XMTPTestHelpers",
			targets: ["XMTPTestHelpers"]
		),
	],
	dependencies: [
		.package(url: "https://github.com/1024jp/GzipSwift", from: "5.2.0"),
		.package(url: "https://github.com/bufbuild/connect-swift", exact: "0.12.0"),
		.package(url: "https://github.com/apple/swift-docc-plugin.git", from: "1.0.0"),
		.package(url: "https://github.com/xmtp/libxmtp-swift.git", exact: "3.0.0"),
		.package(url: "https://github.com/krzyzanowskim/CryptoSwift.git", exact: "1.8.3")
	],
	targets: [
		.target(
			name: "XMTPiOS",
			dependencies: [
				.product(name: "Gzip", package: "GzipSwift"),
				.product(name: "Connect", package: "connect-swift"),
				.product(name: "LibXMTP", package: "libxmtp-swift"),
				.product(name: "Crypto", package: "CryptoSwift")
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
