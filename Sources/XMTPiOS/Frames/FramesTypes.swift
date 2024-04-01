//
//  File.swift
//  
//
//  Created by Alex Risch on 3/28/24.
//

import Foundation

typealias AcceptedFrameClients = [String: String]

enum OpenFrameButton: Codable {
    case link(target: String, label: String)
    case mint(target: String, label: String)
    case post(target: String?, label: String)
    case postRedirect(target: String?, label: String)

    enum CodingKeys: CodingKey {
        case action, target, label
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let action = try container.decode(String.self, forKey: .action)
        let target = try container.decodeIfPresent(String.self, forKey: .target)
        let label = try container.decode(String.self, forKey: .label)

        switch action {
        case "link":
            self = .link(target: target!, label: label)
        case "mint":
            self = .mint(target: target!, label: label)
        case "post":
            self = .post(target: target, label: label)
        case "post_redirect":
            self = .postRedirect(target: target, label: label)
        default:
            throw DecodingError.dataCorruptedError(forKey: .action, in: container, debugDescription: "Invalid action value")
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .link(let target, let label):
            try container.encode("link", forKey: .action)
            try container.encode(target, forKey: .target)
            try container.encode(label, forKey: .label)
        case .mint(let target, let label):
            try container.encode("mint", forKey: .action)
            try container.encode(target, forKey: .target)
            try container.encode(label, forKey: .label)
        case .post(let target, let label):
            try container.encode("post", forKey: .action)
            try container.encode(target, forKey: .target)
            try container.encode(label, forKey: .label)
        case .postRedirect(let target, let label):
            try container.encode("post_redirect", forKey: .action)
            try container.encode(target, forKey: .target)
            try container.encode(label, forKey: .label)
        }
    }
}

struct OpenFrameImage: Codable {
    let content: String
    let aspectRatio: AspectRatio?
    let alt: String?
}

enum AspectRatio: String, Codable {
    case ratio_1_91_1 = "1.91.1"
    case ratio_1_1 = "1:1"
}

struct TextInput: Codable {
    let content: String
}

struct OpenFrameResult: Codable {
    let acceptedClients: AcceptedFrameClients
    let image: OpenFrameImage
    let postUrl: String?
    let textInput: TextInput?
    let buttons: [String: OpenFrameButton]?
    let ogImage: String
    let state: String?
};

struct GetMetadataResponse: Codable {
    let url: String
    let extractedTags: [String: String]
}

struct PostRedirectResponse: Codable  {
    let originalUrl: String
    let redirectedTo: String
};

struct OpenFramesUntrustedData: Codable {
    let url: String
        let timestamp: Int
        let buttonIndex: Int
        let inputText: String?
        let state: String?
}

typealias FramesApiRedirectResponse = PostRedirectResponse;

struct FramePostUntrustedData: Codable {
    let url: String
    let timestamp: UInt64
    let buttonIndex: Int32
    let inputText: String?
    let state: String?
    let walletAddress: String
    let opaqueConversationIdentifier: String
    let unixTimestamp: UInt32
}

struct FramePostTrustedData: Codable {
    let messageBytes: String
}

struct FramePostPayload: Codable {
    let clientProtocol: String
    let untrustedData: FramePostUntrustedData
    let trustedData: FramePostTrustedData
}

struct DmActionInputs: Codable {
    let conversationTopic: String?
    let participantAccountAddresses: [String]
}

struct GroupActionInputs: Codable {
    let groupId: Data
    let groupSecret: Data
}

enum ConversationActionInputs: Codable {
    case dm(DmActionInputs)
    case group(GroupActionInputs)
}

struct FrameActionInputs: Codable {
    let frameUrl: String
    let buttonIndex: Int32
    let inputText: String?
    let state: String?
    let conversationInputs: ConversationActionInputs
}

