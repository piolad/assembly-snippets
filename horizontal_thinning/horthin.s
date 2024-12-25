        section .text
        global  horthin
horthin:
        push ebp
        mov ebp, esp
        ; sub esp, (LOCAL_DATA_SIZE + 3) & ~3 ; allocate locals if needed
        push ebx
        push esi
        push edi

        
fin:
        pop edi
        pop esi 
        pop ebx
        mov esp, ebp ; local vars 
        pop ebp 
        ret