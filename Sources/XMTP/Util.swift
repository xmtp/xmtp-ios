//
//  Util.swift
//  
//
//  Created by Pat Nakajima on 11/20/22.
//

import Foundation
import CryptoSwift

enum Util {
	static func keccak256Digest(_ data: Data) -> Keccak256Digest {
		return Keccak256Digest(keccak256(data).bytes)
	}

	static func keccak256(_ data: Data) -> Data {
		return Data(SHA3(variant: .keccak256).calculate(for: data.bytes))
	}
}
