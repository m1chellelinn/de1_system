#include <iostream>
#include <iomanip>
#include <stdlib.h>
#include <time.h>
#include <vector>
#include <utility>

#include <address_map_arm.hpp>
#include <peripherals.hpp>
#include <snake_consts.hpp>
#include <snake.hpp>


using namespace std;

enum ItemType {
    REGULAR_APPLE,
    GOLDEN_APPLE
};

struct Item {
    int x;
    int y;
    ItemType type;
};


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
    return 0;
}


int Snake::end_game() {
    cout << "Ending the game" << endl;

    /* FOR LOGS BEGIN*/
    cout << "    Current snake snake: (tail) ";
    SnakeBody *current = snake_tail;
    while (true) {
        if (snake_head == current) { cout << "(head) "; } if (current == NULL) { cout << "X" << endl; break; } cout << "{" << current->x << "," << current->y << "}  --> "; 
        current = current->next;
    }
    cout << "X" << endl << "    Head == last section? " << (snake_head == current) << endl;
    /* FOR LOGS END*/

    // FREE the snake
    cout << "  Freeing the snake" << endl;
    current = snake_tail;
    while (current != NULL) {
        // update_snake(current, false);
        SnakeBody *next = current->next;
        cout << "    Removing snake body at pixel (" << current->x << ", " << current->y << ")" << endl;
        delete current;
        current = next;
    }

   // idk if we need this
    // for (const auto& apple : apples) {
    //     update_apple(apple.x, apple.y, apple.type, false);
    //     cout << "    Removing apple at pixel (" << apple.x << ", " << apple.y << ") " << (apple.type == GOLDEN_APPLE ? "(Golden)" : "") << endl;
    // }
    apples.clear();

    // FPGA VGA clear and display end game screen
    update_game_state(false);

    // Unmap FPGA virtual address ranges
    unmap_physical (fpga_v_addr, LW_BRIDGE_SPAN);
    close_physical (snake_fd);

    snake_head = NULL;
    snake_tail = NULL;

    return score;
}


void Snake::eat(ItemType type) {
    num_apples_consumed++;
    if (type == GOLDEN_APPLE) {
        score += 10;
        cout << "  Ate a GOLDEN apple! +10 points!" << endl;
    } else {
        score += 1;
        cout << "  Ate a REGULAR apple! +1 point!" << endl;
    }
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
    SnakeBody *current = snake_tail;
    while (current != NULL) {
        if (current->x == x && current->y == y) {
            cout << "    Collision with self at (" << x << ", " << y << ") " << endl;
            return 1; // Collision detected
        }
        current = current->next;
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
    int eaten_apple_idx = -1;
    for (int i = 0; i < apples.size(); ++i) {
        if (apples[i].x == snake_pos.first &&
            apples[i].y == snake_pos.second) {
            eat(apples[i].type); // Pass the type of apple eaten
            update_apple(apples[i].x, apples[i].y, apples[i].type, false); // Remove eaten apple from FPGA
            eaten_apple_idx = i;
            break; 
        }
    }

    // Remove the eaten apple from the vector and generate a new one
    if (eaten_apple_idx != -1) {
        apples.erase(apples.begin() + eaten_apple_idx);
        gen_apples(1); // Generate one new apple
    } else {
        cout << "  Manipulating tail (no apple eaten)" << endl;
        // If no apple was eaten, move the tail
        SnakeBody *old_tail = snake_tail;
        snake_tail = snake_tail->next;

        // Let the FPGA know too
        update_snake(old_tail, false);
        
        delete old_tail;
    }
    return 0;
}


void Snake::gen_apples(int num_apples_to_generate) {
    cout << "Start generating apples: " << num_apples_to_generate << endl;
    for (int i = 0; i < num_apples_to_generate; ++i) {
        Apple new_apple;
        new_apple.x = (rand() % (NUM_X_PIXELS - 60)) + 30;
        new_apple.y = (rand() % (NUM_Y_PIXELS - 60)) + 30;

        if ((rand() % 10) == 0) { // 1 in 10 chance for a golden apple
            new_apple.type = GOLDEN_APPLE;
            cout << "  + GOLDEN apple @ " << new_apple.x << ", " << new_apple.y << endl;
        } else {
            new_apple.type = REGULAR_APPLE;
            cout << "  + REGULAR apple @ " << new_apple.x << ", " << new_apple.y << endl;
        }
        
        apples.push_back(new_apple);
        update_apple(new_apple.x, new_apple.y, new_apple.type, true); // Send to FPGA
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
    return 0; // Added return statement
}

int Snake::update_score(int score) {
    if (!check_fpga_is_live()) return 1;

    *snake_v_addr = (CMD_NEW_SCORE << MSG_CMD_OFFSET) | score;
    cout << "    Sent update score cmd: " << hex << ((CMD_NEW_SCORE << MSG_CMD_OFFSET) | score) << endl;
    *LEDR_ptr = (*LEDR_ptr + 1) % 256;
    return 0; // Added return statement
}


int Snake::update_game_state(bool if_start) {
    if (!check_fpga_is_live()) return 1;

    *snake_v_addr = (if_start ? CMD_START_GAME : CMD_END_GAME) << MSG_CMD_OFFSET;
    cout << "    Sent update game cmd: " << hex << ((if_start ? CMD_START_GAME : CMD_END_GAME) << MSG_CMD_OFFSET) << endl;
    *LEDR_ptr = (*LEDR_ptr + 1) % 256;
    return 0; // Added return statement
}


// Modified update_apple function to take apple type
int Snake::update_apple(int x, int y, ItemType type, bool if_add) {
    if (!check_fpga_is_live()) return 1;
    
    int cmd_base;
    if (type == GOLDEN_APPLE) {
        cmd_base = if_add ? CMD_GOLDEN_APPLE_ADD : CMD_GOLDEN_APPLE_DEL;
        cout << "    Updating GOLDEN apple" << endl;
    } else {
        cmd_base = if_add ? CMD_APPLE_ADD : CMD_APPLE_DEL;
        cout << "    Updating REGULAR apple" << endl;
    }

    *snake_v_addr = (cmd_base << MSG_CMD_OFFSET) | 
                    (x << MSG_X_OFFSET) | 
                    (y << MSG_Y_OFFSET);
    cout << "    Sent update apple cmd: " << hex << ((cmd_base << MSG_CMD_OFFSET) | (x << MSG_X_OFFSET) | (y << MSG_Y_OFFSET)) << endl;
    *LEDR_ptr = (*LEDR_ptr + 1) % 256;
    return 0; // Added return statement
}


inline int Snake::check_fpga_is_live() {
    return snake_v_addr && snake_fd;
}