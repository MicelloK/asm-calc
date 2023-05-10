dane1 segment
    nline db 13,10,'$'
    in_msg db "Wprowadz slowny opis dzialania: $"
    out_msg db "Wynikiem jest: $"
    exception_msg db "Niepoprawne dane wejsciowe! $"

    input db 63, ?, 64 dup('$') ; bufor na dane wejściowe
    arg1 db 15, ?, 16 dup('$') ; bufor na argument 1
    arg2 db 15, ?, 16 dup('$') ; bufor na argument 2
    op db 15, ?, 16 dup('$') ; bufor na operator

    arg1_int db 0 ; argument 1 jako liczba
    arg2_int db 0 ; argument 2 jako liczba
    result_int dw 0 ; wynik jako liczba

    digits db "zero ", "jeden ", "dwa ", "trzy ", "cztery ", "piec ", "szesc ", "siedem ", "osiem ", "dziewiec "

    units db "zero$", "jeden$", "dwa$", "trzy$", "cztery$", "piec$", "szesc$", "siedem$", "osiem$", "dziewiec$"
    teens db "dziesiec$", "jedenascie$", "dwanascie$", "trzynascie$", "czternascie$", "pietnascie$", "szesnascie$", "siedemnascie$", "osiemnascie$", "dziewietnascie$"
    tens db "dwadziescia $", "trzydziesci $", "czterdziesci $", "piecdziesiat $", "szescdziesiat $", "siedemdziesiat $", "osiemdziesiat $"

    units_val db 0, 1, 2, 3, 4, 5, 6, 7, 8, 9
    teens_val db 10, 11, 12, 13, 14, 15, 16, 17, 18, 19

    plus db "plus$"
    minus db "minus$"
    mlt db "razy$"
    minus_print db "minus $"

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

    ; konwersja argumentów na liczby
    mov dx, offset arg1+2
    call arg_to_int
    mov byte ptr ds:[arg1_int], al

    mov dx, offset arg2+2
    call arg_to_int
    mov byte ptr ds:[arg2_int], al

    ; działanie
    call operation

    mov dx, offset out_msg
    call puts

    call parse_int


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

; si - wskaźnik na początek pierwszego ciągu znaków
; di - wskaźnik na początek drugiego ciągu znaków
cmp_str:
    xor al, al ; 1 - równe, 0 - różne

    cmploop:
        mov bl, byte ptr ds:[si] ; bl - aktualny znak z si
        mov cl, byte ptr ds:[di] ; cl - aktualny znak z di

        cmp bl, '$' ; jeśli koniec ciągu znaków to koniec
        je cmploop_equal

        cmp cl, '$' ; jeśli koniec ciągu znaków to koniec
        je cmploop_not_equal

        cmp bl, cl ; jeśli znaki są różne to koniec
        jne cmploop_not_equal

        inc si
        inc di
        jmp cmploop

    cmploop_not_equal:
        mov al, 0
        ret

    cmploop_equal:
        mov al, 1
        ret

endl:
    mov dx, offset nline
    call puts
    ret

;------------------------;
;-- PARSOWANIE WEJSCIA --;
;------------------------;

split: ; dzieli ciąg znaków na argumenty i operator
    mov si, offset input+2 ; si - wskaźnik na początek ciągu znaków

    ; usuwanie początkowych spacji
    spcloop0:
        mov al, byte ptr ds:[si] ; al - aktualny znak
        cmp al, ' '
        jne arg1start ; jeśli nie ma spacji to znaczy że argument 1
        inc si
        jmp spcloop0

    arg1start:
        mov di, offset arg1+2

    arg1loop:
        mov al, byte ptr ds:[si] ; al - aktualny znak
        cmp al, ' '
        je arg1loop_done ; jeśli spacja to koniec
        mov byte ptr ds:[di], al ; zapisanie znaku do bufora
        inc si
        inc di
        jmp arg1loop

    arg1loop_done:
        mov byte ptr ds:[di], '$' ; zakończenie bufora

    ; pomijanie spacji
    spcloop1:
        mov al, byte ptr ds:[si] ; al - aktualny znak
        cmp al, ' '
        jne operator ; jeśli nie ma spacji to znaczy że operator
        inc si
        jmp spcloop1

    operator:
        mov di, offset op+2

    oploop:
        mov al, byte ptr ds:[si] ; al - aktualny znak
        cmp al, ' '
        je oploop_done ; jeśli spacja to koniec
        mov byte ptr ds:[di], al ; zapisanie znaku do bufora
        inc si
        inc di
        jmp oploop

    oploop_done:
        mov byte ptr ds:[di], '$' ; zakończenie bufora
    
    spcloop2:
        mov al, byte ptr ds:[si]
        cmp al, ' '
        jne arg2start
        inc si
        jmp spcloop2

    arg2start:
        mov di, offset arg2+2

    arg2loop:
        mov al, byte ptr ds:[si]
        cmp al, ' '
        je arg2loop_done
        cmp al , 13
        je arg2loop_done
        mov byte ptr ds:[di], al
        inc si
        inc di
        jmp arg2loop

    arg2loop_done:
        mov byte ptr ds:[di], '$' ; zakończenie bufora

    ret

