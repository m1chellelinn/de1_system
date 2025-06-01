#include <vector>

struct SnakeGame {

    public:
    SnakeGame();
    void step_game();

    std::vector<std::pair<int,int>> apples;
    bool shutdown;
    Snake snake;
    int newest_input_code ;

};

void input_thread(std::shared_ptr<SnakeGame> game);

