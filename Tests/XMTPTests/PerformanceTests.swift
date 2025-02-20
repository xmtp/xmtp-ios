import Foundation
import LibXMTP
import XCTest
import XMTPTestHelpers

@testable import XMTPiOS

@available(iOS 15, *)
class PerformanceTests: XCTestCase {
	func testCreatesADevClientPerformance() async throws {
		let key = try Crypto.secureRandomBytes(count: 32)
		let fakeWallet = try PrivateKey.generate()

		// Measure time to create the client
		let start = Date()
		let client = try await Client.create(
			account: fakeWallet,
			options: ClientOptions(
				api: ClientOptions.Api(env: .dev, isSecure: true),
				dbEncryptionKey: key
			)
		)
		let end = Date()
		let time1 = end.timeIntervalSince(start)
		print("PERF: Created a client in \(time1)s")

		// Measure time to build a client
		let start2 = Date()
		let buildClient1 = try await Client.build(
			address: fakeWallet.address,
			options: ClientOptions(
				api: ClientOptions.Api(env: .dev, isSecure: true),
				dbEncryptionKey: key
			)
		)
		let end2 = Date()
		let time2 = end2.timeIntervalSince(start2)
		print("PERF: Built a client in \(time2)s")

		// Measure time to build a client with an inboxId
		let start3 = Date()
		let buildClient2 = try await Client.build(
			address: fakeWallet.address,
			options: ClientOptions(
				api: ClientOptions.Api(env: .dev, isSecure: true),
				dbEncryptionKey: key
			),
			inboxId: client.inboxID
		)
		let end3 = Date()
		let time3 = end3.timeIntervalSince(start3)
		print("PERF: Built a client with inboxId in \(time3)s")

		// Measure time to build a client with an inboxId and apiClient
		try await Client.connectToApiBackend(
			api: ClientOptions.Api(env: .dev, isSecure: true))
		let start4 = Date()
		try await Client.create(
			account: fakeWallet,
			options: ClientOptions(
				api: ClientOptions.Api(env: .dev, isSecure: true),
				dbEncryptionKey: key
			)
		)
		let end4 = Date()
		let time4 = end4.timeIntervalSince(start4)
		print("PERF: Create a client with prebuild in \(time4)s")

		// Assert performance comparisons
		XCTAssertTrue(
			time2 < time1,
			"Building a client should be faster than creating one.")
		XCTAssertTrue(
			time3 < time1,
			"Building a client with inboxId should be faster than creating one."
		)
		XCTAssertTrue(
			time3 < time2,
			"Building a client with inboxId should be faster than building one without."
		)
		XCTAssertTrue(
			time4 < time1,
			"Creating a client with apiClient should be faster than creating one without."
		)

		// Assert that inbox IDs match
		XCTAssertEqual(
			client.inboxID, buildClient1.inboxID,
			"Inbox ID of the created client and first built client should match."
		)
		XCTAssertEqual(
			client.inboxID, buildClient2.inboxID,
			"Inbox ID of the created client and second built client should match."
		)
	}

}
