# HTTP server

Usage:

```bash
nasm -f elf32 http.s -o http.o
ld -m elf_i386 http.o -o http
./http
```

in another terminal:

```bash
curl http://localhost:8080
```