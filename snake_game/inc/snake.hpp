struct SnakeBody {
    int x = -1;
    int y = -1;
    SnakeBody *next = nullptr;
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

private:
    int snake_fd = -1;
    uint32_t *snake_v_addr = 0x0;

    int score = 0;
    int num_apples = 0;

    SnakeBody *snake_head = nullptr;
    SnakeBody *snake_tail = nullptr;

    void update_vga(SnakeBody snake_section, bool if_add);
};
