use64
        section .text
        global  horthin

horthin:
        push    rbp
        mov     rbp, rsp
        
        push    rbx
        ; push    rsi
        ; push    rdi
        ; r12-r15 ?
        ; RDI, RSI, RDX

        mov     r11, rsi
        add     r11, 7
        shr     r11, 3

        mov     r10, rsi
        add     r10, 31
        shr     r10, 5
        shl     r10, 2
        sub     r10, r11
        shl     r10, 2

        xor     rcx, rcx
nextrow:
        mov     rbx, rsi   ; width of image
        
next_qword:
        mov     r8, 1000000000000000000000000000000000000000000000000000000000000000b
        mov     r9, [rdi]
        bswap   r9

next_pixel:
        test    r9, r8        ; check this pixel's value by and-ing qword with mask
        jnz     black_run_ended     ; white pixel

        ; otherwise black pixel - inc counter and continue loop
        inc     rcx

cont_loop:
        dec     rbx
        jle     prep_nextrow
        
        shr     r8, 1           ; move mask to next pixel
        jnz     next_pixel
        add     rdi, 8
        jmp     next_qword

black_run_ended:
        cmp     rcx, 3          ; only thin if more then 3 consecutive blacks found
        jl      finish_thin
        
        ; current pixel is white - move to previous
        mov     rax, 1
        shl     r8, 1
        cmovz   r8, rax

        or      r9, r8          ; make it white
        dec     cl
        
        bswap   r9
        mov     [rdi], r9
        bswap   r9

        mov     rax, rsi        ; width of the image
        sub     rax, rbx        ; find current position
        ; dec     rax
        cmp     rax, 64
        je      single
        and     rax, 63         ; position within qword

        cmp     rcx, rax
        jge     multi_qword_thin  ;  check if the black run is contained within qword

single:
        ; single-qword
        shl     r8, cl 
        or      r9, r8
        shr     r8, cl 

        bswap   r9
        mov     [rdi], r9
        bswap   r9
        shr     r8, 1
        jmp     finish_thin

multi_qword_thin:
        ; mov     r, rax
        test    rax, rax
        jnz     rax_not_z
        mov     rax, 64

rax_not_z:
        neg     rax
        add     rax, rcx        ; offset from start of current qword
        mov     rcx, rax
      
        shr     rax, 6          ; divide by 64 to get qword difference
        inc     rax             ; +1 as offset comes from beginning of curr qword
        shl     rax, 3          ; *8 for qword address

        and     rcx, 63         ; mod 64 - offset from the found qword's beginning position

        ; load the qword
        sub     rdi, rax
        mov     r9, [rdi]
        bswap   r9

        ; prep mask for qword with run's first black pixel
        mov     r11, 1
        shl     r11, cl
        or      r9, r11

        bswap   r9
        mov     [rdi], r9

        ; load previous byte
        add     rdi, rax
        mov     r9, [rdi]
        bswap   r9

        shr     r8, 1      

finish_thin:
        xor     rcx, rcx        ; clear counter of black pixels
        jmp     cont_loop


prep_nextrow:
        
        shr     r8, 1
        test    rcx, rcx
        jnz     black_run_ended


        ; mov     rax, rbx
        ; xchg    cl, al
        mov     rcx, rbx
        neg     cl
        shl     r8, cl
        ; xchg    cl, al
        xor     ecx, ecx
        add     rdi, 4
        test    r8, r8
        jz      add4_to_rdi
        test    r8, 1111111111111111111111111111111b
        jz      dec_rdx
        ; test    r8, 32

add4_to_rdi:
        ; jz      dec_rdx
        add     rdi, 4
        
dec_rdx:
        dec     rdx
        ja      nextrow

fin:
        ; pop    rdi
        ; pop    rsi
        pop    rbx

        leave
        ret