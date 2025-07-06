section .data
    hello_msg db 'Hello, world!', 0xa
    hello_len equ $ - hello_msg ; $ -> current address, hello_msg -> begginnging of string

section .text
    global _start

_start:


    ; Create a socket
    ; int socketcall(int call, unsigned long *args)
    ; call = 1 (SYS_SOCKET)
    ; args = { AF_INET, SOCK_STREAM, 0 }
    push 0x0          ; Protocol = 0 (IP)
    push 0x1          ; Type = SOCK_STREAM (TCP)
    push 0x2          ; Domain = AF_INET (IPv4)
    mov ecx, esp      ; Arguments pointer
    mov ebx, 0x1      ; SYS_SOCKET
    mov eax, 0x66     ; socketcall syscall
    int 0x80          ; Kernel interrupt
    mov esi, eax      ; Save the socket file descriptor in esi

    ; Bind the socket to an address and port
    ; int socketcall(int call, unsigned long *args)
    ; call = 2 (SYS_BIND)
    ; args = { sockfd, &sockaddr, sizeof(sockaddr) }
    ; sockaddr_in struct:
    ;   sa_family: 2 (AF_INET)
    ;   sin_port:  htons(8080) -> 0x901f (big-endian)
    ;   sin_addr:  INADDR_ANY -> 0
    push 0x0          ; sin_addr = 0 (INADDR_ANY)
    push word 0x901f  ; sin_port = 8080
    push word 0x2     ; sa_family = AF_INET
    mov edi, esp      ; edi now points to the sockaddr_in struct

    push 0x10         ; sizeof(sockaddr_in) = 16
    push edi          ; Pointer to sockaddr_in
    push esi          ; The socket file descriptor
    mov ecx, esp      ; Arguments pointer
    mov ebx, 0x2      ; SYS_BIND
    mov eax, 0x66     ; socketcall syscall
    int 0x80          ; Kernel interrupt

    ; Listen for incoming connections
    ; int socketcall(int call, unsigned long *args)
    ; call = 4 (SYS_LISTEN)
    ; args = { sockfd, backlog }
    push 0x1          ; Backlog = 1 (max pending connections)
    push esi          ; The socket file descriptor
    mov ecx, esp      ; Arguments pointer
    mov ebx, 0x4      ; SYS_LISTEN
    mov eax, 0x66     ; socketcall syscall
    int 0x80          ; Kernel interrupt

    ; Accept a connection
    ; int socketcall(int call, unsigned long *args)
    ; call = 5 (SYS_ACCEPT)
    ; args = { sockfd, NULL, NULL }
    push 0x0          ; addrlen = NULL
    push 0x0          ; addr = NULL
    push esi          ; The socket file descriptor
    mov ecx, esp      ; Arguments pointer
    mov ebx, 0x5      ; SYS_ACCEPT
    mov eax, 0x66     ; socketcall syscall
    int 0x80          ; Kernel interrupt
    mov edi, eax      ; Save the new client socket descriptor in edi

    ; Send the "Hello, world!" message to the client
    ; ssize_t write(int fd, const void *buf, size_t count);
    mov edx, hello_len ; Number of bytes to write
    mov ecx, hello_msg ; The message buffer
    mov ebx, edi       ; The client socket file descriptor
    mov eax, 0x4       ; write syscall
    int 0x80           ; Kernel interrupt

    ; Close the client socket
    ; int close(int fd);
    mov ebx, edi       ; The client socket file descriptor
    mov eax, 0x6       ; close syscall
    int 0x80           ; Kernel interrupt

    ; Close the listening socket
    mov ebx, esi       ; The server socket file descriptor
    mov eax, 0x6       ; close syscall
    int 0x80           ; Kernel interrupt


exit:
    mov ebx, 0x0       ; Exit status 0
    mov eax, 0x1       ; exit syscall
    int 0x80           ; Kernel interrupt