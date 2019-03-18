set(VCPKG_TARGET_ARCHITECTURE x64)
set(VCPKG_LIBRARY_LINKAGE static)
# must be specified but irrelevant with OE (not used in scripts/toolchains/linux-oe.cmake)
set(VCPKG_CRT_LINKAGE static)

set(VCPKG_CMAKE_SYSTEM_NAME Linux)
set(VCPKG_OE_BUILD_ENCLAVE ON)

# TODO is there a better way? VCPKG_ROOT not available here
set(VCPKG_CHAINLOAD_TOOLCHAIN_FILE "${CMAKE_CURRENT_LIST_DIR}/../scripts/toolchains/linux-oe.cmake")
