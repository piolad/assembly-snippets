        section .text
        global  getFirstNumber
getFirstNumber:
        push    ebp             ; save caller's frame pointer
        mov     ebp, esp

        push    ebx
        push    esi
        push    edi

        mov     ecx, [ebp+8]
        
        xor     eax, eax        ; result of converison
        xor     ebx, ebx        ; zeroing for later


findFirstNum:
        xor     edi, edi        ; flag for negation
afterclear:

        mov     bl, [ecx]
        cmp     bl, ' '
        jb      fin

        inc     ecx

        cmp     bl, '-'
        je      setMinus

        cmp     bl, '0'
        jb      findFirstNum

        cmp     bl, '9'
        ja      findFirstNum

        
        mov      esi, 10
getNumber:

        imul    dword esi       ; IMPORTANT! when multiplaying here, half is moved to !!!!edx!!! which was causing memory dereferencing
        sub     bl, '0'
        add     eax, ebx

        mov     bl, [ecx]
        inc     ecx

        cmp     bl, '0'
        jb      fin
        ;jl      fin

        cmp     bl, '9'
        ja      fin
        ; jg      fin

        

        jmp getNumber
        


fin:
        test    edi, edi
        jz      skip_neg
        ; mov     eax, 20    ; return the original arg

        neg     eax
skip_neg:

        pop     edi
        pop     esi
        pop     ebx
        mov     esp, ebp        ; deallocate local variables

        pop     ebp             ; restore caller's frame pointer
        ret


setMinus:
        mov     edi, 1
        jmp afterclear