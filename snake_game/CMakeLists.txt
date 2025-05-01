cmake_minimum_required(VERSION 2.8)
project(de1_system CXX)

include_directories(inc)

add_library(peripherals src/peripherals.cpp)

add_executable(snake_game src/snake_game.cpp)

target_link_libraries(snake_game peripherals)
