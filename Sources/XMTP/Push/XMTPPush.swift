//
//  XMTPPush.swift
//
//
//  Created by Pat Nakajima on 1/20/23.
//

import Connect
import UIKit
import UserNotifications

public struct XMTPPush {
	public static var shared = XMTPPush()

	var installationID: String
	var installationIDKey: String = "installationID"

	private init() {
		if let id = UserDefaults.standard.string(forKey: installationIDKey) {
			installationID = id
		} else {
			installationID = UUID().uuidString
		}
	}

	public func request() async throws -> Bool {
		if try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge]) {
			await UIApplication.shared.registerForRemoteNotifications()

			return true
		}

		return false
	}

	public func register(token: String) async {
		let request = Notifications_V1_RegisterInstallationRequest.with { request in
			request.installationID = installationID
			request.deliveryMechanism = Notifications_V1_DeliveryMechanism.with { delivery in
				delivery.apnsDeviceToken = token
				delivery.deliveryMechanismType = .apnsDeviceToken(token)
			}
		}

		_ = await client.registerInstallation(request: request)
	}

	public func subscribe(topics: [String]) async {
		let request = Notifications_V1_SubscribeRequest.with { request in
			request.installationID = installationID
			request.topics = topics
		}

		_ = await client.subscribe(request: request)
	}

	var client: Notifications_V1_NotificationsClient = {
		var protocolClient = ProtocolClient(
			host: "https://69fb9fe214ef.ngrok.io",
			httpClient: URLSessionHTTPClient(),
			ProtoClientOption(),
			ConnectClientOption() // Use the Connect protocol
		)

		return Notifications_V1_NotificationsClient(client: protocolClient)
	}()
}
