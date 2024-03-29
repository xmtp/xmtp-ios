// DO NOT EDIT.
// swift-format-ignore-file
//
// Generated by the Swift generator plugin for the protocol buffer compiler.
// Source: mls/message_contents/group_metadata.proto
//
// For information on using the generated types, please see the documentation:
//   https://github.com/apple/swift-protobuf/

/// Group metadata

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

/// Defines the type of conversation
public enum Xmtp_Mls_MessageContents_ConversationType: SwiftProtobuf.Enum {
  public typealias RawValue = Int
  case unspecified // = 0
  case group // = 1
  case dm // = 2
  case UNRECOGNIZED(Int)

  public init() {
    self = .unspecified
  }

  public init?(rawValue: Int) {
    switch rawValue {
    case 0: self = .unspecified
    case 1: self = .group
    case 2: self = .dm
    default: self = .UNRECOGNIZED(rawValue)
    }
  }

  public var rawValue: Int {
    switch self {
    case .unspecified: return 0
    case .group: return 1
    case .dm: return 2
    case .UNRECOGNIZED(let i): return i
    }
  }

}

#if swift(>=4.2)

extension Xmtp_Mls_MessageContents_ConversationType: CaseIterable {
  // The compiler won't synthesize support with the UNRECOGNIZED case.
  public static let allCases: [Xmtp_Mls_MessageContents_ConversationType] = [
    .unspecified,
    .group,
    .dm,
  ]
}

#endif  // swift(>=4.2)

/// Parent message for group metadata
public struct Xmtp_Mls_MessageContents_GroupMetadataV1 {
  // SwiftProtobuf.Message conformance is added in an extension below. See the
  // `Message` and `Message+*Additions` files in the SwiftProtobuf library for
  // methods supported on all messages.

  public var conversationType: Xmtp_Mls_MessageContents_ConversationType = .unspecified

  public var creatorAccountAddress: String = String()

  public var policies: Xmtp_Mls_MessageContents_PolicySet {
    get {return _policies ?? Xmtp_Mls_MessageContents_PolicySet()}
    set {_policies = newValue}
  }
  /// Returns true if `policies` has been explicitly set.
  public var hasPolicies: Bool {return self._policies != nil}
  /// Clears the value of `policies`. Subsequent reads from it will return its default value.
  public mutating func clearPolicies() {self._policies = nil}

  public var unknownFields = SwiftProtobuf.UnknownStorage()

  public init() {}

  fileprivate var _policies: Xmtp_Mls_MessageContents_PolicySet? = nil
}

/// The set of policies that govern the group
public struct Xmtp_Mls_MessageContents_PolicySet {
  // SwiftProtobuf.Message conformance is added in an extension below. See the
  // `Message` and `Message+*Additions` files in the SwiftProtobuf library for
  // methods supported on all messages.

  public var addMemberPolicy: Xmtp_Mls_MessageContents_MembershipPolicy {
    get {return _addMemberPolicy ?? Xmtp_Mls_MessageContents_MembershipPolicy()}
    set {_addMemberPolicy = newValue}
  }
  /// Returns true if `addMemberPolicy` has been explicitly set.
  public var hasAddMemberPolicy: Bool {return self._addMemberPolicy != nil}
  /// Clears the value of `addMemberPolicy`. Subsequent reads from it will return its default value.
  public mutating func clearAddMemberPolicy() {self._addMemberPolicy = nil}

  public var removeMemberPolicy: Xmtp_Mls_MessageContents_MembershipPolicy {
    get {return _removeMemberPolicy ?? Xmtp_Mls_MessageContents_MembershipPolicy()}
    set {_removeMemberPolicy = newValue}
  }
  /// Returns true if `removeMemberPolicy` has been explicitly set.
  public var hasRemoveMemberPolicy: Bool {return self._removeMemberPolicy != nil}
  /// Clears the value of `removeMemberPolicy`. Subsequent reads from it will return its default value.
  public mutating func clearRemoveMemberPolicy() {self._removeMemberPolicy = nil}

  public var unknownFields = SwiftProtobuf.UnknownStorage()

  public init() {}

  fileprivate var _addMemberPolicy: Xmtp_Mls_MessageContents_MembershipPolicy? = nil
  fileprivate var _removeMemberPolicy: Xmtp_Mls_MessageContents_MembershipPolicy? = nil
}

/// A policy that governs adding/removing members or installations
public struct Xmtp_Mls_MessageContents_MembershipPolicy {
  // SwiftProtobuf.Message conformance is added in an extension below. See the
  // `Message` and `Message+*Additions` files in the SwiftProtobuf library for
  // methods supported on all messages.

