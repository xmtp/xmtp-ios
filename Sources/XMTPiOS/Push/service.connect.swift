// Code generated by protoc-gen-connect-swift. DO NOT EDIT.
//
// Source: notifications/v1/service.proto
//

import Connect
import Foundation
import SwiftProtobuf

public protocol Notifications_V1_NotificationsClientInterface: Sendable {

	@discardableResult
	func `registerInstallation`(request: Notifications_V1_RegisterInstallationRequest, headers: Connect.Headers, completion: @escaping @Sendable (ResponseMessage<Notifications_V1_RegisterInstallationResponse>) -> Void) -> Connect.Cancelable

	@available(iOS 13, *)
	func `registerInstallation`(request: Notifications_V1_RegisterInstallationRequest, headers: Connect.Headers) async -> ResponseMessage<Notifications_V1_RegisterInstallationResponse>

	@discardableResult
	func `deleteInstallation`(request: Notifications_V1_DeleteInstallationRequest, headers: Connect.Headers, completion: @escaping @Sendable (ResponseMessage<SwiftProtobuf.Google_Protobuf_Empty>) -> Void) -> Connect.Cancelable

	@available(iOS 13, *)
	func `deleteInstallation`(request: Notifications_V1_DeleteInstallationRequest, headers: Connect.Headers) async -> ResponseMessage<SwiftProtobuf.Google_Protobuf_Empty>

	@discardableResult
	func `subscribe`(request: Notifications_V1_SubscribeRequest, headers: Connect.Headers, completion: @escaping @Sendable (ResponseMessage<SwiftProtobuf.Google_Protobuf_Empty>) -> Void) -> Connect.Cancelable

	@available(iOS 13, *)
	func `subscribe`(request: Notifications_V1_SubscribeRequest, headers: Connect.Headers) async -> ResponseMessage<SwiftProtobuf.Google_Protobuf_Empty>

	@discardableResult
	func `subscribeWithMetadata`(request: Notifications_V1_SubscribeWithMetadataRequest, headers: Connect.Headers, completion: @escaping @Sendable (ResponseMessage<SwiftProtobuf.Google_Protobuf_Empty>) -> Void) -> Connect.Cancelable

	@available(iOS 13, *)
	func `subscribeWithMetadata`(request: Notifications_V1_SubscribeWithMetadataRequest, headers: Connect.Headers) async -> ResponseMessage<SwiftProtobuf.Google_Protobuf_Empty>

	@discardableResult
	func `unsubscribe`(request: Notifications_V1_UnsubscribeRequest, headers: Connect.Headers, completion: @escaping @Sendable (ResponseMessage<SwiftProtobuf.Google_Protobuf_Empty>) -> Void) -> Connect.Cancelable

	@available(iOS 13, *)
	func `unsubscribe`(request: Notifications_V1_UnsubscribeRequest, headers: Connect.Headers) async -> ResponseMessage<SwiftProtobuf.Google_Protobuf_Empty>
}

/// Concrete implementation of `Notifications_V1_NotificationsClientInterface`.
public final class Notifications_V1_NotificationsClient: Notifications_V1_NotificationsClientInterface, Sendable {
	private let client: Connect.ProtocolClientInterface

	public init(client: Connect.ProtocolClientInterface) {
		self.client = client
	}

	@discardableResult
	public func `registerInstallation`(request: Notifications_V1_RegisterInstallationRequest, headers: Connect.Headers = [:], completion: @escaping @Sendable (ResponseMessage<Notifications_V1_RegisterInstallationResponse>) -> Void) -> Connect.Cancelable {
		return self.client.unary(path: "/notifications.v1.Notifications/RegisterInstallation", idempotencyLevel: .unknown, request: request, headers: headers, completion: completion)
	}

	@available(iOS 13, *)
	public func `registerInstallation`(request: Notifications_V1_RegisterInstallationRequest, headers: Connect.Headers = [:]) async -> ResponseMessage<Notifications_V1_RegisterInstallationResponse> {
		return await self.client.unary(path: "/notifications.v1.Notifications/RegisterInstallation", idempotencyLevel: .unknown, request: request, headers: headers)
	}

