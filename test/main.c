#include <config.h>

#ifdef HAVE_STDIO_H
    #include <stdio.h>
#endif

#include "test.h"

int
main (int argc, char **argv)
{
    printf("version: %d\n", VERSION);
    test();
    return 0;
}