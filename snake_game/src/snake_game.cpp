#include <stdlib.h>
#include <unistd.h>
#include <fcntl.h>
#include <errno.h>
#include <linux/input.h>
#include <string.h>
#include <stdio.h>

#include "address_map_arm.hpp"
#include "peripherals.hpp"
#include <snake.hpp>


static const char *const action_mappings[3] = {
    "RELEASED",
    "PRESSED ",
    "REPEATED"
};


int main(void)
{
    const char *dev = "/dev/input/event0";
    struct input_event event_;
    ssize_t num_bytes_read;
    int keys_fd;
    volatile int * snake_ptr; // virtual address pointer to red LEDs
    int fd = -1; // used to open /dev/mem
    void *LW_virtual; // physical addresses for light-weight bridge
    int x = 100;
    int y = 100;


    // Create virtual memory access to the FPGA light-weight bridge
    if ((fd = open_physical (fd)) == -1)
    return (-1);
    if (!(LW_virtual = map_physical (fd, LW_BRIDGE_BASE, LW_BRIDGE_SPAN)))
    return (-1);

    keys_fd = open(dev, O_RDONLY);
    if (keys_fd == -1) {
        fprintf(stderr, "Cannot open %s: %s.\n", dev, strerror(errno));
        return EXIT_FAILURE;
    }

    while (1) {
        num_bytes_read = read(keys_fd, &event_, sizeof event_);
        if (num_bytes_read == (ssize_t)-1) {
            if (errno == EINTR)
                continue;
            else
                break;
        } else
        if (num_bytes_read != sizeof event_) {
            errno = EIO;
            break;
        }

        if (event_.type == EV_KEY && event_.value >= 0 && event_.value <= 2 && event_.value && event_.value == 1) {
            switch (event_.code) {
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
            // Set virtual address pointer to I/O port
            snake_ptr = (int *) (LW_virtual + SNAKE_GAME_BASE);
            if (event_.value) 
                *snake_ptr = (CMD_SNAKE_ADD << MSG_CMD_OFFSET) | (x << MSG_X_OFFSET) | (y << MSG_Y_OFFSET);
            
            // Print a message
            printf("Action = %s. Key.code = 0x%04x (%d)\n", action_mappings[event_.value], (int)event_.code, (int)event_.code);
        }
    }

    unmap_physical (LW_virtual, LW_BRIDGE_SPAN);
    close_physical (fd);
    fflush(stdout);
    fprintf(stderr, "Error state: %s.\n", strerror(errno));
    return EXIT_FAILURE;
}
