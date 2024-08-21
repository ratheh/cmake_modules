# Copyright 2024 DreamWorks Animation LLC
# SPDX-License-Identifier: Apache-2.0

# ================================================
# Convenience variables for checking the platform
# ================================================

set(UnixPlatforms Linux Darwin)
if(CMAKE_SYSTEM_NAME IN_LIST UnixPlatforms)
    set(IsUnixPlatform TRUE)
endif()

set(LinuxPlatforms Linux)
if(CMAKE_SYSTEM_NAME IN_LIST LinuxPlatforms)
    set(IsLinuxPlatform TRUE)
endif()

set(DarwinPlatforms Darwin)
if(CMAKE_SYSTEM_NAME IN_LIST DarwinPlatforms)
    set(IsDarwinPlatform TRUE)
endif()

set(WindowsPlatforms Windows)
if(CMAKE_SYSTEM_NAME IN_LIST WindowsPlatforms)
    set(IsWindowsPlatform TRUE)
endif()

# ================================================
# Platform-specific globals
# ================================================
include(CheckLanguage)

if(IsUnixPlatform)
    list(APPEND GLOBAL_COMPILE_DEFINITIONS PLATFORM_UNIX)
endif()

if(IsLinuxPlatform)
    list(APPEND GLOBAL_COMPILE_DEFINITIONS PLATFORM_LINUX)
endif()

if(IsDarwinPlatform)
    list(APPEND GLOBAL_COMPILE_DEFINITIONS PLATFORM_APPLE)
endif()

if(IsWindowsPlatform)
    list(APPEND GLOBAL_COMPILE_DEFINITIONS PLATFORM_WINDOWS)
endif()

if(IsDarwinPlatform)
    check_language(OBJCXX)

    if(CMAKE_OBJCXX_COMPILER)
        enable_language(OBJCXX)
    endif()

    if (CMAKE_CXX_COMPILER_ID STREQUAL Clang)
        set(CMAKE_CXX_STANDARD 17)
    endif()

    # Ignore Homebrew packages
    set(CMAKE_IGNORE_PATH /opt/homebrew)
    set(CMAKE_IGNORE_PREFIX_PATH /opt/homebrew)

    set(ISPC_COMPILER $ENV{ISPC} CACHE STRING "Path to ISPC compiler")
    set(CMAKE_XCODE_ATTRIBUTE_OTHER_CODE_SIGN_FLAGS "-o linker-signed")
    set(GLOBAL_LINK_FLAGS "-Wl,-ld_classic")
    set(GLOBAL_INSTALL_RPATH "@loader_path/" "@loader_path/../lib")
    set(GLOBAL_ISPC_FLAGS -D__aarch64__ -D__APPLE__ -D__ARM_NEON__ --pic)
    set(GLOBAL_ISPC_INSTRUCTION_SETS neon-i32x4)
    set(CMAKE_OSX_ARCHITECTURES arm64)
    set(GLOBAL_ISPC_ARCH aarch64)
    set(GLOBAL_ISPC_TARGET_OS macos)
elseif(IsLinuxPlatform)
    set(GLOBAL_CPP_FLAGS __AVX__)
    set(GLOBAL_LINK_FLAGS "-Wl,--enable-new-dtags")
    set(GLOBAL_INSTALL_RPATH "$ORIGIN" "$ORIGIN/../lib64" "${COMPILER_LIBRARY_DIR}")
    set(GLOBAL_ISPC_FLAGS --pic)
    set(GLOBAL_ISPC_INSTRUCTION_SETS avx2-i32x8)
elseif(IsWindowsPlatform)
    set(GLOBAL_CPP_FLAGS __AVX__)
    set(GLOBAL_INSTALL_RPATH "$ORIGIN" "$ORIGIN/../lib64" "${COMPILER_LIBRARY_DIR}")
    set(GLOBAL_ISPC_FLAGS -D__x86_64__ -D__WIN32__ -D__AVX__ -D__AVX2__ --dllexport)
    set(GLOBAL_ISPC_INSTRUCTION_SETS avx2-i32x8)
    set(ISPC_COMPILER $ENV{ISPC} CACHE STRING "Path to ISPC compiler")
    set(GLOBAL_ISPC_ARCH x86-64)
    set(GLOBAL_ISPC_TARGET_OS windows)
    set(CMAKE_WINDOWS_EXPORT_ALL_SYMBOLS 1) # Windows needs to be explicit with exporting symbols
    if (CMAKE_CXX_COMPILER_ID STREQUAL "MSVC")
        set(CMAKE_CXX_STANDARD 17)
    endif()
endif()

# ================================================
# Options
# ================================================
if(IsLinuxPlatform OR IsWindowsPlatform)
    option(MOONRAY_USE_OPTIX "Whether to enable XPU mode and Optix denoising" YES)
elseif(IsDarwinPlatform)
    option(MOONRAY_USE_METAL "Whether to enable XPU mode and OIDN Metal denoising" YES)
endif()


