#
# Be sure to run `pod lib lint PahkatClient.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'PahkatClient'
  s.version          = '0.1.0'
  s.summary          = 'A short description of PahkatClient.'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
TODO: Add long description of the pod here.
                       DESC

  s.homepage         = 'https://github.com/bbqsrc/pahkat-client-sdk-swift'
  s.license          = { :type => 'Apache-2.0 OR MIT' }
  s.author           = { 'Brendan Molloy' => 'brendan@bbqsrc.net' }
  s.source           = { :git => 'https://github.com/bbqsrc/pahkat-client-sdk-swift', :tag => s.version.to_s }
  # s.static_framework = true

  s.macos.deployment_target = '10.10'
  s.ios.deployment_target = '8.0'
  s.pod_target_xcconfig = {
    'CARGO_HOME': "$(HOME)/.cargo",
    'OTHER_LDFLAGS': '-lpahkat_client',
    'ENABLE_BITCODE': 'NO',
    'LZMA_API_STATIC': '1',
    'DEFINES_MODULE' => 'YES'
  }
  s.macos.pod_target_xcconfig = {
    'LIBRARY_SEARCH_PATHS': '"${PODS_TARGET_SRCROOT}/pahkat-client-core/target/${CONFIGURATION}"'
  }
  s.ios.pod_target_xcconfig = {
    'LIBRARY_SEARCH_PATHS': '"${PODS_TARGET_SRCROOT}/pahkat-client-core/target/universal/${CONFIGURATION}"'
  }
  s.ios.script_phases = [
    {
      :name => "Build PahkatClient with Cargo",
      :execution_position => :before_compile,
      :script => "pushd ${PODS_TARGET_SRCROOT}/pahkat-client-core && ${CARGO_HOME}/bin/cargo lipo --xcode-integ --features ffi,prefix",
      :shell_path => "/bin/sh"
    }
  ]
  s.macos.script_phases = [
    {
      :name => "Build PahkatClient with Cargo",
      :execution_position => :before_compile,
      :script => "pushd ${PODS_TARGET_SRCROOT}/pahkat-client-core && ${CARGO_HOME}/bin/cargo build --lib --features ffi,macos,prefix && rm ${PODS_TARGET_SRCROOT}/pahkat-client-core/target/${CONFIGURATION}/*.dylib",
      :shell_path => "/bin/sh"
    }
  ]
  s.preserve_paths = "pahkat-client-core"
  s.source_files = 'PahkatClient/Classes/**/*'
  #s.ios.vendored_libraries = 'pahkat-client-core/target/universal/${CONFIGURATION}/libpahkat_client.a'
  #s.macos.vendored_libraries = 'pahkat-client-core/target/${CONFIGURATION}/libpahkat_client.a'
  s.public_header_files = 'PahkatClient/Classes/**/*.h'
end