	@discardableResult
	public func `deleteInstallation`(request: Notifications_V1_DeleteInstallationRequest, headers: Connect.Headers = [:], completion: @escaping @Sendable (ResponseMessage<SwiftProtobuf.Google_Protobuf_Empty>) -> Void) -> Connect.Cancelable {
		return self.client.unary(path: "/notifications.v1.Notifications/DeleteInstallation", idempotencyLevel: .unknown, request: request, headers: headers, completion: completion)
	}

	@available(iOS 13, *)
	public func `deleteInstallation`(request: Notifications_V1_DeleteInstallationRequest, headers: Connect.Headers = [:]) async -> ResponseMessage<SwiftProtobuf.Google_Protobuf_Empty> {
		return await self.client.unary(path: "/notifications.v1.Notifications/DeleteInstallation", idempotencyLevel: .unknown, request: request, headers: headers)
	}

	@discardableResult
	public func `subscribe`(request: Notifications_V1_SubscribeRequest, headers: Connect.Headers = [:], completion: @escaping @Sendable (ResponseMessage<SwiftProtobuf.Google_Protobuf_Empty>) -> Void) -> Connect.Cancelable {
		return self.client.unary(path: "/notifications.v1.Notifications/Subscribe", idempotencyLevel: .unknown, request: request, headers: headers, completion: completion)
	}

	@available(iOS 13, *)
	public func `subscribe`(request: Notifications_V1_SubscribeRequest, headers: Connect.Headers = [:]) async -> ResponseMessage<SwiftProtobuf.Google_Protobuf_Empty> {
		return await self.client.unary(path: "/notifications.v1.Notifications/Subscribe", idempotencyLevel: .unknown, request: request, headers: headers)
	}

	@discardableResult
	public func `subscribeWithMetadata`(request: Notifications_V1_SubscribeWithMetadataRequest, headers: Connect.Headers = [:], completion: @escaping @Sendable (ResponseMessage<SwiftProtobuf.Google_Protobuf_Empty>) -> Void) -> Connect.Cancelable {
		return self.client.unary(path: "/notifications.v1.Notifications/SubscribeWithMetadata", idempotencyLevel: .unknown, request: request, headers: headers, completion: completion)
	}

	@available(iOS 13, *)
	public func `subscribeWithMetadata`(request: Notifications_V1_SubscribeWithMetadataRequest, headers: Connect.Headers = [:]) async -> ResponseMessage<SwiftProtobuf.Google_Protobuf_Empty> {
		return await self.client.unary(path: "/notifications.v1.Notifications/SubscribeWithMetadata", idempotencyLevel: .unknown, request: request, headers: headers)
	}

	@discardableResult
	public func `unsubscribe`(request: Notifications_V1_UnsubscribeRequest, headers: Connect.Headers = [:], completion: @escaping @Sendable (ResponseMessage<SwiftProtobuf.Google_Protobuf_Empty>) -> Void) -> Connect.Cancelable {
		return self.client.unary(path: "/notifications.v1.Notifications/Unsubscribe", idempotencyLevel: .unknown, request: request, headers: headers, completion: completion)
	}

	@available(iOS 13, *)
	public func `unsubscribe`(request: Notifications_V1_UnsubscribeRequest, headers: Connect.Headers = [:]) async -> ResponseMessage<SwiftProtobuf.Google_Protobuf_Empty> {
		return await self.client.unary(path: "/notifications.v1.Notifications/Unsubscribe", idempotencyLevel: .unknown, request: request, headers: headers)
	}

	public enum Metadata {
		public enum Methods {
			public static let registerInstallation = Connect.MethodSpec(name: "RegisterInstallation", service: "notifications.v1.Notifications", type: .unary)
			public static let deleteInstallation = Connect.MethodSpec(name: "DeleteInstallation", service: "notifications.v1.Notifications", type: .unary)
			public static let subscribe = Connect.MethodSpec(name: "Subscribe", service: "notifications.v1.Notifications", type: .unary)
			public static let subscribeWithMetadata = Connect.MethodSpec(name: "SubscribeWithMetadata", service: "notifications.v1.Notifications", type: .unary)
			public static let unsubscribe = Connect.MethodSpec(name: "Unsubscribe", service: "notifications.v1.Notifications", type: .unary)
		}
	}
}
