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
    trap 'echo "[prepare_command] Error on line $LINENO"; exit 1' ERR
    ZIP_URL="https://github.com/xmtp/libxmtp/releases/download/swift-bindings-1.4.0.a9d19aa/LibXMTPSwiftFFI.zip"
    EXPECTED_SHA256="a4bcf78ced5f4dd80c161a17a498bac508a30b59f72dfba9c5318020528ccc0e"
    echo "[prepare_command] Downloading LibXMTPSwiftFFI.zip..."
    curl --fail --location --show-error --silent "$ZIP_URL" -o LibXMTPSwiftFFI.zip
    echo "[prepare_command] Verifying checksum..."
    ACTUAL_SHA256=$(shasum -a 256 LibXMTPSwiftFFI.zip | awk '{print $1}')
    if [ "$ACTUAL_SHA256" != "$EXPECTED_SHA256" ]; then
      echo "[prepare_command] Checksum mismatch. Expected $EXPECTED_SHA256, got $ACTUAL_SHA256"; exit 1
    fi
    echo "[prepare_command] Unzipping xcframework..."
    rm -rf LibXMTPSwiftFFI.xcframework
    unzip -qo LibXMTPSwiftFFI.zip 'LibXMTPSwiftFFI.xcframework/*' -d .
    rm -f LibXMTPSwiftFFI.zip
    if [ ! -d LibXMTPSwiftFFI.xcframework ]; then
      echo "[prepare_command] LibXMTPSwiftFFI.xcframework not found after unzip"; exit 1
    fi
  CMD
  spec.vendored_frameworks = 'LibXMTPSwiftFFI.xcframework'
  
  spec.ios.deployment_target = '14.0'
end
