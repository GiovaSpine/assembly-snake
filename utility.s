
# ci servono:
# - outline
# - outmess
# - outdecimal_word
# - newline
# - indecimal_byte
# - outchar
# - inchar

# funzioni ncurses
.EXTERN endwin
.EXTERN addch
.EXTERN refresh
.EXTERN getch


.TEXT

# =============================================================================

.GLOBL inchar
inchar:
    PUSH %ECX  # perché è un registro scratch
    PUSH %EDX  # perché è un registro scratch
    CALL getch
    # il risultato è in AL
    POP %EDX
    POP %ECX
    RET

# =============================================================================

.GLOBL outchar
outchar:
    PUSH %EAX  # perché va esteso, e magari in AH c'erano altre informazioni
    PUSH %ECX  # perché è un registro scratch
    PUSH %EDX  # perché è un registro scratch

    # si aspetta il carattere in AL
    MOVZBL %AL, %EAX  # estensione di campo
    PUSH %EAX
    CALL addch
    ADD $4, %ESP  # ripristino stack

    # CALL refresh  # in genere dopo aver messo qualcosa sul terminale si fa refresh

    POP %EDX
    POP %ECX
    POP %EAX
    RET

# =============================================================================

.GLOBL outmess
outmess:
        PUSH   %EAX
	    PUSH   %EBX
	    PUSH   %ECX
L087509:
        CMP    $0,%CX
	    JE     L087508
	    MOV    (%EBX),%AL
	    CALL   outchar
	    INC    %EBX
	    DEC    %CX
	    JMP    L087509
L087508:
        POP    %ECX
	    POP    %EBX
	    POP    %EAX
	    RET

# =============================================================================

.GLOBL outline
outline:
        # si aspetta il buffer in EBX
        # stampa massimo 80 caratteri
        # si ferma prima se trova INVIO (\n), stampando anche i caratteri per andare a capo
        PUSH %EAX
        PUSH %EBX
        PUSH %ECX
        MOV $80,%CX
L4001B: MOV  (%EBX),%AL
        CMP  $'\n',%AL
        JZ   L4002A
        DEC %CX
        JZ   L4002A
        CALL outchar
        INC  %EBX
        JMP  L4001B
L4002A: CALL newline
		POP  %ECX
        POP  %EBX
        POP  %EAX
        RET

# =============================================================================

.GLOBL newline
newline:
    PUSH %EAX
    MOV $'\n', %AL
    CALL outchar

    MOV $'\r', %AL
    CALL outchar

    POP %EAX
    RET


# =============================================================================

.GLOBL outdecimal_word
.TEXT
outdecimal_word:
outdecimal_short:   PUSH %EAX  
                    AND  $0x0000FFFF,%EAX 
                    CALL outdecimal_long 
                    POP  %EAX 
                    RET

.DATA
resti_cifre:      .fill 11,1

.TEXT
outdecimal_long:    PUSH  %EAX
	                PUSH  %EBX
                    PUSH  %ECX
                    PUSH  %EDX
                    PUSH  %ESI
                    PUSH  %EDI
	                PUSH  %EBP
    
                    MOV   $10,%ECX
                    CMP   $999999999,%EAX
                    JA    long_L4013K
                    DEC   %ECX
                    CMP   $99999999,%EAX
                    JA    long_L4013K
                    DEC   %ECX
                    CMP   $9999999,%EAX
                    JA    long_L4013K
                    DEC   %ECX
                    CMP   $999999,%EAX
                    JA    long_L4013K
                    DEC   %ECX
                    CMP   $99999,%EAX
                    JA    long_L4013K
                    DEC   %ECX
                    CMP   $9999,%EAX
                    JA    long_L4013K
                    DEC   %ECX
                    CMP   $999,%EAX
                    JA    long_L4013K
                    DEC   %ECX
                    CMP   $99,%EAX
                    JA    long_L4013K
                    DEC   %ECX
                    CMP   $9,%EAX
                    JA    long_L4013K
                    DEC   %ECX
    
long_L4013K:        LEA   resti_cifre,%EDI
                    MOV   %ECX, %EBP
                    ADD   %ECX,%EDI      # EDI punta sotto alla cifra da inserire per prima
                    DEC   %EDI           # EDI torna a puntare alla prima cifra da inserire
ciclolongL4013K:    MOV   $0,%EDX        # costruzione del dividendo EDX:EAX
                    MOV   $10,%ESI       # divisore in ESI
                    DIVL  %ESI   
                    AND   $0x0000000F,%EDX # sistemazione del resto_cifra codificato ASCII
                    ADD   $0x30,%DL
                    MOV   %DL,(%EDI) 
    
                    DEC   %EDI   
                    DEC   %ECX
                    CMP   $0,%ECX        # Controllo fine ciclo
                    JNE   ciclolongL4013K
    
                    LEA   resti_cifre,%EBX
				    MOV   %EBP, %ECX
                    CALL  outmess  
    
				    POP   %EBP
				    POP   %EDI
                    POP   %ESI
                    POP   %EDX
                    POP   %ECX
				    POP   %EBX
                    POP   %EAX
                    RET

# =============================================================================

.GLOBL indecimal_byte
indecimal_byte:
    # ritorna in AL un numero
indecimal_tiny:
    MOVB  $3,num_cifre_1eWK7
    PUSH %EBX
    PUSH %EAX
    CALL converti_1eWK6
    MOV  %AL,%BL
    POP  %EAX
    MOV  %BL,%AL
    POP  %EBX
    RET


.DATA
prodotti_parziali_1eWK7:   .fill 1,4
num_cifre_1eWK7:           .fill 1,1

.TEXT
converti_1eWK6:     NOP
	                PUSH %EDX
P_di_0_1eWK7:       MOVL  $0, prodotti_parziali_1eWK7
                 
ciclo_1eWK7:        CMPB  $0x00,num_cifre_1eWK7     # termina se cifre finite
                    JE    fine_1eWK7
new_cifra_1eWK7:    CALL  inchar                    # prelievo eventuale nuova cifra
                    CMP   $'\n',%AL                 # termina se ritorno carrello
                    JE    fine_1eWK7 
                
                    CMP   $'0',%AL                  # scarta cifre non decimali
                    JB    new_cifra_1eWK7
                    CMP   $'9',%AL
                    JA    new_cifra_1eWK7
                    CALL  outchar
                    PUSH  %EAX                      # nuovo prodotto parziale
                    MOV   $10,%EAX
                    MULL  prodotti_parziali_1eWK7    
                    MOV   %EAX,prodotti_parziali_1eWK7
                    POP   %EAX          
                    AND   $0x0000000F,%EAX
                    ADDL  %EAX, prodotti_parziali_1eWK7
                    DECB  num_cifre_1eWK7                  
                    JNE   ciclo_1eWK7                        
                  
fine_1eWK7:         MOV   prodotti_parziali_1eWK7,%EAX 
                    POP %EDX
                    RET

