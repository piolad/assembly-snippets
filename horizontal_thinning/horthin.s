        section .text
        global  horthin
horthin:
        push    ebp
        mov     ebp, esp
        ; sub esp, (LOCAL_DATA_SIZE + 3) & ~3 ; allocate locals if needed
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
        
nextrow:
        mov     esi, [ebp+16]
        dec     esi
        jz      fin
        mov     [ebp+16], esi

        xor     ecx, ecx
        mov     esi, 10000000000000000000000000000000b
        mov     edi, dword [edx]
        bswap   edi
        mov     ebx, [ebp+12]   ; width of image
loop_:
        mov     eax, edi

        and     eax, esi  ; check this pixel value
        jz      black
        ; white it is
        test    ecx, ecx
        jnz     end_blk_run

cont_loop:
        shr     esi, 1  ; move to next pixel within dword
        dec     ebx
        jnz     loop_
        add     edx, 4
        jmp     nextrow

black:
        inc     ecx
        jmp     cont_loop

end_blk_run:
        cmp     ecx, 3  ; only clean if more then 3 consecutive blacks found
        jl      after_thin_cleanup
        
        shl     esi, 1
        add     edi, esi
        dec     cl
        shl     esi, cl ; -1?
        add     edi, esi
        shr     esi, cl ; -1?

        bswap   edi
        mov     [edx], edi
        bswap   edi

after_thin_cleanup:
        xor     ecx, ecx ; clear counter of black pixels
        jmp     cont_loop

fin:
        pop     edi
        pop     esi 
        pop     ebx
        mov     esp, ebp ; deallocate local vars 
        pop     ebp 
        ret