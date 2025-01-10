        section .text
        global  horthin

; wszystkie skoki warunkowe
; brak liczbze znakiem - nie uzywac jng etc

; sprawdzic xor ecx ecx czy jest powtorzenie
; za duzo skoków bezwarunkowych
; sprawdizć czy dałoby się ogarnmąć th2ndpart
horthin:
        push    ebp
        mov     ebp, esp
        
        push    ebx
        push    esi
        push    edi

        mov     edx, [ebp+8]    ; bitmap data
        xor     ecx, ecx

nextrow:
        mov     ebx, [ebp+12]   ; width of image
        
next_dword:
        mov     esi, 10000000000000000000000000000000b
        mov     edi, dword [edx]
        bswap   edi

next_pixel:
        test    edi, esi        ; check this pixel's value by and-ing dword with mask
        jnz     end_blk_run     ; white pixel

        ; otherwise black pixel - inc counter and continue loop
        inc     ecx

cont_loop:
        dec     ebx
        jle     pr_nextrow
        
        shr     esi, 1          ; move mask to next pixel
        jnz     next_pixel
        add     edx, 4
        jmp     next_dword

end_blk_run:
        cmp     ecx, 3          ; only thin if more then 3 consecutive blacks found
        jl      after_thin_cleanup
        
        ; current pixel is white - move to previous
        shl     esi, 1
        or      edi, esi        ; make it white
        dec     cl
        
        bswap   edi
        mov     [edx], edi
        bswap   edi

        mov     eax, [ebp+12]   ; width of the image
        sub     eax, ebx        ; find current position
        and     eax, 31         ; position within dword

        cmp     ecx, eax
        jl      th2ndpart       ; check if the black run is contained within dword

        ; othwerwise, change the other dword
        mov     esi, eax        ; save mask's shamt

        neg     eax
        add     eax, ecx        ; offset from start of current dword
        mov     ecx, eax

        
        shr     eax, 5          ; divide by 32 to get dword difference
        inc     eax             ; +1 as offset comes from beginning of curr dword
        shl     eax, 2          ; *4 for dword address

        and     ecx, 31         ; mod 32 - offset from the found dword's beginning position

        ; load the dword
        sub     edx, eax
        mov     edi, [edx]
        bswap   edi

        ; save the prev mask's shamt to ch
        xchg    eax, esi
        mov     ch, al
        xchg    eax, esi

        ; prep mask for dword with run's first black pixel
        mov     esi, 1
        shl     esi, cl
        or      edi, esi

        bswap   edi
        mov     [edx], edi
        

        ; load previous byte
        add     edx, eax
        mov     edi, [edx]
        bswap   edi

        ; restore the shamt
        mov     cl, ch
        xor     ch, ch
        mov     esi, 10000000000000000000000000000000b
        shr     esi, cl
        jmp     after_thin_cleanup
        
th2ndpart:
        
        shl     esi, cl 
        or      edi, esi
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