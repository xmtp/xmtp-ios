import Foundation

// MARK: - Public Types

public struct Credential {
	public let name: Optional<String>
	public let value: String
	public let expiresAtSeconds: Int64

	public init(name: String?, value: String, expiresAtSeconds: Int64) {
		self.name = name
		self.value = value
		self.expiresAtSeconds = expiresAtSeconds
	}

	public var expiresAt: Date {
		Date(timeIntervalSince1970: TimeInterval(expiresAtSeconds))
	}
}

extension Credential {
	var ffi: FfiCredential {
		FfiCredential(
			name: name,
			value: value,
			expiresAtSeconds: expiresAtSeconds
		)
	}

	init(ffi: FfiCredential) {
		self.init(
			name: ffi.name,
			value: ffi.value,
			expiresAtSeconds: ffi.expiresAtSeconds
		)
	}
}

public typealias AuthCallback = @Sendable () async throws -> Credential

public class AuthHandle {
	private let ffiHandle: FfiAuthHandle

	public init() {
		ffiHandle = FfiAuthHandle()
	}

	public func set(_ credential: Credential) async throws {
		try await ffiHandle.set(credential: credential.ffi)
	}

	var ffi: FfiAuthHandle {
		ffiHandle
	}
}

// MARK: - Internal Wrappers

private final class InternalAuthCallback: FfiAuthCallback, @unchecked Sendable {
	let callback: AuthCallback

	init(_ callback: @escaping AuthCallback) {
		self.callback = callback
	}

	func onAuthRequired() async throws -> FfiCredential {
		let credential = try await callback()
		return credential.ffi
	}
}

func makeInternalAuthCallback(_ callback: AuthCallback?) -> FfiAuthCallback? {
	guard let callback = callback else { return nil }
	return InternalAuthCallback(callback)
}