; dx - offset na argument+2
arg_to_int:
    mov si, offset digits
    xor ch, ch ; ch - ilosc spacji = 0

    fit:
        mov di, dx

        number_loop:
            mov al, byte ptr ds:[si] ; al - aktualny znak z si
            mov bl, byte ptr ds:[di] ; bl - aktualny znak z arg1

            cmp ch, 10 ; jeśli mniej niż 10 spacji to ok
            je exception ; jeśli więcej niż 10 spacji to błąd

            cmp bl, '$' ; jeśli koniec ciągu znaków to koniec
            je fit_done

            inc si
            cmp al, bl ; jeśli znaki są różne to koniec
            jne next_num

            inc di
            jmp number_loop

    next_num:
        inc ch

        next_loop:
            mov al, byte ptr ds:[si] ; al - aktualny znak z si
            cmp al, ' '
            je next_loop_done
            inc si
            jmp next_loop

        next_loop_done:
            inc si
            jmp fit

    fit_done:
        cmp al, ' '
        jne exception ; jeśli arg sie skonczyl ale drugi wyraz nie to błąd

        mov al, ch
        ; mov byte ptr ds:[di], ch ; zapisanie ilości spacji
        ret

; operation - wykonuje działanie na arg1 i arg2
operation:
    mov di, offset op+2 ; di - wskaźnik na początek ciągu znaków

    mov si, offset plus ; si - wskaźnik na początek ciągu znaków
    call cmp_str
    cmp al, 1
    je plus_found

    mov si, offset minus
    call cmp_str
    cmp al, 1
    je minus_found

    mov si, offset mlt
    call cmp_str
    cmp al, 1
    je mlt_found

    jmp exception

    plus_found:
        mov al, byte ptr ds:[arg1_int]
        add al, byte ptr ds:[arg2_int] ; al - wynik
        mov byte ptr ds:[result_int], al
        ret

    minus_found:
        mov al, byte ptr ds:[arg1_int]
        sub al, byte ptr ds:[arg2_int]
        mov byte ptr ds:[result_int], al
        ret

    mlt_found:
        xor ax, ax
        mov al, byte ptr ds:[arg1_int]
        mul byte ptr ds:[arg2_int]
        mov byte ptr ds:[result_int], al
        ret

parse_int:
    xor ah, ah
    mov al, byte ptr ds:[result_int]

    cmp al, 0
    jl minus_sign

    cmp al, 10
    jl parse_units
    
    cmp al, 20
    jl parse_teens

    parse_tens:
        mov si, offset units_val+2
        mov di, offset tens

        mov bl, 10
        div bl ; al - dziesiatki, ah - jednosci
        mov bh , ah ; bh - jednosci, puts psuje ax
        
        tens_loop:
            cmp al, byte ptr ds:[si]
            je tens_loop_done
            call next_offset
            inc si
            jmp tens_loop

        tens_loop_done:
            mov dx, di
            call puts
            mov al, bh
            cmp al, 0

            je dont_add_unit
            jmp parse_units
            dont_add_unit:
                ret

    parse_teens:
        mov si, offset teens_val
        mov di, offset teens

        teens_loop:
            cmp al, byte ptr ds:[si]
            je teens_loop_done
            call next_offset
            inc si
            jmp teens_loop

        teens_loop_done:
            mov dx, di
            call puts
            ret

    minus_sign:
        mov dx, offset minus_print
        call puts
        mov al, byte ptr ds:[result_int]
        neg al
        jmp parse_units

    parse_units:
        mov si, offset units_val
        mov di, offset units

        units_loop:
            cmp al, byte ptr ds:[si]
            je units_loop_done
            call next_offset
            inc si
            jmp units_loop

        units_loop_done:
            mov dx, di
            call puts
            ret

    next_offset: ; inkrementuje di do następnego znaku '$'
        mov bl, byte ptr ds:[di]
        cmp bl, '$'
        je next_offset_end

        inc di
        jmp next_offset
        next_offset_end:
            inc di
            ret

        







    















;------------------------;



    


code1 ends

;------------------------------------------------

stos1 segment stack
    dw 300 dup (?) ; 600 bajtów
    wstos1 dw ? ; wierzchołek stosu
stos1 ends

;------------------------------------------------

end start1