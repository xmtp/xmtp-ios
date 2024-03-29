// DO NOT EDIT.
// swift-format-ignore-file
//
// Generated by the Swift generator plugin for the protocol buffer compiler.
// Source: mls/database/intents.proto
//
// For information on using the generated types, please see the documentation:
//   https://github.com/apple/swift-protobuf/

// V3 invite message structure

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

/// The data required to publish a message
public struct Xmtp_Mls_Database_SendMessageData {
  // SwiftProtobuf.Message conformance is added in an extension below. See the
  // `Message` and `Message+*Additions` files in the SwiftProtobuf library for
  // methods supported on all messages.

  public var version: Xmtp_Mls_Database_SendMessageData.OneOf_Version? = nil

  public var v1: Xmtp_Mls_Database_SendMessageData.V1 {
    get {
      if case .v1(let v)? = version {return v}
      return Xmtp_Mls_Database_SendMessageData.V1()
    }
    set {version = .v1(newValue)}
  }

  public var unknownFields = SwiftProtobuf.UnknownStorage()

  public enum OneOf_Version: Equatable {
    case v1(Xmtp_Mls_Database_SendMessageData.V1)

  #if !swift(>=4.1)
    public static func ==(lhs: Xmtp_Mls_Database_SendMessageData.OneOf_Version, rhs: Xmtp_Mls_Database_SendMessageData.OneOf_Version) -> Bool {
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

  /// V1 of SendMessagePublishData
  public struct V1 {
    // SwiftProtobuf.Message conformance is added in an extension below. See the
    // `Message` and `Message+*Additions` files in the SwiftProtobuf library for
    // methods supported on all messages.

    public var payloadBytes: Data = Data()

    public var unknownFields = SwiftProtobuf.UnknownStorage()

    public init() {}
  }

  public init() {}
}

/// Wrapper around a list af repeated EVM Account Addresses
public struct Xmtp_Mls_Database_AccountAddresses {
  // SwiftProtobuf.Message conformance is added in an extension below. See the
  // `Message` and `Message+*Additions` files in the SwiftProtobuf library for
  // methods supported on all messages.

  public var accountAddresses: [String] = []

  public var unknownFields = SwiftProtobuf.UnknownStorage()

  public init() {}
}

/// Wrapper around a list of repeated Installation IDs
public struct Xmtp_Mls_Database_InstallationIds {
  // SwiftProtobuf.Message conformance is added in an extension below. See the
  // `Message` and `Message+*Additions` files in the SwiftProtobuf library for
  // methods supported on all messages.

  public var installationIds: [Data] = []

  public var unknownFields = SwiftProtobuf.UnknownStorage()

  public init() {}
}

/// One of an EVM account address or Installation ID
public struct Xmtp_Mls_Database_AddressesOrInstallationIds {
  // SwiftProtobuf.Message conformance is added in an extension below. See the
  // `Message` and `Message+*Additions` files in the SwiftProtobuf library for
  // methods supported on all messages.

  public var addressesOrInstallationIds: Xmtp_Mls_Database_AddressesOrInstallationIds.OneOf_AddressesOrInstallationIds? = nil

  public var accountAddresses: Xmtp_Mls_Database_AccountAddresses {
    get {
      if case .accountAddresses(let v)? = addressesOrInstallationIds {return v}
      return Xmtp_Mls_Database_AccountAddresses()
    }
    set {addressesOrInstallationIds = .accountAddresses(newValue)}
  }

  public var installationIds: Xmtp_Mls_Database_InstallationIds {
    get {
      if case .installationIds(let v)? = addressesOrInstallationIds {return v}
      return Xmtp_Mls_Database_InstallationIds()
    }
    set {addressesOrInstallationIds = .installationIds(newValue)}
  }

  public var unknownFields = SwiftProtobuf.UnknownStorage()

  public enum OneOf_AddressesOrInstallationIds: Equatable {
    case accountAddresses(Xmtp_Mls_Database_AccountAddresses)
    case installationIds(Xmtp_Mls_Database_InstallationIds)

