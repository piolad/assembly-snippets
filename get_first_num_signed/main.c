#include <stdio.h>

short getFirstNumber(char *s);

int main(int argc, char *argv[])
{
    for (int i = 1; i < argc; i++)
        printf("%d: %s -> %d\n", i, argv[i], getFirstNumber(argv[i]));
}
