import Foundation
import secp256k1Swift
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
		// Hash the message if required
		let msgData = hashing ? message.sha3(.keccak256) : message

		// Ensure the private key is valid
		guard privateKey.count == 32 else {
			throw KeyUtilError.privateKeyInvalid
		}

		// Create a Signing.PrivateKey instance
		guard let signingKey = try? secp256k1.Signing.PrivateKey(rawRepresentation: privateKey) else {
			throw KeyUtilError.privateKeyInvalid
		}
		

		// Sign the message
		guard let signature = try? signingKey.ecdsa.signature(for: msgData) else {
			throw KeyUtilError.signatureFailure
		}

		// Obtain the compact signature and recovery ID
		let compactSignature = try signature.compactRepresentation
		let recoveryID: UInt8  = 0

		// Combine the compact signature and recovery ID
		var signatureWithRecid = Data(compactSignature)
		signatureWithRecid.append(recoveryID)

		return signatureWithRecid
	}

	static func generateAddress(from publicKey: Data) -> String {
		let publicKeyData = publicKey.count == 64 ? publicKey : publicKey[1 ..< publicKey.count]

		let hash = publicKeyData.sha3(.keccak256)
		let address = hash.subdata(in: 12 ..< hash.count)
		return "0x" + address.toHex
	}
}
