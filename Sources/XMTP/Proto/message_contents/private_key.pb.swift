// DO NOT EDIT.
// swift-format-ignore-file
//
// Generated by the Swift generator plugin for the protocol buffer compiler.
// Source: message_contents/private_key.proto
//
// For information on using the generated types, please see the documentation:
//   https://github.com/apple/swift-protobuf/

/// Private Key Storage
///
/// Following definitions are not used in the protocol, instead
/// they provide a way for encoding private keys for storage.

import Foundation
import SwiftProtobuf

// If the compiler emits an error on this type, it is because this file
// was generated by a version of the `protoc` Swift plug-in that is
// incompatible with the version of SwiftProtobuf to which you are linking.
// Please ensure that you are building against the same version of the API
// that was used to generate this file.
fileprivate struct _GeneratedWithProtocGenSwiftVersion: SwiftProtobuf.ProtobufAPIVersionCheck {
  struct _2: SwiftProtobuf.ProtobufAPIVersion_2 {}
  typealias Version = _2
}

/// PrivateKey generalized to support different key types
public struct Xmtp_MessageContents_SignedPrivateKey {
  // SwiftProtobuf.Message conformance is added in an extension below. See the
  // `Message` and `Message+*Additions` files in the SwiftProtobuf library for
  // methods supported on all messages.

  /// time the key was created
  public var createdNs: UInt64 = 0

  /// private key
  public var union: Xmtp_MessageContents_SignedPrivateKey.OneOf_Union? = nil

  public var secp256K1: Xmtp_MessageContents_SignedPrivateKey.Secp256k1 {
    get {
      if case .secp256K1(let v)? = union {return v}
      return Xmtp_MessageContents_SignedPrivateKey.Secp256k1()
    }
    set {union = .secp256K1(newValue)}
  }

  /// public key for this private key
  public var publicKey: Xmtp_MessageContents_SignedPublicKey {
    get {return _publicKey ?? Xmtp_MessageContents_SignedPublicKey()}
    set {_publicKey = newValue}
  }
  /// Returns true if `publicKey` has been explicitly set.
  public var hasPublicKey: Bool {return self._publicKey != nil}
  /// Clears the value of `publicKey`. Subsequent reads from it will return its default value.
  public mutating func clearPublicKey() {self._publicKey = nil}

  public var unknownFields = SwiftProtobuf.UnknownStorage()

  /// private key
  public enum OneOf_Union: Equatable {
    case secp256K1(Xmtp_MessageContents_SignedPrivateKey.Secp256k1)

  #if !swift(>=4.1)
    public static func ==(lhs: Xmtp_MessageContents_SignedPrivateKey.OneOf_Union, rhs: Xmtp_MessageContents_SignedPrivateKey.OneOf_Union) -> Bool {
      // The use of inline closures is to circumvent an issue where the compiler
      // allocates stack space for every case branch when no optimizations are
      // enabled. https://github.com/apple/swift-protobuf/issues/1034
      switch (lhs, rhs) {
      case (.secp256K1, .secp256K1): return {
        guard case .secp256K1(let l) = lhs, case .secp256K1(let r) = rhs else { preconditionFailure() }
        return l == r
      }()
      }
    }
  #endif
  }

  /// EC: SECP256k1
  public struct Secp256k1 {
    // SwiftProtobuf.Message conformance is added in an extension below. See the
    // `Message` and `Message+*Additions` files in the SwiftProtobuf library for
    // methods supported on all messages.

    /// D big-endian, 32 bytes
    public var bytes: Data = Data()

    public var unknownFields = SwiftProtobuf.UnknownStorage()

    public init() {}
  }

  public init() {}

  fileprivate var _publicKey: Xmtp_MessageContents_SignedPublicKey? = nil
}

/// PrivateKeyBundle wraps the identityKey and the preKeys,
/// enforces usage of signed keys.
public struct Xmtp_MessageContents_PrivateKeyBundleV2 {
  // SwiftProtobuf.Message conformance is added in an extension below. See the
  // `Message` and `Message+*Additions` files in the SwiftProtobuf library for
  // methods supported on all messages.

  public var identityKey: Xmtp_MessageContents_SignedPrivateKey {
    get {return _identityKey ?? Xmtp_MessageContents_SignedPrivateKey()}
    set {_identityKey = newValue}
  }
  /// Returns true if `identityKey` has been explicitly set.
  public var hasIdentityKey: Bool {return self._identityKey != nil}
  /// Clears the value of `identityKey`. Subsequent reads from it will return its default value.
  public mutating func clearIdentityKey() {self._identityKey = nil}