  public var kind: Xmtp_Mls_MessageContents_MembershipPolicy.OneOf_Kind? = nil

  public var base: Xmtp_Mls_MessageContents_MembershipPolicy.BasePolicy {
    get {
      if case .base(let v)? = kind {return v}
      return .unspecified
    }
    set {kind = .base(newValue)}
  }

  public var andCondition: Xmtp_Mls_MessageContents_MembershipPolicy.AndCondition {
    get {
      if case .andCondition(let v)? = kind {return v}
      return Xmtp_Mls_MessageContents_MembershipPolicy.AndCondition()
    }
    set {kind = .andCondition(newValue)}
  }

  public var anyCondition: Xmtp_Mls_MessageContents_MembershipPolicy.AnyCondition {
    get {
      if case .anyCondition(let v)? = kind {return v}
      return Xmtp_Mls_MessageContents_MembershipPolicy.AnyCondition()
    }
    set {kind = .anyCondition(newValue)}
  }

  public var unknownFields = SwiftProtobuf.UnknownStorage()

  public enum OneOf_Kind: Equatable {
    case base(Xmtp_Mls_MessageContents_MembershipPolicy.BasePolicy)
    case andCondition(Xmtp_Mls_MessageContents_MembershipPolicy.AndCondition)
    case anyCondition(Xmtp_Mls_MessageContents_MembershipPolicy.AnyCondition)

  #if !swift(>=4.1)
    public static func ==(lhs: Xmtp_Mls_MessageContents_MembershipPolicy.OneOf_Kind, rhs: Xmtp_Mls_MessageContents_MembershipPolicy.OneOf_Kind) -> Bool {
      // The use of inline closures is to circumvent an issue where the compiler
      // allocates stack space for every case branch when no optimizations are
      // enabled. https://github.com/apple/swift-protobuf/issues/1034
      switch (lhs, rhs) {
      case (.base, .base): return {
        guard case .base(let l) = lhs, case .base(let r) = rhs else { preconditionFailure() }
        return l == r
      }()
      case (.andCondition, .andCondition): return {
        guard case .andCondition(let l) = lhs, case .andCondition(let r) = rhs else { preconditionFailure() }
        return l == r
      }()
      case (.anyCondition, .anyCondition): return {
        guard case .anyCondition(let l) = lhs, case .anyCondition(let r) = rhs else { preconditionFailure() }
        return l == r
      }()
      default: return false
      }
    }
  #endif
  }

  /// Base policy
  public enum BasePolicy: SwiftProtobuf.Enum {
    public typealias RawValue = Int
    case unspecified // = 0
    case allow // = 1
    case deny // = 2
    case allowIfActorCreator // = 3
    case UNRECOGNIZED(Int)

    public init() {
      self = .unspecified
    }

    public init?(rawValue: Int) {
      switch rawValue {
      case 0: self = .unspecified
      case 1: self = .allow
      case 2: self = .deny
      case 3: self = .allowIfActorCreator
      default: self = .UNRECOGNIZED(rawValue)
      }
    }

    public var rawValue: Int {
      switch self {
      case .unspecified: return 0
      case .allow: return 1
      case .deny: return 2
      case .allowIfActorCreator: return 3
      case .UNRECOGNIZED(let i): return i
      }
    }

  }

  /// Combine multiple policies. All must evaluate to true
  public struct AndCondition {
    // SwiftProtobuf.Message conformance is added in an extension below. See the
    // `Message` and `Message+*Additions` files in the SwiftProtobuf library for
    // methods supported on all messages.

    public var policies: [Xmtp_Mls_MessageContents_MembershipPolicy] = []

    public var unknownFields = SwiftProtobuf.UnknownStorage()

    public init() {}
  }

  /// Combine multiple policies. Any must evaluate to true
  public struct AnyCondition {
    // SwiftProtobuf.Message conformance is added in an extension below. See the
    // `Message` and `Message+*Additions` files in the SwiftProtobuf library for
    // methods supported on all messages.

    public var policies: [Xmtp_Mls_MessageContents_MembershipPolicy] = []

    public var unknownFields = SwiftProtobuf.UnknownStorage()

    public init() {}
  }

  public init() {}
}

#if swift(>=4.2)

