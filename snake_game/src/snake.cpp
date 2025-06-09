#include <iostream>
#include <iomanip>
#include <stdlib.h>
#include <time.h>

#include <address_map_arm.hpp>
#include <peripherals.hpp>
#include <snake_consts.hpp>
#include <snake.hpp>


using namespace std;

Snake::Snake() {
    snake_fd = -1;
    fpga_v_addr = 0x0;
    snake_v_addr = 0x0;
    score = 0;
    num_apples_consumed = 0;
    snake_head = NULL;
    snake_tail = NULL;

    srand((unsigned int) std::time(NULL));
}

int Snake::start_game() {
    cout << "Starting game" << endl;
    if (snake_head || snake_tail || snake_fd >= 0) {
        // Assume that there is an ongoing game
        cout << "  nah" << endl;
        return 1;
    }

    // Map FPGA virtual address ranges
    if ((snake_fd = open_physical (snake_fd)) == -1)
    return (1);
    if (!(fpga_v_addr = map_physical (snake_fd, LW_BRIDGE_BASE, LW_BRIDGE_SPAN)))
    return (1);
    snake_v_addr = (int *) ( (int)fpga_v_addr + SNAKE_GAME_BASE);
    LEDR_ptr = (int *) ( (int)fpga_v_addr + LEDR_BASE);
    
    cout << "FPGA virtual addr is " << hex << (int) fpga_v_addr << endl;
    cout << "Snake virtual addr is " << hex << (int) snake_v_addr << endl;
    cout << "LEDR virtual addr is " << hex << (int) LEDR_ptr << endl;

    // FPGA start game screen
    update_game_state(true);
    // Init locals
    SnakeBody *new_snake = new SnakeBody;
    snake_tail = new_snake;
    for (int i = 0; i < SNAKE_LEN; i++) {
        new_snake->x = 100;
        new_snake->y = 100 + i;
        snake_head = new_snake;
        update_snake(new_snake, true);

        if (i < SNAKE_LEN - 1) {
            new_snake->next = new SnakeBody();
            new_snake = new_snake->next;
        }
    }

    /* For logs */
    cout << "  Initialized snake: (tail) ";
    SnakeBody *current = snake_tail;
    while (true) {
        if (snake_head == current) {
            cout << "(head) ";
        }
        if (current == NULL) {
            cout << "X" << endl;
            break;
        }
        cout << "{" << current->x << "," << current->y << "}  --> ";
        current = current->next;
    }
    cout << "X" << endl;
    cout << "    Head == last section? " << (snake_head == current) << endl;

    score = 0;
    num_apples_consumed = 0;
    apples.clear();
    gen_apples(NUM_APPLES);
}


int Snake::end_game() {
    cout << "Ending the game" << endl;

    // Unmap FPGA virtual address ranges
    unmap_physical (fpga_v_addr, LW_BRIDGE_SPAN);
    close_physical (snake_fd);

    // FREE the snake
    cout << "  Freeing the snake" << endl;
    SnakeBody *current = snake_tail;

    while (current != NULL) {
        update_snake(current, false);

        SnakeBody *next = current->next;
        cout << "    Removing snake body at pixel (" << current->x << ", " << current->y << ")" << endl;
        delete current;
        current = next;
    }

    for (int i = 0; i < apples.size(); i++) {
        update_apple(apples[i], false);
        cout << "    Removing apple at pixel (" << apples[i].first << ", " << apples[i].second << ")" << endl;
    }

    // FPGA VGA clear and display end game screen
    update_game_state(false);

    snake_head = NULL;
    snake_tail = NULL;

    return score;
}


void Snake::eat() {
    num_apples_consumed++;
    score++;
    update_score(score);
}


