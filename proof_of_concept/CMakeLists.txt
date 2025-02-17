cmake_minimum_required(VERSION 2.8)
project(de1_system C)

include_directories(inc)

add_library(peripherals src/peripherals.c)

add_executable(increment_led src/increment_led.c)]

target_link_libraries(increment_led peripherals)