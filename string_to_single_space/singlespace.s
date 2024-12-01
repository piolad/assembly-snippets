        section .text
        global  singlespace
singlespace:
        push    ebp             ; save caller's frame pointer
        mov     ebp, esp

        push    ebx
        push    esi
        push    edi

        mov     edx, [ebp+8]
        mov     ebx, edx

loop:
        mov     al, [edx]
        mov     [ebx], al
        inc     edx
        inc     ebx

        cmp     al, ' '
        je      space_det        

        jb      fin


        jmp     loop

space_det:
        cmp     byte [edx], ' '
        jnz     loop

        inc     edx
        jmp     space_det
        

fin:
        mov     eax, [ebp+8]    ; return the original arg
        pop     edi
        pop     esi
        pop     ebx
        mov     esp, ebp        ; deallocate local variables

        pop     ebp             ; restore caller's frame pointer
        ret
