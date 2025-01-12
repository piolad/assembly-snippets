use64
        section .text
        global  horthin

horthin:
        push    rbp
        mov     rbp, rsp
        
        push    rbx
        push    rsi
        push    rdi
        ; r12-r15 ?
        ; RDI, RSI, RDX

        xor     rcx, rcx
nextrow:
        mov     rbx, rsi   ; width of image
        
next_dword:
        mov     r8, 1000000000000000000000000000000000000000000000000000000000000000b
        mov     r9, [rdi]
        bswap   r9

next_pixel:
        test    r9, r8        ; check this pixel's value by and-ing dword with mask
        jnz     black_run_ended     ; white pixel

        ; otherwise black pixel - inc counter and continue loop
        inc     rcx

cont_loop:
        dec     rbx
        jle     prep_nextrow
        
        shr     r8, 1           ; move mask to next pixel
        jnz     next_pixel
        add     rdi, 8
        jmp     next_dword

black_run_ended:
        cmp     rcx, 3          ; only thin if more then 3 consecutive blacks found
        jl      finish_thin
        
        ; current pixel is white - move to previous
        shl     r8, 1
        or      r9, r8          ; make it white
        dec     cl
        
        bswap   r9
        mov     [rdi], r9
        bswap   r9

        mov     rax, rsi        ; width of the image
        sub     rax, rbx        ; find current position
        and     rax, 63         ; position within qword

        cmp     rcx, rax
        jge     multi_dword_thin  ;  check if the black run is contained within qword

        ; single-qword
        shl     r8, cl 
        or      r9, r8
        shr     r8, cl 

        bswap   r9
        mov     [rdi], r9
        bswap   r9
        shr     r8, 1
        jmp     finish_thin

multi_dword_thin:
        neg     rax
        add     rax, rcx        ; offset from start of current dword
        mov     rcx, rax
      
        shr     rax, 6          ; divide by 64 to get qword difference
        inc     rax             ; +1 as offset comes from beginning of curr qword
        shl     rax, 3          ; *8 for qword address

        and     rcx, 63         ; mod 64 - offset from the found qword's beginning position

        ; load the dword
        sub     rdi, rax
        mov     r9, [rdi]
        bswap   r9

        ; prep mask for dword with run's first black pixel
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
        add     rdi, 4

        ; here maybe add another 4 if we are still in top half
        mov     r10, r8
        and     r10, 1111111111111111111111111111111b
        jz      dec_rdx
        add     rdi, 4
        
dec_rdx:
        dec     rdx
        ja      nextrow

fin:
        pop    rdi
        pop    rsi
        pop    rbx

        leave
        ret