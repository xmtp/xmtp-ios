import Foundation
import LibXMTP
import XCTest
import XMTPTestHelpers

@testable import XMTPiOS

@available(iOS 15, *)
class ClientTests: XCTestCase {
	func testTakesAWallet() async throws {
		let key = try Crypto.secureRandomBytes(count: 32)
		let clientOptions: ClientOptions = ClientOptions(
			api: ClientOptions.Api(
				env: XMTPEnvironment.local, isSecure: false),
			dbEncryptionKey: key
		)
		let fakeWallet = try PrivateKey.generate()
		_ = try await Client.create(account: fakeWallet, options: clientOptions)
	}

	func testPassingEncryptionKey() async throws {
		let bo = try PrivateKey.generate()
		let key = try Crypto.secureRandomBytes(count: 32)

		_ = try await Client.create(
			account: bo,
			options: .init(
				api: .init(env: .local, isSecure: false),
				dbEncryptionKey: key
			)
		)
	}

	func testCanDeleteDatabase() async throws {
		let key = try Crypto.secureRandomBytes(count: 32)
		let bo = try PrivateKey.generate()
		let alix = try PrivateKey.generate()
		var boClient = try await Client.create(
			account: bo,
			options: .init(
				api: .init(env: .local, isSecure: false),
				dbEncryptionKey: key
			)
		)

		let alixClient = try await Client.create(
			account: alix,
			options: .init(
				api: .init(env: .local, isSecure: false),
				dbEncryptionKey: key
			)
		)

		_ = try await boClient.conversations.newGroup(with: [alixClient.address]
		)
		try await boClient.conversations.sync()

		var groupCount = try await boClient.conversations.listGroups().count
		XCTAssertEqual(groupCount, 1)

		assert(!boClient.dbPath.isEmpty)
		try boClient.deleteLocalDatabase()

		boClient = try await Client.create(
			account: bo,
			options: .init(
				api: .init(env: .local, isSecure: false),
				dbEncryptionKey: key
			)
		)

		try await boClient.conversations.sync()
		groupCount = try await boClient.conversations.listGroups().count
		XCTAssertEqual(groupCount, 0)
	}

	func testCanDropReconnectDatabase() async throws {
		let key = try Crypto.secureRandomBytes(count: 32)
		let bo = try PrivateKey.generate()
		let alix = try PrivateKey.generate()
		let boClient = try await Client.create(
			account: bo,
			options: .init(
				api: .init(env: .local, isSecure: false),
				dbEncryptionKey: key
			)
		)

		let alixClient = try await Client.create(
			account: alix,
			options: .init(
				api: .init(env: .local, isSecure: false),
				dbEncryptionKey: key
			)
		)

		_ = try await boClient.conversations.newGroup(with: [alixClient.address]
		)
		try await boClient.conversations.sync()

		var groupCount = try await boClient.conversations.listGroups().count
		XCTAssertEqual(groupCount, 1)

		try boClient.dropLocalDatabaseConnection()

		await assertThrowsAsyncError(
			try await boClient.conversations.listGroups())

		try await boClient.reconnectLocalDatabase()

		groupCount = try await boClient.conversations.listGroups().count
		XCTAssertEqual(groupCount, 1)
	}

	func testCanMessage() async throws {
		let fixtures = try await fixtures()
		let notOnNetwork = try PrivateKey.generate()

		let canMessage = try await fixtures.alixClient.canMessage(
			address: fixtures.boClient.address)
		let cannotMessage = try await fixtures.alixClient.canMessage(
			address: notOnNetwork.address)
		XCTAssertTrue(canMessage)
		XCTAssertFalse(cannotMessage)
	}

	func testPreAuthenticateToInboxCallback() async throws {
		let fakeWallet = try PrivateKey.generate()
		let expectation = XCTestExpectation(
			description: "preAuthenticateToInboxCallback is called")
		let key = try Crypto.secureRandomBytes(count: 32)

		let preAuthenticateToInboxCallback: () async throws -> Void = {
			print("preAuthenticateToInboxCallback called")
			expectation.fulfill()
		}

		let opts = ClientOptions(
			api: ClientOptions.Api(env: .local, isSecure: false),
			preAuthenticateToInboxCallback: preAuthenticateToInboxCallback,
			dbEncryptionKey: key
		)
		do {
			_ = try await Client.create(account: fakeWallet, options: opts)
			await XCTWaiter().fulfillment(of: [expectation], timeout: 30)
		} catch {
			XCTFail("Error: \(error)")
		}
	}

