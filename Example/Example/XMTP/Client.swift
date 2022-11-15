//
//  Client.swift
//  xmtp-ios example
//
//  Created by Pat Nakajima on 11/11/22.
//

import CryptoSwift
import Foundation
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
	var account: web3.EthereumAccount

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

		let account = try! web3.EthereumAccount.importAccount(keyStorage: EthereumKeyLocalStorage(), privateKey: String(bytes: keys.identityKey.secp256k1Bytes), keystorePassword: "password")

		address = account.address.value
		conversations = Conversations()
		maxContentSize = Constants.maxContentSize
		self.apiClient = apiClient

		self.account = account
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

		print("GOT A RES \(res)")

		var contactBundle: Xmtp_MessageContents_ContactBundle?

		for envelope in res.envelopes {
			guard let data = Data(base64Encoded: envelope.message) else {
				continue
			}

			do {
				contactBundle = try Xmtp_MessageContents_ContactBundle(serializedData: data)
			} catch {
				if let publicKeyBundle = try? Xmtp_MessageContents_PublicKeyBundle(serializedData: data) {
					contactBundle = Xmtp_MessageContents_ContactBundle()
					contactBundle?.v1.keyBundle = publicKeyBundle
				}
			}

			guard let contactBundle else {
				continue
			}

			if contactBundle.v1.hasKeyBundle {
				return true
			}

			if contactBundle.v2.hasKeyBundle {
				return true
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
