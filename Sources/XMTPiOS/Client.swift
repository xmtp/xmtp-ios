import Foundation
import LibXMTP

public typealias PreEventCallback = () async throws -> Void

public enum ClientError: Error, CustomStringConvertible, LocalizedError {
	case creationError(String)
	case missingInboxId

	public var description: String {
		switch self {
		case .creationError(let err):
			return "ClientError.creationError: \(err)"
		case .missingInboxId:
			return "ClientError.missingInboxId"
		}
	}

	public var errorDescription: String? {
		return description
	}
}

/// Specify configuration options for creating a ``Client``.
public struct ClientOptions {
	// Specify network options
	public struct Api {
		/// Specify which XMTP network to connect to. Defaults to ``.dev``
		public var env: XMTPEnvironment = .dev

		/// Specify whether the API client should use TLS security. In general this should only be false when using the `.local` environment.
		public var isSecure: Bool = true

		/// /// Optional: Specify self-reported version e.g. XMTPInbox/v1.0.0.
		public var appVersion: String?

		public init(
			env: XMTPEnvironment = .dev, isSecure: Bool = true,
			appVersion: String? = nil
		) {
			self.env = env
			self.isSecure = isSecure
			self.appVersion = appVersion
		}
	}

	public var api = Api()
	public var codecs: [any ContentCodec] = []

	/// `preAuthenticateToInboxCallback` will be called immediately before an Auth Inbox signature is requested from the user
	public var preAuthenticateToInboxCallback: PreEventCallback?

	public var dbEncryptionKey: Data
	public var dbDirectory: String?
	public var historySyncUrl: String?

	public init(
		api: Api = Api(),
		codecs: [any ContentCodec] = [],
		preAuthenticateToInboxCallback: PreEventCallback? = nil,
		dbEncryptionKey: Data,
		dbDirectory: String? = nil,
		historySyncUrl: String? = nil
	) {
		self.api = api
		self.codecs = codecs
		self.preAuthenticateToInboxCallback = preAuthenticateToInboxCallback
		self.dbEncryptionKey = dbEncryptionKey
		self.dbDirectory = dbDirectory
		if historySyncUrl == nil {
			switch api.env {
			case .production:
				self.historySyncUrl =
					"https://message-history.production.ephemera.network/"
			case .local:
				self.historySyncUrl = "http://localhost:5558"
			default:
				self.historySyncUrl =
					"https://message-history.dev.ephemera.network/"
			}
		} else {
			self.historySyncUrl = historySyncUrl
		}
	}
}

public final class Client {
	public let address: String
	public let inboxID: String
	public let libXMTPVersion: String = getVersionInfo()
	public let dbPath: String
	public let installationID: String
	public let environment: XMTPEnvironment
	private let ffiClient: LibXMTP.FfiXmtpClient

	public lazy var conversations: Conversations = .init(
		client: self, ffiConversations: ffiClient.conversations())
	public lazy var preferences: PrivatePreferences = .init(
		client: self, ffiClient: ffiClient)

	var codecRegistry = CodecRegistry()

	public func register(codec: any ContentCodec) {
		codecRegistry.register(codec: codec)
	}

	static func initializeClient(
		accountAddress: String,
		options: ClientOptions,
		signingKey: SigningKey?,
		inboxId: String
	) async throws -> Client {
		let (libxmtpClient, dbPath) = try await initFFiClient(
			accountAddress: accountAddress.lowercased(),
			options: options,
			signingKey: signingKey,
			inboxId: inboxId
		)

		let client = try Client(
			address: accountAddress.lowercased(),
			ffiClient: libxmtpClient,
			dbPath: dbPath,
			installationID: libxmtpClient.installationId().toHex,
			inboxID: libxmtpClient.inboxId(),
			environment: options.api.env
		)

		// Register codecs
		for codec in options.codecs {
			client.register(codec: codec)
		}

		return client
	}

	public static func create(account: SigningKey, options: ClientOptions)
		async throws -> Client
	{
		let accountAddress = account.address.lowercased()
		let inboxId = try await getOrCreateInboxId(
			api: options.api, address: accountAddress)

		return try await initializeClient(
			accountAddress: accountAddress,
			options: options,
			signingKey: account,
			inboxId: inboxId
		)
	}

	public static func build(address: String, options: ClientOptions)
		async throws -> Client
	{
		let accountAddress = address.lowercased()
		let inboxId = try await getOrCreateInboxId(
			api: options.api, address: accountAddress)

		return try await initializeClient(
			accountAddress: accountAddress,
			options: options,
			signingKey: nil,
			inboxId: inboxId
		)
	}