  /// all the known pre-keys, newer keys first,
  public var preKeys: [Xmtp_MessageContents_SignedPrivateKey] = []

  public var unknownFields = SwiftProtobuf.UnknownStorage()

  public init() {}

  fileprivate var _identityKey: Xmtp_MessageContents_SignedPrivateKey? = nil
}

/// LEGACY: PrivateKey generalized to support different key types
public struct Xmtp_MessageContents_PrivateKey {
  // SwiftProtobuf.Message conformance is added in an extension below. See the
  // `Message` and `Message+*Additions` files in the SwiftProtobuf library for
  // methods supported on all messages.

  /// time the key was created
  public var timestamp: UInt64 = 0

  /// private key
  public var union: Xmtp_MessageContents_PrivateKey.OneOf_Union? = nil

  public var secp256K1: Xmtp_MessageContents_PrivateKey.Secp256k1 {
    get {
      if case .secp256K1(let v)? = union {return v}
      return Xmtp_MessageContents_PrivateKey.Secp256k1()
    }
    set {union = .secp256K1(newValue)}
  }

  /// public key for this private key
  public var publicKey: Xmtp_MessageContents_PublicKey {
    get {return _publicKey ?? Xmtp_MessageContents_PublicKey()}
    set {_publicKey = newValue}
  }
  /// Returns true if `publicKey` has been explicitly set.
  public var hasPublicKey: Bool {return self._publicKey != nil}
  /// Clears the value of `publicKey`. Subsequent reads from it will return its default value.
  public mutating func clearPublicKey() {self._publicKey = nil}

  public var unknownFields = SwiftProtobuf.UnknownStorage()

  /// private key
  public enum OneOf_Union: Equatable {
    case secp256K1(Xmtp_MessageContents_PrivateKey.Secp256k1)

  #if !swift(>=4.1)
    public static func ==(lhs: Xmtp_MessageContents_PrivateKey.OneOf_Union, rhs: Xmtp_MessageContents_PrivateKey.OneOf_Union) -> Bool {
      // The use of inline closures is to circumvent an issue where the compiler
      // allocates stack space for every case branch when no optimizations are
      // enabled. https://github.com/apple/swift-protobuf/issues/1034
      switch (lhs, rhs) {
      case (.secp256K1, .secp256K1): return {
        guard case .secp256K1(let l) = lhs, case .secp256K1(let r) = rhs else { preconditionFailure() }
        return l == r
      }()
      }
    }
  #endif
  }

  /// EC: SECP256k1
  public struct Secp256k1 {
    // SwiftProtobuf.Message conformance is added in an extension below. See the
    // `Message` and `Message+*Additions` files in the SwiftProtobuf library for
    // methods supported on all messages.

    /// D big-endian, 32 bytes
    public var bytes: Data = Data()

    public var unknownFields = SwiftProtobuf.UnknownStorage()

    public init() {}
  }

  public init() {}

  fileprivate var _publicKey: Xmtp_MessageContents_PublicKey? = nil
}

/// LEGACY: PrivateKeyBundleV1 wraps the identityKey and the preKeys
public struct Xmtp_MessageContents_PrivateKeyBundleV1 {
  // SwiftProtobuf.Message conformance is added in an extension below. See the
  // `Message` and `Message+*Additions` files in the SwiftProtobuf library for
  // methods supported on all messages.

  public var identityKey: Xmtp_MessageContents_PrivateKey {
    get {return _identityKey ?? Xmtp_MessageContents_PrivateKey()}
    set {_identityKey = newValue}
  }
  /// Returns true if `identityKey` has been explicitly set.
  public var hasIdentityKey: Bool {return self._identityKey != nil}
  /// Clears the value of `identityKey`. Subsequent reads from it will return its default value.
  public mutating func clearIdentityKey() {self._identityKey = nil}

  /// all the known pre-keys, newer keys first,
  public var preKeys: [Xmtp_MessageContents_PrivateKey] = []

  public var unknownFields = SwiftProtobuf.UnknownStorage()

  public init() {}

  fileprivate var _identityKey: Xmtp_MessageContents_PrivateKey? = nil
}

/// Versioned PrivateKeyBundle
public struct Xmtp_MessageContents_PrivateKeyBundle {
  // SwiftProtobuf.Message conformance is added in an extension below. See the
  // `Message` and `Message+*Additions` files in the SwiftProtobuf library for
  // methods supported on all messages.

