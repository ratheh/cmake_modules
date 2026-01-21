# Copyright 2023-2024 DreamWorks Animation LLC
# SPDX-License-Identifier: Apache-2.0

# Find OpenSubDiv
#
# Imported targets
# ----------------
# This module defines the following imported targets:
#
# ``OpenSubDiv::OpenSubDiv``
#   The OpenSubDiv library, if found
#
# Result variables
# ----------------
# ``OpenSubDiv_INCLUDE_DIRS``
#   where to find headers
# ``OpenSubDiv_LIBRARIES``
#   the libraries to link against to use OpenSubDiv
#

# First, try to find OpenSubdiv via vcpkg/CMake config (handles debug/release properly)
# vcpkg provides OpenSubdiv as "OpenSubdiv" (note the case) with target OpenSubdiv::osdCPU_static
find_package(OpenSubdiv CONFIG QUIET)

if(OpenSubdiv_FOUND AND TARGET OpenSubdiv::osdCPU_static)
    message(STATUS "Found OpenSubdiv via CMake config")

    # Get the include directory from the target
    get_target_property(_osd_include_dirs OpenSubdiv::osdCPU_static INTERFACE_INCLUDE_DIRECTORIES)
    if(_osd_include_dirs)
        set(OpenSubDiv_INCLUDE_DIRS ${_osd_include_dirs})
    endif()

    # Set found status
    set(OpenSubDiv_FOUND TRUE)

    # Create our alias target if it doesn't exist
    if(NOT TARGET OpenSubDiv::OpenSubDiv)
        # Create an interface library that links to the vcpkg target
        add_library(OpenSubDiv::OpenSubDiv INTERFACE IMPORTED)
        set_target_properties(OpenSubDiv::OpenSubDiv PROPERTIES
            INTERFACE_LINK_LIBRARIES OpenSubdiv::osdCPU_static)
    endif()

    if(NOT TARGET OpenSubDiv::osdCPU)
        add_library(OpenSubDiv::osdCPU INTERFACE IMPORTED)
        set_target_properties(OpenSubDiv::osdCPU PROPERTIES
            INTERFACE_LINK_LIBRARIES OpenSubdiv::osdCPU_static)
    endif()

    return()
endif()

# Fallback: Manual search for OpenSubdiv
message(STATUS "OpenSubdiv CMake config not found, falling back to manual search")

find_path(OpenSubDiv_INCLUDE_DIR
  NAMES version.h
  PATH_SUFFIXES opensubdiv
  HINTS $ENV{OPENSUBDIV_ROOT}/include $ENV{OpenSubDiv_ROOT}/include /usr/local/include)

# need to find <opensubdiv/version.h>
set(OpenSubDiv_INCLUDE_DIRS ${OpenSubDiv_INCLUDE_DIR}/..)

# Find Release library first (avoid linking debug libs in release builds)
find_library(OpenSubDiv_CPU_LIBRARY
  NAMES osdCPU
  HINTS $ENV{OPENSUBDIV_ROOT}/lib $ENV{OpenSubDiv_ROOT}/lib /usr/local/lib
  PATH_SUFFIXES lib
  NO_DEFAULT_PATH)

if(NOT OpenSubDiv_CPU_LIBRARY)
  find_library(OpenSubDiv_CPU_LIBRARY
    NAMES osdCPU
    HINTS $ENV{OPENSUBDIV_ROOT}/lib $ENV{OpenSubDiv_ROOT}/lib /usr/local/lib)
endif()

find_library(OpenSubDiv_GPU_LIBRARY
  NAMES osdGPU
  HINTS $ENV{OPENSUBDIV_ROOT}/lib $ENV{OpenSubDiv_ROOT}/lib /usr/local/lib
  PATH_SUFFIXES lib
  NO_DEFAULT_PATH)

if(NOT OpenSubDiv_GPU_LIBRARY)
  find_library(OpenSubDiv_GPU_LIBRARY
    NAMES osdGPU
    HINTS $ENV{OPENSUBDIV_ROOT}/lib $ENV{OpenSubDiv_ROOT}/lib /usr/local/lib)
endif()

# osdGPU is optional - only include if found
if(OpenSubDiv_GPU_LIBRARY)
  set(OpenSubDiv_LIBRARIES "${OpenSubDiv_CPU_LIBRARY};${OpenSubDiv_GPU_LIBRARY}")
else()
  set(OpenSubDiv_LIBRARIES "${OpenSubDiv_CPU_LIBRARY}")
endif()

mark_as_advanced(OpenSubDiv_INCLUDE_DIR OpenSubDiv_INCLUDE_DIRS OpenSubDiv_CPU_LIBRARY OpenSubDiv_GPU_LIBRARY OpenSubDiv_LIBRARIES)

include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(OpenSubDiv
  REQUIRED_VARS OpenSubDiv_LIBRARIES OpenSubDiv_INCLUDE_DIRS
)

if (OpenSubDiv_FOUND AND NOT TARGET OpenSubDiv::OpenSubDiv)
    add_library(OpenSubDiv::osdCPU UNKNOWN IMPORTED)
    set_target_properties(OpenSubDiv::osdCPU PROPERTIES
      IMPORTED_LINK_INTERFACE_LANGUAGES "CXX"
      IMPORTED_LOCATION "${OpenSubDiv_CPU_LIBRARY}"
      INTERFACE_INCLUDE_DIRECTORIES "${OpenSubDiv_INCLUDE_DIRS}")

    # osdGPU is optional
    if(OpenSubDiv_GPU_LIBRARY)
        add_library(OpenSubDiv::osdGPU UNKNOWN IMPORTED)
        set_target_properties(OpenSubDiv::osdGPU PROPERTIES
          IMPORTED_LINK_INTERFACE_LANGUAGES "CXX"
          IMPORTED_LOCATION "${OpenSubDiv_GPU_LIBRARY}"
          INTERFACE_INCLUDE_DIRECTORIES "${OpenSubDiv_INCLUDE_DIRS}")
        add_library(OpenSubDiv::OpenSubDiv UNKNOWN IMPORTED)
        set_target_properties(OpenSubDiv::OpenSubDiv PROPERTIES
          IMPORTED_LINK_INTERFACE_LANGUAGES "CXX"
          IMPORTED_LOCATION "${OpenSubDiv_GPU_LIBRARY}"
          INTERFACE_INCLUDE_DIRECTORIES "${OpenSubDiv_INCLUDE_DIRS}")
        target_link_libraries(OpenSubDiv::OpenSubDiv
          INTERFACE OpenSubDiv::osdCPU)
    else()
        # CPU only - create OpenSubDiv::OpenSubDiv pointing to CPU library
        add_library(OpenSubDiv::OpenSubDiv UNKNOWN IMPORTED)
        set_target_properties(OpenSubDiv::OpenSubDiv PROPERTIES
          IMPORTED_LINK_INTERFACE_LANGUAGES "CXX"
          IMPORTED_LOCATION "${OpenSubDiv_CPU_LIBRARY}"
          INTERFACE_INCLUDE_DIRECTORIES "${OpenSubDiv_INCLUDE_DIRS}")
    endif()
endif()
