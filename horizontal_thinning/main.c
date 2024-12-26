#include <stdio.h>
#include <stdint.h>

#pragma pack(push, 1) // disable adding padding to structures

typedef struct
{
    uint16_t bfType; // must be 'BM' (0x4D42)
    uint32_t bfSize;
    uint16_t bfReserved1;
    uint16_t bfReserved2;
    uint32_t bfOffBits; // offset to start of pixel data
} BMPFileHeader;

typedef struct
{
    uint32_t biSize;     // size of this header
    int32_t biWidth;     // image width
    int32_t biHeight;    // image height
    uint16_t biPlanes;   // must be 1
    uint16_t biBitCount; // bits per pixel
    uint32_t biCompression;
    uint32_t biSizeImage;
    int32_t biXPelsPerMeter;
    int32_t biYPelsPerMeter;
    uint32_t biClrUsed;
    uint32_t biClrImportant;
} BMPInfoHeader;

#pragma pack(pop)

void horthin(void *img, uint32_t width, uint32_t height);

int main(int argc, char *argv[])
{
    if (argc != 3)
    {
        printf("Usage: <input_bmp_file> <output_bmp_file>\n");
        return 1;
    }

    FILE *f_in;
    FILE *f_out;
    if (!(f_in = fopen(argv[1], "rb")))
    {
        printf("File \"%s\" could not be opened", argv[1]);
        return 1;
    }

    BMPFileHeader fileHeader;
    if (fread(&fileHeader, sizeof(BMPFileHeader), 1, f_in) != 1)
    {
        printf("Error reading BMP file header.\n");
        fclose(f_in);
        return 1;
    }
    print_debug_BMP_fileheader(fileHeader);

    BMPInfoHeader infoHeader;
    if (fread(&infoHeader, sizeof(BMPInfoHeader), 1, f_in) != 1)
    {
        printf("Error reading BMP info header.\n");
        fclose(f_in);
        return 1;
    }
    print_debug_BMP_infoheader(infoHeader);


    if(fseek(f_in, fileHeader.bfOffBits, SEEK_SET) != 0){
        printf("Error seeking to image data.\n");
        fclose(f_in);
        return 1;
    }

    uint32_t width  = (uint32_t) infoHeader.biWidth;
    uint32_t height = (uint32_t) infoHeader.biHeight;

    // 1 bpp, each row is padded to a multiple of 4 bytes
    size_t rowSize  = ((width + 31u) / 32u) * 4u;
    size_t dataSize = rowSize * height;

    printf("width: %d\n", width);
    printf("height: %d\n", height);
    printf("rowSize: %d\n", rowSize);
    printf("dataSize: %d\n", dataSize);

    uint8_t *imgData = (uint8_t *)malloc(dataSize);
    if (!imgData) {
        fprintf(stderr, "Memory allocation failed.\n");
        fclose(f_in);
        return 1;
    }

    if (fread(imgData, 1, dataSize, f_in) != dataSize) {
        fprintf(stderr, "Error reading BMP pixel data.\n");
        free(imgData);
        fclose(f_in);
        return 1;
    }

    displayBitmap1bpp(imgData, width, height);
    horthin(imgData, width, height);
    // horthin_t(imgData, width, height);
    
    uint32_t headerSize = fileHeader.bfOffBits;
    rewind(f_in);
    uint8_t *headerBlock = (uint8_t *)malloc(headerSize);
    if (!headerBlock) {
        fprintf(stderr, "Memory allocation failed for header.\n");
        fclose(f_in);
        return 1;
    }
    if (fread(headerBlock, 1, headerSize, f_in) != headerSize) {
        fprintf(stderr, "Error reading complete header block.\n");
        free(headerBlock);
        fclose(f_in);
        return 1;
    }
    fclose(f_in);

    f_out = fopen(argv[2], "wb");

    if (fwrite(headerBlock, 1, headerSize, f_out) != headerSize) {
        fprintf(stderr, "Error writing header block.\n");
        fclose(f_out);
        free(imgData);
        free(headerBlock);
        return 1;
    }

    if (fwrite(imgData, 1, dataSize, f_out) != dataSize) {
        fprintf(stderr, "Error writing modified pixel data.\n");
        fclose(f_out);
        free(imgData);
        free(headerBlock);
        return 1;
    }
    fclose(f_out);


    free(imgData);
    free(headerBlock);
}




void print_debug_BMP_fileheader(BMPFileHeader fileHeader)
{
    printf("bfType: %x\n", fileHeader.bfType);
    printf("bfSize: %x\n", fileHeader.bfSize);
    printf("bfReserved1: %x\n", fileHeader.bfReserved1);
    printf("bfReserved2: %x\n", fileHeader.bfReserved2);
    printf("bfOffBits: %x\n", fileHeader.bfOffBits);
}
void print_debug_BMP_infoheader(BMPInfoHeader infoHeader)
{
    printf("biSize: %x\n", infoHeader.biSize);
    printf("biWidth: %x\n", infoHeader.biWidth);
    printf("biHeight: %x\n", infoHeader.biHeight);
    printf("biPlanes: %x\n", infoHeader.biPlanes);
    printf("biBitCount: %x\n", infoHeader.biBitCount);
    printf("biCompression: %x\n", infoHeader.biCompression);
    printf("biSizeImage: %x\n", infoHeader.biSizeImage);
    printf("biXPelsPerMeter: %x\n", infoHeader.biXPelsPerMeter);
    printf("biYPelsPerMeter: %x\n", infoHeader.biYPelsPerMeter);
    printf("biClrUsed: %x\n", infoHeader.biClrUsed);
    printf("biClrImportant: %x\n", infoHeader.biClrImportant);
}


void displayBitmap1bpp(const uint8_t *imgData, uint32_t width, uint32_t height)
{
    size_t rowSize = ((width + 31u) / 32u) * 4u;

    // display from bottom to top
    for (int row = (int)height - 1; row >= 0; row--) {
        const uint8_t *rowPtr = imgData + row * rowSize;

        // left to right
        for (uint32_t col = 0; col < width; col++) {
            // For 1bpp, the leftmost pixel is bit 7 of the byte
            // '>> (7 - (col % 8))' shifts that bit down to position 0
            // '& 1' extracts it.
            int bit = (rowPtr[col / 8] >> (7 - (col % 8))) & 1;
            
            printf("%d", bit);
        }
        printf("\n");
    }
}


void horthin_t(void *img, uint32_t width, uint32_t height){
    // invert colors to see if it works
    size_t rowSize = ((width + 31u) / 32u) * 4u;
    uint8_t *p = (uint8_t *)img;
    for (size_t row = 0; row < height; row++) {
        for (size_t col = 0; col < rowSize; col++) {
            p[col] = ~p[col];
        }
        p += rowSize;
    }
}