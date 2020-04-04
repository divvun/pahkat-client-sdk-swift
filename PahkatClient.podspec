Pod::Spec.new do |s|
  s.name             = 'PahkatClient'
  s.version          = '0.2.3'
  s.summary          = 'Swift SDK for Pahkat Client'
  s.description      = <<-DESC
  Swift SDK for Pahkat Client
                       DESC

  s.homepage         = 'https://github.com/divvun/pahkat-client-sdk-swift'
  s.license          = { :type => 'Apache-2.0 OR MIT' }
  s.author           = { 'Brendan Molloy' => 'brendan@bbqsrc.net' }
  s.source           = { :git => 'https://github.com/divvun/pahkat-client-sdk-swift', :tag => s.version.to_s }
  
  s.static_framework = true
  s.macos.deployment_target = '10.10'
  s.ios.deployment_target = '12.4'
  s.pod_target_xcconfig = {
    'CARGO_HOME': "$(HOME)/.cargo",
    'ENABLE_BITCODE': 'NO',
    'OTHER_LDFLAGS': '-lpahkat_client',
    'LZMA_API_STATIC': '1',
    'DEFINES_MODULE' => 'YES'
  }
  # s.macos.pod_target_xcconfig = {
  #   'LIBRARY_SEARCH_PATHS': '"${PODS_TARGET_SRCROOT}/pahkat/pahkat-client-core/target/${CONFIGURATION}"'
  # }
  # s.ios.pod_target_xcconfig = {
  #   'LIBRARY_SEARCH_PATHS': '"${PODS_TARGET_SRCROOT}/pahkat/pahkat-client-core/target/universal/${CONFIGURATION}"'
  # }
  # s.macos.user_target_xcconfig = {
  #   'LIBRARY_SEARCH_PATHS': '"${PODS_ROOT}/PahkatClient/pahkat/pahkat-client-core/target/${CONFIGURATION}"'
  # }
  # s.ios.user_target_xcconfig = {
  #   'LIBRARY_SEARCH_PATHS': '"${PODS_ROOT}/PahkatClient/pahkat/pahkat-client-core/target/universal/${CONFIGURATION}"'
  # }
  s.ios.script_phases = [
    {
      :name => "Build PahkatClient with Cargo",
      :execution_position => :before_compile,
      :script => "unset CARGO_TARGET_DIR &&\
          pushd ${PODS_TARGET_SRCROOT}/pahkat/pahkat-client-core &&\
          [[ $CONFIGURATION == 'Release' ]] && V='--release' || V='' &&\
          ${CARGO_HOME}/bin/cargo lipo --xcode-integ --features ffi,prefix $V &&\
          cp ${PODS_TARGET_SRCROOT}/pahkat/target/universal/${CONFIGURATION}/libpahkat_client.a ${PODS_TARGET_SRCROOT}/Libraries",
      :shell_path => "/bin/sh"
    }
  ]
  s.macos.script_phases = [
    {
      :name => "Build PahkatClient with Cargo",
      :execution_position => :before_compile,
      :script => "unset CARGO_TARGET_DIR &&\
          pushd ${PODS_TARGET_SRCROOT}/pahkat/pahkat-client-core &&\
          [[ $CONFIGURATION == 'Release' ]] && V='--release' || V='' &&\
          ${CARGO_HOME}/bin/cargo build --lib --features ffi,macos,prefix $V &&\
          cp ${PODS_TARGET_SRCROOT}/pahkat/target/${CONFIGURATION}/libpahkat_client.a ${PODS_TARGET_SRCROOT}/Libraries",
      :shell_path => "/bin/sh"
    }
  ]
  s.preserve_paths = "pahkat"
  s.source_files = 'PahkatClient/Classes/**/*'
  s.public_header_files = 'PahkatClient/Classes/**/*.h'
  s.vendored_libraries = 'Libraries/libpahkat_client.a'
end
