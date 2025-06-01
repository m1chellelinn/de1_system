#include <stdint.h>
#include <unistd.h>
#include <vector>


struct SnakeBody {
    int x;
    int y;
    SnakeBody *next;
};

class Snake {
public:
    Snake();

    /** 
     * Starts the game at a random location, initially pointing up
     * @return 0 if successful
     */
    int start_game();

    /**
     * End game prematurely
     * @return the game score
     */
    int end_game();

    /**
     * To eat an apple. +1 score
     */
    void eat();

    /**
     * To move
     * @return 0 if move is valid. 1 if move results in collision
     */
    int move(int keycode);
    
    /**
     * Generates the specified number of apples on screen
     */
    void gen_apples(int num_apples);

    /**
     * Retrieves (x,y) coordinate of snake head
     */
    std::pair<int, int> get_current_head_position();

private:
    int snake_fd;
    void *fpga_v_addr;
    volatile uint32_t *snake_v_addr;

    int score;
    int num_apples_consumed;
    std::vector< std::pair<int,int> > apples;

    SnakeBody *snake_head;
    SnakeBody *snake_tail;

    /* Tell FPGA to either add or delete a section of snake */
    int update_snake(SnakeBody *snake_section, bool if_add);

    /* Tell FPGA that we have a new score */
    int update_score(int score);

    /* Tell FPGA to start/end games */
    int update_game_state(bool if_start);

    int update_apple(std::pair<int,int> apple, bool if_add);

    /* Check if the FPGA bridge is up, and we can (probably) send commands*/
    inline int check_fpga_is_live();
};