extension Xmtp_Mls_MessageContents_MembershipPolicy.BasePolicy: CaseIterable {
  // The compiler won't synthesize support with the UNRECOGNIZED case.
  public static let allCases: [Xmtp_Mls_MessageContents_MembershipPolicy.BasePolicy] = [
    .unspecified,
    .allow,
    .deny,
    .allowIfActorCreator,
  ]
}

#endif  // swift(>=4.2)

#if swift(>=5.5) && canImport(_Concurrency)
extension Xmtp_Mls_MessageContents_ConversationType: @unchecked Sendable {}
extension Xmtp_Mls_MessageContents_GroupMetadataV1: @unchecked Sendable {}
extension Xmtp_Mls_MessageContents_PolicySet: @unchecked Sendable {}
extension Xmtp_Mls_MessageContents_MembershipPolicy: @unchecked Sendable {}
extension Xmtp_Mls_MessageContents_MembershipPolicy.OneOf_Kind: @unchecked Sendable {}
extension Xmtp_Mls_MessageContents_MembershipPolicy.BasePolicy: @unchecked Sendable {}
extension Xmtp_Mls_MessageContents_MembershipPolicy.AndCondition: @unchecked Sendable {}
extension Xmtp_Mls_MessageContents_MembershipPolicy.AnyCondition: @unchecked Sendable {}
#endif  // swift(>=5.5) && canImport(_Concurrency)

// MARK: - Code below here is support for the SwiftProtobuf runtime.

fileprivate let _protobuf_package = "xmtp.mls.message_contents"

extension Xmtp_Mls_MessageContents_ConversationType: SwiftProtobuf._ProtoNameProviding {
  public static let _protobuf_nameMap: SwiftProtobuf._NameMap = [
    0: .same(proto: "CONVERSATION_TYPE_UNSPECIFIED"),
    1: .same(proto: "CONVERSATION_TYPE_GROUP"),
    2: .same(proto: "CONVERSATION_TYPE_DM"),
  ]
}

extension Xmtp_Mls_MessageContents_GroupMetadataV1: SwiftProtobuf.Message, SwiftProtobuf._MessageImplementationBase, SwiftProtobuf._ProtoNameProviding {
  public static let protoMessageName: String = _protobuf_package + ".GroupMetadataV1"
  public static let _protobuf_nameMap: SwiftProtobuf._NameMap = [
    1: .standard(proto: "conversation_type"),
    2: .standard(proto: "creator_account_address"),
    3: .same(proto: "policies"),
  ]

  public mutating func decodeMessage<D: SwiftProtobuf.Decoder>(decoder: inout D) throws {
    while let fieldNumber = try decoder.nextFieldNumber() {
      // The use of inline closures is to circumvent an issue where the compiler
      // allocates stack space for every case branch when no optimizations are
      // enabled. https://github.com/apple/swift-protobuf/issues/1034
      switch fieldNumber {
      case 1: try { try decoder.decodeSingularEnumField(value: &self.conversationType) }()
      case 2: try { try decoder.decodeSingularStringField(value: &self.creatorAccountAddress) }()
      case 3: try { try decoder.decodeSingularMessageField(value: &self._policies) }()
      default: break
      }
    }
  }

  public func traverse<V: SwiftProtobuf.Visitor>(visitor: inout V) throws {
    // The use of inline closures is to circumvent an issue where the compiler
    // allocates stack space for every if/case branch local when no optimizations
    // are enabled. https://github.com/apple/swift-protobuf/issues/1034 and
    // https://github.com/apple/swift-protobuf/issues/1182
    if self.conversationType != .unspecified {
      try visitor.visitSingularEnumField(value: self.conversationType, fieldNumber: 1)
    }
    if !self.creatorAccountAddress.isEmpty {
      try visitor.visitSingularStringField(value: self.creatorAccountAddress, fieldNumber: 2)
    }
    try { if let v = self._policies {
      try visitor.visitSingularMessageField(value: v, fieldNumber: 3)
    } }()
    try unknownFields.traverse(visitor: &visitor)
  }

  public static func ==(lhs: Xmtp_Mls_MessageContents_GroupMetadataV1, rhs: Xmtp_Mls_MessageContents_GroupMetadataV1) -> Bool {
    if lhs.conversationType != rhs.conversationType {return false}
    if lhs.creatorAccountAddress != rhs.creatorAccountAddress {return false}
    if lhs._policies != rhs._policies {return false}
    if lhs.unknownFields != rhs.unknownFields {return false}
    return true
  }
}

