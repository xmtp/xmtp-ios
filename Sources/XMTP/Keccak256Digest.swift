//
//  File.swift
//
//
//  Created by Pat Nakajima on 11/20/22.
//

import Foundation
import secp256k1

public struct Keccak256Digest: Digest {
	let bytes: (UInt64, UInt64, UInt64, UInt64)

	public init(_ output: [UInt8]) {
		let first = output[0 ..< 8].withUnsafeBytes { $0.load(as: UInt64.self) }
		let second = output[8 ..< 16].withUnsafeBytes { $0.load(as: UInt64.self) }
		let third = output[16 ..< 24].withUnsafeBytes { $0.load(as: UInt64.self) }
		let forth = output[24 ..< 32].withUnsafeBytes { $0.load(as: UInt64.self) }
		bytes = (first, second, third, forth)
	}

	public static var byteCount: Int {
		get { 32 }
		set { fatalError("Cannot set byte count on Keccak256Digest") }
	}

	public func withUnsafeBytes<R>(_ body: (UnsafeRawBufferPointer) throws -> R) rethrows -> R {
		try Swift.withUnsafeBytes(of: bytes) {
			let boundsCheckedPtr = UnsafeRawBufferPointer(
				start: $0.baseAddress,
				count: Self.byteCount
			)
			return try body(boundsCheckedPtr)
		}
	}

	public func hash(into hasher: inout Hasher) {
		withUnsafeBytes { hasher.combine(bytes: $0) }
	}
}
