if(NOT _VCPKG_LINUX_OE_TOOLCHAIN)
set(_VCPKG_LINUX_OE_TOOLCHAIN 1)
if(NOT CMAKE_HOST_SYSTEM_NAME STREQUAL "Linux")
    message(FATAL_ERROR "Host system must be Linux")
endif()

# We're always cross-compiling.
set(CMAKE_CROSSCOMPILING ON CACHE BOOL "")
# Some linker flags prevent building regular executables, so limit try_compile.
set(CMAKE_TRY_COMPILE_TARGET_TYPE "STATIC_LIBRARY" CACHE STRING "")
set(CMAKE_SYSTEM_NAME Linux CACHE STRING "")
set(CMAKE_SYSTEM_VERSION "${CMAKE_HOST_SYSTEM_VERSION}" CACHE STRING "")
set(CMAKE_SYSTEM_PROCESSOR "${CMAKE_HOST_SYSTEM_PROCESSOR}" CACHE STRING "")
# Hint to apply OE-specific customizations if necessary.
# Not strictly required, just convenience.
set(OE_BUILD_ENCLAVE ON CACHE BOOL "")

# TODO is there a better way? VCPKG_ROOT not available here
get_filename_component(prefix "${CMAKE_CURRENT_LIST_DIR}/../../installed/x64-linux" REALPATH)
set(libdir "${prefix}/lib")
set(includedir "${prefix}/include")
if (NOT EXISTS "${libdir}/openenclave")
    message(FATAL_ERROR "Run 'vcpkg install openenclave' first")
endif()

# Linker flags are for building enclave images. Enclave images are not provided
# in vcpkg ports but are built by the user's project.
# Users have to add the following when they build their CMake project:
# -DCMAKE_TOOLCHAIN_FILE=/path/to/vcpkg/scripts/buildsystems/vcpkg.cmake
# -DVCPKG_CHAINLOAD_TOOLCHAIN_FILE=/path/to/vcpkg/scripts/toolchains/linux-oe.cmake
# -DVCPKG_TARGET_TRIPLET=x64-linux-oe
# Building an enclave image can be done with add_executable(foo ..).
# OE tools like oeedger8r or oesign can be located with
# find_program() after running 'vcpkg install openenclave:x64-linux-oe'.
set(linker_flags "-nostdlib -nodefaultlibs -nostartfiles -Wl,--no-undefined,-Bstatic,-Bsymbolic,--export-dynamic,-pie,--build-id")

# Inject library dependencies to all targets.
set(link_dir "${libdir}/openenclave/enclave")
set(link_libs oeenclave mbedx509 mbedcrypto oelibcxx oelibc oecore)

set(defs
    # important as it's used in public OE headers
    # TODO how to keep this up-to-date?
    -DOE_API_VERSION=2
    # TODO needed? not used in public headers
    -DOE_USE_LIBSGX
    # TODO needed? not used in public headers
    -DOE_BUILD_ENCLAVE
    )

set(compile_flags "-nostdinc -m64 -fPIC -fno-stack-protector -fvisibility=hidden")

set(include_dirs
    $<$<COMPILE_LANGUAGE:CXX>:${includedir}/openenclave/3rdparty/libcxx>
    ${includedir}/openenclave/3rdparty/libc 
    ${includedir}/openenclave/3rdparty
    ${includedir}
    )

# Note: This check only works when try_compile is used in project variant, not
# in source file variant. For the source file variant, the generated CMakeLists.txt
# copies over all compiler and linker variables to the CMakeLists.txt directly.
# TODO what's the point of the check? when would this help?
get_property( _CMAKE_IN_TRY_COMPILE GLOBAL PROPERTY IN_TRY_COMPILE )
if(NOT _CMAKE_IN_TRY_COMPILE)
    string(APPEND CMAKE_C_FLAGS_INIT " ${compile_flags} ${VCPKG_C_FLAGS} ")
    string(APPEND CMAKE_CXX_FLAGS_INIT " ${compile_flags} ${VCPKG_CXX_FLAGS} ")
    string(APPEND CMAKE_C_FLAGS_DEBUG_INIT " ${VCPKG_C_FLAGS_DEBUG} ")
    string(APPEND CMAKE_CXX_FLAGS_DEBUG_INIT " ${VCPKG_CXX_FLAGS_DEBUG} ")
    string(APPEND CMAKE_C_FLAGS_RELEASE_INIT " ${VCPKG_C_FLAGS_RELEASE} ")
    string(APPEND CMAKE_CXX_FLAGS_RELEASE_INIT " ${VCPKG_CXX_FLAGS_RELEASE} ")

    include_directories(${include_dirs})
    add_definitions(${defs})

    string(APPEND CMAKE_SHARED_LINKER_FLAGS_INIT " ${linker_flags} ${VCPKG_LINKER_FLAGS} ")
    string(APPEND CMAKE_EXE_LINKER_FLAGS_INIT " ${linker_flags} ${VCPKG_LINKER_FLAGS} ")

    link_directories(${link_dir})
    link_libraries(${link_libs})
endif()
endif()
