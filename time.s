

.EXTERN gettimeofday
.EXTERN time
.EXTERN localtime

.DATA
now:    .long 0  # conterrà i secondi dall'epoch
tv:
        .long 0  # tv_sec
        .long 0  # tv_usec (u per micro)


.TEXT
.GLOBL ricava_tempo_dos
ricava_tempo_dos:
    PUSH %EAX
    PUSH %ESI

    # ritorniamo, seguendo la convenzione DOS,
    # CH: le ore
    # CL: i minuti
    # DH: i secondi
    # DL: i centisecondi

    # chiamata time(&now)
    PUSHL $now
    CALL time
    ADD $4, %ESP  # ripristino stack

    # chiamata localtime(&now)
    PUSHL $now
    CALL localtime
    ADD $4, %ESP  # ripristino stack

    # il risultato è un puntatore a struct tm in %eax
    MOV %EAX, %ESI

    # push degli argomenti (tz = NULL, tv = &tv)
    PUSHL $0
    PUSHL $tv
    CALL gettimeofday
    ADD $8, %ESP  # ripristino stack

    # ora tv contiene i valori
    # ci interessano i microsecondi per ottenere i centisecondi
    MOV tv+4, %EAX
    MOV $0, %EDX
    MOV $10000, %ECX
    DIV %ECX  # EAX = microsecondi / 10000, che sta in 8 bit

    # sarebbero degli int, che però stanno in un byte
    MOV 0(%ESI), %DH  # secondi
    MOV 4(%ESI), %CL  # minuti
    MOV 8(%ESI), %CH  # ore
    MOV %AL, %DL  # centisecondi
    
    POP %ESI
    POP %EAX
    RET


.TEXT
.GLOBL ricava_tempo
ricava_tempo:
    PUSH %ESI

    # ritorniamo, seguendo la convenzione DOS
    # in EAX i secondi dalla Epoch
    # in EDX i microsecondi del secondo

    # push degli argomenti (tz = NULL, tv = &tv)
    PUSHL $0
    PUSHL $tv
    CALL gettimeofday
    ADD $8, %ESP  # ripristino stack

    MOV tv, %EDX
    MOV tv+4, %EAX

    
    POP %ESI
    RET
