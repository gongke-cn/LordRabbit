ref "std/io"

stdout.puts(''
#include <stdio.h>

int gen()
{
    printf("gen\n");
    return 0;
}
'')