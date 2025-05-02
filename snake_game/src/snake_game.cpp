#include <stdlib.h>
#include <unistd.h>
#include <fcntl.h>
#include <errno.h>
#include <linux/input.h>
#include <string.h>
#include <stdio.h>
#include <stdint.h>

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
    // Keyboard inputs
    int keys_fd;
    const char *dev = "/dev/input/event0";
    struct input_event event_;
    ssize_t num_bytes_read;

    // Snake game and LEDs
    int snake_fd = -1; // used to open /dev/mem
    void *LW_virtual; // physical addresses for light-weight bridge
    volatile int * snake_ptr; // virtual address pointer to red LEDs
    volatile int * LEDR_ptr; // virtual address pointer to red LEDs
    int x = 100;
    int y = 100;

    // VGA screen (debug only)
    int vga_fd = -1;
    void *SRAM_virtual;
    volatile uint16_t * vga_ptr;


    // Create virtual memory access to the FPGA light-weight bridge
    if ((snake_fd = open_physical (snake_fd)) == -1)
    return (-1);
    if (!(LW_virtual = map_physical (snake_fd, LW_BRIDGE_BASE, LW_BRIDGE_SPAN)))
    return (-1);

    // Create virtual memory access to the FPGA heavy-weight bridge
    if ((vga_fd = open_physical (vga_fd)) == -1)
    return (-1);
    if (!(SRAM_virtual = map_physical (snake_fd, FPGA_ONCHIP_BASE, FPGA_ONCHIP_SPAN)))
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
            snake_ptr = (int *) ((int)LW_virtual + SNAKE_GAME_BASE);
            int cmd = (CMD_SNAKE_ADD << MSG_CMD_OFFSET) | (x << MSG_X_OFFSET) | (y << MSG_Y_OFFSET);
            
            LEDR_ptr = (int *) (LW_virtual + LEDR_BASE);
            
            vga_ptr = (uint16_t *) ((int)SRAM_virtual + (x << MSG_X_OFFSET) + (y << MSG_Y_OFFSET));
            
            // Print a message
            printf("Key.code = 0x%04x (%d).\n Wrote to 0x%8x with value 0x%8x\n Wrote to 0x%8x with colour value\n", 
                (int)action_mappings[event_.value], 
                (int)event_.code, 
                (int)snake_ptr, 
                (int)cmd,
                (int)vga_ptr
            );
            *snake_ptr = cmd;
            *LEDR_ptr = *LEDR_ptr + 1; // Add 1 to the I/O register
            *vga_ptr = 0xFF00;
        }
    }

    unmap_physical (LW_virtual, LW_BRIDGE_SPAN);
    close_physical (snake_fd);
    unmap_physical (SRAM_virtual, FPGA_ONCHIP_SPAN);
    close_physical (vga_fd);
    fflush(stdout);
    fprintf(stderr, "Error state: %s.\n", strerror(errno));
    return EXIT_FAILURE;
}
