#include <vector>
#include <memory>

struct SnakeGame {

    public:
    SnakeGame();
    void step_game();

    std::vector<std::pair<int,int> > apples;
    bool shutdown;
    bool game_running;
    Snake snake;
    int newest_input_code ;

};
