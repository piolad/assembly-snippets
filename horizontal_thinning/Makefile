EXEFILE = hth
OBJECTS = horthin.o main.o
CCFMT = -m32
NASMFMT = -f elf32
CCOPT = -g -O0
NASMOPT = -g -F dwarf -w+all

.c.o:
	cc $(CCFMT) $(CCOPT) -c $<

.s.o:
	nasm $(NASMFMT) $(NASMOPT) -l $*.lst $<

$(EXEFILE): $(OBJECTS)
	cc $(CCFMT) -o $@ $^
	
clean:
	rm *.o *.lst $(EXEFILE)
