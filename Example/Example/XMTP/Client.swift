//
//  Client.swift
//  xmtp-ios example
//
//  Created by Pat Nakajima on 11/11/22.
//

import Foundation
import secp256k1
import SwiftProtobuf
import WalletConnectSwift
import web3
import XMTPProto

struct ContentTypeID {
	var authorityID: String
	var typeID: String
	var versionMajor: Int
	var versionMinor: Int
}

struct EncodedContent {
	var type: ContentTypeID
	var parameters: [String: String]
	var fallback: String?
	var compression: Int?
	var content: [UInt8]
}

struct CodecRegistry {}

protocol ContentCodec<T> {
	associatedtype T

	var contentType: ContentTypeID { get }
	func encode(content: T, registry: CodecRegistry) throws -> EncodedContent
	func decode(content: EncodedContent, registry: CodecRegistry) throws -> T
}

enum CodecError: Error {
	case unrecognizedEncoding(String)
	case decodingError(String)
}

struct Conversations {}

struct NetworkOptions {
	var env: Environment = .dev
	var apiURL: String?
	var appVersion: String?
}

struct ContentOptions {
	var codecs: [any ContentCodec] = [TextCodec()]
	var maxContentSize: Int = Constants.maxContentSize
}

enum KeyStoreType {
	case networkTopicStoreV1Store, staticStore
}

struct KeyStoreOptions {
	var keyStoreType: KeyStoreType = .networkTopicStoreV1Store
	var privateKeyOverride: [UInt8]?
}

struct LegacyOptions {
	var publishLegacyContact: Bool?
}

struct ClientOptions {
	var network = NetworkOptions()
	var content = ContentOptions()
	var keystore = KeyStoreOptions()
	var legacy = LegacyOptions()
}

enum ClientError: Error {
	case noKeyOrWalletFound
}

protocol KeyStore {
	func loadPrivateKeyBundle() async -> PrivateKeyBundleV1?
	func storePrivateKeyBundle(bundle: PrivateKeyBundleV1) async
}

class MemoryKeyStore: KeyStore {
	static var shared = MemoryKeyStore()
	var privateKeyBundle: PrivateKeyBundleV1?

	private init() {}

	func loadPrivateKeyBundle() async -> PrivateKeyBundleV1? {
		return privateKeyBundle
	}

	func storePrivateKeyBundle(bundle: PrivateKeyBundleV1) async {
		privateKeyBundle = bundle
	}
}

enum KeyBundle {
	case publicKeyBundle(Xmtp_MessageContents_PublicKeyBundle)
	case signedPublicKeyBundle(Xmtp_MessageContents_SignedPublicKeyBundle)
}

struct Client {
	var address: String
	var keys: PrivateKeyBundleV2
	var legacyKeys: PrivateKeyBundleV1
	var apiClient: ApiClient
	var contacts: Set<String> = []
	private var knownPublicKeyBundles: [String: PrivateKeyBundle] = [:]
	public private(set) var conversations: Conversations
	public private(set) var codecs: [String: any ContentCodec] = [:]
	public private(set) var maxContentSize: Int

	init(keys: PrivateKeyBundleV1, apiClient: ApiClient) {
		legacyKeys = keys
		self.keys = PrivateKeyBundleV2.fromLegacyBundle(keys)

		address = KeyUtil.generateAddress(from: Data(keys.identityKey.publicKey.secp256k1UncompressedBytes)).value
		conversations = Conversations()
		maxContentSize = Constants.maxContentSize
		self.apiClient = apiClient
	}

	static func create(wallet: WalletConnectSwift.Client?, options: ClientOptions? = nil) async throws -> Client {
		let options = options ?? ClientOptions()

		let apiClient = ApiClient(
			pathPrefix: options.network.env.rawValue,
			options: ApiClientOptions(appVersion: options.network.appVersion)
		)

		let legacyKeys = try await loadOrCreateKeysFromOptions(options: options, wallet: wallet, apiClient: apiClient)

		return Client(keys: legacyKeys!, apiClient: apiClient)
	}

	private static func loadOrCreateKeysFromOptions(options: ClientOptions, wallet: WalletConnectSwift.Client?, apiClient _: ApiClient) async throws -> PrivateKeyBundleV1? {
		if wallet == nil, options.keystore.privateKeyOverride == nil {
			throw ClientError.noKeyOrWalletFound
		}

		// TODO: FIXME use actual key store
		let store = MemoryKeyStore.shared

		return try await loadOrCreateKeysFromStore(wallet: wallet, store: store)
	}

