# XMTP-iOS

This SDK is in Developer Preview status. Software in this status:

- Is not formally supported
- Will change without warning
- May not be backward compatible
- We do NOT recommend using Developer Preview software in production apps.

Specifically, this SDK is missing this functionality:

- Specifying `apiUrl`, `keyStoreType`, `codecs`, `maxContentSize` and `appVersion` when creating a `Client`
- Content types other than text
- Streaming all messages from all conversations
- Message content compression

Follow along in the [tracking issue](https://github.com/xmtp/xmtp-ios/issues/7) for updates.

![Test](https://github.com/xmtp/xmtp-ios/actions/workflows/test.yml/badge.svg)
![Lint](https://github.com/xmtp/xmtp-ios/actions/workflows/lint.yml/badge.svg)
![Status](https://camo.githubusercontent.com/5bb5892781bbf711c7fe5eba3328e9e15a767de87c587d3fb65f2fd7e1f4ae72/68747470733a2f2f696d672e736869656c64732e696f2f62616467652f50726f6a6563745f5374617475732d446576656c6f7065725f507265766965772d726564)

![x-red-sm](https://user-images.githubusercontent.com/510695/163488403-1fb37e86-c673-4b48-954e-8460ae4d4b05.png)

**XMTP client SDK for iOS applications**

`xmtp-ios` provides a Swift implementation of an XMTP client for use with iOS applications.

Build with `xmtp-ios` to provide messaging between blockchain wallet addresses, delivering on use cases such as wallet-to-wallet messaging and dapp-to-wallet notifications.

For a demonstration of the core concepts and capabilities of the `xmtp-ios` client SDK, see the [Example project](https://github.com/xmtp/xmtp-ios/tree/main/XMTPiOSExample/XMTPiOSExample).

`xmtp-ios` has not undergone a formal security audit.

To learn more about XMTP and get answers to frequently asked questions, see [FAQ about XMTP](https://xmtp.org/docs/dev-concepts/faq).

## Installation

### Install with Swift Package Manager

Use Xcode to add to the project (File -> Swift Packages) or add this to your Package.swift file:

```swift
.package(url: "https://github.com/xmtp/xmtp-ios.swift", branch: "main")
```

## Usage

The API revolves around a network Client that allows retrieving and sending messages to other network participants. A Client must be connected to a wallet on startup. If this is the very first time the Client is created, the client will generate a key bundle that is used to encrypt and authenticate messages. The key bundle persists encrypted in the network using a wallet signature. The public side of the key bundle is also regularly advertised on the network to allow parties to establish shared encryption keys. All this happens transparently, without requiring any additional code.

```swift
import XMTP

// You'll want to replace this with a wallet from your application.
let account = try PrivateKey.generate()

// Create the client with your wallet. This will connect to the XMTP development network by default.
// The account is anything that conforms to the `XMTP.SigningKey` protocol.
let client = try await Client.create(account: account)

// Start a conversation with XMTP
let conversation = try await client.conversations.newConversation(with: "0x3F11b27F323b62B159D2642964fa27C46C841897")

// Load all messages in the conversation
let messages = try await conversation.messages()
// Send a message
try await conversation.send(content: "gm")
// Listen for new messages in the conversation
for try await message in conversation.streamMessages() {
  print("\(message.senderAddress): \(message.body)")
}
```

### Creating a Client

A Client is created with `Client.create(account: SigningKey) async throws -> Client` that requires passing in an object capable of creating signatures on your behalf. The Client will request a signature in 2 cases:

1. To sign the newly generated key bundle. This happens only the very first time when key bundle is not found in storage.
2. To sign a random salt used to encrypt the key bundle in storage. This happens every time the Client is started (including the very first time).

**Important:** The Client connects to the XMTP `dev` environment by default. [Use `ClientOptions`](#configuring-the-client) to change this and other parameters of the network connection.

```swift
import XMTP

// Create the client with an `SigningKey` from your application
let client = try await Client.create(account: account)
```

#### Configuring the Client

The client's network connection and key storage method can be configured with these optional parameters of `Client.create`:

| Parameter | Default | Description                                                                                                                                                                                                                                                                     |
| --------- | ------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| env       | `dev`   | Connect to the specified XMTP network environment. Valid values include `.dev`, `.production`, or `.local`. For important details about working with these environments, see [XMTP `production` and `dev` network environments](#xmtp-production-and-dev-network-environments). |

```swift
// Configure the client to use the production network
let clientOptions = ClientOptions(api: .init(env: .production))
let client = try await Client.create(account: account, options: clientOptions)
```

**Note: that the `apiUrl`, `keyStoreType`, `codecs`, `maxContentSize` and `appVersion` parameters from the JavaScript SDK are not yet supported.**

### Conversations

Most of the time, when interacting with the network, you'll want to do it through `conversations`. Conversations are between two wallets.

```swift
import XMTP
// Create the client with a wallet from your application
let client = try await Client.create(account: account)
let conversations = try await client.conversations.list()
```

#### List existing conversations

You can get a list of all conversations that have had 1 or more messages exchanged in the last 30 days.

```swift
let allConversations = try await client.conversations.list()

for conversation in allConversations {
  print("Saying GM to \(conversation.peerAddress)")
  try await conversation.send(content: "gm")
}
```

#### Listen for new conversations

You can also listen for new conversations being started in real-time. This will allow applications to display incoming messages from new contacts.

_Warning: this stream will continue infinitely. To end the stream, break from the loop`_

```swift
for try await conversation in client.conversations.stream() {
  print("New conversation started with \(conversation.peerAddress)")

  // Say hello to your new friend
  try await conversation.send(content: "Hi there!")

  // Break from the loop to stop listening
  break
}
```

#### Start a new conversation

You can create a new conversation with any Ethereum address on the XMTP network.

```swift
let newConversation = try await client.conversations.newConversation(with: "0x3F11b27F323b62B159D2642964fa27C46C841897")
```

#### Sending messages

To be able to send a message, the recipient must have already started their Client at least once and consequently advertised their key bundle on the network. Messages are addressed using wallet addresses. The message payload must be a plain string.

**Note: Other types of content are currently not supported.**

```swift
let conversation = try await client.conversations.newConversation(with: "0x3F11b27F323b62B159D2642964fa27C46C841897")
try await conversation.send(content: "Hello world")
```

#### List messages in a conversation

You can receive the complete message history in a conversation by calling `conversation.messages()`

```swift
for conversation in client.conversations.list() {
  let messagesInConversation = try await conversation.messages()
}
```

#### List messages in a conversation with pagination

It may be helpful to retrieve and process the messages in a conversation page by page. You can do this by calling `conversation.messages(limit: Int, before: Date)` which will return the specified number of messages sent before that time.

```swift
let conversation = try await clienet.conversations.newConversation(with: "0x3F11b27F323b62B159D2642964fa27C46C841897")

let messages = conversation.messages(limit: 25)
let nextPage = conversation.messages(limit: 25, before: messages[0].sent)
```

#### Listen for new messages in a conversation

You can listen for any new messages (incoming or outgoing) in a conversation by calling `conversation.streamMessages()`.

A successfully received message (that makes it through the decoding and decryption without throwing) can be trusted to be authentic, i.e. that it was sent by the owner of the `message.senderAddress` wallet and that it wasn't modified in transit. The `message.sent` timestamp can be trusted to have been set by the sender.

The Stream returned by the `stream` methods is an asynchronous iterator and as such usable by a for-await-of loop. Note however that it is by its nature infinite, so any looping construct used with it will not terminate, unless the termination is explicitly initiated (by breaking the loop)

```swift
let conversation = try await client.conversations.newConversation(with: "0x3F11b27F323b62B159D2642964fa27C46C841897")

for try await message in conversation.streamMessages() {
  if message.senderAddress == client.address {
    // This message was sent from me
    continue
  }

  print("New message from \(message.senderAddress): \(message.body)")
}
```

**This package does not currently include xmtp-js's `streamAllMessages()` functionality.**

#### Handling multiple conversations with the same blockchain address

With XMTP, you can have multiple ongoing conversations with the same blockchain address. For example, you might want to have a conversation scoped to your particular application, or even a conversation scoped to a particular item in your application.

To accomplish this, you can pass a context with a `conversationId` when you are creating a conversation. We recommend conversation IDs start with a domain, to help avoid unwanted collisions between your application and other apps on the XMTP network.

```swift
// Start a scoped conversation with ID mydomain.xyz/foo
let conversation1 = try await client.conversations.newConversation(
  with: "0x3F11b27F323b62B159D2642964fa27C46C841897",
  context: .init(conversationID: "mydomain.xyz/foo")
)

// Start a scoped conversation with ID mydomain.xyz/bar. And add some metadata
let conversation2 = try await client.conversations.newConversation(
  with: "0x3F11b27F323b62B159D2642964fa27C46C841897",
  context: .init(conversationID: "mydomain.xyz/bar", metadata: ["title": "Bar conversation"])
)

// Get all the conversations
let conversations = try await client.conversations.list()

// Filter for the ones from your application
let myAppConversations = conversations.filter {
  guard let conversationID = $0.context?.conversationID else {
    return false
  }

  return conversationID.hasPrefix("mydomain.xyz/")
}
```

#### Compression

This package currently does not support message content compression.

## 🏗 **Breaking revisions**

Because `xmtp-ios` is in active development, you should expect breaking revisions that might require you to adopt the latest SDK release to enable your app to continue working as expected.

XMTP communicates about breaking revisions in the [XMTP Discord community](https://discord.gg/xmtp), providing as much advance notice as possible. Additionally, breaking revisions in an `xmtp-ios` release are described on the [Releases page](https://github.com/xmtp/xmtp-ios/releases).

### Deprecation

Older versions of the SDK will eventually become deprecated, which means:

1. The network will not support and eventually actively reject connections from clients using deprecated versions.
2. Bugs will not be fixed in deprecated versions.

Following table shows the deprecation schedule.

| Announced  | Effective  | Minimum Version | Rationale                                                                                                         |
| ---------- | ---------- | --------------- | ----------------------------------------------------------------------------------------------------------------- |
| 2022-08-18 | 2022-11-08 | v6.0.0          | XMTP network will stop supporting the Waku/libp2p based client interface in favor of the new GRPC based interface |

Issues and PRs are welcome in accordance with our [contribution guidelines](https://github.com/xmtp/xmtp-ios/blob/main/CONTRIBUTING.md).

## XMTP `production` and `dev` network environments

XMTP provides both `production` and `dev` network environments to support the development phases of your project.

The `production` and `dev` networks are completely separate and not interchangeable.
For example, for a given blockchain account address, its XMTP identity on `dev` network is completely distinct from its XMTP identity on the `production` network, as are the messages associated with these identities. In addition, XMTP identities and messages created on the `dev` network can't be accessed from or moved to the `production` network, and vice versa.

**Important:** When you [create a client](#creating-a-client), it connects to the XMTP `dev` environment by default. To learn how to use the `env` parameter to set your client's network environment, see [Configuring the Client](#configuring-the-client).

The `env` parameter accepts one of three valid values: `dev`, `production`, or `local`. Here are some best practices for when to use each environment:

- `dev`: Use to have a client communicate with the `dev` network. As a best practice, set `env` to `dev` while developing and testing your app. Follow this best practice to isolate test messages to `dev` inboxes.

- `production`: Use to have a client communicate with the `production` network. As a best practice, set `env` to `production` when your app is serving real users. Follow this best practice to isolate messages between real-world users to `production` inboxes.

- `local`: Use to have a client communicate with an XMTP node you are running locally. For example, an XMTP node developer can set `env` to `local` to generate client traffic to test a node running locally.

The `production` network is configured to store messages indefinitely. XMTP may occasionally delete messages and keys from the `dev` network, and will provide advance notice in the [XMTP Discord community](https://discord.gg/xmtp).
