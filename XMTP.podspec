Pod::Spec.new do |spec|
  spec.name         = "XMTP"
  spec.version      = "4.4.0"

  spec.summary      = "XMTP SDK Cocoapod"

  spec.description  = <<-DESC
  The XMTP cocoapod implements the XMTP protocol for iOS. It handles cryptographic operations and network communication with the XMTP network.
                   DESC

  spec.homepage     	= "https://github.com/xmtp/xmtp-ios"

  spec.license      	= "MIT"
  spec.author       	= { "XMTP" => "eng@xmtp.com" }

  spec.platform      	= :ios, '14.0', :macos, '11.0'

  spec.swift_version  = '5.3'

  spec.source       	= { :git => "https://github.com/xmtp/xmtp-ios.git", :tag => "#{spec.version}" }
  # Exclude LibXMTP sources; they are provided by the LibXMTP pod
  spec.source_files  	= "Sources/**/*.swift"
  spec.exclude_files 	= "Sources/LibXMTP/**/*"
  spec.frameworks 		= "CryptoKit", "UIKit"
  spec.frameworks      += ["CoreFoundation", "SystemConfiguration"]

  spec.dependency 'CSecp256k1', '~> 0.2'
  spec.dependency "Connect-Swift", "= 1.0.0"
  spec.dependency 'CryptoSwift', '= 1.8.3'
  spec.dependency 'SQLCipher', '= 4.5.7'
  spec.dependency 'LibXMTP', '= 4.4.0'

  # Prepare vendored binary (wrapper is committed in Sources/LibXMTP)
  spec.prepare_command = <<-CMD
    set -euo pipefail
    ZIP_URL="https://github.com/xmtp/libxmtp/releases/download/swift-bindings-1.4.0.a9d19aa/LibXMTPSwiftFFI.zip"

    curl -L "$ZIP_URL" -o LibXMTPSwiftFFI.zip
    rm -rf LibXMTPSwiftFFI.xcframework
    unzip -o LibXMTPSwiftFFI.zip -d . >/dev/null
    rm -f LibXMTPSwiftFFI.zip
  CMD

  spec.vendored_frameworks = 'LibXMTPSwiftFFI.xcframework'
  
  spec.ios.deployment_target = '14.0'
end
