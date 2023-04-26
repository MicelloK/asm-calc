dane1 segment
    nline db 13,10,'$'
    in_msg db "Wprowadz slowny opis dzialania: $"
    out_msg db "Wynikiem jest: $"
    exception_msg db "Niepoprawne dane wejsciowe! $"

    input db 64, ?, 65 dup('$') ; bufor na dane wejściowe
    arg1 db 16, ?, 17 dup('$') ; bufor na argument 1
    arg2 db 16, ?, 17 dup('$') ; bufor na argument 2
    op db 1, ?, 2 dup('$') ; bufor na operator

    zero db "zero$",0
    one db "jeden$",1
    two db "dwa$",2
    three db "trzy$",3
    four db "cztery$",4
    five db "piec$",5
    six db "szesc$",6
    seven db "siedem$",7
    eight db "osiem$",8
    nine db "dziewiec$",9

    ten db "dziesiec$",10
    eleven db "jedenascie$",11
    twelve db "dwanascie$",12
    thirteen db "trzynascie$",13
    fourteen db "czternascie$",14
    fifteen db "pietnascie$",15
    sixteen db "szesnascie$",16
    seventeen db "siedemnascie$",17
    eighteen db "osiemnascie$",18
    nineteen db "dziewietnascie$",19

    twenty db "dwadziescia$",20
    thirty db "trzydziesci$",30
    forty db "czterdziesci$",40
    fifty db "piecdziesiat$",50
    sixty db "szescdziesiat$",60
    seventy db "siedemdziesiat$",70
    eighty db "osiemdziesiat$",80

    plus db "plus$"
    minus db "minus$"
    mlt db "razy$"

dane1 ends

;------------------------------------------------

code1 segment
start1:
    ; inicjalizacja stosu
    mov ax, seg stos1
    mov ss, ax
    mov sp, offset wstos1

    ; początek programu
    mov dx, offset in_msg
    call puts

    ; wczytanie danych
    call getl
    call endl

    ; analiza danych
    call split

    mov dx, offset arg2+2
    call puts

    mov dx, offset op+2
    call puts

    mov dx, offset arg1+2
    call puts

exit:
    mov al,0 ; zwroc 0 do systemu
    mov ah,4ch
    int 21h

exception:
    mov dx, offset exception_msg
    call puts
    jmp exit


;------------------------;
;-- FUNKCJE POMOCNICZE --;
;------------------------;

puts: ; wypisuje ciąg znaków, którego offset jest w dx
    mov ax, seg dane1
    mov ds, ax
    mov ah, 09h
    int 21h
    ret

getl: ; wczytuje ciąg znaków z klawiatury i zapisuje do bufora
    mov ax, seg dane1
    mov ds, ax
    mov dx, offset input
    mov ah, 0ah ; wczytaj ciąg znaków
    int 21h
    ret

endl:
    mov dx, offset nline
    call puts
    ret

split: ; dzieli ciąg znaków na argumenty i operator
    mov si, offset input+2 ; si - wskaźnik na początek ciągu znaków

    mov di, offset arg1+2
    arg1loop:
        mov al, [si]
        cmp al, ' '
        je arg1loop_done
        mov [di], al
        inc si
        inc di
        jmp arg1loop

    arg1loop_done:
        mov byte ptr [di], '$' ; zakończenie bufora

    ; pomijanie spacji
    spcloop1:
        mov al, [si]
        cmp al, ' '
        jne operator
        inc si
        jmp spcloop1

    operator:
        mov di, offset op+2 ; di - wskaźnik na początek bufora operatora
        mov al, [si]
        cmp al, '+' ; sprawdzenie czy operator jest dodawaniem
        je op_plus
        cmp al, '-' ; sprawdzenie czy operator jest odejmowaniem
        je op_minus
        cmp al, '*' ; sprawdzenie czy operator jest mnożeniem
        je op_mlt
        jmp exception ; niepoprawny operator

    op_plus:
        mov dx, offset plus
        jmp op_done

    op_minus:
        mov dx, offset minus
        jmp op_done

    op_mlt:
        mov dx, offset mlt
        jmp op_done

    op_done:
        inc si
        mov [di], al
        inc di
        mov byte ptr [di], '$' ; zakończenie bufora
    
    spcloop2:
        mov al, [si]
        cmp al, ' '
        jne arg2start
        inc si
        jmp spcloop2

    arg2start:
        mov di, offset arg2+2

    arg2loop:
        mov al, [si]
        cmp al, ' '
        je arg2loop_done
        cmp al , 13
        je arg2loop_done
        mov [di], al
        inc si
        inc di
        jmp arg2loop

    arg2loop_done:
        mov byte ptr [di], '$' ; zakończenie bufora

    ret
    


code1 ends

;------------------------------------------------

stos1 segment stack
    dw 300 dup (?) ; 600 bajtów
    wstos1 dw ? ; wierzchołek stosu
stos1 ends

;------------------------------------------------

end start1