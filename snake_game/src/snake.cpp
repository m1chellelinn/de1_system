#include <iostream>
#include <stdint.h>

#include <address_map_arm.hpp>
#include <peripherals.hpp>
#include <snake_consts.hpp>
#include <snake.hpp>


namespace std {

int Snake::start_game() {
    if (snake_head || snake_tail || snake_fd >= 0) {
        // Assume that there is an ongoing game
        return 1;
    }

    // Map FPGA virtual address ranges
    if ((snake_fd = open_physical (snake_fd)) == -1)
    return (1);
    if (!(fpga_v_addr = (uint32_t *) map_physical (snake_fd, LW_BRIDGE_BASE, LW_BRIDGE_SPAN)))
    return (1);
    snake_v_addr = ((uint32_t *) fpga_v_addr) + SNAKE_GAME_BASE;

    // Init locals
    SnakeBody *initial_snake = new SnakeBody;
    initial_snake->x = 100;
    initial_snake->y = 100;
    initial_snake->next = nullptr;
    
    snake_head = initial_snake;
    snake_tail = initial_snake;
    
    score = 0;
    num_apples_consumed = 0;
    apples.clear();

    // FPGA start game screen
    update_game_state(true);
    update_snake(initial_snake, true);
}


int Snake::end_game() {
    cout << "Ending the game" << endl;

    // FPGA VGA clear and display end game screen

    // Unmap FPGA virtual address ranges
    unmap_physical (fpga_v_addr, LW_BRIDGE_SPAN);
    close_physical (snake_fd);

    // FREE the snake
    SnakeBody *current = snake_head;

    while (current != nullptr) {
        update_snake(current, false);

        SnakeBody *next = current->next;
        cout << "  Removing snake body at pixel (" << current->x << ", " << current->y << ")" << endl;
        delete current;
        current = next;
    }

    for (auto apple : apples) {
        update_apple(apple, false);
        //log?
    }

    snake_head = nullptr;
    snake_tail = nullptr;

    return score;
}


void Snake::eat() {
    num_apples_consumed++;
    score++;
}


int Snake::move(int keycode) {
    int x = snake_head->x;
    int y = snake_head->y;

    switch (keycode) {
        case KEYCODE_UP:
            y -= 1;
            break;
    
        case KEYCODE_DOWN:
            y += 1;
            break;
    
        case KEYCODE_LEFT:
            x -= 1;
            break;
    
        case KEYCODE_RIGHT:
            x += 1;
            break;
    
        default:
            break;
    }

    // Check for collision
    cout << "Checking snek for collision" << endl;
    bool if_collision = false;
    SnakeBody *current = snake_head;
    while (current != nullptr) {
        if (current->x == x && current->y == y) {
            return 1;
        }
        current = current->next;
    }
    if (if_collision) {
        return 1;
    }

    // Move to new head
    SnakeBody *new_head = new SnakeBody;
    new_head->x = x;
    new_head->y = y;
    new_head->next = snake_head;

    snake_head = new_head;
    
    // Let the FPGA know too
    update_snake(snake_head, true);

    // Check for food, and move the tail if we're out of food
    std::pair<int,int> snake_pos = get_current_head_position();
    for (auto apple_pos : apples) {
        if (apple_pos.first == snake_pos.first &&
            apple_pos.second == snake_pos.second) {

            eat();
        }
    }
    
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
    for (int i = 0; i < num_apples; i++) {
        apples.push_back( std::pair<int,int>(
            (std::rand() % 50) + 100, (std::rand() % 50) + 100
        ));
    }
}


std::pair<int, int> Snake::get_current_head_position() {
    if (snake_head != nullptr) {
        return std::pair<int,int>(snake_head->x,snake_head->y);
    }
    return std::pair<int,int>(-1,-1);
}


int Snake::update_snake(SnakeBody *snake_section, bool if_add) {
    if (!check_fpga_is_live()) return 1;
    
    int cmd = ((if_add ? CMD_SNAKE_ADD : CMD_SNAKE_DEL) << MSG_CMD_OFFSET) | 
              (snake_section->x << MSG_X_OFFSET) | 
              (snake_section->y << MSG_Y_OFFSET);
    *snake_v_addr = cmd;
}

int Snake::update_score(int score) {
    if (!check_fpga_is_live()) return 1;

    *snake_v_addr = (CMD_NEW_SCORE << MSG_CMD_OFFSET) | score;
}


int Snake::update_game_state(bool if_start) {
    if (!check_fpga_is_live()) return 1;

    *snake_v_addr = (if_start ? CMD_START_GAME : CMD_END_GAME) << MSG_CMD_OFFSET;
}


int Snake::update_apple(std::pair<int,int> apple, bool if_add) {
    if (!check_fpga_is_live()) return 1;
    
    *snake_v_addr = (if_add ? CMD_APPLE_ADD : CMD_APPLE_DEL) << MSG_CMD_OFFSET| 
              (apple.first << MSG_X_OFFSET) | 
              (apple.second << MSG_Y_OFFSET);
}


inline int Snake::check_fpga_is_live() {
    return snake_v_addr && snake_fd;
}

} /* namespace std*/