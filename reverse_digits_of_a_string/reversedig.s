        section .text
        global  reversedig
reversedig:
        push    ebp             ; save caller's frame pointer
        mov     ebp, esp

        push    ebx
        push    esi
        push    edi

        mov     esi, [ebp+8]
        mov     edi, esi
        
        xor     eax, eax
        ; xor     ecx, ecx
        
        mov     ecx, 0xFFFFFFFF 
        cld     ; clear direction flag - for string instructions

lastchar:
        repne   scasb   ; repeat as long as [EDI] not equal to AL=0
        dec     edi     ; go back as now edi is '\0'

f_nextnum:      ; find next num from the front
        cmp     edi, esi
        jbe     fin

        mov     bl, [esi]
        inc     esi

        ; rerun loop if non-numeric character
        cmp     bl, '0'
        jb      f_nextnum
        cmp     bl, '9'
        ja      f_nextnum

e_nextnum:      ; find next num from the end
        ; cmp     edi, esi
        ; jbe      fin

        mov al, [edi]
        dec edi
        
        ; rerun loop if non-numeric character
        cmp     al, '0'
        jb      e_nextnum
        cmp     al, '9'
        ja      e_nextnum

; swap chars:
        mov    byte [esi-1], al
        mov    byte [edi+1], bl

        jmp f_nextnum
fin:
        mov     eax, [ebp+8]
        ; xor eax, eax

        pop     edi
        pop     esi
        pop     ebx
        mov     esp, ebp        ; deallocate local variables

        pop     ebp             ; restore caller's frame pointer
        ret