	private static func initFFiClient(
		accountAddress: String,
		options: ClientOptions,
		signingKey: SigningKey?,
		inboxId: String
	) async throws -> (FfiXmtpClient, String) {
		let address = accountAddress.lowercased()

		let mlsDbDirectory = options.dbDirectory
		var directoryURL: URL
		if let mlsDbDirectory = mlsDbDirectory {
			let fileManager = FileManager.default
			directoryURL = URL(
				fileURLWithPath: mlsDbDirectory, isDirectory: true)
			// Check if the directory exists, if not, create it
			if !fileManager.fileExists(atPath: directoryURL.path) {
				do {
					try fileManager.createDirectory(
						at: directoryURL, withIntermediateDirectories: true,
						attributes: nil)
				} catch {
					throw ClientError.creationError(
						"Failed db directory \(mlsDbDirectory)")
				}
			}
		} else {
			directoryURL = URL.documentsDirectory
		}

		let alias = "xmtp-\(options.api.env.rawValue)-\(inboxId).db3"
		let dbURL = directoryURL.appendingPathComponent(alias).path

		let ffiClient = try await LibXMTP.createClient(
			logger: XMTPLogger(),
			host: options.api.env.url,
			isSecure: options.api.env.isSecure == true,
			db: dbURL,
			encryptionKey: options.dbEncryptionKey,
			inboxId: inboxId,
			accountAddress: address,
			nonce: 0,
			legacySignedPrivateKeyProto: nil,
			historySyncUrl: options.historySyncUrl
		)

		try await options.preAuthenticateToInboxCallback?()
		if let signatureRequest = ffiClient.signatureRequest() {
			if let signingKey = signingKey {
				do {
					try await handleSignature(
						for: signatureRequest, signingKey: signingKey)
					try await ffiClient.registerIdentity(
						signatureRequest: signatureRequest)
				} catch {
					throw ClientError.creationError(
						"Failed to sign the message: \(error.localizedDescription)"
					)
				}
			} else {
				throw ClientError.creationError(
					"No v3 keys found, you must pass a SigningKey in order to enable alpha MLS features"
				)
			}
		}

		return (ffiClient, dbURL)
	}

	private static func handleSignature(
		for signatureRequest: FfiSignatureRequest,
		signingKey: SigningKey
	) async throws {
		if signingKey.type == .SCW {
			guard let chainId = signingKey.chainId else {
				throw ClientError.creationError(
					"Chain id must be present to sign Smart Contract Wallet")
			}
			let signedData = try await signingKey.signSCW(
				message: signatureRequest.signatureText())
			try await signatureRequest.addScwSignature(
				signatureBytes: signedData,
				address: signingKey.address.lowercased(),
				chainId: UInt64(chainId),
				blockNumber: signingKey.blockNumber.flatMap {
					$0 >= 0 ? UInt64($0) : nil
				}
			)
		} else {
			let signedData = try await signingKey.sign(
				message: signatureRequest.signatureText())
			try await signatureRequest.addEcdsaSignature(
				signatureBytes: signedData.rawData)
		}
	}

	public static func getOrCreateInboxId(
		api: ClientOptions.Api, address: String
	) async throws -> String {
		var inboxId: String
		do {
			inboxId =
				try await getInboxIdForAddress(
					logger: XMTPLogger(),
					host: api.env.url,
					isSecure: api.env.isSecure == true,
					accountAddress: address.lowercased()
				)
				?? generateInboxId(
					accountAddress: address.lowercased(), nonce: 0)
		} catch {
			inboxId = try generateInboxId(
				accountAddress: address.lowercased(), nonce: 0)
		}
		return inboxId
	}

	init(
		address: String, ffiClient: LibXMTP.FfiXmtpClient, dbPath: String,
		installationID: String, inboxID: String, environment: XMTPEnvironment
	) throws {
		self.address = address
		self.ffiClient = ffiClient
		self.dbPath = dbPath
		self.installationID = installationID
		self.inboxID = inboxID
		self.environment = environment
	}

	public func addAccount(recoveryAccount: SigningKey, newAccount: SigningKey)
		async throws
	{
		let signatureRequest = try await ffiClient.addWallet(
			existingWalletAddress: recoveryAccount.address.lowercased(),
			newWalletAddress: newAccount.address.lowercased())
		do {
			try await Client.handleSignature(
				for: signatureRequest, signingKey: recoveryAccount)
			try await Client.handleSignature(
				for: signatureRequest, signingKey: newAccount)
			try await ffiClient.applySignatureRequest(
				signatureRequest: signatureRequest)
		} catch {
			throw ClientError.creationError(
				"Failed to sign the message: \(error.localizedDescription)")
		}
	}

