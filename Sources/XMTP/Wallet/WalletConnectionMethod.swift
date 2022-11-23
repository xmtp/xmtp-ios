//
//  WalletConnectionMethod.swift
//
//
//  Created by Pat Nakajima on 11/22/22.
//

import CoreImage.CIFilterBuiltins
import UIKit

protocol WalletConnectionMethod {
	var type: WalletConnectionMethodType { get }
}

enum WalletConnectionMethodType {
	case redirect, qrCode(UIImage), manual(String)
}

struct WalletRedirectConnectionMethod: WalletConnectionMethod {
	var redirectURI: String
	var type: WalletConnectionMethodType {
		.redirect
	}
}

struct WalletQRCodeConnectionMethod: WalletConnectionMethod {
	var redirectURI: String
	var type: WalletConnectionMethodType {
		let data = Data(redirectURI.utf8)
		let context = CIContext()
		let filter = CIFilter.qrCodeGenerator()
		filter.setValue(data, forKey: "inputMessage")

		// swiftlint:disable force_unwrapping
		let outputImage = filter.outputImage!
		let scaledImage = outputImage.transformed(by: CGAffineTransform(scaleX: 3, y: 3))
		let cgImage = context.createCGImage(scaledImage, from: scaledImage.extent)!
		// swiftlint:enable force_unwrapping

		let image = UIImage(cgImage: cgImage)

		return .qrCode(image)
	}
}

struct WalletManualConnectionMethod: WalletConnectionMethod {
	var redirectURI: String
	var type: WalletConnectionMethodType {
		.manual(redirectURI)
	}
}
