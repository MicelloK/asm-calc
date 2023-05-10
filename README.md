# Asm calculator

## Opis:

Proszę napisać program będący słownym kalkulatorem realizującym trzy podstawowe działania: dodawanie, odejmowanie i mnożenie.
Kalkulator powinien wykonywać słownie zapisane działanie (plus, minus, razy) na dwóch słownie zapisanych cyfrach (od zero do dziewięć).
Po uruchomieniu programu na ekranie w trybie tekstowym powinien pojawić się komunikat: "Wprowadź słowny opis działania" i po jego wprowadzeniu, w nowej linii powinien pojawić się słowny wynik.

Przykłady wywołania Programu:

Wprowadź słowny opis działania: trzy razy pięć
Wynikiem jest: piętnaście

Wprowadź słowny opis działania: osiem minus zero
Wynikiem jest: osiem

Wprowadź słowny opis działania: czy plus dwa
Błąd danych wejściowych!

 
# Zawartość

* calc.asm - kod źródłowy programu
* DOSXNT.386, DOSXNT.EXE, LINK.EXE, ML.ERR, ML.EXE - pliki kompilatora

# Kompilowanie

Aby skompilować program należy wykonać w programie w programie DosBox w katalogu z programem i kompilatorem polecenie:

```
ml calc.asm
```

Aby uruchomić program należy w tym samym katalogu wykonać polecenie:
```
calc.exe
```

