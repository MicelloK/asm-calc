;===============================================================================;
;                                    DANE                                       ;
;===============================================================================;

dane1 segment
    nline db 13,10,'$'                                  ; znak nowej linii
    in_msg db "Wprowadz slowny opis dzialania: $"       ; wiadomość wejściowa
    out_msg db "Wynikiem jest: $"                       ; wiadomość wyjściowa
    exception_msg db "Niepoprawne dane wejsciowe! $"    ; wiadomość wyjątku

    input db 63, ?, 64 dup('$')                         ; bufor na dane wejściowe
    arg1 db 15, ?, 16 dup('$')                          ; bufor na argument 1
    arg2 db 15, ?, 16 dup('$')                          ; bufor na argument 2
    op db 15, ?, 16 dup('$')                            ; bufor na operator

    arg1_int db 0                                       ; argument 1 jako liczba
    arg2_int db 0                                       ; argument 2 jako liczba
    result_int dw 0                                     ; wynik jako liczba

    ; digits - do parsowania wejśścia (arg_to_int)
    ; units, teens, tens - do wyświetlania wyniku (parse_int)
    digits db "zero ", "jeden ", "dwa ", "trzy ", "cztery ", "piec ", "szesc ", "siedem ", "osiem ", "dziewiec "
    units db "zero$", "jeden$", "dwa$", "trzy$", "cztery$", "piec$", "szesc$", "siedem$", "osiem$", "dziewiec$"
    teens db "dziesiec$", "jedenascie$", "dwanascie$", "trzynascie$", "czternascie$", "pietnascie$", "szesnascie$", "siedemnascie$", "osiemnascie$", "dziewietnascie$"
    tens db "dwadziescia $", "trzydziesci $", "czterdziesci $", "piecdziesiat $", "szescdziesiat $", "siedemdziesiat $", "osiemdziesiat $"

    ; units_val, teens_val - do konwersji napisów na liczby (parse_int)
    units_val db 0, 1, 2, 3, 4, 5, 6, 7, 8, 9
    teens_val db 10, 11, 12, 13, 14, 15, 16, 17, 18, 19

    ; plus, minus, mlt - do rozpoznawania operatora (operation)
    ; minus_print - do wypisywania wyniku (parse_int)
    plus db "plus$"
    minus db "minus$"
    mlt db "razy$"
    minus_print db "minus $"

dane1 ends

;===============================================================================;
;                                KOD PROGRAMU                                   ;
;===============================================================================;

code1 segment
start1:
    ; \inicjalizacja stosu\
    mov ax, seg stos1                                   ; segment stosu
    mov ss, ax                                          ; ss = stos1
    mov sp, offset wstos1                               ; sp = wstos1

    ; \początek programu\
    mov dx, offset in_msg                               ; dx = in_msg
    call puts ; wypisanie wiadomości

    ; \obsługa wejścia\
    call getl                                           ; wczytanie ciągu znaków
    call endl                                           ; wypisanie znaku nowej linii

    call split                                          ; podział ciągu znaków na argumenty i operator

    ; \konwersja argumentów na liczby\
    mov dx, offset arg1+2                               ; dx - offset na argument1
    call arg_to_int                                     ; konwersja argumentu 1 na liczbę
    mov byte ptr ds:[arg1_int], al                      ; zapisanie wyniku funkcji arg_to_int do arg1_int

    mov dx, offset arg2+2                               ; dx - offset na argument2
    call arg_to_int                                     ; konwersja argumentu 2 na liczbę
    mov byte ptr ds:[arg2_int], al                      ; zapisanie wyniku funkcji arg_to_int do arg2_int

    ; \wykonanie działania\
    call operation                                      ; wykonanie działania i zapisanie wyniku do result_int

    ; \wypisanie wyniku\
    mov dx, offset out_msg                              ; dx - offset na wiadomość wyjściową
    call puts                                           ; wypisanie wiadomości

    call parse_int                                      ; parsowanie wyniku i wypisanie słownego opisu


exit:
    mov al,0                                            ; zwroc 0 do systemu
    mov ah,4ch                                          ; wyjscie z programu
    int 21h                                             ; wywolanie przerwania

exception:
    mov dx, offset exception_msg
    call puts
    jmp exit

;===============================================================================;
;                               FUNKCJE POMOCNICZE                              ;
;===============================================================================;

;-------------------------------------------------------------------------------;
; wypisuje ciąg znaków                                                          ;
; dx - offset na ciąg znaków                                                    ;
;-------------------------------------------------------------------------------;

puts:
    mov ax, seg dane1                                   ; segment danych
    mov ds, ax                                          ; ds - dane1
    mov ah, 09h                                         ; wypisz ciąg znaków
    int 21h                                             ; wywołanie przerwania
    ret

