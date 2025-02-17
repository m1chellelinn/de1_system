cmake_minimum_required(VERSION 2.8.7)
project(proof_of_concept C)

add_executable(increment_led src/increment_led.c)

target_include_directories(increment_led PRIVATE inc src)
