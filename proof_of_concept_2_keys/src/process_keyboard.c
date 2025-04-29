#include <stdlib.h>
#include <unistd.h>
#include <fcntl.h>
#include <errno.h>
#include <linux/input.h>
#include <string.h>
#include <stdio.h>

#include "address_map_arm.h"
#include "peripherals.h"


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

    volatile int * LEDR_ptr; // virtual address pointer to red LEDs
    int fd = -1; // used to open /dev/mem
    void *LW_virtual; // physical addresses for light-weight bridge

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

        if (event_.type == EV_KEY && event_.value >= 0 && event_.value <= 2) {

            // Set virtual address pointer to I/O port
            LEDR_ptr = (int *) (LW_virtual + LEDR_BASE);
            if (event_.value) 
                *LEDR_ptr = *LEDR_ptr + 1; // Add 1 to the I/O register
            
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