;-------------------------------------------------------------------------------;
; wczytuje ciąg znaków z klawiatury i zapisuje do bufora (input)                ;
;-------------------------------------------------------------------------------;

getl:
    mov ax, seg dane1                                   ; segment danych
    mov ds, ax                                          ; ds - dane1
    mov dx, offset input                                ; dx - offset na bufor
    mov ah, 0ah                                         ; wczytaj ciąg znaków
    int 21h                                             ; wywołanie przerwania
    ret

;-------------------------------------------------------------------------------;
; porównuje dwa ciągi znaków                                                    ;
; zwraca 1 jeśli są równe, 0 jeśli są różne (al)                                ;
; si - wskaźnik na początek pierwszego ciągu znaków                             ;
; di - wskaźnik na początek drugiego ciągu znaków                               ;
;-------------------------------------------------------------------------------;

cmp_str:
    xor al, al ; al - wynik

    cmploop:
        mov bl, byte ptr ds:[si]                        ; bl - aktualny znak z si
        mov cl, byte ptr ds:[di]                        ; cl - aktualny znak z di

        cmp bl, '$'                                     ; jeśli bl się skończył to napisy są równe
        je cmploop_equal ; 

        cmp cl, '$'                                     ; jeśli di się skończył a si nie to napisy są różne
        je cmploop_not_equal

        cmp bl, cl                                      ; jeśli znaki są różne to koniec
        jne cmploop_not_equal

        inc si                                          ; inkrementacja na następny znak si
        inc di                                          ; inkrementacja na następny znak di
        jmp cmploop

    cmploop_not_equal:
        mov al, 0                                       ; zwróć 0
        ret

    cmploop_equal:
        mov al, 1                                       ; zwróć 1
        ret

;-------------------------------------------------------------------------------;
; wypisuje znak nowej linii                                                     ;
;-------------------------------------------------------------------------------;

endl:
    mov dx, offset nline                                ; dx - offset na znak nowej linii
    call puts                                           ; wypisanie znaku nowej linii
    ret

;===============================================================================;
;                              PARSOWANIE WEJŚCIA                               ;
;===============================================================================;

;-------------------------------------------------------------------------------;
; dzieli ciąg znaków na argumenty i operator                                    ;
; wynik zapisuje do bufferów odpowiednio: arg1, op, arg2                        ;
; input - ciąg znaków do podziału                                               ;
;-------------------------------------------------------------------------------;

split:
    mov si, offset input+2                              ; si - wskaźnik na początek wejścia

    ; /usuwanie początkowych spacji/
    spcloop0:
        mov al, byte ptr ds:[si]                        ; al - aktualny znak
        cmp al, ' '                                     ; jeśli nie spacja to koniec
        jne arg1start
        inc si                                          ; inkrementacja na następny znak
        jmp spcloop0

    arg1start:
        mov di, offset arg1+2                           ; di - wskaźnik na początek arg1

    arg1loop:
        mov al, byte ptr ds:[si]                        ; al - aktualny znak
        cmp al, ' '
        je arg1loop_done                                ; jeśli spacja to koniec
        mov byte ptr ds:[di], al                        ; zapisanie znaku do bufora
        inc si                                          ; inkrementacja na następny znak
        inc di                                          ; inkrementacja na następny znak
        jmp arg1loop

    arg1loop_done:
        mov byte ptr ds:[di], '$'                       ; zakończenie bufora znakiem '$'

    ; pomijanie spacji
    spcloop1:
        mov al, byte ptr ds:[si]                        ; al - aktualny znak
        cmp al, ' '
        jne operator                                    ; jeśli nie ma spacji to znaczy że operator
        inc si                                          ; inkrementacja na następny znak
        jmp spcloop1

    operator:
        mov di, offset op+2                             ; di - wskaźnik na początek op

    oploop:
        mov al, byte ptr ds:[si]                        ; al - aktualny znak
        cmp al, ' '
        je oploop_done                                  ; jeśli spacja to koniec
        mov byte ptr ds:[di], al                        ; zapisanie znaku do bufora
        inc si                                          ; inkrementacja na następny znak
        inc di                                          ; inkrementacja na następny znak
        jmp oploop

    oploop_done:
        mov byte ptr ds:[di], '$'                       ; zakończenie bufora znakiem '$'
    
    spcloop2:
        mov al, byte ptr ds:[si]                        ; al - aktualny znak
        cmp al, ' '
        jne arg2start                                   ; jeśli nie ma spacji to parsuj arg2
        inc si                                          ; inkrementacja na następny znak
        jmp spcloop2

    arg2start:
        mov di, offset arg2+2                           ; di - wskaźnik na początek arg2

    arg2loop:
        mov al, byte ptr ds:[si]                        ; al - aktualny znak
        cmp al, ' '                                     ; jeśli spacja to koniec
        je arg2loop_done 
        cmp al , 13                                     ; jeśli znak nowej linii to koniec
        je arg2loop_done                                
        mov byte ptr ds:[di], al                        ; zapisanie znaku do bufora (arg2)
        inc si                                          ; inkrementacja na następny znak
        inc di                                          ; inkrementacja na następny znak
        jmp arg2loop

    arg2loop_done:
        mov byte ptr ds:[di], '$'                       ; zakończenie bufora

    ret

