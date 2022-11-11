//
//  Client.swift
//  xmtp-ios example
//
//  Created by Pat Nakajima on 11/11/22.
//

import Foundation
import WalletConnectSwift
import CryptoSwift

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

struct CodecRegistry {

}

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

struct Conversations {

}

protocol UnsignedPublicKey {
	var createdNs: Int { get }
	var secp256k1UncompressedBytes: [UInt8] { get }
}

struct SignedPublicKey: UnsignedPublicKey {
	var createdNs: Int
	var secp256k1UncompressedBytes: [UInt8]

	var keyBytes: [UInt8]
	var signature: Signature
}

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
		self.privateKeyBundle = bundle
	}
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
		self.legacyKeys = keys
		self.keys = PrivateKeyBundleV2.fromLegacyBundle(keys)

		self.address = keys.identityKey.publicKey.walletSignatureAddress()
		self.conversations = Conversations()
		self.maxContentSize = Constants.maxContentSize
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

	private static func loadOrCreateKeysFromOptions(options: ClientOptions, wallet: WalletConnectSwift.Client?, apiClient: ApiClient) async throws -> PrivateKeyBundleV1? {

		if wallet == nil && options.keystore.privateKeyOverride == nil {
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
}
