unset CARGO_TARGET_DIR
pushd ${PODS_TARGET_SRCROOT}/pahkat/pahkat-client-core
[[ $CONFIGURATION == 'Release' ]] && V='--release' || V=''
cargo update
for i in {1..5}; do
    ${CARGO_HOME}/bin/cargo lipo --features ffi,prefix --package pahkat-client $V && break || echo "build failed" && cargo clean && sleep 1;
done
cp ${PODS_TARGET_SRCROOT}/pahkat/target/universal/${CONFIGURATION}/libpahkat_client.a ${PODS_TARGET_SRCROOT}/Libraries