;-------------------------------------------------------------------------------;
; konwertuje argument na liczbę                                                 ;
; dx - offset na argument                                                       ;
;-------------------------------------------------------------------------------;

arg_to_int:
    mov si, offset digits                               ; si - wskaźnik na początek ciągu znaków do porównania
    xor ch, ch                                          ; ch - aktualnie rozpatrywana liczba = 0

    fit:
        mov di, dx                                      ; di - wskaźnik na początek ciągu znaków do porównania

        number_loop:
            mov al, byte ptr ds:[si]                    ; al - aktualny znak z si
            mov bl, byte ptr ds:[di]                    ; bl - aktualny znak z arg1

            cmp ch, 10 
            je exception                                ; jeśli aktualnie rozptrywana liczba jest równa 10 to błąd

            cmp bl, '$'                                 ; jeśli koniec ciągu znaków to koniec porównywania
            je fit_done

            inc si                                      ; inkrementacja na następny znak
            cmp al, bl                                  ; jeśli znaki są różne to koniec
            jne next_num

            inc di                                      ; inkrementacja na następny znak
            jmp number_loop

    next_num:
        inc ch                                          ; inkrementacja aktualnie rozpatrywanej liczby

        next_loop:
            mov al, byte ptr ds:[si]                    ; al - aktualny znak z si
            cmp al, ' '
            je next_loop_done                           ; jeśli spacja to koniec
            inc si                                      ; inkrementacja na następny znak
            jmp next_loop

        next_loop_done:
            inc si                                      ; inkrementacja na następny znak po spacji
            jmp fit

    fit_done:
        cmp al, ' '
        jne exception                                   ; jeśli arg sie skonczyl ale drugi wyraz nie to błąd

        mov al, ch                                      ; zapisanie znalezionej liczby do al
        ret

;===============================================================================;
;                            WYKONYWANIE DZIAŁANIA                              ;
;===============================================================================;

;-------------------------------------------------------------------------------;
; wykonuje działanie i zapisuje wynik do result_int                             ;
; arg1_int - argument 1 jako liczba                                             ;
; arg2_int - argument 2 jako liczba                                             ;
; op - operator                                                                 ;
;-------------------------------------------------------------------------------;

operation:
    mov di, offset op+2                                 ; di - wskaźnik na początek ciągu znaków

    mov si, offset plus                                 ; si - wskaźnik na początek ciągu znaków
    call cmp_str                                        ; sprawdz czy operator to plus
    cmp al, 1 
    je plus_found                                       ; jeśli tak to wykonaj dodawanie

    mov si, offset minus                                ; si - wskaźnik na początek ciągu znaków
    call cmp_str                                        ; sprawdz czy operator to minus
    cmp al, 1 
    je minus_found                                      ; jeśli tak to wykonaj odejmowanie

    mov si, offset mlt                                  ; si - wskaźnik na początek ciągu znaków
    call cmp_str                                        ; sprawdz czy operator to mnożenie
    cmp al, 1
    je mlt_found                                        ; jeśli tak to wykonaj mnożenie

    jmp exception                                       ; w pozostałych przypadkach błąd

    plus_found:
        mov al, byte ptr ds:[arg1_int]                  ; al - argument 1
        add al, byte ptr ds:[arg2_int]                  ; doawanie do al arg2
        mov byte ptr ds:[result_int], al                ; zapisanie wyniku do result_int
        ret

    minus_found:
        mov al, byte ptr ds:[arg1_int]                  ; al - argument 1
        sub al, byte ptr ds:[arg2_int]                  ; odejmowanie od al arg2
        mov byte ptr ds:[result_int], al                ; zapisanie wyniku do result_int
        ret

    mlt_found:
        xor ax, ax                                      ; zerowanie ax !!!!!!!!!
        mov al, byte ptr ds:[arg1_int]                  ; al - argument 1
        mul byte ptr ds:[arg2_int]                      ; mnożenie al przez arg2
        mov byte ptr ds:[result_int], al                ; zapisanie wyniku do result_int
        ret