extension Xmtp_Mls_MessageContents_PolicySet: SwiftProtobuf.Message, SwiftProtobuf._MessageImplementationBase, SwiftProtobuf._ProtoNameProviding {
  public static let protoMessageName: String = _protobuf_package + ".PolicySet"
  public static let _protobuf_nameMap: SwiftProtobuf._NameMap = [
    1: .standard(proto: "add_member_policy"),
    2: .standard(proto: "remove_member_policy"),
  ]

  public mutating func decodeMessage<D: SwiftProtobuf.Decoder>(decoder: inout D) throws {
    while let fieldNumber = try decoder.nextFieldNumber() {
      // The use of inline closures is to circumvent an issue where the compiler
      // allocates stack space for every case branch when no optimizations are
      // enabled. https://github.com/apple/swift-protobuf/issues/1034
      switch fieldNumber {
      case 1: try { try decoder.decodeSingularMessageField(value: &self._addMemberPolicy) }()
      case 2: try { try decoder.decodeSingularMessageField(value: &self._removeMemberPolicy) }()
      default: break
      }
    }
  }

  public func traverse<V: SwiftProtobuf.Visitor>(visitor: inout V) throws {
    // The use of inline closures is to circumvent an issue where the compiler
    // allocates stack space for every if/case branch local when no optimizations
    // are enabled. https://github.com/apple/swift-protobuf/issues/1034 and
    // https://github.com/apple/swift-protobuf/issues/1182
    try { if let v = self._addMemberPolicy {
      try visitor.visitSingularMessageField(value: v, fieldNumber: 1)
    } }()
    try { if let v = self._removeMemberPolicy {
      try visitor.visitSingularMessageField(value: v, fieldNumber: 2)
    } }()
    try unknownFields.traverse(visitor: &visitor)
  }

  public static func ==(lhs: Xmtp_Mls_MessageContents_PolicySet, rhs: Xmtp_Mls_MessageContents_PolicySet) -> Bool {
    if lhs._addMemberPolicy != rhs._addMemberPolicy {return false}
    if lhs._removeMemberPolicy != rhs._removeMemberPolicy {return false}
    if lhs.unknownFields != rhs.unknownFields {return false}
    return true
  }
}

extension Xmtp_Mls_MessageContents_MembershipPolicy: SwiftProtobuf.Message, SwiftProtobuf._MessageImplementationBase, SwiftProtobuf._ProtoNameProviding {
  public static let protoMessageName: String = _protobuf_package + ".MembershipPolicy"
  public static let _protobuf_nameMap: SwiftProtobuf._NameMap = [
    1: .same(proto: "base"),
    2: .standard(proto: "and_condition"),
    3: .standard(proto: "any_condition"),
  ]