  public var version: Xmtp_MessageContents_PrivateKeyBundle.OneOf_Version? = nil

  public var v1: Xmtp_MessageContents_PrivateKeyBundleV1 {
    get {
      if case .v1(let v)? = version {return v}
      return Xmtp_MessageContents_PrivateKeyBundleV1()
    }
    set {version = .v1(newValue)}
  }

  public var v2: Xmtp_MessageContents_PrivateKeyBundleV2 {
    get {
      if case .v2(let v)? = version {return v}
      return Xmtp_MessageContents_PrivateKeyBundleV2()
    }
    set {version = .v2(newValue)}
  }

  public var unknownFields = SwiftProtobuf.UnknownStorage()

  public enum OneOf_Version: Equatable {
    case v1(Xmtp_MessageContents_PrivateKeyBundleV1)
    case v2(Xmtp_MessageContents_PrivateKeyBundleV2)

  #if !swift(>=4.1)
    public static func ==(lhs: Xmtp_MessageContents_PrivateKeyBundle.OneOf_Version, rhs: Xmtp_MessageContents_PrivateKeyBundle.OneOf_Version) -> Bool {
      // The use of inline closures is to circumvent an issue where the compiler
      // allocates stack space for every case branch when no optimizations are
      // enabled. https://github.com/apple/swift-protobuf/issues/1034
      switch (lhs, rhs) {
      case (.v1, .v1): return {
        guard case .v1(let l) = lhs, case .v1(let r) = rhs else { preconditionFailure() }
        return l == r
      }()
      case (.v2, .v2): return {
        guard case .v2(let l) = lhs, case .v2(let r) = rhs else { preconditionFailure() }
        return l == r
      }()
      default: return false
      }
    }
  #endif
  }

  public init() {}
}

/// PrivateKeyBundle encrypted with key material generated by
/// signing a randomly generated "pre-key" with the user's wallet,
/// i.e. EIP-191 signature of a "storage signature" message with
/// the pre-key embedded in it.
/// (see xmtp-js::PrivateKeyBundle.toEncryptedBytes for details)
public struct Xmtp_MessageContents_EncryptedPrivateKeyBundleV1 {
  // SwiftProtobuf.Message conformance is added in an extension below. See the
  // `Message` and `Message+*Additions` files in the SwiftProtobuf library for
  // methods supported on all messages.

  /// randomly generated pre-key 
  public var walletPreKey: Data = Data()

  /// MUST contain encrypted PrivateKeyBundle
  public var ciphertext: Xmtp_MessageContents_Ciphertext {
    get {return _ciphertext ?? Xmtp_MessageContents_Ciphertext()}
    set {_ciphertext = newValue}
  }
  /// Returns true if `ciphertext` has been explicitly set.
  public var hasCiphertext: Bool {return self._ciphertext != nil}
  /// Clears the value of `ciphertext`. Subsequent reads from it will return its default value.
  public mutating func clearCiphertext() {self._ciphertext = nil}

  public var unknownFields = SwiftProtobuf.UnknownStorage()

  public init() {}

  fileprivate var _ciphertext: Xmtp_MessageContents_Ciphertext? = nil
}

/// Versioned encrypted PrivateKeyBundle
public struct Xmtp_MessageContents_EncryptedPrivateKeyBundle {
  // SwiftProtobuf.Message conformance is added in an extension below. See the
  // `Message` and `Message+*Additions` files in the SwiftProtobuf library for
  // methods supported on all messages.

  public var version: Xmtp_MessageContents_EncryptedPrivateKeyBundle.OneOf_Version? = nil

  public var v1: Xmtp_MessageContents_EncryptedPrivateKeyBundleV1 {
    get {
      if case .v1(let v)? = version {return v}
      return Xmtp_MessageContents_EncryptedPrivateKeyBundleV1()
    }
    set {version = .v1(newValue)}
  }

  public var unknownFields = SwiftProtobuf.UnknownStorage()

  public enum OneOf_Version: Equatable {
    case v1(Xmtp_MessageContents_EncryptedPrivateKeyBundleV1)

  #if !swift(>=4.1)
    public static func ==(lhs: Xmtp_MessageContents_EncryptedPrivateKeyBundle.OneOf_Version, rhs: Xmtp_MessageContents_EncryptedPrivateKeyBundle.OneOf_Version) -> Bool {
      // The use of inline closures is to circumvent an issue where the compiler
      // allocates stack space for every case branch when no optimizations are
      // enabled. https://github.com/apple/swift-protobuf/issues/1034
      switch (lhs, rhs) {
      case (.v1, .v1): return {
        guard case .v1(let l) = lhs, case .v1(let r) = rhs else { preconditionFailure() }
        return l == r
      }()
      }
    }
  #endif
  }

