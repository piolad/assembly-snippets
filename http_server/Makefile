EXEFILE = http
OBJECTS = http.o
NASMFMT = -f elf32
NASMOPT = -g -F dwarf -w+all


all: $(EXEFILE)

$(OBJECTS): %.o: %.s
	nasm $(NASMFMT) $(NASMOPT) -o $@ $<


$(EXEFILE): $(OBJECTS)
	ld -m elf_i386 -o $(EXEFILE) $(OBJECTS)

.PHONY: clean
clean:
	rm -f $(EXEFILE) $(OBJECTS) *.lst