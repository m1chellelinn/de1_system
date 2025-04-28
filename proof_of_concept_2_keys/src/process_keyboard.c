#include <stdlib.h>
#include <unistd.h>
#include <fcntl.h>
#include <errno.h>
#include <linux/input.h>
#include <string.h>
#include <stdio.h>

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
    int fd;

    fd = open(dev, O_RDONLY);
    if (fd == -1) {
        fprintf(stderr, "Cannot open %s: %s.\n", dev, strerror(errno));
        return EXIT_FAILURE;
    }

    while (1) {
        num_bytes_read = read(fd, &event_, sizeof event_);
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
        if (event_.type == EV_KEY && event_.value >= 0 && event_.value <= 2)
            printf("Action = %s. Key.code = 0x%04x (%d)\n", action_mappings[event_.value], (int)event_.code, (int)event_.code);
    }

    fflush(stdout);
    fprintf(stderr, "Error state: %s.\n", strerror(errno));
    return EXIT_FAILURE;
}