  public init() {}
}

#if swift(>=5.5) && canImport(_Concurrency)
extension Xmtp_MessageContents_SignedPrivateKey: @unchecked Sendable {}
extension Xmtp_MessageContents_SignedPrivateKey.OneOf_Union: @unchecked Sendable {}
extension Xmtp_MessageContents_SignedPrivateKey.Secp256k1: @unchecked Sendable {}
extension Xmtp_MessageContents_PrivateKeyBundleV2: @unchecked Sendable {}
extension Xmtp_MessageContents_PrivateKey: @unchecked Sendable {}
extension Xmtp_MessageContents_PrivateKey.OneOf_Union: @unchecked Sendable {}
extension Xmtp_MessageContents_PrivateKey.Secp256k1: @unchecked Sendable {}
extension Xmtp_MessageContents_PrivateKeyBundleV1: @unchecked Sendable {}
extension Xmtp_MessageContents_PrivateKeyBundle: @unchecked Sendable {}
extension Xmtp_MessageContents_PrivateKeyBundle.OneOf_Version: @unchecked Sendable {}
extension Xmtp_MessageContents_EncryptedPrivateKeyBundleV1: @unchecked Sendable {}
extension Xmtp_MessageContents_EncryptedPrivateKeyBundle: @unchecked Sendable {}
extension Xmtp_MessageContents_EncryptedPrivateKeyBundle.OneOf_Version: @unchecked Sendable {}
#endif  // swift(>=5.5) && canImport(_Concurrency)

// MARK: - Code below here is support for the SwiftProtobuf runtime.

fileprivate let _protobuf_package = "xmtp.message_contents"

extension Xmtp_MessageContents_SignedPrivateKey: SwiftProtobuf.Message, SwiftProtobuf._MessageImplementationBase, SwiftProtobuf._ProtoNameProviding {
  public static let protoMessageName: String = _protobuf_package + ".SignedPrivateKey"
  public static let _protobuf_nameMap: SwiftProtobuf._NameMap = [
    1: .standard(proto: "created_ns"),
    2: .same(proto: "secp256k1"),
    3: .standard(proto: "public_key"),
  ]

  public mutating func decodeMessage<D: SwiftProtobuf.Decoder>(decoder: inout D) throws {
    while let fieldNumber = try decoder.nextFieldNumber() {
      // The use of inline closures is to circumvent an issue where the compiler
      // allocates stack space for every case branch when no optimizations are
      // enabled. https://github.com/apple/swift-protobuf/issues/1034
      switch fieldNumber {
      case 1: try { try decoder.decodeSingularUInt64Field(value: &self.createdNs) }()
      case 2: try {
        var v: Xmtp_MessageContents_SignedPrivateKey.Secp256k1?
        var hadOneofValue = false
        if let current = self.union {
          hadOneofValue = true
          if case .secp256K1(let m) = current {v = m}
        }
        try decoder.decodeSingularMessageField(value: &v)
        if let v = v {
          if hadOneofValue {try decoder.handleConflictingOneOf()}
          self.union = .secp256K1(v)
        }
      }()
      case 3: try { try decoder.decodeSingularMessageField(value: &self._publicKey) }()
      default: break
      }
    }
  }

  public func traverse<V: SwiftProtobuf.Visitor>(visitor: inout V) throws {
    // The use of inline closures is to circumvent an issue where the compiler
    // allocates stack space for every if/case branch local when no optimizations
    // are enabled. https://github.com/apple/swift-protobuf/issues/1034 and
    // https://github.com/apple/swift-protobuf/issues/1182
    if self.createdNs != 0 {
      try visitor.visitSingularUInt64Field(value: self.createdNs, fieldNumber: 1)
    }
    try { if case .secp256K1(let v)? = self.union {
      try visitor.visitSingularMessageField(value: v, fieldNumber: 2)
    } }()
    try { if let v = self._publicKey {
      try visitor.visitSingularMessageField(value: v, fieldNumber: 3)
    } }()
    try unknownFields.traverse(visitor: &visitor)
  }