  #if !swift(>=4.1)
    public static func ==(lhs: Xmtp_Mls_Database_AddressesOrInstallationIds.OneOf_AddressesOrInstallationIds, rhs: Xmtp_Mls_Database_AddressesOrInstallationIds.OneOf_AddressesOrInstallationIds) -> Bool {
      // The use of inline closures is to circumvent an issue where the compiler
      // allocates stack space for every case branch when no optimizations are
      // enabled. https://github.com/apple/swift-protobuf/issues/1034
      switch (lhs, rhs) {
      case (.accountAddresses, .accountAddresses): return {
        guard case .accountAddresses(let l) = lhs, case .accountAddresses(let r) = rhs else { preconditionFailure() }
        return l == r
      }()
      case (.installationIds, .installationIds): return {
        guard case .installationIds(let l) = lhs, case .installationIds(let r) = rhs else { preconditionFailure() }
        return l == r
      }()
      default: return false
      }
    }
  #endif
  }

  public init() {}
}

/// The data required to add members to a group
public struct Xmtp_Mls_Database_AddMembersData {
  // SwiftProtobuf.Message conformance is added in an extension below. See the
  // `Message` and `Message+*Additions` files in the SwiftProtobuf library for
  // methods supported on all messages.

  public var version: Xmtp_Mls_Database_AddMembersData.OneOf_Version? = nil

  public var v1: Xmtp_Mls_Database_AddMembersData.V1 {
    get {
      if case .v1(let v)? = version {return v}
      return Xmtp_Mls_Database_AddMembersData.V1()
    }
    set {version = .v1(newValue)}
  }

  public var unknownFields = SwiftProtobuf.UnknownStorage()

  public enum OneOf_Version: Equatable {
    case v1(Xmtp_Mls_Database_AddMembersData.V1)

  #if !swift(>=4.1)
    public static func ==(lhs: Xmtp_Mls_Database_AddMembersData.OneOf_Version, rhs: Xmtp_Mls_Database_AddMembersData.OneOf_Version) -> Bool {
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

  /// V1 of AddMembersPublishData
  public struct V1 {
    // SwiftProtobuf.Message conformance is added in an extension below. See the
    // `Message` and `Message+*Additions` files in the SwiftProtobuf library for
    // methods supported on all messages.

    public var addressesOrInstallationIds: Xmtp_Mls_Database_AddressesOrInstallationIds {
      get {return _addressesOrInstallationIds ?? Xmtp_Mls_Database_AddressesOrInstallationIds()}
      set {_addressesOrInstallationIds = newValue}
    }
    /// Returns true if `addressesOrInstallationIds` has been explicitly set.
    public var hasAddressesOrInstallationIds: Bool {return self._addressesOrInstallationIds != nil}
    /// Clears the value of `addressesOrInstallationIds`. Subsequent reads from it will return its default value.
    public mutating func clearAddressesOrInstallationIds() {self._addressesOrInstallationIds = nil}

    public var unknownFields = SwiftProtobuf.UnknownStorage()

    public init() {}

    fileprivate var _addressesOrInstallationIds: Xmtp_Mls_Database_AddressesOrInstallationIds? = nil
  }

  public init() {}
}

/// The data required to remove members from a group
public struct Xmtp_Mls_Database_RemoveMembersData {
  // SwiftProtobuf.Message conformance is added in an extension below. See the
  // `Message` and `Message+*Additions` files in the SwiftProtobuf library for
  // methods supported on all messages.

  public var version: Xmtp_Mls_Database_RemoveMembersData.OneOf_Version? = nil

  public var v1: Xmtp_Mls_Database_RemoveMembersData.V1 {
    get {
      if case .v1(let v)? = version {return v}
      return Xmtp_Mls_Database_RemoveMembersData.V1()
    }
    set {version = .v1(newValue)}
  }

  public var unknownFields = SwiftProtobuf.UnknownStorage()

  public enum OneOf_Version: Equatable {
    case v1(Xmtp_Mls_Database_RemoveMembersData.V1)

