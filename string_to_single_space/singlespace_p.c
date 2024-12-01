#include <stdio.h>

char *singlespace(char *s);

int main(int argc, char *argv[])
{
    for (int i = 1; i < argc; i++)
        printf("%d: %s\n", i, singlespace(argv[i]));
}