  public static func ==(lhs: Xmtp_MessageContents_SignedPrivateKey, rhs: Xmtp_MessageContents_SignedPrivateKey) -> Bool {
    if lhs.createdNs != rhs.createdNs {return false}
    if lhs.union != rhs.union {return false}
    if lhs._publicKey != rhs._publicKey {return false}
    if lhs.unknownFields != rhs.unknownFields {return false}
    return true
  }
}

extension Xmtp_MessageContents_SignedPrivateKey.Secp256k1: SwiftProtobuf.Message, SwiftProtobuf._MessageImplementationBase, SwiftProtobuf._ProtoNameProviding {
  public static let protoMessageName: String = Xmtp_MessageContents_SignedPrivateKey.protoMessageName + ".Secp256k1"
  public static let _protobuf_nameMap: SwiftProtobuf._NameMap = [
    1: .same(proto: "bytes"),
  ]

  public mutating func decodeMessage<D: SwiftProtobuf.Decoder>(decoder: inout D) throws {
    while let fieldNumber = try decoder.nextFieldNumber() {
      // The use of inline closures is to circumvent an issue where the compiler
      // allocates stack space for every case branch when no optimizations are
      // enabled. https://github.com/apple/swift-protobuf/issues/1034
      switch fieldNumber {
      case 1: try { try decoder.decodeSingularBytesField(value: &self.bytes) }()
      default: break
      }
    }
  }

  public func traverse<V: SwiftProtobuf.Visitor>(visitor: inout V) throws {
    if !self.bytes.isEmpty {
      try visitor.visitSingularBytesField(value: self.bytes, fieldNumber: 1)
    }
    try unknownFields.traverse(visitor: &visitor)
  }

  public static func ==(lhs: Xmtp_MessageContents_SignedPrivateKey.Secp256k1, rhs: Xmtp_MessageContents_SignedPrivateKey.Secp256k1) -> Bool {
    if lhs.bytes != rhs.bytes {return false}
    if lhs.unknownFields != rhs.unknownFields {return false}
    return true
  }
}

extension Xmtp_MessageContents_PrivateKeyBundleV2: SwiftProtobuf.Message, SwiftProtobuf._MessageImplementationBase, SwiftProtobuf._ProtoNameProviding {
  public static let protoMessageName: String = _protobuf_package + ".PrivateKeyBundleV2"
  public static let _protobuf_nameMap: SwiftProtobuf._NameMap = [
    1: .standard(proto: "identity_key"),
    2: .standard(proto: "pre_keys"),
  ]

  public mutating func decodeMessage<D: SwiftProtobuf.Decoder>(decoder: inout D) throws {
    while let fieldNumber = try decoder.nextFieldNumber() {
      // The use of inline closures is to circumvent an issue where the compiler
      // allocates stack space for every case branch when no optimizations are
      // enabled. https://github.com/apple/swift-protobuf/issues/1034
      switch fieldNumber {
      case 1: try { try decoder.decodeSingularMessageField(value: &self._identityKey) }()
      case 2: try { try decoder.decodeRepeatedMessageField(value: &self.preKeys) }()
      default: break
      }
    }
  }

  public func traverse<V: SwiftProtobuf.Visitor>(visitor: inout V) throws {
    // The use of inline closures is to circumvent an issue where the compiler
    // allocates stack space for every if/case branch local when no optimizations
    // are enabled. https://github.com/apple/swift-protobuf/issues/1034 and
    // https://github.com/apple/swift-protobuf/issues/1182
    try { if let v = self._identityKey {
      try visitor.visitSingularMessageField(value: v, fieldNumber: 1)
    } }()
    if !self.preKeys.isEmpty {
      try visitor.visitRepeatedMessageField(value: self.preKeys, fieldNumber: 2)
    }
    try unknownFields.traverse(visitor: &visitor)
  }

  public static func ==(lhs: Xmtp_MessageContents_PrivateKeyBundleV2, rhs: Xmtp_MessageContents_PrivateKeyBundleV2) -> Bool {
    if lhs._identityKey != rhs._identityKey {return false}
    if lhs.preKeys != rhs.preKeys {return false}
    if lhs.unknownFields != rhs.unknownFields {return false}
    return true
  }
}

extension Xmtp_MessageContents_PrivateKey: SwiftProtobuf.Message, SwiftProtobuf._MessageImplementationBase, SwiftProtobuf._ProtoNameProviding {
  public static let protoMessageName: String = _protobuf_package + ".PrivateKey"
  public static let _protobuf_nameMap: SwiftProtobuf._NameMap = [
    1: .same(proto: "timestamp"),
    2: .same(proto: "secp256k1"),
    3: .standard(proto: "public_key"),
  ]