	public func removeAccount(
		recoveryAccount: SigningKey, addressToRemove: String
	) async throws {
		let signatureRequest = try await ffiClient.revokeWallet(
			walletAddress: addressToRemove.lowercased())
		do {
			try await Client.handleSignature(
				for: signatureRequest, signingKey: recoveryAccount)
			try await ffiClient.applySignatureRequest(
				signatureRequest: signatureRequest)
		} catch {
			throw ClientError.creationError(
				"Failed to sign the message: \(error.localizedDescription)")
		}
	}

	public func revokeAllOtherInstallations(signingKey: SigningKey) async throws
	{
		let signatureRequest = try await ffiClient.revokeAllOtherInstallations()
		do {
			try await Client.handleSignature(
				for: signatureRequest, signingKey: signingKey)
			try await ffiClient.applySignatureRequest(
				signatureRequest: signatureRequest)
		} catch {
			throw ClientError.creationError(
				"Failed to sign the message: \(error.localizedDescription)")
		}
	}

	public func canMessage(address: String) async throws -> Bool {
		let canMessage = try await ffiClient.canMessage(accountAddresses: [
			address
		])
		return canMessage[address.lowercased()] ?? false
	}

	public func canMessage(addresses: [String]) async throws -> [String: Bool] {
		return try await ffiClient.canMessage(accountAddresses: addresses)
	}

	public func deleteLocalDatabase() throws {
		try dropLocalDatabaseConnection()
		let fm = FileManager.default
		try fm.removeItem(atPath: dbPath)
	}

	@available(
		*, deprecated,
		message:
			"This function is delicate and should be used with caution. App will error if database not properly reconnected. See: reconnectLocalDatabase()"
	)
	public func dropLocalDatabaseConnection() throws {
		try ffiClient.releaseDbConnection()
	}

	public func reconnectLocalDatabase() async throws {
		try await ffiClient.dbReconnect()
	}

	public func inboxIdFromAddress(address: String) async throws -> String? {
		return try await ffiClient.findInboxId(address: address.lowercased())
	}

	public func signWithInstallationKey(message: String) throws -> Data {
		return try ffiClient.signWithInstallationKey(text: message)
	}

	public func findGroup(groupId: String) throws -> Group? {
		do {
			return Group(
				ffiGroup: try ffiClient.conversation(
					conversationId: groupId.hexToData), client: self)
		} catch {
			return nil
		}
	}

	public func findConversation(conversationId: String) throws -> Conversation?
	{
		do {
			let conversation = try ffiClient.conversation(
				conversationId: conversationId.hexToData)
			return try conversation.toConversation(client: self)
		} catch {
			return nil
		}
	}

	public func findConversationByTopic(topic: String) throws -> Conversation? {
		do {
			let regexPattern = #"/xmtp/mls/1/g-(.*?)/proto"#
			if let regex = try? NSRegularExpression(pattern: regexPattern) {
				let range = NSRange(location: 0, length: topic.utf16.count)
				if let match = regex.firstMatch(
					in: topic, options: [], range: range)
				{
					let conversationId = (topic as NSString).substring(
						with: match.range(at: 1))
					let conversation = try ffiClient.conversation(
						conversationId: conversationId.hexToData)
					return try conversation.toConversation(client: self)
				}
			}
		} catch {
			return nil
		}
		return nil
	}

	public func findDmByInboxId(inboxId: String) throws -> Dm? {
		do {
			let conversation = try ffiClient.dmConversation(
				targetInboxId: inboxId)
			return Dm(ffiConversation: conversation, client: self)
		} catch {
			return nil
		}
	}

	public func findDmByAddress(address: String) async throws -> Dm? {
		guard let inboxId = try await inboxIdFromAddress(address: address)
		else {
			throw ClientError.creationError("No inboxId present")
		}
		return try findDmByInboxId(inboxId: inboxId)
	}

	public func findMessage(messageId: String) throws -> Message? {
		do {
			return Message(
				client: self,
				ffiMessage: try ffiClient.message(
					messageId: messageId.hexToData))
		} catch {
			return nil
		}
	}

	public func requestMessageHistorySync() async throws {
		try await ffiClient.sendSyncRequest(kind: .messages)
	}

	public func syncConsent() async throws {
		try await ffiClient.sendSyncRequest(kind: .consent)
	}

	public func inboxState(refreshFromNetwork: Bool) async throws -> InboxState
	{
		return InboxState(
			ffiInboxState: try await ffiClient.inboxState(
				refreshFromNetwork: refreshFromNetwork))
	}

	public func inboxStatesForInboxIds(
		refreshFromNetwork: Bool, inboxIds: [String]
	) async throws -> [InboxState] {
		return try await ffiClient.addressesFromInboxId(
			refreshFromNetwork: refreshFromNetwork, inboxIds: inboxIds
		).map { InboxState(ffiInboxState: $0) }
	}
}
