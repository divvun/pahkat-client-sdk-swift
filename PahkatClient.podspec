Pod::Spec.new { |spec|
  spec.name = 'PahkatClient'
  spec.version = '0.2.0'
  spec.summary = 'UNKNOWN'
  spec.authors = {
    'Brendan Molloy' => 'brendan@bbqsrc.net',
  }
  spec.license = { :type => 'Apache-2.0 OR MIT' }
  spec.homepage = 'UNKNOWN'
  spec.macos.deployment_target = '10.10'
  spec.ios.deployment_target = '8.0'
  spec.pod_target_xcconfig = {
    'ENABLE_BITCODE' => 'NO',
    'OTHER_LDFLAGS[sdk=iphoneos*][arch=arm64]' => '${PODS_TARGET_SRCROOT}/dist/aarch64-apple-ios/libpahkat_client.a',
    'OTHER_LDFLAGS[sdk=iphonesimulator*][arch=x86_64]' => '${PODS_TARGET_SRCROOT}/dist/x86_64-apple-ios/libpahkat_client.a',
    'OTHER_LDFLAGS[sdk=iphonesimulator*][arch=arm64]' => '${PODS_TARGET_SRCROOT}/dist/aarch64-apple-ios-sim/libpahkat_client.a',
    'OTHER_LDFLAGS[sdk=macos*][arch=x86_64]' => '${PODS_TARGET_SRCROOT}/dist/x86_64-apple-darwin/libpahkat_client.a',
    'OTHER_LDFLAGS[sdk=macos*][arch=arm64]' => '${PODS_TARGET_SRCROOT}/dist/aarch64-apple-darwin/libpahkat_client.a',
  }
  spec.preserve_paths = ['dist/**/*']
  spec.source_files = ['src/**/*']
  spec.source = {
    :http => 'https://github.com/divvun/pahkat-client-sdk-swift/releases/download/v#{spec.version}/cargo-pod.tgz',
  }
  spec.vendored_libraries = 'dist/aarch64-apple-ios/libpahkat_client.a'
}
