//
//  ContentTypeID.swift
//
//
//  Created by Pat Nakajima on 11/28/22.
//

public typealias ContentTypeID = Xmtp_MessageContents_ContentTypeId

public extension ContentTypeID {
	init(authorityID: String, typeID: String, versionMajor: Int, versionMinor: Int) {
		self.init()
		self.authorityID = authorityID
		self.typeID = typeID
		self.versionMajor = UInt32(versionMajor)
		self.versionMinor = UInt32(versionMinor)
	}
}

extension ContentTypeID {
	var id: String {
		"\(authorityID):\(typeID)"
	}

	var description: String {
		"\(authorityID)/\(typeID):\(versionMajor).\(versionMinor)"
	}
}

extension ContentTypeID: Codable {
    enum CodingKeys: CodingKey {
        case authorityID, typeID, versionMajor, versionMinor
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(authorityID, forKey: .authorityID)
        try container.encode(typeID, forKey: .typeID)
        try container.encode(versionMajor, forKey: .versionMajor)
        try container.encode(versionMinor, forKey: .versionMinor)
    }

    public init(from decoder: Decoder) throws {
        self.init()

        let container = try decoder.container(keyedBy: CodingKeys.self)
        authorityID = try container.decode(String.self, forKey: .authorityID)
        typeID = try container.decode(String.self, forKey: .typeID)
        versionMajor = try container.decode(UInt32.self, forKey: .versionMajor)
        versionMinor = try container.decode(UInt32.self, forKey: .versionMinor)
    }
}