  #if !swift(>=4.1)
    public static func ==(lhs: Xmtp_Mls_Database_RemoveMembersData.OneOf_Version, rhs: Xmtp_Mls_Database_RemoveMembersData.OneOf_Version) -> Bool {
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

  /// V1 of RemoveMembersPublishData
  public struct V1 {
    // SwiftProtobuf.Message conformance is added in an extension below. See the
    // `Message` and `Message+*Additions` files in the SwiftProtobuf library for
    // methods supported on all messages.

    public var addressesOrInstallationIds: Xmtp_Mls_Database_AddressesOrInstallationIds {
      get {return _addressesOrInstallationIds ?? Xmtp_Mls_Database_AddressesOrInstallationIds()}
      set {_addressesOrInstallationIds = newValue}
    }
    /// Returns true if `addressesOrInstallationIds` has been explicitly set.
    public var hasAddressesOrInstallationIds: Bool {return self._addressesOrInstallationIds != nil}
    /// Clears the value of `addressesOrInstallationIds`. Subsequent reads from it will return its default value.
    public mutating func clearAddressesOrInstallationIds() {self._addressesOrInstallationIds = nil}

    public var unknownFields = SwiftProtobuf.UnknownStorage()

    public init() {}

    fileprivate var _addressesOrInstallationIds: Xmtp_Mls_Database_AddressesOrInstallationIds? = nil
  }

  public init() {}
}

/// Generic data-type for all post-commit actions
public struct Xmtp_Mls_Database_PostCommitAction {
  // SwiftProtobuf.Message conformance is added in an extension below. See the
  // `Message` and `Message+*Additions` files in the SwiftProtobuf library for
  // methods supported on all messages.

  public var kind: Xmtp_Mls_Database_PostCommitAction.OneOf_Kind? = nil

  public var sendWelcomes: Xmtp_Mls_Database_PostCommitAction.SendWelcomes {
    get {
      if case .sendWelcomes(let v)? = kind {return v}
      return Xmtp_Mls_Database_PostCommitAction.SendWelcomes()
    }
    set {kind = .sendWelcomes(newValue)}
  }

  public var unknownFields = SwiftProtobuf.UnknownStorage()

  public enum OneOf_Kind: Equatable {
    case sendWelcomes(Xmtp_Mls_Database_PostCommitAction.SendWelcomes)

  #if !swift(>=4.1)
    public static func ==(lhs: Xmtp_Mls_Database_PostCommitAction.OneOf_Kind, rhs: Xmtp_Mls_Database_PostCommitAction.OneOf_Kind) -> Bool {
      // The use of inline closures is to circumvent an issue where the compiler
      // allocates stack space for every case branch when no optimizations are
      // enabled. https://github.com/apple/swift-protobuf/issues/1034
      switch (lhs, rhs) {
      case (.sendWelcomes, .sendWelcomes): return {
        guard case .sendWelcomes(let l) = lhs, case .sendWelcomes(let r) = rhs else { preconditionFailure() }
        return l == r
      }()
      }
    }
  #endif
  }

  /// An installation
  public struct Installation {
    // SwiftProtobuf.Message conformance is added in an extension below. See the
    // `Message` and `Message+*Additions` files in the SwiftProtobuf library for
    // methods supported on all messages.

    public var installationKey: Data = Data()

    public var hpkePublicKey: Data = Data()

    public var unknownFields = SwiftProtobuf.UnknownStorage()

    public init() {}
  }

  /// SendWelcome message
  public struct SendWelcomes {
    // SwiftProtobuf.Message conformance is added in an extension below. See the
    // `Message` and `Message+*Additions` files in the SwiftProtobuf library for
    // methods supported on all messages.

    public var installations: [Xmtp_Mls_Database_PostCommitAction.Installation] = []

    public var welcomeMessage: Data = Data()

    public var unknownFields = SwiftProtobuf.UnknownStorage()

    public init() {}
  }

