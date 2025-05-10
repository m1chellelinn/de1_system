#include <iostream>
#include <stdint.h>

#include <address_map_arm.hpp>
#include <peripherals.hpp>
#include <snake_consts.hpp>
#include <snake.hpp>


namespace std
{

int Snake::start_game() {
    if (snake_head || snake_tail || snake_fd >= 0) {
        // Assume that there is an ongoing game
        return 1;
    }

    // Map FPGA virtual address ranges
    if ((snake_fd = open_physical (snake_fd)) == -1)
    return (-1);
    if (!(snake_v_addr = (uint32_t *) map_physical (snake_fd, LW_BRIDGE_BASE, LW_BRIDGE_SPAN)))
    return (-1);


    // Init locals
    SnakeBody *initial_snake = new SnakeBody;
    initial_snake->x = 100;
    initial_snake->y = 100;
    initial_snake->next = nullptr;

    snake_head = initial_snake;
    snake_tail = initial_snake;

    score = 0;
    num_apples = 0;
}


int Snake::end_game() {
    cout << "Ending the game" << endl;

    // FPGA VGA clear and display end game screen

    // Unmap FPGA virtual address ranges

    // FREE the snake
    SnakeBody *current = snake_head;

    while (current != nullptr) {
        SnakeBody *next = current->next;
        cout << "  Removing snake body at pixel (" << current->x << ", " << current->y << ")" << endl;
        delete current;
        current = next;
    }

    snake_head = nullptr;
    snake_tail = nullptr;

    return score;
}


void Snake::eat() {
    num_apples++;
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

    // Move to new head
    SnakeBody *new_head = new SnakeBody;
    new_head->x = x;
    new_head->y = y;
    new_head->next = snake_head;

    snake_head = new_head;
    // TODO: update VGA

    // Check for food, and move the tail if we're out of food
    if (num_apples > 0) {
        num_apples -= 1;
    }
    else {
        SnakeBody *old_tail = snake_tail;
        snake_tail = snake_tail->next;
        delete old_tail;

        // TODO: update VGA
    }
    return 0;
}

void Snake::update_vga(SnakeBody snake_section, bool if_add) {

}

} /* namespace std*/