;===============================================================================;
;                               PARSOWANIE WYNIKU                               ;
;===============================================================================;

;-------------------------------------------------------------------------------;
; parsuje liczbę i wypisuje jej słowny opis                                     ;
; result_int - liczba do sparsowania                                            ;
;-------------------------------------------------------------------------------;

parse_int:
    xor ah, ah                                          ; zerowanie ah (do dzielenia)
    mov al, byte ptr ds:[result_int]                    ; al - liczba do sparsowania

    cmp al, 0
    jl minus_sign                                       ; jeśli liczba jest ujemna to wypisz minus

    cmp al, 10
    jl parse_units                                      ; jeśli liczba jest mniejsza od 10 to wypisz jednosci
    
    cmp al, 20
    jl parse_teens                                      ; jeśli liczba jest mniejsza od 20 to wypisz teens
    
    ; \jeśli liczba jest większa od 20 to wypisz dziesiatki i jednosci\
    parse_tens:
        mov si, offset units_val+2                      ; si - wskaźnik na tablicę jedności (od liczby 2)
        mov di, offset tens                             ; di - wskaźnik na początek ciągu znaków

        mov bl, 10                                      ; dzielimy al przez 10
        div bl                                          ; al - dziesiatki, ah - jednosci
        mov bh , ah                                     ; zapisanie do bh jednosci, puts psuje ax
        
        tens_loop:
            cmp al, byte ptr ds:[si]                    ; jeśli al jest równy wartości z tablicy jedności to koniec
            je tens_loop_done
            call next_offset                            ; przejdź do następnej liczby
            inc si                                      ; inkrementacja na następny znak
            jmp tens_loop

        tens_loop_done:
            mov dx, di                                  ; dx - offset na ciąg znaków do wypisania
            call puts                                   ; wypisanie ciągu znaków
            mov al, bh                                  ; al - cyfra jedności wyniku
            cmp al, 0

            je dont_add_unit                            ; jeśli jednosci są równe 0 to koniec
            jmp parse_units                             ; w przeciwnym przypadku wypisz jednosci
            dont_add_unit:
                ret

    parse_teens:
        mov si, offset teens_val                        ; si - wskaźnik na tablicę teens_val
        mov di, offset teens                            ; di - wskaźnik na początek ciągu znaków

        teens_loop:
            cmp al, byte ptr ds:[si]                    ; jeśli al jest równy wartości z tablicy teens_val to koniec
            je teens_loop_done
            call next_offset                            ; przejdź do następnej liczby
            inc si                                      ; inkrementacja na następny znak
            jmp teens_loop

        teens_loop_done:
            mov dx, di                                  ; dx - offset na ciąg znaków do wypisania
            call puts                                   ; wypisanie ciągu znaków
            ret

    minus_sign:
        mov dx, offset minus_print                      ; dx - offset na ciąg znaków do wypisania
        call puts                                       ; wypisanie ciągu znaków
        mov al, byte ptr ds:[result_int]                ; al - liczba do sparsowania
        neg al                                          ; usunięcie minusa przed parsowaniem

    parse_units:
        mov si, offset units_val                        ; si - wskaźnik na tablicę units_val
        mov di, offset units                            ; di - wskaźnik na początek ciągu znaków

        units_loop:
            cmp al, byte ptr ds:[si]                    ; jeśli al jest równy wartości z tablicy units_val to koniec
            je units_loop_done
            call next_offset                            ; przejdź do następnej liczby
            inc si                                      ; inkrementacja na następny znak
            jmp units_loop

        units_loop_done:
            mov dx, di                                  ; dx - offset na ciąg znaków do wypisania
            call puts                                   ; wypisanie ciągu znaków
            ret

;-------------------------------------------------------------------------------;
; ustawia di na następny znak po '$'                                            ;
;-------------------------------------------------------------------------------;

next_offset:
    mov bl, byte ptr ds:[di]                            ; bl - aktualny znak
    cmp bl, '$'                                         ; jeśli znaleziono '$' to koniec
    je next_offset_end

    inc di                                              ; w przeciwnym wypadku przejdz do następnego znaku
    jmp next_offset
    next_offset_end:
        inc di                                          ; inkrementacja na następny znak po '$'
        ret

;===============================================================================;
;                                    KONIEC                                     ;
;===============================================================================;
code1 ends

;-------------------------------------------------------------------------------;

stos1 segment stack
    dw 300 dup (?)                                      ; 600 bajtów
    wstos1 dw ?                                         ; wierzchołek stosu
stos1 ends

;-------------------------------------------------------------------------------;

end start1
