cmake_minimum_required(VERSION 2.8)
project(de1_system CXX)

set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -std=c++0x -pthread")

include_directories(inc)

add_library(peripherals src/peripherals.cpp)
add_library(snake src/snake.cpp)

add_executable(snake_game src/game.cpp)

target_link_libraries(snake_game snake peripherals)
