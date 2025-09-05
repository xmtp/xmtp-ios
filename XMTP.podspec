Pod::Spec.new do |spec|
  spec.name         = "XMTP"
  spec.version      = "4.4.0-dev"

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
  spec.source_files  	= "Sources/**/*.swift"
  spec.frameworks 		= "CryptoKit", "UIKit", "CoreFoundation", "SystemConfiguration"

  spec.dependency 'CSecp256k1', '~> 0.2'
  spec.dependency "Connect-Swift", "= 1.0.0"
  spec.dependency 'CryptoSwift', '= 1.8.3'
  spec.dependency 'SQLCipher', '= 4.5.7'
  # Fetch the FFI binary at install time (no git-lfs needed)
  spec.prepare_command = <<-CMD
    set -euo pipefail
    ZIP_URL="https://github.com/xmtp/libxmtp/releases/download/swift-bindings-1.4.0.a9d19aa/LibXMTPSwiftFFI.zip"
    for i in 1 2 3; do
      if curl -L "$ZIP_URL" -o LibXMTPSwiftFFI.zip; then
        break
      fi
      echo "Retrying download... ($i)" && sleep 5
    done
    rm -rf LibXMTPSwiftFFI.xcframework
    unzip -o LibXMTPSwiftFFI.zip 'LibXMTPSwiftFFI.xcframework/*' -d . >/dev/null
    rm -f LibXMTPSwiftFFI.zip
  CMD
  spec.vendored_frameworks = 'LibXMTPSwiftFFI.xcframework'
  
  spec.ios.deployment_target = '14.0'
end
