#include <chrono>
#include <cstdlib>
#include <errno.h>
#include <fcntl.h>
#include <iostream>
#include <iomanip>
#include <linux/input.h>
#include <string.h>
#include <thread>

#include <address_map_arm.hpp>
#include <peripherals.hpp>
#include <snake_consts.hpp>
#include <snake.hpp>
#include <game.hpp>

using namespace std;

static const char *const action_mappings[3] = {
    "RELEASED",
    "PRESSED ",
    "REPEATED"
};

void input_thread(std::shared_ptr<SnakeGame> /* game */);

SnakeGame::SnakeGame() {
    shutdown = false;
    snake = Snake();
    newest_input_code = -1;
}

void SnakeGame::step_game() {
    cout << "Game step invoke" << endl;
    if (snake.move(newest_input_code) != 0) {
        // Collision found
        shutdown = true;
        snake.end_game();

    }
}


void input_thread(std::shared_ptr<SnakeGame> game) {
    // Setup keyboard input reading
    int keys_fd;
    const char *dev = KEYBOARD_EVENT_PATH;
    struct input_event event_;
    ssize_t num_bytes_read;
    keys_fd = open(dev, O_RDONLY);
    if (keys_fd == -1) {
        fprintf(stderr, "Cannot open %s: %s.\n", dev, strerror(errno));
        return;
    }
    cout << "Opened " << KEYBOARD_EVENT_PATH << " for reading" << endl;

    while (true) {
        if (game->shutdown) {
            cout << "Shutdown signal requested. Input thread exiting" << endl;
            break;
        }

        num_bytes_read = read(keys_fd, &event_, sizeof event_);
        if (num_bytes_read == (ssize_t) -1) {
            cout << "Input thread error: input read failed" << endl;
            if (errno == EINTR)
                continue;
            else
                break;
        } else
        if (num_bytes_read != sizeof event_) {
            cout << "Input thread shutdown: invalid input read size" << endl;
            break;
        }

        if (event_.type == EV_KEY && 
            event_.value >  0 && 
            event_.value <= 2) {
            
            game->newest_input_code = event_.code;
            cout << "New input with code: " << event_.code << endl;
        }
    }
    game->shutdown = true;
}


int main(void) {
    int snake_fd = -1;
    void *fpga_v_addr = 0x0;
    volatile int *snake_v_addr = 0x0;
    volatile int *LEDR_ptr = 0x0;

    if ((snake_fd = open_physical (snake_fd)) == -1)
    return (1);
    if (!(fpga_v_addr = map_physical (snake_fd, LW_BRIDGE_BASE, LW_BRIDGE_SPAN)))
    return (1);
    snake_v_addr = (int *) ( (int)fpga_v_addr + SNAKE_GAME_BASE);
    LEDR_ptr = (int *) ( (int)fpga_v_addr + LEDR_BASE);
    cout << "FPGA virtual addr is " << hex << (int) fpga_v_addr << endl;
    cout << "Snake virtual addr is " << hex << (int) snake_v_addr << endl;

    std::shared_ptr<SnakeGame> game = std::make_shared<SnakeGame>();
    game->snake.start_game(snake_v_addr, LEDR_ptr);
    

    cout << "Initializing thread" << endl;
    std::thread in_thread(input_thread, game);
    in_thread.detach();

    cout << "Main thread entering main loop" << endl;
    while (true) {
        std::this_thread::sleep_for(std::chrono::milliseconds(GAME_UPDATE_PERIOD_MS));
        game->step_game();

        if (game->shutdown) {
            cout << "Main thread received shutdown signal" << endl;
            in_thread.join();
            cout << "Threads gathered. Exiting." << endl;
            break;
        }
    }
    return 0;
}