  public mutating func decodeMessage<D: SwiftProtobuf.Decoder>(decoder: inout D) throws {
    while let fieldNumber = try decoder.nextFieldNumber() {
      // The use of inline closures is to circumvent an issue where the compiler
      // allocates stack space for every case branch when no optimizations are
      // enabled. https://github.com/apple/swift-protobuf/issues/1034
      switch fieldNumber {
      case 1: try {
        var v: Xmtp_Mls_MessageContents_MembershipPolicy.BasePolicy?
        try decoder.decodeSingularEnumField(value: &v)
        if let v = v {
          if self.kind != nil {try decoder.handleConflictingOneOf()}
          self.kind = .base(v)
        }
      }()
      case 2: try {
        var v: Xmtp_Mls_MessageContents_MembershipPolicy.AndCondition?
        var hadOneofValue = false
        if let current = self.kind {
          hadOneofValue = true
          if case .andCondition(let m) = current {v = m}
        }
        try decoder.decodeSingularMessageField(value: &v)
        if let v = v {
          if hadOneofValue {try decoder.handleConflictingOneOf()}
          self.kind = .andCondition(v)
        }
      }()
      case 3: try {
        var v: Xmtp_Mls_MessageContents_MembershipPolicy.AnyCondition?
        var hadOneofValue = false
        if let current = self.kind {
          hadOneofValue = true
          if case .anyCondition(let m) = current {v = m}
        }
        try decoder.decodeSingularMessageField(value: &v)
        if let v = v {
          if hadOneofValue {try decoder.handleConflictingOneOf()}
          self.kind = .anyCondition(v)
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
    switch self.kind {
    case .base?: try {
      guard case .base(let v)? = self.kind else { preconditionFailure() }
      try visitor.visitSingularEnumField(value: v, fieldNumber: 1)
    }()
    case .andCondition?: try {
      guard case .andCondition(let v)? = self.kind else { preconditionFailure() }
      try visitor.visitSingularMessageField(value: v, fieldNumber: 2)
    }()
    case .anyCondition?: try {
      guard case .anyCondition(let v)? = self.kind else { preconditionFailure() }
      try visitor.visitSingularMessageField(value: v, fieldNumber: 3)
    }()
    case nil: break
    }
    try unknownFields.traverse(visitor: &visitor)
  }

  public static func ==(lhs: Xmtp_Mls_MessageContents_MembershipPolicy, rhs: Xmtp_Mls_MessageContents_MembershipPolicy) -> Bool {
    if lhs.kind != rhs.kind {return false}
    if lhs.unknownFields != rhs.unknownFields {return false}
    return true
  }
}

extension Xmtp_Mls_MessageContents_MembershipPolicy.BasePolicy: SwiftProtobuf._ProtoNameProviding {
  public static let _protobuf_nameMap: SwiftProtobuf._NameMap = [
    0: .same(proto: "BASE_POLICY_UNSPECIFIED"),
    1: .same(proto: "BASE_POLICY_ALLOW"),
    2: .same(proto: "BASE_POLICY_DENY"),
    3: .same(proto: "BASE_POLICY_ALLOW_IF_ACTOR_CREATOR"),
  ]
}

extension Xmtp_Mls_MessageContents_MembershipPolicy.AndCondition: SwiftProtobuf.Message, SwiftProtobuf._MessageImplementationBase, SwiftProtobuf._ProtoNameProviding {
  public static let protoMessageName: String = Xmtp_Mls_MessageContents_MembershipPolicy.protoMessageName + ".AndCondition"
  public static let _protobuf_nameMap: SwiftProtobuf._NameMap = [
    1: .same(proto: "policies"),
  ]

  public mutating func decodeMessage<D: SwiftProtobuf.Decoder>(decoder: inout D) throws {
    while let fieldNumber = try decoder.nextFieldNumber() {
      // The use of inline closures is to circumvent an issue where the compiler
      // allocates stack space for every case branch when no optimizations are
      // enabled. https://github.com/apple/swift-protobuf/issues/1034
      switch fieldNumber {
      case 1: try { try decoder.decodeRepeatedMessageField(value: &self.policies) }()
      default: break
      }
    }
  }

  public func traverse<V: SwiftProtobuf.Visitor>(visitor: inout V) throws {
    if !self.policies.isEmpty {
      try visitor.visitRepeatedMessageField(value: self.policies, fieldNumber: 1)
    }
    try unknownFields.traverse(visitor: &visitor)
  }

  public static func ==(lhs: Xmtp_Mls_MessageContents_MembershipPolicy.AndCondition, rhs: Xmtp_Mls_MessageContents_MembershipPolicy.AndCondition) -> Bool {
    if lhs.policies != rhs.policies {return false}
    if lhs.unknownFields != rhs.unknownFields {return false}
    return true
  }
}

extension Xmtp_Mls_MessageContents_MembershipPolicy.AnyCondition: SwiftProtobuf.Message, SwiftProtobuf._MessageImplementationBase, SwiftProtobuf._ProtoNameProviding {
  public static let protoMessageName: String = Xmtp_Mls_MessageContents_MembershipPolicy.protoMessageName + ".AnyCondition"
  public static let _protobuf_nameMap: SwiftProtobuf._NameMap = [
    1: .same(proto: "policies"),
  ]

  public mutating func decodeMessage<D: SwiftProtobuf.Decoder>(decoder: inout D) throws {
    while let fieldNumber = try decoder.nextFieldNumber() {
      // The use of inline closures is to circumvent an issue where the compiler
      // allocates stack space for every case branch when no optimizations are
      // enabled. https://github.com/apple/swift-protobuf/issues/1034
      switch fieldNumber {
      case 1: try { try decoder.decodeRepeatedMessageField(value: &self.policies) }()
      default: break
      }
    }
  }

  public func traverse<V: SwiftProtobuf.Visitor>(visitor: inout V) throws {
    if !self.policies.isEmpty {
      try visitor.visitRepeatedMessageField(value: self.policies, fieldNumber: 1)
    }
    try unknownFields.traverse(visitor: &visitor)
  }

  public static func ==(lhs: Xmtp_Mls_MessageContents_MembershipPolicy.AnyCondition, rhs: Xmtp_Mls_MessageContents_MembershipPolicy.AnyCondition) -> Bool {
    if lhs.policies != rhs.policies {return false}
    if lhs.unknownFields != rhs.unknownFields {return false}
    return true
  }
}
