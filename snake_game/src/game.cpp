// #include <stdlib.h>
#include <unistd.h>
#include <fcntl.h>
#include <errno.h>
#include <linux/input.h>
#include <string.h>
#include <stdio.h>
#include <stdint.h>
#include <thread>
#include <chrono>
#include <cstdlib>

#include "address_map_arm.hpp"
#include "peripherals.hpp"
#include <snake_consts.hpp>
#include <snake.hpp>
#include <game.hpp>

namespace std {  // only used for "cout" and "endl"

static const char *const action_mappings[3] = {
    "RELEASED",
    "PRESSED ",
    "REPEATED"
};


void SnakeGame::gen_apples(int num_apples) {
    for (int i = 0; i < num_apples; i++) {
        apples.push_back( std::pair<int,int>(
            (std::rand() % 50) + 100, (std::rand() % 50) + 100
        ));
    }
}


void SnakeGame::step_game() {
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

    while (true) {
        if (game->shutdown) {
            break;
        }

        num_bytes_read = read(keys_fd, &event_, sizeof event_);
        if (num_bytes_read == (ssize_t)-1) {
            if (errno == EINTR)
                continue;
            else
                break;
        } else
        if (num_bytes_read != sizeof event_) {
            errno = EIO;
            break;
        }

        if (event_.type == EV_KEY && 
            event_.value >  0 && 
            event_.value <= 2) {
            
            game->newest_input_code = event_.code;
        }
    }
}


int main(void) {
    std::shared_ptr<SnakeGame> game = std::make_shared<SnakeGame>();
    game->gen_apples(NUM_APPLES);
    game->snake.start_game();

    std::thread in_thread(input_thread, game);
    in_thread.detach();

    while (true) {
        std::this_thread::sleep_for(std::chrono::milliseconds(GAME_UPDATE_PERIOD_MS));
        game->step_game();

        if (game->shutdown) {
            in_thread.join();
            break;
        }
    }
    return 0;
}

} /* namespace std */