  public mutating func decodeMessage<D: SwiftProtobuf.Decoder>(decoder: inout D) throws {
    while let fieldNumber = try decoder.nextFieldNumber() {
      // The use of inline closures is to circumvent an issue where the compiler
      // allocates stack space for every case branch when no optimizations are
      // enabled. https://github.com/apple/swift-protobuf/issues/1034
      switch fieldNumber {
      case 1: try { try decoder.decodeSingularUInt64Field(value: &self.timestamp) }()
      case 2: try {
        var v: Xmtp_MessageContents_PrivateKey.Secp256k1?
        var hadOneofValue = false
        if let current = self.union {
          hadOneofValue = true
          if case .secp256K1(let m) = current {v = m}
        }
        try decoder.decodeSingularMessageField(value: &v)
        if let v = v {
          if hadOneofValue {try decoder.handleConflictingOneOf()}
          self.union = .secp256K1(v)
        }
      }()
      case 3: try { try decoder.decodeSingularMessageField(value: &self._publicKey) }()
      default: break
      }
    }
  }

  public func traverse<V: SwiftProtobuf.Visitor>(visitor: inout V) throws {
    // The use of inline closures is to circumvent an issue where the compiler
    // allocates stack space for every if/case branch local when no optimizations
    // are enabled. https://github.com/apple/swift-protobuf/issues/1034 and
    // https://github.com/apple/swift-protobuf/issues/1182
    if self.timestamp != 0 {
      try visitor.visitSingularUInt64Field(value: self.timestamp, fieldNumber: 1)
    }
    try { if case .secp256K1(let v)? = self.union {
      try visitor.visitSingularMessageField(value: v, fieldNumber: 2)
    } }()
    try { if let v = self._publicKey {
      try visitor.visitSingularMessageField(value: v, fieldNumber: 3)
    } }()
    try unknownFields.traverse(visitor: &visitor)
  }

  public static func ==(lhs: Xmtp_MessageContents_PrivateKey, rhs: Xmtp_MessageContents_PrivateKey) -> Bool {
    if lhs.timestamp != rhs.timestamp {return false}
    if lhs.union != rhs.union {return false}
    if lhs._publicKey != rhs._publicKey {return false}
    if lhs.unknownFields != rhs.unknownFields {return false}
    return true
  }
}

extension Xmtp_MessageContents_PrivateKey.Secp256k1: SwiftProtobuf.Message, SwiftProtobuf._MessageImplementationBase, SwiftProtobuf._ProtoNameProviding {
  public static let protoMessageName: String = Xmtp_MessageContents_PrivateKey.protoMessageName + ".Secp256k1"
  public static let _protobuf_nameMap: SwiftProtobuf._NameMap = [
    1: .same(proto: "bytes"),
  ]

  public mutating func decodeMessage<D: SwiftProtobuf.Decoder>(decoder: inout D) throws {
    while let fieldNumber = try decoder.nextFieldNumber() {
      // The use of inline closures is to circumvent an issue where the compiler
      // allocates stack space for every case branch when no optimizations are
      // enabled. https://github.com/apple/swift-protobuf/issues/1034
      switch fieldNumber {
      case 1: try { try decoder.decodeSingularBytesField(value: &self.bytes) }()
      default: break
      }
    }
  }

  public func traverse<V: SwiftProtobuf.Visitor>(visitor: inout V) throws {
    if !self.bytes.isEmpty {
      try visitor.visitSingularBytesField(value: self.bytes, fieldNumber: 1)
    }
    try unknownFields.traverse(visitor: &visitor)
  }

  public static func ==(lhs: Xmtp_MessageContents_PrivateKey.Secp256k1, rhs: Xmtp_MessageContents_PrivateKey.Secp256k1) -> Bool {
    if lhs.bytes != rhs.bytes {return false}
    if lhs.unknownFields != rhs.unknownFields {return false}
    return true
  }
}

extension Xmtp_MessageContents_PrivateKeyBundleV1: SwiftProtobuf.Message, SwiftProtobuf._MessageImplementationBase, SwiftProtobuf._ProtoNameProviding {
  public static let protoMessageName: String = _protobuf_package + ".PrivateKeyBundleV1"
  public static let _protobuf_nameMap: SwiftProtobuf._NameMap = [
    1: .standard(proto: "identity_key"),
    2: .standard(proto: "pre_keys"),
  ]

