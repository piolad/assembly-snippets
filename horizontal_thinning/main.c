#include <stdio.h>
#include <stdint.h>

void horthin(void *img, uint32_t width, uint32_t height);

int main(int argc, char *argv[])
{
    FILE *fptr;
    for(int i=0; i<argc; i++){
        if(!(fptr = fopen("./newprogram.txt","rb"))){
            printf("file \"%s\" could not be opened");
            continue;
        }

        //....

        fclose(fptr); 
    }
    
}
