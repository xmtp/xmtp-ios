Pod::Spec.new do |spec|
  spec.name         = "LibXMTP"
  spec.version      = "4.4.0-dev"

  spec.summary      = "XMTP shared Rust code that powers cross-platform SDKs"
  spec.description  = <<-DESC
  LibXMTP provides the generated Swift bindings and vendored FFI binary used by XMTP iOS.
  DESC

  spec.homepage      = "https://github.com/xmtp/xmtp-ios"
  spec.license       = "MIT"
  spec.author        = { "XMTP" => "eng@xmtp.com" }

  spec.platform      = :ios, '14.0', :macos, '11.0'
  spec.swift_version = '5.3'

  spec.source        = { :git => "https://github.com/xmtp/xmtp-ios.git", :tag => "#{spec.version}" }
  spec.source_files  = "Sources/LibXMTP/**/*"
  spec.frameworks    = ["CoreFoundation", "SystemConfiguration"]

  # Download vendored FFI binary matching the bindings
  spec.prepare_command = <<-CMD
    set -euo pipefail
    ZIP_URL="https://github.com/xmtp/libxmtp/releases/download/swift-bindings-1.4.0.a9d19aa/LibXMTPSwiftFFI.zip"
    curl -L "$ZIP_URL" -o LibXMTPSwiftFFI.zip
    rm -rf LibXMTPSwiftFFI.xcframework
    unzip -o LibXMTPSwiftFFI.zip -d . >/dev/null
    rm -f LibXMTPSwiftFFI.zip
  CMD

  spec.vendored_frameworks = 'LibXMTPSwiftFFI.xcframework'
end


