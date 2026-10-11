# Compiles the translations and installs them to
# <CMAKE_INSTALL_PREFIX>/<language>/LC_MESSAGES/plasma_applet_panon.mo
cmake_minimum_required(VERSION 3.16)
project(panon-translations LANGUAGES NONE)

find_program(GETTEXT_MSGFMT_EXECUTABLE msgfmt)
if(NOT GETTEXT_MSGFMT_EXECUTABLE)
    message(WARNING "msgfmt not found. Translations will *not* be installed")
    return()
endif()

set(catalogname plasma_applet_panon)

file(GLOB PO_FILES ${CMAKE_CURRENT_SOURCE_DIR}/po/${catalogname}_*.po)
set(GMO_FILES)

foreach(_poFile ${PO_FILES})
    get_filename_component(_lang ${_poFile} NAME_WE)
    string(REGEX REPLACE "^${catalogname}_" "" _langCode ${_lang})
    set(_gmoFile ${CMAKE_CURRENT_BINARY_DIR}/${_lang}.gmo)

    add_custom_command(
        OUTPUT ${_gmoFile}
        COMMAND ${GETTEXT_MSGFMT_EXECUTABLE} --check -o ${_gmoFile} ${_poFile}
        DEPENDS ${_poFile})
    install(FILES ${_gmoFile} DESTINATION ${_langCode}/LC_MESSAGES RENAME ${catalogname}.mo)
    list(APPEND GMO_FILES ${_gmoFile})
endforeach()

add_custom_target(translations ALL DEPENDS ${GMO_FILES})
