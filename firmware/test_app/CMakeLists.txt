cmake_minimum_required(VERSION 3.16)

set(EXTRA_COMPONENT_DIRS ../components/vph_ble)
set(COMPONENTS main)

include($ENV{IDF_PATH}/tools/cmake/project.cmake)
project(vph_ble_test)