	func testPassingEncryptionKeyAndDatabaseDirectory() async throws {
		let bo = try PrivateKey.generate()
		let key = try Crypto.secureRandomBytes(count: 32)

		let client = try await Client.create(
			account: bo,
			options: .init(
				api: .init(env: .local, isSecure: false),
				dbEncryptionKey: key,
				dbDirectory: "xmtp_db"
			)
		)

		let bundleClient = try await Client.build(
			address: bo.address,
			options: .init(
				api: .init(env: .local, isSecure: false),
				dbEncryptionKey: key,
				dbDirectory: "xmtp_db"
			)
		)

		XCTAssertEqual(client.address, bundleClient.address)
		XCTAssertEqual(client.dbPath, bundleClient.dbPath)
		XCTAssert(!client.installationID.isEmpty)

		await assertThrowsAsyncError(
			_ = try await Client.build(
				address: bo.address,
				options: .init(
					api: .init(env: .local, isSecure: false),
					dbEncryptionKey: key,
					dbDirectory: nil
				)
			)
		)
	}

	func testEncryptionKeyCanDecryptCorrectly() async throws {
		let bo = try PrivateKey.generate()
		let alix = try PrivateKey.generate()
		let key = try Crypto.secureRandomBytes(count: 32)

		let boClient = try await Client.create(
			account: bo,
			options: .init(
				api: .init(env: .local, isSecure: false),
				dbEncryptionKey: key,
				dbDirectory: "xmtp_db"
			)
		)

		let alixClient = try await Client.create(
			account: alix,
			options: .init(
				api: .init(env: .local, isSecure: false),
				dbEncryptionKey: key,
				dbDirectory: "xmtp_db"
			)
		)

		_ = try await boClient.conversations.newGroup(with: [
			alixClient.address
		])

		let key2 = try Crypto.secureRandomBytes(count: 32)
		await assertThrowsAsyncError(
			try await Client.create(
				account: bo,
				options: .init(
					api: .init(env: .local, isSecure: false),
					dbEncryptionKey: key2,
					dbDirectory: "xmtp_db"
				)
			)
		)
	}

	func testCanGetAnInboxIdFromAddress() async throws {
		let key = try Crypto.secureRandomBytes(count: 32)
		let bo = try PrivateKey.generate()
		let alix = try PrivateKey.generate()
		let boClient = try await Client.create(
			account: bo,
			options: .init(
				api: .init(env: .local, isSecure: false),
				dbEncryptionKey: key
			)
		)

		let alixClient = try await Client.create(
			account: alix,
			options: .init(
				api: .init(env: .local, isSecure: false),
				dbEncryptionKey: key
			)
		)
		let boInboxId = try await alixClient.inboxIdFromAddress(
			address: boClient.address)
		XCTAssertEqual(boClient.inboxID, boInboxId)
	}

	func testCreatesAClient() async throws {
		let key = try Crypto.secureRandomBytes(count: 32)
		let alix = try PrivateKey.generate()
		let options = ClientOptions.init(
			api: .init(env: .local, isSecure: false),
			dbEncryptionKey: key
		)

		let inboxId = try await Client.getOrCreateInboxId(
			api: options.api, address: alix.address)
		let alixClient = try await Client.create(
			account: alix,
			options: options
		)

		XCTAssertEqual(inboxId, alixClient.inboxID)

		let alixClient2 = try await Client.build(
			address: alix.address,
			options: options
		)

		XCTAssertEqual(alixClient2.inboxID, alixClient.inboxID)
	}

	func testRevokesAllOtherInstallations() async throws {
		let key = try Crypto.secureRandomBytes(count: 32)
		let alix = try PrivateKey.generate()
		let options = ClientOptions.init(
			api: .init(env: .local, isSecure: false),
			dbEncryptionKey: key
		)

		let alixClient = try await Client.create(
			account: alix,
			options: options
		)
		try alixClient.dropLocalDatabaseConnection()
		try alixClient.deleteLocalDatabase()

		let alixClient2 = try await Client.create(
			account: alix,
			options: options
		)
		try alixClient2.dropLocalDatabaseConnection()
		try alixClient2.deleteLocalDatabase()

		let alixClient3 = try await Client.create(
			account: alix,
			options: options
		)

		let state = try await alixClient3.inboxState(refreshFromNetwork: true)
		XCTAssertEqual(state.installations.count, 3)
		XCTAssert(state.installations.first?.createdAt != nil)

		try await alixClient3.revokeAllOtherInstallations(signingKey: alix)

		let newState = try await alixClient3.inboxState(
			refreshFromNetwork: true)
		XCTAssertEqual(newState.installations.count, 1)
	}

	func testsCanFindOthersInboxStates() async throws {
		let fixtures = try await fixtures()
		let states = try await fixtures.alixClient.inboxStatesForInboxIds(
			refreshFromNetwork: true,
			inboxIds: [fixtures.boClient.inboxID, fixtures.caroClient.inboxID]
		)
		XCTAssertEqual(
			states.first!.recoveryAddress.lowercased(),
			fixtures.bo.walletAddress.lowercased())
		XCTAssertEqual(
			states.last!.recoveryAddress.lowercased(),
			fixtures.caro.walletAddress.lowercased())
	}

