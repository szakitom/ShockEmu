#include <IOKit/hid/IOHIDManager.h>
#include <unistd.h>
#include <stdio.h>
#include "gamepad.h"

int fd ;

static void callback(int type, int page, int usage, int value)
{
    char data[50];
    // printf("type=%d, page=%d, usage=%d, value=%d\n", type, page, usage, value);
    sprintf(data, "%4d %4d", usage, value);
    write(fd, data, strlen(data)+1);
    fflush(stdout);

    /* end main loop if push esc key */
    if (2 == type && 7 == page && 41 == usage && 0 == value) {
        CFRunLoopStop(CFRunLoopGetCurrent());
    }
}



int main()
{
    void* ctx;

    fd = open("/tmp/gpad-daemon-data",O_WRONLY);

    /* initialize gamepad */
    ctx = gamepad_init(1, 0, 0);
    if (!ctx) {
        puts("init failed");
        return -1;
    }

    /* set callback */
    gamepad_set_callback(ctx, callback);

    CFRunLoopRun();

    /* terminate gamepad */
    gamepad_term(ctx);


    close(fd);
    return 0;
}
