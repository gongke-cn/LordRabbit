#include <stdio.h>

extern int sub1();
extern int sub2();

int
test ()
{
    sub1();
    sub2();
    return 0;
}