  public mutating func decodeMessage<D: SwiftProtobuf.Decoder>(decoder: inout D) throws {
    while let fieldNumber = try decoder.nextFieldNumber() {
      // The use of inline closures is to circumvent an issue where the compiler
      // allocates stack space for every case branch when no optimizations are
      // enabled. https://github.com/apple/swift-protobuf/issues/1034
      switch fieldNumber {
      case 1: try { try decoder.decodeSingularMessageField(value: &self._identityKey) }()
      case 2: try { try decoder.decodeRepeatedMessageField(value: &self.preKeys) }()
      default: break
      }
    }
  }

  public func traverse<V: SwiftProtobuf.Visitor>(visitor: inout V) throws {
    // The use of inline closures is to circumvent an issue where the compiler
    // allocates stack space for every if/case branch local when no optimizations
    // are enabled. https://github.com/apple/swift-protobuf/issues/1034 and
    // https://github.com/apple/swift-protobuf/issues/1182
    try { if let v = self._identityKey {
      try visitor.visitSingularMessageField(value: v, fieldNumber: 1)
    } }()
    if !self.preKeys.isEmpty {
      try visitor.visitRepeatedMessageField(value: self.preKeys, fieldNumber: 2)
    }
    try unknownFields.traverse(visitor: &visitor)
  }

  public static func ==(lhs: Xmtp_MessageContents_PrivateKeyBundleV1, rhs: Xmtp_MessageContents_PrivateKeyBundleV1) -> Bool {
    if lhs._identityKey != rhs._identityKey {return false}
    if lhs.preKeys != rhs.preKeys {return false}
    if lhs.unknownFields != rhs.unknownFields {return false}
    return true
  }
}

extension Xmtp_MessageContents_PrivateKeyBundle: SwiftProtobuf.Message, SwiftProtobuf._MessageImplementationBase, SwiftProtobuf._ProtoNameProviding {
  public static let protoMessageName: String = _protobuf_package + ".PrivateKeyBundle"
  public static let _protobuf_nameMap: SwiftProtobuf._NameMap = [
    1: .same(proto: "v1"),
    2: .same(proto: "v2"),
  ]

  public mutating func decodeMessage<D: SwiftProtobuf.Decoder>(decoder: inout D) throws {
    while let fieldNumber = try decoder.nextFieldNumber() {
      // The use of inline closures is to circumvent an issue where the compiler
      // allocates stack space for every case branch when no optimizations are
      // enabled. https://github.com/apple/swift-protobuf/issues/1034
      switch fieldNumber {
      case 1: try {
        var v: Xmtp_MessageContents_PrivateKeyBundleV1?
        var hadOneofValue = false
        if let current = self.version {
          hadOneofValue = true
          if case .v1(let m) = current {v = m}
        }
        try decoder.decodeSingularMessageField(value: &v)
        if let v = v {
          if hadOneofValue {try decoder.handleConflictingOneOf()}
          self.version = .v1(v)
        }
      }()
      case 2: try {
        var v: Xmtp_MessageContents_PrivateKeyBundleV2?
        var hadOneofValue = false
        if let current = self.version {
          hadOneofValue = true
          if case .v2(let m) = current {v = m}
        }
        try decoder.decodeSingularMessageField(value: &v)
        if let v = v {
          if hadOneofValue {try decoder.handleConflictingOneOf()}
          self.version = .v2(v)
        }
      }()
      default: break
      }
    }
  }

  public func traverse<V: SwiftProtobuf.Visitor>(visitor: inout V) throws {
    // The use of inline closures is to circumvent an issue where the compiler
    // allocates stack space for every if/case branch local when no optimizations
    // are enabled. https://github.com/apple/swift-protobuf/issues/1034 and
    // https://github.com/apple/swift-protobuf/issues/1182
    switch self.version {
    case .v1?: try {
      guard case .v1(let v)? = self.version else { preconditionFailure() }
      try visitor.visitSingularMessageField(value: v, fieldNumber: 1)
    }()
    case .v2?: try {
      guard case .v2(let v)? = self.version else { preconditionFailure() }
      try visitor.visitSingularMessageField(value: v, fieldNumber: 2)
    }()
    case nil: break
    }
    try unknownFields.traverse(visitor: &visitor)
  }

  public static func ==(lhs: Xmtp_MessageContents_PrivateKeyBundle, rhs: Xmtp_MessageContents_PrivateKeyBundle) -> Bool {
    if lhs.version != rhs.version {return false}
    if lhs.unknownFields != rhs.unknownFields {return false}
    return true
  }
}