  public init() {}
}

#if swift(>=5.5) && canImport(_Concurrency)
extension Xmtp_Mls_Database_SendMessageData: @unchecked Sendable {}
extension Xmtp_Mls_Database_SendMessageData.OneOf_Version: @unchecked Sendable {}
extension Xmtp_Mls_Database_SendMessageData.V1: @unchecked Sendable {}
extension Xmtp_Mls_Database_AccountAddresses: @unchecked Sendable {}
extension Xmtp_Mls_Database_InstallationIds: @unchecked Sendable {}
extension Xmtp_Mls_Database_AddressesOrInstallationIds: @unchecked Sendable {}
extension Xmtp_Mls_Database_AddressesOrInstallationIds.OneOf_AddressesOrInstallationIds: @unchecked Sendable {}
extension Xmtp_Mls_Database_AddMembersData: @unchecked Sendable {}
extension Xmtp_Mls_Database_AddMembersData.OneOf_Version: @unchecked Sendable {}
extension Xmtp_Mls_Database_AddMembersData.V1: @unchecked Sendable {}
extension Xmtp_Mls_Database_RemoveMembersData: @unchecked Sendable {}
extension Xmtp_Mls_Database_RemoveMembersData.OneOf_Version: @unchecked Sendable {}
extension Xmtp_Mls_Database_RemoveMembersData.V1: @unchecked Sendable {}
extension Xmtp_Mls_Database_PostCommitAction: @unchecked Sendable {}
extension Xmtp_Mls_Database_PostCommitAction.OneOf_Kind: @unchecked Sendable {}
extension Xmtp_Mls_Database_PostCommitAction.Installation: @unchecked Sendable {}
extension Xmtp_Mls_Database_PostCommitAction.SendWelcomes: @unchecked Sendable {}
#endif  // swift(>=5.5) && canImport(_Concurrency)

// MARK: - Code below here is support for the SwiftProtobuf runtime.

fileprivate let _protobuf_package = "xmtp.mls.database"

extension Xmtp_Mls_Database_SendMessageData: SwiftProtobuf.Message, SwiftProtobuf._MessageImplementationBase, SwiftProtobuf._ProtoNameProviding {
  public static let protoMessageName: String = _protobuf_package + ".SendMessageData"
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
        var v: Xmtp_Mls_Database_SendMessageData.V1?
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

  public static func ==(lhs: Xmtp_Mls_Database_SendMessageData, rhs: Xmtp_Mls_Database_SendMessageData) -> Bool {
    if lhs.version != rhs.version {return false}
    if lhs.unknownFields != rhs.unknownFields {return false}
    return true
  }
}

extension Xmtp_Mls_Database_SendMessageData.V1: SwiftProtobuf.Message, SwiftProtobuf._MessageImplementationBase, SwiftProtobuf._ProtoNameProviding {
  public static let protoMessageName: String = Xmtp_Mls_Database_SendMessageData.protoMessageName + ".V1"
  public static let _protobuf_nameMap: SwiftProtobuf._NameMap = [
    1: .standard(proto: "payload_bytes"),
  ]

  public mutating func decodeMessage<D: SwiftProtobuf.Decoder>(decoder: inout D) throws {
    while let fieldNumber = try decoder.nextFieldNumber() {
      // The use of inline closures is to circumvent an issue where the compiler
      // allocates stack space for every case branch when no optimizations are
      // enabled. https://github.com/apple/swift-protobuf/issues/1034
      switch fieldNumber {
      case 1: try { try decoder.decodeSingularBytesField(value: &self.payloadBytes) }()
      default: break
      }
    }
  }

  public func traverse<V: SwiftProtobuf.Visitor>(visitor: inout V) throws {
    if !self.payloadBytes.isEmpty {
      try visitor.visitSingularBytesField(value: self.payloadBytes, fieldNumber: 1)
    }
    try unknownFields.traverse(visitor: &visitor)
  }

  public static func ==(lhs: Xmtp_Mls_Database_SendMessageData.V1, rhs: Xmtp_Mls_Database_SendMessageData.V1) -> Bool {
    if lhs.payloadBytes != rhs.payloadBytes {return false}
    if lhs.unknownFields != rhs.unknownFields {return false}
    return true
  }
}

extension Xmtp_Mls_Database_AccountAddresses: SwiftProtobuf.Message, SwiftProtobuf._MessageImplementationBase, SwiftProtobuf._ProtoNameProviding {
  public static let protoMessageName: String = _protobuf_package + ".AccountAddresses"
  public static let _protobuf_nameMap: SwiftProtobuf._NameMap = [
    1: .standard(proto: "account_addresses"),
  ]

