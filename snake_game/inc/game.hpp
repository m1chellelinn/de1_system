#include <vector>

struct SnakeGame {

    public:
    SnakeGame();

    void step_game();

    std::vector<std::pair<int,int>> apples;
    
    bool shutdown = false;
    Snake snake;
    int newest_input_code = -1;

};

void input_thread(SnakeGame *game);

// int main();