#include <chrono>
#include <cstdlib>
#include <errno.h>
#include <fcntl.h>
#include <iostream>
#include <linux/input.h>
#include <string.h>
#include <thread>

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
    game_running = false;
    snake = Snake();
    newest_input_code = -1;
}

void SnakeGame::step_game() {
    cout << "Game step invoke" << endl;

    try {
        if (game_running) {
            if (snake.move(newest_input_code) != 0) {
                // Collision found
                snake.end_game();
                game_running = false;
            }
        }
        else if (newest_input_code == KEY_ENTER) {
            cout << "User pressed ENTER while game was ended. Starting game." << endl;
            snake.start_game();
            game_running = true;
            newest_input_code = KEY_DOWN;
        }
    }
    catch (std::exception e) {
        cout << "Error occured. Shutting down game. Original error: " << e.what() << endl;
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
            event_.value <= 2) 
        {

            // If new input is directly opposite of prev input, ignore it. 
            // Otherwise the snake will die immediately, and that's no fun
            if (KEY_UP + KEY_DOWN == game->newest_input_code + event_.code ||
                KEY_LEFT + KEY_RIGHT == game->newest_input_code + event_.code) 
            {
                cout << "Opposite input as previous. Ignoring." << endl;
            }
            else {
                game->newest_input_code = event_.code;
                cout << "New input with code: " << event_.code << endl;
            }
        }
    }
    game->shutdown = true;
}


int main(void) {
    std::shared_ptr<SnakeGame> game = std::make_shared<SnakeGame>();
    game->snake.start_game();
    

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
