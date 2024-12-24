        section .text
        global  horthin
horthin:
; prologue – same for all routines
        push ebp ; save caller's frame pointer
        mov ebp, esp ; set own frame pointer
        ; at this point ESP == n*16 + 8
        sub esp, (LOCAL_DATA_SIZE + 3) & ~3 ; allocate locals if needed
        ; save “saved” registers if used
        push ebx
        push esi
        push edi
        ; function body - procedure-specific
        ; ...
        ; epilogue – same for all routines
        ; restore saved registers if they were saved in the prologue
        pop edi
        pop esi 
        pop ebx
        mov esp, ebp ; discard local vars if they were allocated
        pop ebp ; restore caller's frame pointer
        ret ; return to calle