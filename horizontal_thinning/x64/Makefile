# x64/Makefile

EXEFILE   = hth64
CC        = gcc
NASM      = nasm

CFLAGS    = -m64 -g -O0
NASMFLAGS = -f elf64 -g -F dwarf -w+all

# We'll compile main.c (which is one level up) and horthin.s (in this folder).
OBJECTS = horthin.o main.o

all: $(EXEFILE)

$(EXEFILE): $(OBJECTS)
	$(CC) $(CFLAGS) -o $@ $^

horthin.o: horthin.s
	$(NASM) $(NASMFLAGS) -l $*.lst $<

# Note the "../" in front of main.c, since it's one directory up.
main.o: ../main.c
	$(CC) $(CFLAGS) -c $< -o $@

clean:
	rm -f *.o *.lst $(EXEFILE)
