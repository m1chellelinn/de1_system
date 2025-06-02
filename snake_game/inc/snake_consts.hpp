/* Address Mapping */
#define SNAKE_GAME_BASE     0x00000100

/* HPS --> FPGA messages */
#define CMD_START_GAME 0
#define CMD_END_GAME 1
#define CMD_SNAKE_ADD 2
#define CMD_SNAKE_DEL 3
#define CMD_NEW_SCORE 4
#define CMD_APPLE_ADD 5
#define CMD_APPLE_DEL 6

#define MSG_X_OFFSET 1
#define MSG_Y_OFFSET 10
#define MSG_CMD_OFFSET 24

/* VGA screen */
#define NUM_X_PIXELS 320
#define NUM_Y_PIXELS 240

/* Linux keyboard events */
#define KEYCODE_UP 103
#define KEYCODE_DOWN 108
#define KEYCODE_LEFT 105
#define KEYCODE_RIGHT 106
#define KEYBOARD_EVENT_PATH "/dev/input/event0"

/* Game logic */
#define GAME_UPDATE_PERIOD_MS 100
#define NUM_APPLES 5
#define SNAKE_LEN 5