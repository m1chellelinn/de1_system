cmake_minimum_required(VERSION 2.8)
project(de1_system C)

include_directories(inc)

# add_library(name path)

add_executable(process_keyboard src/process_keyboard.c)

# target_link_libraries(increment_led peripherals)