  public mutating func decodeMessage<D: SwiftProtobuf.Decoder>(decoder: inout D) throws {
    while let fieldNumber = try decoder.nextFieldNumber() {
      // The use of inline closures is to circumvent an issue where the compiler
      // allocates stack space for every case branch when no optimizations are
      // enabled. https://github.com/apple/swift-protobuf/issues/1034
      switch fieldNumber {
      case 1: try { try decoder.decodeRepeatedStringField(value: &self.accountAddresses) }()
      default: break
      }
    }
  }

  public func traverse<V: SwiftProtobuf.Visitor>(visitor: inout V) throws {
    if !self.accountAddresses.isEmpty {
      try visitor.visitRepeatedStringField(value: self.accountAddresses, fieldNumber: 1)
    }
    try unknownFields.traverse(visitor: &visitor)
  }

  public static func ==(lhs: Xmtp_Mls_Database_AccountAddresses, rhs: Xmtp_Mls_Database_AccountAddresses) -> Bool {
    if lhs.accountAddresses != rhs.accountAddresses {return false}
    if lhs.unknownFields != rhs.unknownFields {return false}
    return true
  }
}

extension Xmtp_Mls_Database_InstallationIds: SwiftProtobuf.Message, SwiftProtobuf._MessageImplementationBase, SwiftProtobuf._ProtoNameProviding {
  public static let protoMessageName: String = _protobuf_package + ".InstallationIds"
  public static let _protobuf_nameMap: SwiftProtobuf._NameMap = [
    1: .standard(proto: "installation_ids"),
  ]

  public mutating func decodeMessage<D: SwiftProtobuf.Decoder>(decoder: inout D) throws {
    while let fieldNumber = try decoder.nextFieldNumber() {
      // The use of inline closures is to circumvent an issue where the compiler
      // allocates stack space for every case branch when no optimizations are
      // enabled. https://github.com/apple/swift-protobuf/issues/1034
      switch fieldNumber {
      case 1: try { try decoder.decodeRepeatedBytesField(value: &self.installationIds) }()
      default: break
      }
    }
  }

  public func traverse<V: SwiftProtobuf.Visitor>(visitor: inout V) throws {
    if !self.installationIds.isEmpty {
      try visitor.visitRepeatedBytesField(value: self.installationIds, fieldNumber: 1)
    }
    try unknownFields.traverse(visitor: &visitor)
  }

  public static func ==(lhs: Xmtp_Mls_Database_InstallationIds, rhs: Xmtp_Mls_Database_InstallationIds) -> Bool {
    if lhs.installationIds != rhs.installationIds {return false}
    if lhs.unknownFields != rhs.unknownFields {return false}
    return true
  }
}

extension Xmtp_Mls_Database_AddressesOrInstallationIds: SwiftProtobuf.Message, SwiftProtobuf._MessageImplementationBase, SwiftProtobuf._ProtoNameProviding {
  public static let protoMessageName: String = _protobuf_package + ".AddressesOrInstallationIds"
  public static let _protobuf_nameMap: SwiftProtobuf._NameMap = [
    1: .standard(proto: "account_addresses"),
    2: .standard(proto: "installation_ids"),
  ]

