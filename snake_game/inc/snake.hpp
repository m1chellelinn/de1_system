/* Address Mapping */
#define SNAKE_GAME_BASE     0x00000100

#define CMD_START_GAME 0
#define CMD_END_GAME 1
#define CMD_SNAKE_ADD 2
#define CMD_SNAKE_DEL 3
#define CMD_NEW_SCORE 4

#define ADDR_X_OFFSET 1
#define ADDR_Y_OFFSET 10

#define MSG_X_OFFSET 0
#define MSG_Y_OFFSET 12
#define MSG_CMD_OFFSET 24

#define KEYCODE_UP 103
#define KEYCODE_DOWN 108
#define KEYCODE_LEFT 105
#define KEYCODE_RIGHT 106