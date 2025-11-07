import XCTest

@testable import XMTPiOS

final class AuthTests: XCTestCase {
	func testCredentialConversion() async throws {
		// Test forward conversion
		let publicCredential = Credential(
			name: "test-name",
			value: "test-value",
			expiresAtSeconds: 1_234_567_890
		)
		let ffiCredential = publicCredential.ffi
		XCTAssertEqual(ffiCredential.name, "test-name")
		XCTAssertEqual(ffiCredential.value, "test-value")
		XCTAssertEqual(ffiCredential.expiresAtSeconds, 1_234_567_890)

		// Test backward conversion
		let backConverted = Credential(ffi: ffiCredential)
		XCTAssertEqual(backConverted.name, "test-name")
		XCTAssertEqual(backConverted.value, "test-value")
		XCTAssertEqual(backConverted.expiresAtSeconds, 1_234_567_890)
		XCTAssertEqual(backConverted.expiresAt.timeIntervalSince1970, 1_234_567_890.0, accuracy: 0.1)
	}

	func testAuthCallback() async throws {
		let expectation = XCTestExpectation(description: "AuthCallback invoked")

		let testCallback: AuthCallback = {
			expectation.fulfill()
			return Credential(
				name: "dummy-name",
				value: "dummy-value",
				expiresAtSeconds: Int64(Date().timeIntervalSince1970 + 3600)
			)
		}

		let internalCallback = makeInternalAuthCallback(testCallback)!
		let ffiCredential = try await internalCallback.onAuthRequired()

		XCTAssertEqual(ffiCredential.name, "dummy-name")
		XCTAssertEqual(ffiCredential.value, "dummy-value")

		wait(for: [expectation], timeout: 1.0)

		// Verify acceptance in connectToApiBackend
		let api = ClientOptions.Api(
			env: .local,
			gatewayHost: "https://gateway.example.com",
			authCallback: testCallback
		)
		let client = try await Client.connectToApiBackend(api: api)
		XCTAssertNotNil(client)
	}

	func testAuthHandleSet() async throws {
		let handle = AuthHandle()
		let credential = Credential(
			name: "handle-name",
			value: "handle-value",
			expiresAtSeconds: 1_234_567_890
		)

		// Verify acceptance in connectToApiBackend
		let api = ClientOptions.Api(
			env: .local,
			gatewayHost: "https://gateway.example.com",
			authHandle: handle
		)
		let client = try await Client.connectToApiBackend(api: api)
		XCTAssertNotNil(client)

		// This should not throw if the wrapper works
		try await handle.set(credential)
	}
}