int Snake::move(int keycode) {
    cout << "--Begin move step: " << endl;

    int x = snake_head->x;
    int y = snake_head->y;

    switch (keycode) {
        case KEYCODE_UP:
            y = (y - 1) % NUM_Y_PIXELS;
            break;
    
        case KEYCODE_DOWN:
            y = (y + 1) % NUM_Y_PIXELS;
            break;
    
        case KEYCODE_LEFT:
            x = (x - 1) % NUM_X_PIXELS;
            break;
    
        case KEYCODE_RIGHT:
            x = (x + 1) % NUM_X_PIXELS;
            break;
    
        default:
            cout << "  No input / invalid input. Skipping this step. " << endl;
            return 0;
            break;
    }

    // Check for collision
    cout << "  Checking snek for collision" << endl;
    bool if_collision = false;
    SnakeBody *current = snake_tail;
    while (current != NULL) {
        if (current->x == x && current->y == y) {
            cout << "    Collision at (" << x << ", " << y << ") " << endl;
            return 1;
        }
        current = current->next;
    }
    if (if_collision) {
        return 1;
    }

    // Move to new head
    cout << "  Manipulating new head" << endl;
    SnakeBody *new_head = new SnakeBody;
    new_head->x = x;
    new_head->y = y;
    new_head->next = NULL;
    snake_head->next = new_head;

    snake_head = new_head;
    
    // Let the FPGA know too
    update_snake(snake_head, true);

    // Check for food, and move the tail if we're out of food
    cout << "  Checking food" << endl;
    std::pair<int,int> snake_pos = get_current_head_position();
    for (int i = 0; i < apples.size(); i++) {
        if (apples[i].first == snake_pos.first &&
            apples[i].second == snake_pos.second) {

            eat();
            cout << "    Ate food at (" << apples[i].first << ", " << apples[i].second << ") " << endl;
            gen_apples(1);
        }
    }

    cout << "  Manipulating tail" << endl;
    if (num_apples_consumed > 0) {
        num_apples_consumed -= 1;
    }
    else {
        SnakeBody *old_tail = snake_tail;
        snake_tail = snake_tail->next;

        // Let the FPGA know too
        update_snake(old_tail, false);
        
        delete old_tail;
    }
    return 0;
}


void Snake::gen_apples(int num_apples) {
    cout << "Start generating apples: " << num_apples << endl;
    for (int i = 0; i < num_apples; i++) {
        std::pair<int,int> apple = 
            std::pair<int,int>((rand() % 260) + 30, (rand() % 180) + 30);
        apples.push_back( apple );
        update_apple(apple, true);
        cout << "  + apple @ " << apples[i].first << ", " << apples[i].second << endl;
    }
}


std::pair<int, int> Snake::get_current_head_position() {
    cout << "    Getting snake head pos" << endl;
    if (snake_head != NULL) {
        return std::pair<int,int>(snake_head->x,snake_head->y);
    }
    return std::pair<int,int>(-1,-1);
}


int Snake::update_snake(SnakeBody *snake_section, bool if_add) {
    if (!check_fpga_is_live()) return 1;
    
    int cmd = ((if_add ? CMD_SNAKE_ADD : CMD_SNAKE_DEL) << MSG_CMD_OFFSET) +
              (snake_section->x << MSG_X_OFFSET) +
              (snake_section->y << MSG_Y_OFFSET);
    *snake_v_addr = cmd;
    cout << "    Sent update snake cmd: " << hex << cmd << endl;
    cout << "      Addr: " << hex << (long) snake_v_addr << endl;
    *LEDR_ptr = (*LEDR_ptr + 1) % 256;
}

int Snake::update_score(int score) {
    if (!check_fpga_is_live()) return 1;

    *snake_v_addr = (CMD_NEW_SCORE << MSG_CMD_OFFSET) | score;
    cout << "    Sent update score cmd" << endl;
    *LEDR_ptr = (*LEDR_ptr + 1) % 256;
}


int Snake::update_game_state(bool if_start) {
    if (!check_fpga_is_live()) return 1;

    *snake_v_addr = (if_start ? CMD_START_GAME : CMD_END_GAME) << MSG_CMD_OFFSET;
    cout << "    Sent update game cmd" << endl;
    *LEDR_ptr = (*LEDR_ptr + 1) % 256;
}


int Snake::update_apple(std::pair<int,int> apple, bool if_add) {
    if (!check_fpga_is_live()) return 1;
    
    *snake_v_addr = (if_add ? CMD_APPLE_ADD : CMD_APPLE_DEL) << MSG_CMD_OFFSET| 
              (apple.first << MSG_X_OFFSET) | 
              (apple.second << MSG_Y_OFFSET);
    cout << "    Sent update apple cmd" << endl;
    *LEDR_ptr = (*LEDR_ptr + 1) % 256;
}


inline int Snake::check_fpga_is_live() {
    return snake_v_addr && snake_fd;
}
