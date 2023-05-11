#
#  Be sure to run `pod spec lint XMTP.podspec' to ensure this is a
#  valid spec and to remove all comments including this before submitting the spec.
#
#  To learn more about Podspec attributes see https://guides.cocoapods.org/syntax/podspec.html
#  To see working Podspecs in the CocoaPods repo see https://github.com/CocoaPods/Specs/
#

Pod::Spec.new do |spec|

  # ―――  Spec Metadata  ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  #
  #  These will help people to find your library, and whilst it
  #  can feel like a chore to fill in it's definitely to your advantage. The
  #  summary should be tweet-length, and the description more in depth.
  #

  spec.name         = "XMTP"
  spec.version      = "0.2.0"
  spec.summary      = "XMTP pod."

  # This description is used to generate tags and improve search results.
  #   * Think: What does it do? Why did you write it? What is the focus?
  #   * Try to keep it short, snappy and to the point.
  #   * Write the description between the DESC delimiters below.
  #   * Finally, don't worry about the indent, CocoaPods strips it!
  spec.description  = <<-DESC
  TODO
                   DESC

  spec.homepage     	= "https://github.com/xmtp/xmtp-ios"

  spec.license      	= "MIT"
  spec.author       	= { "Pat Nakajima" => "pat@xmtp.com" }

	spec.platform      	= :ios, '14.0', :macos, '11.0'

  spec.swift_version  = '5.3'

  spec.source       	= { :git => "https://github.com/xmtp/xmtp-ios.git", :tag => "#{spec.version}" }
  spec.source_files  	= "Sources/**/*.swift"
  spec.frameworks 		= "CryptoKit", "UIKit"

  spec.dependency "web3.swift"
  spec.dependency "GzipSwift"
  spec.dependency "Connect-Swift"
  spec.dependency 'XMTPRust', '= 0.2.0-beta0'

  spec.xcconfig = {'VALID_ARCHS' =>  'arm64' }
#  spec.pod_target_xcconfig = { 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'arm64' }

#  def spec.post_install(target)
#    target.build_configurations.each do |config|
#      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '16.0'
#    end
#  end
end
