        section .text
        global  horthin
horthin:
        push    ebp
        mov     ebp, esp
        ; sub esp, (LOCAL_DATA_SIZE + 3) & ~3 ; allocate locals if needed
        sub     esp, 4
        push    ebx
        push    esi
        push    edi

        mov     edx, [ebp+8]
        mov     ebx, [ebp+12]   ; width of image
        mov     ecx, [ebp+16]   ; height of image
        ; stride:
        mov     edi, ebx
        add     edi, 31
        shr     edi, 5
        shl     edi, 2          ; image stride
        
        shr     ebx, 2
        sub     ebx, edi
        mov     [ebp - 4], ebx
        
nextrow:
        mov     esi, [ebp+16]
        dec     esi
        jz      fin
        mov     [ebp+16], esi

        mov     ebx, [ebp+12]   ; width of image
        xor     ecx, ecx
nxword:
        mov     esi, 10000000000000000000000000000000b
        mov     edi, dword [edx]
        bswap   edi

loop_:
        test    edi, esi  ; check this pixel value by and'ing
        jz      black
        ; white it is
        test    ecx, ecx
        jnz     end_blk_run

cont_loop:
        dec     ebx
        jng     pr_nextrow
        
        shr     esi, 1  ; move to next pixel within dword
        jnz     loop_
        add     edx, 4
        jmp     nxword

black:
        inc     ecx
        jmp     cont_loop

end_blk_run:
        cmp     ecx, 3  ; only clean if more then 3 consecutive blacks found
        jl      after_thin_cleanup
        
        
        shl     esi, 1
        add     edi, esi
        dec     cl
        
        
        bswap   edi
        mov     [edx], edi
        bswap   edi

        mov     eax, [ebp+12]   ; width of the image
        sub     eax, ebx        ; find current position
        and     eax, 31         ; position within dword

        cmp     ecx, eax
        jl      th2ndpart       ; todo: maybe jle
        ; othwerwise, the first black pixel happened in a one of prev dwords

        mov     esi, eax        ; store eax for current esi recreation later

        ; find pixel with that dword
        neg     eax
        add     eax, ecx        ; offset from start of current dword
        mov     ecx, eax

        
        shr     eax, 5          ; divide by 32
        inc     eax
        shl     eax, 2
        and     ecx, 31         ; mod for finding the offset from the bytes beginnign position

        sub     edx, eax
        mov     edi, [edx]
        bswap   edi

        xchg    eax, esi
        mov     ch, al
        xchg    eax, esi

        mov     esi, 1
        shl     esi, cl
        add     edi, esi
        

        bswap   edi
        mov     [edx], edi
        
        add     edx, eax
        mov     edi, [edx]
        bswap   edi
        mov     cl, ch
        xor     ch, ch
        mov     esi, 10000000000000000000000000000000b
        shr     esi, cl
        jmp     after_thin_cleanup
        
th2ndpart:
        
        shl     esi, cl 
        add     edi, esi
        shr     esi, cl 

        bswap   edi
        mov     [edx], edi
        bswap   edi
        shr     esi, 1


after_thin_cleanup:
        xor     ecx, ecx ; clear counter of black pixels
        jmp     cont_loop


pr_nextrow:
        add     edx, 4
        jmp     nextrow

fin:
        pop     edi
        pop     esi
        pop     ebx
        mov     esp, ebp ; deallocate local vars 
        pop     ebp
        ret