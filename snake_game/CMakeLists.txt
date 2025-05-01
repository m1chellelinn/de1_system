cmake_minimum_required(VERSION 2.8)
project(de1_system C)

include_directories(inc)

add_library(peripherals src/peripherals.cpp)

add_executable(process_keyboard src/process_keyboard.cpp)

target_link_libraries(process_keyboard peripherals)