  public mutating func decodeMessage<D: SwiftProtobuf.Decoder>(decoder: inout D) throws {
    while let fieldNumber = try decoder.nextFieldNumber() {
      // The use of inline closures is to circumvent an issue where the compiler
      // allocates stack space for every case branch when no optimizations are
      // enabled. https://github.com/apple/swift-protobuf/issues/1034
      switch fieldNumber {
      case 1: try {
        var v: Xmtp_Mls_Database_AccountAddresses?
        var hadOneofValue = false
        if let current = self.addressesOrInstallationIds {
          hadOneofValue = true
          if case .accountAddresses(let m) = current {v = m}
        }
        try decoder.decodeSingularMessageField(value: &v)
        if let v = v {
          if hadOneofValue {try decoder.handleConflictingOneOf()}
          self.addressesOrInstallationIds = .accountAddresses(v)
        }
      }()
      case 2: try {
        var v: Xmtp_Mls_Database_InstallationIds?
        var hadOneofValue = false
        if let current = self.addressesOrInstallationIds {
          hadOneofValue = true
          if case .installationIds(let m) = current {v = m}
        }
        try decoder.decodeSingularMessageField(value: &v)
        if let v = v {
          if hadOneofValue {try decoder.handleConflictingOneOf()}
          self.addressesOrInstallationIds = .installationIds(v)
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
    switch self.addressesOrInstallationIds {
    case .accountAddresses?: try {
      guard case .accountAddresses(let v)? = self.addressesOrInstallationIds else { preconditionFailure() }
      try visitor.visitSingularMessageField(value: v, fieldNumber: 1)
    }()
    case .installationIds?: try {
      guard case .installationIds(let v)? = self.addressesOrInstallationIds else { preconditionFailure() }
      try visitor.visitSingularMessageField(value: v, fieldNumber: 2)
    }()
    case nil: break
    }
    try unknownFields.traverse(visitor: &visitor)
  }

  public static func ==(lhs: Xmtp_Mls_Database_AddressesOrInstallationIds, rhs: Xmtp_Mls_Database_AddressesOrInstallationIds) -> Bool {
    if lhs.addressesOrInstallationIds != rhs.addressesOrInstallationIds {return false}
    if lhs.unknownFields != rhs.unknownFields {return false}
    return true
  }
}

extension Xmtp_Mls_Database_AddMembersData: SwiftProtobuf.Message, SwiftProtobuf._MessageImplementationBase, SwiftProtobuf._ProtoNameProviding {
  public static let protoMessageName: String = _protobuf_package + ".AddMembersData"
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
        var v: Xmtp_Mls_Database_AddMembersData.V1?
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

  public static func ==(lhs: Xmtp_Mls_Database_AddMembersData, rhs: Xmtp_Mls_Database_AddMembersData) -> Bool {
    if lhs.version != rhs.version {return false}
    if lhs.unknownFields != rhs.unknownFields {return false}
    return true
  }
}

extension Xmtp_Mls_Database_AddMembersData.V1: SwiftProtobuf.Message, SwiftProtobuf._MessageImplementationBase, SwiftProtobuf._ProtoNameProviding {
  public static let protoMessageName: String = Xmtp_Mls_Database_AddMembersData.protoMessageName + ".V1"
  public static let _protobuf_nameMap: SwiftProtobuf._NameMap = [
    1: .standard(proto: "addresses_or_installation_ids"),
  ]

  public mutating func decodeMessage<D: SwiftProtobuf.Decoder>(decoder: inout D) throws {
    while let fieldNumber = try decoder.nextFieldNumber() {
      // The use of inline closures is to circumvent an issue where the compiler
      // allocates stack space for every case branch when no optimizations are
      // enabled. https://github.com/apple/swift-protobuf/issues/1034
      switch fieldNumber {
      case 1: try { try decoder.decodeSingularMessageField(value: &self._addressesOrInstallationIds) }()
      default: break
      }
    }
  }

  public func traverse<V: SwiftProtobuf.Visitor>(visitor: inout V) throws {
    // The use of inline closures is to circumvent an issue where the compiler
    // allocates stack space for every if/case branch local when no optimizations
    // are enabled. https://github.com/apple/swift-protobuf/issues/1034 and
    // https://github.com/apple/swift-protobuf/issues/1182
    try { if let v = self._addressesOrInstallationIds {
      try visitor.visitSingularMessageField(value: v, fieldNumber: 1)
    } }()
    try unknownFields.traverse(visitor: &visitor)
  }

  public static func ==(lhs: Xmtp_Mls_Database_AddMembersData.V1, rhs: Xmtp_Mls_Database_AddMembersData.V1) -> Bool {
    if lhs._addressesOrInstallationIds != rhs._addressesOrInstallationIds {return false}
    if lhs.unknownFields != rhs.unknownFields {return false}
    return true
  }
}

extension Xmtp_Mls_Database_RemoveMembersData: SwiftProtobuf.Message, SwiftProtobuf._MessageImplementationBase, SwiftProtobuf._ProtoNameProviding {
  public static let protoMessageName: String = _protobuf_package + ".RemoveMembersData"
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
        var v: Xmtp_Mls_Database_RemoveMembersData.V1?
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

  public static func ==(lhs: Xmtp_Mls_Database_RemoveMembersData, rhs: Xmtp_Mls_Database_RemoveMembersData) -> Bool {
    if lhs.version != rhs.version {return false}
    if lhs.unknownFields != rhs.unknownFields {return false}
    return true
  }
}

extension Xmtp_Mls_Database_RemoveMembersData.V1: SwiftProtobuf.Message, SwiftProtobuf._MessageImplementationBase, SwiftProtobuf._ProtoNameProviding {
  public static let protoMessageName: String = Xmtp_Mls_Database_RemoveMembersData.protoMessageName + ".V1"
  public static let _protobuf_nameMap: SwiftProtobuf._NameMap = [
    1: .standard(proto: "addresses_or_installation_ids"),
  ]

  public mutating func decodeMessage<D: SwiftProtobuf.Decoder>(decoder: inout D) throws {
    while let fieldNumber = try decoder.nextFieldNumber() {
      // The use of inline closures is to circumvent an issue where the compiler
      // allocates stack space for every case branch when no optimizations are
      // enabled. https://github.com/apple/swift-protobuf/issues/1034
      switch fieldNumber {
      case 1: try { try decoder.decodeSingularMessageField(value: &self._addressesOrInstallationIds) }()
      default: break
      }
    }
  }

  public func traverse<V: SwiftProtobuf.Visitor>(visitor: inout V) throws {
    // The use of inline closures is to circumvent an issue where the compiler
    // allocates stack space for every if/case branch local when no optimizations
    // are enabled. https://github.com/apple/swift-protobuf/issues/1034 and
    // https://github.com/apple/swift-protobuf/issues/1182
    try { if let v = self._addressesOrInstallationIds {
      try visitor.visitSingularMessageField(value: v, fieldNumber: 1)
    } }()
    try unknownFields.traverse(visitor: &visitor)
  }

  public static func ==(lhs: Xmtp_Mls_Database_RemoveMembersData.V1, rhs: Xmtp_Mls_Database_RemoveMembersData.V1) -> Bool {
    if lhs._addressesOrInstallationIds != rhs._addressesOrInstallationIds {return false}
    if lhs.unknownFields != rhs.unknownFields {return false}
    return true
  }
}

extension Xmtp_Mls_Database_PostCommitAction: SwiftProtobuf.Message, SwiftProtobuf._MessageImplementationBase, SwiftProtobuf._ProtoNameProviding {
  public static let protoMessageName: String = _protobuf_package + ".PostCommitAction"
  public static let _protobuf_nameMap: SwiftProtobuf._NameMap = [
    1: .standard(proto: "send_welcomes"),
  ]

  public mutating func decodeMessage<D: SwiftProtobuf.Decoder>(decoder: inout D) throws {
    while let fieldNumber = try decoder.nextFieldNumber() {
      // The use of inline closures is to circumvent an issue where the compiler
      // allocates stack space for every case branch when no optimizations are
      // enabled. https://github.com/apple/swift-protobuf/issues/1034
      switch fieldNumber {
      case 1: try {
        var v: Xmtp_Mls_Database_PostCommitAction.SendWelcomes?
        var hadOneofValue = false
        if let current = self.kind {
          hadOneofValue = true
          if case .sendWelcomes(let m) = current {v = m}
        }
        try decoder.decodeSingularMessageField(value: &v)
        if let v = v {
          if hadOneofValue {try decoder.handleConflictingOneOf()}
          self.kind = .sendWelcomes(v)
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
    try { if case .sendWelcomes(let v)? = self.kind {
      try visitor.visitSingularMessageField(value: v, fieldNumber: 1)
    } }()
    try unknownFields.traverse(visitor: &visitor)
  }

  public static func ==(lhs: Xmtp_Mls_Database_PostCommitAction, rhs: Xmtp_Mls_Database_PostCommitAction) -> Bool {
    if lhs.kind != rhs.kind {return false}
    if lhs.unknownFields != rhs.unknownFields {return false}
    return true
  }
}

extension Xmtp_Mls_Database_PostCommitAction.Installation: SwiftProtobuf.Message, SwiftProtobuf._MessageImplementationBase, SwiftProtobuf._ProtoNameProviding {
  public static let protoMessageName: String = Xmtp_Mls_Database_PostCommitAction.protoMessageName + ".Installation"
  public static let _protobuf_nameMap: SwiftProtobuf._NameMap = [
    1: .standard(proto: "installation_key"),
    2: .standard(proto: "hpke_public_key"),
  ]

  public mutating func decodeMessage<D: SwiftProtobuf.Decoder>(decoder: inout D) throws {
    while let fieldNumber = try decoder.nextFieldNumber() {
      // The use of inline closures is to circumvent an issue where the compiler
      // allocates stack space for every case branch when no optimizations are
      // enabled. https://github.com/apple/swift-protobuf/issues/1034
      switch fieldNumber {
      case 1: try { try decoder.decodeSingularBytesField(value: &self.installationKey) }()
      case 2: try { try decoder.decodeSingularBytesField(value: &self.hpkePublicKey) }()
      default: break
      }
    }
  }

  public func traverse<V: SwiftProtobuf.Visitor>(visitor: inout V) throws {
    if !self.installationKey.isEmpty {
      try visitor.visitSingularBytesField(value: self.installationKey, fieldNumber: 1)
    }
    if !self.hpkePublicKey.isEmpty {
      try visitor.visitSingularBytesField(value: self.hpkePublicKey, fieldNumber: 2)
    }
    try unknownFields.traverse(visitor: &visitor)
  }

  public static func ==(lhs: Xmtp_Mls_Database_PostCommitAction.Installation, rhs: Xmtp_Mls_Database_PostCommitAction.Installation) -> Bool {
    if lhs.installationKey != rhs.installationKey {return false}
    if lhs.hpkePublicKey != rhs.hpkePublicKey {return false}
    if lhs.unknownFields != rhs.unknownFields {return false}
    return true
  }
}

extension Xmtp_Mls_Database_PostCommitAction.SendWelcomes: SwiftProtobuf.Message, SwiftProtobuf._MessageImplementationBase, SwiftProtobuf._ProtoNameProviding {
  public static let protoMessageName: String = Xmtp_Mls_Database_PostCommitAction.protoMessageName + ".SendWelcomes"
  public static let _protobuf_nameMap: SwiftProtobuf._NameMap = [
    1: .same(proto: "installations"),
    2: .standard(proto: "welcome_message"),
  ]

  public mutating func decodeMessage<D: SwiftProtobuf.Decoder>(decoder: inout D) throws {
    while let fieldNumber = try decoder.nextFieldNumber() {
      // The use of inline closures is to circumvent an issue where the compiler
      // allocates stack space for every case branch when no optimizations are
      // enabled. https://github.com/apple/swift-protobuf/issues/1034
      switch fieldNumber {
      case 1: try { try decoder.decodeRepeatedMessageField(value: &self.installations) }()
      case 2: try { try decoder.decodeSingularBytesField(value: &self.welcomeMessage) }()
      default: break
      }
    }
  }

  public func traverse<V: SwiftProtobuf.Visitor>(visitor: inout V) throws {
    if !self.installations.isEmpty {
      try visitor.visitRepeatedMessageField(value: self.installations, fieldNumber: 1)
    }
    if !self.welcomeMessage.isEmpty {
      try visitor.visitSingularBytesField(value: self.welcomeMessage, fieldNumber: 2)
    }
    try unknownFields.traverse(visitor: &visitor)
  }

  public static func ==(lhs: Xmtp_Mls_Database_PostCommitAction.SendWelcomes, rhs: Xmtp_Mls_Database_PostCommitAction.SendWelcomes) -> Bool {
    if lhs.installations != rhs.installations {return false}
    if lhs.welcomeMessage != rhs.welcomeMessage {return false}
    if lhs.unknownFields != rhs.unknownFields {return false}
    return true
  }
}
