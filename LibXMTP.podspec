Pod::Spec.new do |spec|
  spec.name         = "LibXMTP"
  spec.version      = "4.4.0-dev"

  spec.summary      = "XMTP shared Rust code that powers cross-platform SDKs"
  spec.description  = <<-DESC
  LibXMTP provides the generated Swift bindings and vendored FFI binary used by XMTP iOS.
  DESC

  spec.homepage      = "https://github.com/xmtp/libxmtp-swift"
  spec.license       = { :type => 'MIT', :file => 'LICENSE' }
  spec.author        = { "XMTP Labs" => "eng@xmtp.com" }

  spec.platform      = :ios, '14.0'
  spec.osx.deployment_target = '13.0'
  spec.swift_version = '5.3'

  # Release artifact includes both the xcframework and Sources/LibXMTP/xmtpv3.swift
  spec.source        = { :http => "https://github.com/xmtp/libxmtp/releases/download/swift-bindings-1.4.0.a9d19aa/LibXMTPSwiftFFI.zip", :type => :zip }
  spec.vendored_frameworks = 'LibXMTPSwiftFFI.xcframework'
  spec.source_files  = 'Sources/LibXMTP/**/*'
  spec.frameworks    = ["CoreFoundation", "SystemConfiguration"]
  spec.libraries     = 'c++'
end