	func testAddAccounts() async throws {
		let fixtures = try await fixtures()
		let alix2Wallet = try PrivateKey.generate()
		let alix3Wallet = try PrivateKey.generate()

		try await fixtures.alixClient.addAccount(newAccount: alix2Wallet)
		try await fixtures.alixClient.addAccount(newAccount: alix3Wallet)

		let state = try await fixtures.alixClient.inboxState(
			refreshFromNetwork: true)
		XCTAssertEqual(state.installations.count, 1)
		XCTAssertEqual(state.addresses.count, 3)
		XCTAssertEqual(
			state.recoveryAddress.lowercased(),
			fixtures.alixClient.address.lowercased())
		XCTAssertEqual(
			state.addresses.sorted(),
			[
				alix2Wallet.address.lowercased(),
				alix3Wallet.address.lowercased(),
				fixtures.alixClient.address.lowercased(),
			].sorted()
		)
	}

	func testRemovingAccounts() async throws {
		let fixtures = try await fixtures()
		let alix2Wallet = try PrivateKey.generate()
		let alix3Wallet = try PrivateKey.generate()

		try await fixtures.alixClient.addAccount(newAccount: alix2Wallet)
		try await fixtures.alixClient.addAccount(newAccount: alix3Wallet)

		var state = try await fixtures.alixClient.inboxState(
			refreshFromNetwork: true)
		XCTAssertEqual(state.addresses.count, 3)
		XCTAssertEqual(
			state.recoveryAddress.lowercased(),
			fixtures.alixClient.address.lowercased())

		try await fixtures.alixClient.removeAccount(
			recoveryAccount: fixtures.alix, addressToRemove: alix2Wallet.address
		)

		state = try await fixtures.alixClient.inboxState(
			refreshFromNetwork: true)
		XCTAssertEqual(state.addresses.count, 2)
		XCTAssertEqual(
			state.recoveryAddress.lowercased(),
			fixtures.alixClient.address.lowercased())
		XCTAssertEqual(
			state.addresses.sorted(),
			[
				alix3Wallet.address.lowercased(),
				fixtures.alixClient.address.lowercased(),
			].sorted()
		)
		XCTAssertEqual(state.installations.count, 1)

		// Cannot remove the recovery address
		await assertThrowsAsyncError(
			try await fixtures.alixClient.removeAccount(
				recoveryAccount: alix3Wallet,
				addressToRemove: fixtures.alixClient.address
			))
	}

	func testSignatures() async throws {
		let fixtures = try await fixtures()

		// Signing with installation key
		let signature = try fixtures.alixClient.signWithInstallationKey(
			message: "Testing")
		XCTAssertTrue(
			try fixtures.alixClient.verifySignature(
				message: "Testing", signature: signature))
		XCTAssertFalse(
			try fixtures.alixClient.verifySignature(
				message: "Not Testing", signature: signature))

		let alixInstallationId = fixtures.alixClient.installationID

		XCTAssertTrue(
			try fixtures.alixClient.verifySignatureWithInstallationId(
				message: "Testing",
				signature: signature,
				installationId: alixInstallationId
			))
		XCTAssertFalse(
			try fixtures.alixClient.verifySignatureWithInstallationId(
				message: "Not Testing",
				signature: signature,
				installationId: alixInstallationId
			))
		XCTAssertFalse(
			try fixtures.alixClient.verifySignatureWithInstallationId(
				message: "Testing",
				signature: signature,
				installationId: fixtures.boClient.installationID
			))
		XCTAssertTrue(
			try fixtures.boClient.verifySignatureWithInstallationId(
				message: "Testing",
				signature: signature,
				installationId: alixInstallationId
			))

		try fixtures.alixClient.deleteLocalDatabase()
		let key = try Crypto.secureRandomBytes(count: 32)
		let options = ClientOptions.init(
			api: .init(env: .local, isSecure: false),
			dbEncryptionKey: key
		)

		// Creating a new client
		let alixClient2 = try await Client.create(
			account: fixtures.alix,
			options: options
		)

		XCTAssertTrue(
			try alixClient2.verifySignatureWithInstallationId(
				message: "Testing",
				signature: signature,
				installationId: alixInstallationId
			))
		XCTAssertFalse(
			try alixClient2.verifySignatureWithInstallationId(
				message: "Testing2",
				signature: signature,
				installationId: alixInstallationId
			))
	}
	
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

		// Assert performance comparisons
		XCTAssertTrue(time2 < time1, "Building a client should be faster than creating one.")
		XCTAssertTrue(time3 < time1, "Building a client with inboxId should be faster than creating one.")
		XCTAssertTrue(time3 < time2, "Building a client with inboxId should be faster than building one without.")
		
		// Assert that inbox IDs match
		XCTAssertEqual(client.inboxID, buildClient1.inboxID, "Inbox ID of the created client and first built client should match.")
		XCTAssertEqual(client.inboxID, buildClient2.inboxID, "Inbox ID of the created client and second built client should match.")
	}

}
