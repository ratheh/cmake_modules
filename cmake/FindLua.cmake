# Copyright 2024 DreamWorks Animation LLC
# SPDX-License-Identifier: Apache-2.0

# FindLua.cmake - Find Lua library with vcpkg support
#
# This module finds the Lua library and creates the Lua::lua target.
# It works with both traditional installations and vcpkg.
#
# Outputs:
#   LUA_FOUND       - True if Lua was found
#   LUA_INCLUDE_DIR - Include directories
#   LUA_LIBRARY     - Library to link against
#   Lua::lua        - Imported target

# First try vcpkg's unofficial-lua package
find_package(unofficial-lua CONFIG QUIET)

if(unofficial-lua_FOUND OR TARGET lua)
    # vcpkg's lua package creates a target called 'lua'
    if(TARGET lua AND NOT TARGET Lua::lua)
        # Get properties from the lua target
        get_target_property(_lua_type lua TYPE)
        get_target_property(_lua_configs lua IMPORTED_CONFIGURATIONS)

        # Create Lua::lua as an IMPORTED library
        add_library(Lua::lua SHARED IMPORTED)

        # Copy all configuration-specific properties
        foreach(_config ${_lua_configs})
            get_target_property(_lua_location lua IMPORTED_LOCATION_${_config})
            get_target_property(_lua_implib lua IMPORTED_IMPLIB_${_config})
            if(_lua_location)
                set_property(TARGET Lua::lua APPEND PROPERTY IMPORTED_CONFIGURATIONS ${_config})
                set_target_properties(Lua::lua PROPERTIES
                    IMPORTED_LOCATION_${_config} "${_lua_location}"
                )
            endif()
            if(_lua_implib)
                set_target_properties(Lua::lua PROPERTIES
                    IMPORTED_IMPLIB_${_config} "${_lua_implib}"
                )
            endif()
        endforeach()

        # Copy interface include directories
        get_target_property(_lua_includes lua INTERFACE_INCLUDE_DIRECTORIES)
        if(_lua_includes)
            set_target_properties(Lua::lua PROPERTIES
                INTERFACE_INCLUDE_DIRECTORIES "${_lua_includes}"
            )
        endif()
    endif()

    # Set the standard variables for compatibility
    get_target_property(LUA_INCLUDE_DIR lua INTERFACE_INCLUDE_DIRECTORIES)
    if(NOT LUA_INCLUDE_DIR)
        set(LUA_INCLUDE_DIR "${_VCPKG_INSTALLED_DIR}/${VCPKG_TARGET_TRIPLET}/include")
    endif()

    # For multi-config generators, get the release location
    get_target_property(LUA_LIBRARY lua IMPORTED_LOCATION_RELEASE)
    if(NOT LUA_LIBRARY)
        get_target_property(LUA_LIBRARY lua IMPORTED_LOCATION)
    endif()
    if(NOT LUA_LIBRARY)
        get_target_property(LUA_LIBRARY lua IMPORTED_IMPLIB_RELEASE)
    endif()

    set(LUA_LIBRARIES lua)
    set(LUA_FOUND TRUE)
else()
    # Fallback to standard CMake FindLua
    include(${CMAKE_ROOT}/Modules/FindLua.cmake)

    if(LUA_FOUND AND NOT TARGET Lua::lua)
        add_library(Lua::lua UNKNOWN IMPORTED)
        set_target_properties(Lua::lua PROPERTIES
            IMPORTED_LOCATION "${LUA_LIBRARY}"
            INTERFACE_INCLUDE_DIRECTORIES "${LUA_INCLUDE_DIR}"
        )
    endif()
endif()

include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(Lua
    REQUIRED_VARS LUA_FOUND
)
