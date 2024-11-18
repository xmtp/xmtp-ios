import Foundation
import secp256k1
import LibXMTP
import CryptoSwift

enum KeyUtilError: Error {
	case invalidContext
	case privateKeyInvalid
	case unknownError
	case signatureFailure
	case signatureParseFailure
	case badArguments
	case parseError
}

enum KeyUtilx {
	static func generatePublicKey(from data: Data) throws -> Data {
		let vec = try LibXMTP.publicKeyFromPrivateKeyK256(privateKeyBytes: data)
		return Data(vec)
	}

	static func recoverPublicKeySHA256(from data: Data, message: Data) throws -> Data {
		return try Data(LibXMTP.recoverPublicKeyK256Sha256(message: message, signature: data))
	}

	static func recoverPublicKeyKeccak256(from data: Data, message: Data) throws -> Data {
		return Data(try LibXMTP.recoverPublicKeyK256Keccak256(message: message, signature: data))
	}

	static func sign(message: Data, with privateKey: Data, hashing: Bool) throws -> Data {
		guard let ctx = secp256k1_context_create(UInt32(SECP256K1_CONTEXT_SIGN | SECP256K1_CONTEXT_VERIFY)) else {
			throw KeyUtilError.invalidContext
		}

		defer {
			secp256k1_context_destroy(ctx)
		}

		let msgData = hashing ? message.sha3(.keccak256) : message
		let msg = (msgData as NSData).bytes.assumingMemoryBound(to: UInt8.self)
		let privateKeyPtr = (privateKey as NSData).bytes.assumingMemoryBound(to: UInt8.self)
		let signaturePtr = UnsafeMutablePointer<secp256k1_ecdsa_recoverable_signature>.allocate(capacity: 1)
		defer {
			signaturePtr.deallocate()
		}
		guard secp256k1_ecdsa_sign_recoverable(ctx, signaturePtr, msg, privateKeyPtr, nil, nil) == 1 else {
			throw KeyUtilError.signatureFailure
		}

		let outputPtr = UnsafeMutablePointer<UInt8>.allocate(capacity: 64)
		defer {
			outputPtr.deallocate()
		}
		var recid: Int32 = 0
		secp256k1_ecdsa_recoverable_signature_serialize_compact(ctx, outputPtr, &recid, signaturePtr)

		let outputWithRecidPtr = UnsafeMutablePointer<UInt8>.allocate(capacity: 65)
		defer {
			outputWithRecidPtr.deallocate()
		}
		outputWithRecidPtr.update(from: outputPtr, count: 64)
		outputWithRecidPtr.advanced(by: 64).pointee = UInt8(recid)

		let signature = Data(bytes: outputWithRecidPtr, count: 65)

		return signature
	}

	static func generateAddress(from publicKey: Data) -> String {
		let publicKeyData = publicKey.count == 64 ? publicKey : publicKey[1 ..< publicKey.count]

		let hash = publicKeyData.sha3(.keccak256)
		let address = hash.subdata(in: 12 ..< hash.count)
		return "0x" + address.toHex
	}

	static func recoverPublicKey(message: Data, signature: Data) throws -> Data {
		guard let ctx = secp256k1_context_create(UInt32(SECP256K1_CONTEXT_SIGN | SECP256K1_CONTEXT_VERIFY)) else {
			throw KeyUtilError.invalidContext
		}
		defer { secp256k1_context_destroy(ctx) }

		// get recoverable signature
		let signaturePtr = UnsafeMutablePointer<secp256k1_ecdsa_recoverable_signature>.allocate(capacity: 1)
		defer { signaturePtr.deallocate() }
    if signature.count < 65 {
        throw KeyUtilError.signatureParseFailure
    }

		let serializedSignature = Data(signature[0 ..< 64])
		var v = Int32(signature[64])
		if v >= 27, v <= 30 {
			v -= 27
		} else if v >= 31, v <= 34 {
			v -= 31
		} else if v >= 35, v <= 38 {
			v -= 35
		}

    try serializedSignature.withUnsafeBytes {
        guard let baseAddress = $0.bindMemory(to: UInt8.self).baseAddress else {
            throw KeyUtilError.signatureParseFailure // or a more specific error for "empty buffer"
        }
        if v > 3 {
            throw KeyUtilError.signatureParseFailure
        }
        guard secp256k1_ecdsa_recoverable_signature_parse_compact(ctx, signaturePtr, baseAddress, v) == 1 else {
            throw KeyUtilError.signatureParseFailure
        }
    }
    
    let pubkey = UnsafeMutablePointer<secp256k1_pubkey>.allocate(capacity: 1)
		defer { pubkey.deallocate() }

        try message.withUnsafeBytes {
            guard let baseAddress = $0.bindMemory(to: UInt8.self).baseAddress else {
                throw KeyUtilError.signatureFailure // Consider throwing a more specific error
            }

            guard secp256k1_ecdsa_recover(ctx, pubkey, signaturePtr, baseAddress) == 1 else {
                throw KeyUtilError.signatureFailure
            }
        }

		var size = 65
        var rv = Data(count: size)
        rv.withUnsafeMutableBytes { buffer -> Void in
            guard let baseAddress = buffer.bindMemory(to: UInt8.self).baseAddress else {
                return // Optionally, handle the error or log this condition
            }
            secp256k1_ec_pubkey_serialize(ctx, baseAddress, &size, pubkey, UInt32(SECP256K1_EC_UNCOMPRESSED))
        }

		return rv
	}
}
