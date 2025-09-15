import CryptoSwift
import Foundation
import LibXMTP

enum KeyUtilError: Error {
	case invalidContext
	case privateKeyInvalid
	case unknownError
	case signatureFailure
	case signatureParseFailure
	case badArguments
	case parseError
}

enum SignatureError: Error, CustomStringConvertible {
	case invalidMessage

	var description: String {
		return "SignatureError.invalidMessage"
	}
}

enum KeyUtilx {
	static func generatePublicKey(from data: Data) throws -> Data {
        try LibXMTP.ethereumGeneratePublicKey(privateKey32: data)
	}
    
    static func sign(message: Data, with privateKey: Data, hashing: Bool) throws -> Data {
        try LibXMTP.ethereumSignRecoverable(msg: message, privateKey32: privateKey, hashing: hashing)
      }
      static func generateAddress(from publicKey: Data) throws -> String {
          try LibXMTP.ethereumAddressFromPubkey(pubkey: publicKey)
      }
      static func ethHash(_ message: String) throws -> Data {
          try LibXMTP.ethereumHashPersonal(message: message)
      }
}
