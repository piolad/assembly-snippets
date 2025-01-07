        section .text
        global  horthin

; wszystkie skoki warunkowe
; brak liczbze znakiem - nie uzywac jng etc

; sprawdzic xor ecx ecx czy jest powtorzenie
; za duzo skoków bezwarunkowych
horthin:
        push    ebp
        mov     ebp, esp
        
        push    ebx
        push    esi
        push    edi

        mov     edx, [ebp+8]    ; bitmap data
        



nextrow:
        mov     ebx, [ebp+12]   ; width of image
        xor     ecx, ecx
next_dword:
        mov     esi, 10000000000000000000000000000000b
        mov     edi, dword [edx]
        bswap   edi

next_pixel:
        test    edi, esi        ; check this pixel's value by and-ing dword with mask
        jz      black

        ; white it is
        test    ecx, ecx
        jnz     end_blk_run

cont_loop:
        dec     ebx
        jle     pr_nextrow      ; nie not grater 
        
        shr     esi, 1          ; move mask to next pixel
        jnz     next_pixel
        add     edx, 4
        jmp     next_dword

black:
        inc     ecx
        jmp     cont_loop

end_blk_run:
        cmp     ecx, 3          ; only clean if more then 3 consecutive blacks found
        jl      after_thin_cleanup
        
        ; this pixel is white - move to previous
        shl     esi, 1
        or     edi, esi        ; make it white
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
        xor     ecx, ecx        ; clear counter of black pixels
        jmp     cont_loop


pr_nextrow:
        shr     esi, 1
        test    ecx, ecx
        jnz     end_blk_run
        add     edx, 4

        mov     esi, [ebp+16]
        dec     esi
        mov     [ebp+16], esi
        ja      nextrow

fin:
        pop     edi
        pop     esi
        pop     ebx
        ; mov     esp, ebp        ; deallocate local vars 
        pop     ebp
        ret