extension Xmtp_MessageContents_EncryptedPrivateKeyBundleV1: SwiftProtobuf.Message, SwiftProtobuf._MessageImplementationBase, SwiftProtobuf._ProtoNameProviding {
  public static let protoMessageName: String = _protobuf_package + ".EncryptedPrivateKeyBundleV1"
  public static let _protobuf_nameMap: SwiftProtobuf._NameMap = [
    1: .standard(proto: "wallet_pre_key"),
    2: .same(proto: "ciphertext"),
  ]

  public mutating func decodeMessage<D: SwiftProtobuf.Decoder>(decoder: inout D) throws {
    while let fieldNumber = try decoder.nextFieldNumber() {
      // The use of inline closures is to circumvent an issue where the compiler
      // allocates stack space for every case branch when no optimizations are
      // enabled. https://github.com/apple/swift-protobuf/issues/1034
      switch fieldNumber {
      case 1: try { try decoder.decodeSingularBytesField(value: &self.walletPreKey) }()
      case 2: try { try decoder.decodeSingularMessageField(value: &self._ciphertext) }()
      default: break
      }
    }
  }

  public func traverse<V: SwiftProtobuf.Visitor>(visitor: inout V) throws {
    // The use of inline closures is to circumvent an issue where the compiler
    // allocates stack space for every if/case branch local when no optimizations
    // are enabled. https://github.com/apple/swift-protobuf/issues/1034 and
    // https://github.com/apple/swift-protobuf/issues/1182
    if !self.walletPreKey.isEmpty {
      try visitor.visitSingularBytesField(value: self.walletPreKey, fieldNumber: 1)
    }
    try { if let v = self._ciphertext {
      try visitor.visitSingularMessageField(value: v, fieldNumber: 2)
    } }()
    try unknownFields.traverse(visitor: &visitor)
  }

  public static func ==(lhs: Xmtp_MessageContents_EncryptedPrivateKeyBundleV1, rhs: Xmtp_MessageContents_EncryptedPrivateKeyBundleV1) -> Bool {
    if lhs.walletPreKey != rhs.walletPreKey {return false}
    if lhs._ciphertext != rhs._ciphertext {return false}
    if lhs.unknownFields != rhs.unknownFields {return false}
    return true
  }
}

extension Xmtp_MessageContents_EncryptedPrivateKeyBundle: SwiftProtobuf.Message, SwiftProtobuf._MessageImplementationBase, SwiftProtobuf._ProtoNameProviding {
  public static let protoMessageName: String = _protobuf_package + ".EncryptedPrivateKeyBundle"
  public static let _protobuf_nameMap: SwiftProtobuf._NameMap = [
    1: .same(proto: "v1"),
  ]

  public mutating func decodeMessage<D: SwiftProtobuf.Decoder>(decoder: inout D) throws {
    while let fieldNumber = try decoder.nextFieldNumber() {
      // The use of inline closures is to circumvent an issue where the compiler
      // allocates stack space for every case branch when no optimizations are
      // enabled. https://github.com/apple/swift-protobuf/issues/1034
      switch fieldNumber {
      case 1: try {
        var v: Xmtp_MessageContents_EncryptedPrivateKeyBundleV1?
        var hadOneofValue = false
        if let current = self.version {
          hadOneofValue = true
          if case .v1(let m) = current {v = m}
        }
        try decoder.decodeSingularMessageField(value: &v)
        if let v = v {
          if hadOneofValue {try decoder.handleConflictingOneOf()}
          self.version = .v1(v)
        }
      }()
      default: break
      }
    }
  }

  public func traverse<V: SwiftProtobuf.Visitor>(visitor: inout V) throws {
    // The use of inline closures is to circumvent an issue where the compiler
    // allocates stack space for every if/case branch local when no optimizations
    // are enabled. https://github.com/apple/swift-protobuf/issues/1034 and
    // https://github.com/apple/swift-protobuf/issues/1182
    try { if case .v1(let v)? = self.version {
      try visitor.visitSingularMessageField(value: v, fieldNumber: 1)
    } }()
    try unknownFields.traverse(visitor: &visitor)
  }

  public static func ==(lhs: Xmtp_MessageContents_EncryptedPrivateKeyBundle, rhs: Xmtp_MessageContents_EncryptedPrivateKeyBundle) -> Bool {
    if lhs.version != rhs.version {return false}
    if lhs.unknownFields != rhs.unknownFields {return false}
    return true
  }
}
