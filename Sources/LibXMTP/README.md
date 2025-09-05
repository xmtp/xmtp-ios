# LibXMTP local wrapper

This directory hosts the generated Swift bindings that wrap the vendored `LibXMTPSwiftFFI.xcframework`.

The wrapper file `xmtpv3.swift` is committed directly to this repository, so both SwiftPM and CocoaPods consume it without any network step.

If you regenerate the bindings, replace `xmtpv3.swift` with the new file and ensure the `LibXMTPSwiftFFI` binary URL (and checksum in Package.swift) stays in sync with the version used to generate the file.


