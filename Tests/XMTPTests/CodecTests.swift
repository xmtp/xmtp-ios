//
//  CodecTests.swift
//  
//
//  Created by Pat Nakajima on 12/16/22.
//

import XCTest
@testable import XMTP

class CodecTests: XCTestCase {
	func testTextCodecRoundtrip() throws {
		let encodedContent = try TextCodec().encode(content: "hello world")
		let decodedContent = try TextCodec().decode(content: encodedContent)
		XCTAssertEqual("hello world", decodedContent)
	}

	
}

