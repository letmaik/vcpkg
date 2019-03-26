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

# TODO how to keep this up-to-date?
# TODO OE_API_VERSION is supposed to be set by the user, not here
# TODO OE_USE_LIBSGX/OE_BUILD_ENCLAVE needed? not used in public headers
set(defs "-DOE_API_VERSION=2 -DOE_USE_LIBSGX -DOE_BUILD_ENCLAVE")

set(compile_flags "-nostdinc -m64 -fPIC -fno-stack-protector -fvisibility=hidden")

# Temporary work-around: add compiler intrinsics headers to includes
# TODO this should probably be provided by OE
# FIXME CMAKE_C_COMPILER is not set yet (only after project()), so use gcc for now
#  -> Note that clang has it's own folder!
set(C_COMPILER gcc)
execute_process(
    COMMAND /bin/bash ${CMAKE_CURRENT_LIST_DIR}/get_c_compiler_dir.sh ${C_COMPILER}
    OUTPUT_VARIABLE C_COMPILER_INCDIR
    ERROR_VARIABLE err)
if (NOT err STREQUAL "")
    message(FATAL_ERROR ${err})
endif ()

set(include_dirs_c
    "-I${includedir}/openenclave/3rdparty/libc -I${includedir}/openenclave/3rdparty -I${includedir} -I${C_COMPILER_INCDIR}")

set(include_dirs_cxx
    "-I${includedir}/openenclave/3rdparty/libcxx ${include_dirs_c}")

string(APPEND CMAKE_C_FLAGS_INIT " ${compile_flags} ${include_dirs_c} ${defs} ${VCPKG_C_FLAGS} ")
string(APPEND CMAKE_CXX_FLAGS_INIT " ${compile_flags} ${include_dirs_cxx} ${defs} ${VCPKG_CXX_FLAGS} ")
string(APPEND CMAKE_C_FLAGS_DEBUG_INIT " ${VCPKG_C_FLAGS_DEBUG} ")
string(APPEND CMAKE_CXX_FLAGS_DEBUG_INIT " ${VCPKG_CXX_FLAGS_DEBUG} ")
string(APPEND CMAKE_C_FLAGS_RELEASE_INIT " ${VCPKG_C_FLAGS_RELEASE} ")
string(APPEND CMAKE_CXX_FLAGS_RELEASE_INIT " ${VCPKG_CXX_FLAGS_RELEASE} ")

string(APPEND CMAKE_SHARED_LINKER_FLAGS_INIT " ${linker_flags} ${VCPKG_LINKER_FLAGS} ")
string(APPEND CMAKE_EXE_LINKER_FLAGS_INIT " ${linker_flags} ${VCPKG_LINKER_FLAGS} ")

# We can't use CMAKE_*_LINKER_FLAGS_INIT to add libraries because the ordering
# wouldn't be right. Instead, inject the linked libraries and search paths to all targets.
# Note that this is not used in try_compile, but that should be fine.
link_directories(${link_dir})
link_libraries(${link_libs})

# so that find_package(Threads) is a no-op
set(prefix_oe ${CMAKE_CURRENT_LIST_DIR}/../../installed/x64-linux-oe)
set(CMAKE_MODULE_PATH ${prefix_oe}/share/openenclave/cmake ${CMAKE_MODULE_PATH})

endif()
