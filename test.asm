dane1 segment
    t1 db "Hello Worlds!", 13, 10, "$"
dane1 ends



code1 segment
start1:
    mov ax, seg t1
    mov ds, ax
    mov dx, offset t1 ; to chyba tworzy adres t1

    mov ah, 9
    int 21h ; to chyba wypisuje t1 jak w ah jest 9

    mov ah, 4ch
    int 21h ; to chyba konczy program jak w ah jest 4ch
code1 ends



stack1 segment stack
    dw 300 dup(?)
stack1 ends

end start1