	private static func loadOrCreateKeysFromStore(wallet: WalletConnectSwift.Client?, store: MemoryKeyStore) async throws -> PrivateKeyBundleV1? {
		if let bundle = await store.loadPrivateKeyBundle() {
			return bundle
		}

		guard let wallet else {
			throw ClientError.noKeyOrWalletFound
		}

		let keys = try await PrivateKeyBundleV1.generate(wallet: wallet)
		await store.storePrivateKeyBundle(bundle: keys)
		return keys
	}

	func canMessage(peerAddress: String) async -> Bool {
		guard let res = await getUserContactFromNetwork(apiClient: apiClient, peerAddress: peerAddress) else {
			return false
		}

		var contactBundle = Xmtp_MessageContents_ContactBundle()

		for envelope in res.envelopes {
			let data = envelope.message

			do {
				let publicKeyBundle = try Xmtp_MessageContents_PublicKeyBundle(serializedData: data)
				contactBundle.v1.keyBundle = publicKeyBundle
				print("GOT PUBLIC KEY BUNDLE FROM MESSAGE \(try! publicKeyBundle.jsonString())")
			} catch {
				print("ERROR GETTING PUBLIC KEY BUNDLE \(error)")
			}

			if !contactBundle.v1.keyBundle.identityKey.hasSignature {
				do {
					try contactBundle.merge(serializedData: data)
				} catch {
					print("Error trying to merge!")
				}
			}

			let v1Bundle = contactBundle.v1
			let v2Bundle = contactBundle.v2

			if !v1Bundle.keyBundle.hasIdentityKey, !v2Bundle.keyBundle.hasIdentityKey {
				print("NO KEYBUNDLES FOUND")
				continue
			}

			do {
				var signerKey = Xmtp_MessageContents_PublicKey()
				var signature = Data()

				if contactBundle.v2.keyBundle.identityKey.hasSignature {
					print("V2 BUNDLE: \(try! v2Bundle.jsonString())")
					let bundleKey = v2Bundle.keyBundle.identityKey
					signerKey = try Xmtp_MessageContents_PublicKey(serializedData: bundleKey.keyBytes)
					if bundleKey.signature.walletEcdsaCompact.bytes.count > 0 {
						signature = bundleKey.signature.walletEcdsaCompact.bytes + [UInt8(bundleKey.signature.walletEcdsaCompact.recovery)]
					} else {
						signature = bundleKey.signature.ecdsaCompact.bytes + [UInt8(bundleKey.signature.ecdsaCompact.recovery)]
					}
				} else {
					print("V1 BUNDLE: \(try! v1Bundle.jsonString())")
					let bundleKey = v1Bundle.keyBundle.identityKey
					signerKey = Xmtp_MessageContents_PublicKey()
					signerKey.timestamp = bundleKey.timestamp
					signerKey.secp256K1Uncompressed = bundleKey.secp256K1Uncompressed

					if bundleKey.signature.walletEcdsaCompact.bytes.count > 0 {
						signature = bundleKey.signature.walletEcdsaCompact.bytes + [UInt8(bundleKey.signature.walletEcdsaCompact.recovery)]
					} else {
						signature = bundleKey.signature.ecdsaCompact.bytes + [UInt8(bundleKey.signature.ecdsaCompact.recovery)]
					}
				}

				let msg = WalletSigner.identitySigRequestText(keyBytes: try! signerKey.serializedData())
				let decoratedBytes = "\u{19}Ethereum Signed Message:\n\(msg.count)\(msg)".data(using: .utf8)!
				let digest = decoratedBytes.web3.keccak256

				let recovered = try KeyUtil.recoverPublicKey(message: digest, signature: signature)
				print("recovered IS \(recovered.debugDescription)")

				let walletAddress = recovered.description

//				let walletSigAddress = KeyUtil.generateAddress(from: key).value

				print("WALLET SIG ADDRESS: \(walletAddress)")
				return walletAddress.lowercased() == peerAddress.lowercased()
			} catch {
				print("error finding wallet sig addr \(error)")
				return false
			}
		}

		print("NO GOOD ENVELOPES")

		return false
	}

	func getUserContactFromNetwork(apiClient: ApiClient, peerAddress: String) async -> Xmtp_MessageApi_V1_QueryResponse? {
		let name = "contact-\(peerAddress)"
		let topic = "/xmtp/0/\(name)/proto"

		var params = QueryParams(contentTopics: [topic])

		do {
			return try await apiClient.queryIteratePages(params: params)
		} catch {
			return nil
		}
	}
}
