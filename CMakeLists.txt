cmake_minimum_required (VERSION 3.12)

set(PLATFORM_NAME ${CMAKE_SYSTEM_NAME})
if(WIN32)
    set(PLATFORM_NAME windows)
elseif(ANDROID)
    set(PLATFORM_NAME android)
endif()

set(LIBCXX_SHARED_OUTPUT_NAME "c++_shared" CACHE STRING "Output name for the shared libc++ runtime library." FORCE)
set(LIBCXX_STATIC_OUTPUT_NAME "c++_static" CACHE STRING "Output name for the static libc++ runtime library." FORCE)
set(LIBCXX_CXX_ABI "libcxxabi" CACHE STRING "Specify C++ ABI library to use." FORCE)#none libcxxabi system-libcxxabi libcxxrt libstdc++ libsupc++ vcruntime
set(LIBCXX_STATICALLY_LINK_ABI_IN_SHARED_LIBRARY ON CACHE BOOL "Statically link the ABI library to shared library" FORCE)
set(LIBCXX_INCLUDE_TESTS OFF)
set(LIBCXX_INCLUDE_BENCHMARKS OFF)
set(LIBCXX_INCLUDE_DOCS OFF)
set(LIBCXX_INSTALL_HEADERS OFF)
set(LIBCXXABI_INCLUDE_TESTS OFF)
set(LIBCXXABI_INSTALL_HEADERS OFF)
set(LIBCXXABI_ENABLE_SHARED OFF)

set(LLVM_BINARY_DIR ${RELEASE_DIR})
set(RELEASE_OUTPUT_DIR ${RELEASE_DIR}/lib/${PLATFORM_NAME}_${CMAKE_BUILD_TYPE})
if (CMAKE_BUILD_TYPE STREQUAL "Debug")
	set(RELEASE_OUTPUT_DIR ${RELEASE_DIR}/lib/${PLATFORM_NAME}_debug)
elseif (CMAKE_BUILD_TYPE STREQUAL "Release")
	set(RELEASE_OUTPUT_DIR ${RELEASE_DIR}/lib/${PLATFORM_NAME})
endif ()
set(LLVM_LIBRARY_OUTPUT_INTDIR ${RELEASE_OUTPUT_DIR}/${TARGET_ABI})
set(LIBCXX_INSTALL_LIBRARY_DIR ${TARGET_ABI} CACHE PATH "Path where built libc++ libraries should be installed." FORCE)
set(LIBCXXABI_INSTALL_LIBRARY_DIR ${TARGET_ABI} CACHE PATH "Path where built libc++abi libraries should be installed." FORCE)


add_compile_options(-std=c++20)

if(CMAKE_CXX_COMPILER_ID MATCHES "MSVC")
else()
	get_filename_component(LLVM_DIR ${LLVM_DIR} ABSOLUTE)#convert to absolute path
	add_compile_options(-fmacro-prefix-map=${LLVM_DIR}/= -fdebug-prefix-map=${LLVM_DIR}/=)

	if (CMAKE_BUILD_TYPE STREQUAL "Debug")
		add_compile_options(-O0)
	elseif (CMAKE_BUILD_TYPE STREQUAL "Release")
		add_compile_options(-Os -DNDEBUG)
		add_compile_options(-fvisibility=hidden -fvisibility-inlines-hidden)
		add_compile_options(-fvisibility-global-new-delete-hidden)
		add_compile_options(-Wno-unused-command-line-argument -Wno-macro-redefined)
		add_compile_options(-D__STDC_FORMAT_MACROS -D_LIBCPP_NO_EXCEPTIONS -D_LIBCPP_NO_RTTI -D_LIBCPP_DISABLE_VISIBILITY_ANNOTATIONS)
		add_compile_options(-D_LIBCXXABI_NO_EXCEPTIONS -DHAS_THREAD_LOCAL)
		
		add_compile_options(-flto=full)
		add_link_options(-flto=full)
		
		add_compile_options(-ffunction-sections -fdata-sections)
		add_link_options(-Wl,--gc-sections)
	endif()
endif()

if(ANDROID)
	if (TARGET_ABI STREQUAL "arm64-v8a")
		add_compile_options(-mbranch-protection=standard)
	endif()
endif()


add_subdirectory(${LLVM_DIR}/libcxxabi libcxxabi)
add_subdirectory(${LLVM_DIR}/libcxx libcxx)

add_custom_target(install-cxxandcxxabi
				  DEPENDS cxx cxxabi cxx_experimental
				  COMMAND "${CMAKE_COMMAND}"
				  -DCMAKE_INSTALL_PREFIX="${RELEASE_OUTPUT_DIR}"
				  -P "${CMAKE_BINARY_DIR}/cmake_install.cmake")

add_custom_target(install-cxxandcxxabi-stripped
				  DEPENDS cxx cxxabi cxx_experimental
				  COMMAND "${CMAKE_COMMAND}"
				  -DCMAKE_INSTALL_PREFIX="${RELEASE_OUTPUT_DIR}-strip"
				  -DCMAKE_INSTALL_DO_STRIP=1
				  -P "${CMAKE_BINARY_DIR}/cmake_install.cmake")
