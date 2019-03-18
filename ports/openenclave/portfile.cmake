include(vcpkg_common_functions)

if (NOT VCPKG_CMAKE_SYSTEM_NAME STREQUAL "Linux")
    message(FATAL_ERROR "Only Linux supported")
endif()

if (NOT VCPKG_LIBRARY_LINKAGE STREQUAL "static")
    message(FATAL_ERROR "Only static library linkage supported")
endif()

# In the x64-linux-oe triplet, only copy over tools from x64-linux.
# This allows to use the tools during OE builds, for EDL generation or signing.
if (VCPKG_OE_BUILD_ENCLAVE)
    set(VCPKG_POLICY_EMPTY_INCLUDE_FOLDER enabled)
    get_filename_component(ROOT_INSTALLED_DIR ${CURRENT_INSTALLED_DIR} DIRECTORY)
    if (NOT EXISTS ${ROOT_INSTALLED_DIR}/x64-linux/tools/openenclave)
        message(FATAL_ERROR "Run 'vcpkg install openenclave:x64-linux' first")
    endif()
    file(MAKE_DIRECTORY "${CURRENT_PACKAGES_DIR}/tools")
    file(COPY ${ROOT_INSTALLED_DIR}/x64-linux/tools/openenclave
         DESTINATION ${CURRENT_PACKAGES_DIR}/tools)
    file(MAKE_DIRECTORY "${CURRENT_PACKAGES_DIR}/share/openenclave")
    file(COPY ${ROOT_INSTALLED_DIR}/x64-linux/share/openenclave/copyright
         DESTINATION ${CURRENT_PACKAGES_DIR}/share/openenclave)
    return()
endif()

vcpkg_from_github(
    OUT_SOURCE_PATH SOURCE_PATH
    REPO achamayou/openenclave
    REF v0.5.1
    SHA512 41cd8464f70c3782495c36a96323c5f0255559f561d127724900fd795ffc3282f0b25b9ffe0612d7f51ad04082188047cfe4d2fc6eec895166a712e9a03dddf4
    HEAD_REF master
)

if ("flc" IN_LIST FEATURES)
  set(USE_LIBSGX ON)
endif()

vcpkg_configure_cmake(
    SOURCE_PATH ${SOURCE_PATH}
    OPTIONS
        -DUSE_LIBSGX=${USE_LIBSGX}
)

vcpkg_install_cmake()

if(NOT DEFINED VCPKG_BUILD_TYPE OR VCPKG_BUILD_TYPE STREQUAL "release")
    file(READ ${CURRENT_PACKAGES_DIR}/lib/openenclave/cmake/openenclave-targets-release.cmake RELEASE_MODULE)
    string(REPLACE "\${_IMPORT_PREFIX}/bin/" "\${_IMPORT_PREFIX}/tools/openenclave/" RELEASE_MODULE "${RELEASE_MODULE}")
    file(WRITE ${CURRENT_PACKAGES_DIR}/lib/openenclave/cmake/openenclave-targets-release.cmake "${RELEASE_MODULE}")

    file(READ ${CURRENT_PACKAGES_DIR}/lib/openenclave/cmake/openenclave-config.cmake RELEASE_MODULE)
    string(REPLACE "${CURRENT_PACKAGES_DIR}" "${CURRENT_INSTALLED_DIR}" RELEASE_MODULE "${RELEASE_MODULE}")
    string(REPLACE "\${OE_PREFIX}/bin" "\${OE_PREFIX}/tools/openenclave" RELEASE_MODULE "${RELEASE_MODULE}")
    file(WRITE ${CURRENT_PACKAGES_DIR}/lib/openenclave/cmake/openenclave-config.cmake "${RELEASE_MODULE}")
endif()

if(NOT DEFINED VCPKG_BUILD_TYPE OR VCPKG_BUILD_TYPE STREQUAL "debug")
    file(READ ${CURRENT_PACKAGES_DIR}/debug/lib/openenclave/cmake/openenclave-targets.cmake DEBUG_MODULE)
    string(REPLACE "\${_IMPORT_PREFIX}/include" "\${_IMPORT_PREFIX}/../include" DEBUG_MODULE "${DEBUG_MODULE}")
    file(WRITE ${CURRENT_PACKAGES_DIR}/debug/lib/openenclave/cmake/openenclave-targets.cmake "${DEBUG_MODULE}")

    file(READ ${CURRENT_PACKAGES_DIR}/debug/lib/openenclave/cmake/openenclave-targets-debug.cmake DEBUG_MODULE)
    string(REPLACE "\${_IMPORT_PREFIX}/bin/" "\${_IMPORT_PREFIX}/../tools/openenclave/" DEBUG_MODULE "${DEBUG_MODULE}")
    file(WRITE ${CURRENT_PACKAGES_DIR}/debug/lib/openenclave/cmake/openenclave-targets-debug.cmake "${DEBUG_MODULE}")

    file(READ ${CURRENT_PACKAGES_DIR}/debug/lib/openenclave/cmake/openenclave-config.cmake DEBUG_MODULE)
    string(REPLACE "${CURRENT_PACKAGES_DIR}" "${CURRENT_INSTALLED_DIR}" DEBUG_MODULE "${DEBUG_MODULE}")
    string(REPLACE "\${OE_PREFIX}/bin" "\${OE_PREFIX}/../tools/openenclave" DEBUG_MODULE "${DEBUG_MODULE}")
    string(REPLACE "\${OE_PREFIX}/share" "\${OE_PREFIX}/../share" DEBUG_MODULE "${DEBUG_MODULE}")
    string(REPLACE "\${OE_PREFIX}/include" "\${OE_PREFIX}/../include" DEBUG_MODULE "${DEBUG_MODULE}")
    file(WRITE ${CURRENT_PACKAGES_DIR}/debug/lib/openenclave/cmake/openenclave-config.cmake "${DEBUG_MODULE}")
endif()

file(GLOB EXECUTABLES ${CURRENT_PACKAGES_DIR}/bin/oe*)
foreach(E IN LISTS EXECUTABLES)
    file(INSTALL ${E} DESTINATION ${CURRENT_PACKAGES_DIR}/tools/openenclave
            PERMISSIONS OWNER_READ OWNER_WRITE OWNER_EXECUTE GROUP_READ GROUP_WRITE GROUP_EXECUTE WORLD_READ)
endforeach()

file(REMOVE_RECURSE ${CURRENT_PACKAGES_DIR}/debug/include)
file(REMOVE_RECURSE ${CURRENT_PACKAGES_DIR}/debug/share)
file(REMOVE_RECURSE ${CURRENT_PACKAGES_DIR}/bin ${CURRENT_PACKAGES_DIR}/debug/bin)

file(INSTALL ${SOURCE_PATH}/LICENSE DESTINATION ${CURRENT_PACKAGES_DIR}/share/openenclave RENAME copyright)
