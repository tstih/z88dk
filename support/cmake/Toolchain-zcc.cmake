
message("zcc - Frontend for the z88dk Cross-C Compiler")
message("See https://github.com/z88dk/z88dk/wiki/CMake for more information")

set(CMAKE_TRY_COMPILE_PLATFORM_VARIABLES ZCCTARGET)

if (NOT DEFINED ZCCTARGET)
    message(FATAL_ERROR "Please define variable ZCCTARGET to specify +configuration for zcc. Try the following: cmake -DZCCTARGET=<target> --toolchain=${CMAKE_CURRENT_LIST_DIR}/Toolchain-zcc.cmake")
endif()

set(CMAKE_C_COMPILER zcc)
set(CMAKE_ASM_COMPILER zcc)
set(CMAKE_TRY_COMPILE_TARGET_TYPE STATIC_LIBRARY CACHE INTERNAL "")

set(CMAKE_SYSTEM_NAME Generic)
set(CMAKE_SYSTEM_PROCESSOR z80)


set(CMAKE_EXECUTABLE_SUFFIX ".bin")
set(CMAKE_EXECUTABLE_SUFFIX_C ${CMAKE_EXECUTABLE_SUFFIX})
set(CMAKE_EXECUTABLE_SUFFIX_ASM ${CMAKE_EXECUTABLE_SUFFIX})

set(CMAKE_CROSSCOMPILING 1)
set(CMAKE_LINKER ${CMAKE_C_COMPILER} CACHE INTERNAL "")

set(CMAKE_C_FLAGS "+${ZCCTARGET}")
set(CMAKE_ASM_FLAGS "+${ZCCTARGET}")

include_directories("${CMAKE_CURRENT_LIST_DIR}/../include")

set(CMAKE_C_FLAGS_DEBUG "-debug" CACHE INTERNAL "")
set(CMAKE_ASM_FLAGS_DEBUG "-debug" CACHE INTERNAL "")

set(CMAKE_USER_MAKE_RULES_OVERRIDE "${CMAKE_CURRENT_LIST_DIR}/Extensions.cmake" CACHE STRING "" FORCE)

set(CMAKE_DEPFILE_FLAGS_C "" CACHE STRING "" FORCE)
set(CMAKE_DEPFILE_FLAGS_ASM "" CACHE STRING "" FORCE)
set(CMAKE_C_SYSROOT_FLAG "" CACHE STRING "" FORCE)
set(CMAKE_ASM_SYSROOT_FLAG "" CACHE STRING "" FORCE)
set(CMAKE_C_OSX_DEPLOYMENT_TARGET_FLAG "" CACHE STRING "" FORCE)
set(CMAKE_ASM_OSX_DEPLOYMENT_TARGET_FLAG "" CACHE STRING "" FORCE)

set(CMAKE_C_COMPILE_OBJECT "<CMAKE_C_COMPILER> <INCLUDES> <DEFINES> <FLAGS> -o <OBJECT> -c <SOURCE>" CACHE STRING "" FORCE)
set(CMAKE_ASM_COMPILE_OBJECT "<CMAKE_ASM_COMPILER> <INCLUDES> <DEFINES> <FLAGS> -o <OBJECT> -c <SOURCE>" CACHE STRING "" FORCE)
set(CMAKE_C_LINK_EXECUTABLE "<CMAKE_C_COMPILER> <FLAGS> <CMAKE_C_LINK_FLAGS> <LINK_FLAGS> <OBJECTS> -o <TARGET> <LINK_LIBRARIES>" CACHE STRING "" FORCE)
