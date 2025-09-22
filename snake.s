
# funzioni ncurses
.EXTERN initscr
.EXTERN noecho
.EXTERN refresh
.EXTERN clear
.EXTERN flushinp
.EXTERN nodelay
.EXTERN stdscr

.GLOBAL main

.DATA
tempo:			.LONG 500000  # tempo tra un movimento all'altro (espresso in microsecondi)
# per poter far si' che il movimento sia alla stessa velocita' per ogni dispositivo
# campioniamo il tempo iniziale e controlleremo quanto tempo e' passato da questo tempo iniziale
sec_iniziali:  	.LONG 0  # secondi dall'Epoch campionati all'inizio
usec_iniziali: 	.LONG 0  # microsecondi del secondo campionato all'inizio
usec_totali:	.LONG 0  # sec_iniziali * 10^6 + usec_totali
sec_ora:		.LONG 0  # secondi dall'Epoch campionati ora
usec_ora:		.LONG 0  # microsecondi del secondo campionato ora

# il seed per la generazione casuale dei frutti
seed:           .LONG 0

mappa:			.FILL 361, 1, ' '  # (17+2) x (17+2),  +2 e' per il bordo

				.SET spazio, ' '
				.SET personaggio, '0'
				.SET frutto, '1'

# l'origine (0, 0) e' in alto a sinistra
pos_x:			.BYTE 1
pos_y:			.BYTE 9  # posizione iniziale (ricorda che c'e' anche il bordo)

# l'idea e' quella di avere pos_x e pos_y che sono la testa, e scrivono una scia di '0' (personaggio)
# mentra la coda cancella tale scia, scrivendo ' ' (spazio)
# la coda deve eseguire il movimento attuale n volte in ritardo (dove n a regola e' la lunghezza dello snake)
pos_x_coda:		.BYTE 1
pos_y_coda:		.BYTE 9

# stack per ricordare i movimenti che dovra' fare la coda
# 300 spazi per inserire movimenti perche' nel caso peggiore si ha lo snake lungo quasi quanto tutta la mappa
# la coda dovra' ricordarsi "quasi quanto tutta la mappa" movimenti (17 * 17 = 289, e facciamo 300 per essere sicuri)
my_stack:		.FILL 300, 1, '0'  # dove verrano segnati i movimenti che la coda deve seguire
				.SET my_stack_dim, 300
ind_testa:		.WORD 0  # indice testa
ind_coda:		.WORD 0  # indice coda

# lo snake all'inizio e' lungo 3

# la posizione del frutto e' casuale, ma puo' variare solo tra (1,1) a (16, 16) (non arriva quindi a (17, 17))
# si ha un frutto iniziale in (7, 9)
pos_x_frutto:	.BYTE 7
pos_y_frutto:	.BYTE 9
punteggio:		.WORD 0

messaggio1:		.ASCII "- ASSEMBLY SNAKE\n"
messaggio1_2:   .ASCII "- Use wasd to move the snake and try to collect as many fruits as possible!!!!!!"
messaggio1_3:   .ASCII "- Press q, in game, to quit the game.\n"
messaggio2:		.ASCII "- Enter the time between snake's movements (in centiseconds): "
messaggio3:		.ASCII "- Score: "
messaggio4:		.ASCII "- You won!!!!\n- Score: "
messaggio5:		.ASCII "- Press q to exit.\n"



.TEXT
main:	NOP

		CALL initscr  # inizializza ncurses
    	CALL noecho  # la inchar non deve fare echo a video

		CALL crea_mappa

		# impostiamo il seed
		CALL ricava_tempo_dos  # ritorna CH ore,  CL, minuti, DH secondi, DL centisecondi
		# usiamo l'orario come seed
		MOV $0, %EAX
		MOV %CH, %AL
		SHL $8, %EAX
		MOV %CL, %AL
		SHL $8, %EAX
		MOV %DH, %AL
		SHL $8, %EAX
		MOV %DL, %AL

		MOV %EAX, seed

		# disegniamo lo snake
		MOV $personaggio, %DL
		CALL disegna_posizione_attuale
		INCB pos_x
		CALL disegna_posizione_attuale
		INCB pos_x
		CALL disegna_posizione_attuale

		
		MOV $'d', %BL  # all'inizio va a destra
		# LA CODA EFFETTUERA' 3 movimenti a destra a prescindere
		CALL push_mystack
		CALL push_mystack
		

		CALL disegna_frutto

		# STAMPIAMO LE INFORMAZIONI INIZIALI PER PARTIRE
		PUSH %EBX
		CALL stampa_mappa
		LEA messaggio1, %EBX
		CALL outline
		MOV $80, %ECX
		LEA messaggio1_2, %EBX
		CALL outmess
		CALL newline
		LEA messaggio1_3, %EBX
		CALL outline
		MOV $62, %ECX  # "- Enter the time between snake's movements (in centiseconds): " ha 62 caratteri
		LEA messaggio2, %EBX
		CALL outmess
		CALL inserimento_tempo
		POP %EBX

		MOV $0, %ECX  # per sanificarlo (serve per determinare se ha mangiato un frutto o no)


		MOV $1, %EAX  # e' per determinare se continuare il gioco oppure no
		
		# ============================
		# LOOP PRINCIPALE PER IL GIOCO
loop_main:
		CALL stampa_mappa

		MOV %BL, %DL  # valore vecchio
		CALL inchar_delay  # il risultato e' la modifica di BL

		# BL puo' essere q (l'utente voleva uscire)
		CMP $'q', %BL
		JE fine_main

		CALL movimento  # si aspetta in BL un carattere che sia w, a, s oppure d, e DL che e' la direzione vecchia
		# ritorna un valore che puo' far finire il programma, ovvero AL
		# ritorna anche ECX che contiene 1 se ha appena mangiato un frutto, altrimenti 0

		CMP $0, %EAX
		JE fine_main

		# CALL push_mystack  NO! viene fatta a seguito di un movimento certo

		# dopo movimento, puo' aver mangiato un frutto
		# cio' deve causare il fatto che la coda rimanga ferma
		CALL movimento_coda  # ha in ingresso ECX, e la pila di movimenti
		
		JMP loop_main
		
fine_main:

		# il punteggio massimo e' ((17 * 17) - 3)
		# se l'utente ha fatto quel punteggio, vuol dire che ha vinto

		CMPW $286, punteggio
		JAE gioco_vinto

		# altrimenti
		MOV $9, %ECX  # "- Score: " e' 9 caratteri
		LEA messaggio3, %EBX
		CALL outmess

		JMP stampa_punteggio

gioco_vinto:
		MOV $23, %ECX
		LEA messaggio4, %EBX
		CALL outmess

stampa_punteggio:
		MOV punteggio, %AX
		CALL outdecimal_word
		CALL newline

		# stampa messaggio per uscire
		LEA messaggio5, %EBX
		CALL outline

carattere_uscita:
		CALL inchar
		CMP $'q', %AL
		JNE carattere_uscita

		CALL endwin  # per chiudere ncurses
		MOV $0, %EAX  # return 0
		RET

# =============================================================================

inserimento_tempo:
	PUSH %EAX
	PUSH %ECX

	MOV $0, %EAX

	CALL indecimal_byte

	CMP $150, %AL
	JBE tempo_valido

	# altrimenti il tempo è troppo lento
	MOV $150, %AL

tempo_valido:
	# va moltiplicato per 10^4 per convertirlo in microsecondi
	MOV $10000, %ECX
	MULL %ECX  # EDX|EAX = EAX * 10000

	MOV %EAX, tempo

	JMP fine_inserimento_tempo

fine_inserimento_tempo:

	POP %ECX
	POP %EAX
	RET

# =============================================================================

crea_mappa:
		NOP
		PUSH %ESI
		PUSH %ECX
		PUSH %EBX

		# la dimensione e' di 19 x 19, considerando anche il bordo

		MOV $0, %ESI  # funziona come indice per il vettore

		MOV $0, %EBX

loop_creazione:
		CMP $18, %EBX  # <---
		JA fine_creazione  # > 18

		# se EBX e' 0 allora la prima riga e' #################
		# se EBX e' 18, allora l'ultima riga e' #################
		# se EBX non e' nessuno dei due allora la riga e' #-----------------#

		CMP $0, %EBX
		JE crea_riga_intera

		CMP $18, %EBX  # <---
		JE crea_riga_intera

		# altrimenti non e' ne' 0 ne' 18
		# creo una riga parziale
		MOVB $'#', mappa(%ESI)
		ADD $18, %ESI  # 19 - 1 <---
		MOVB $'#', mappa(%ESI)
		INC %ESI

		JMP fine_loop_creazione


crea_riga_intera:
		MOV $19, %ECX  # <---

loop_crea_riga_intera:
		MOVB $'#', mappa(%ESI)
		INC %ESI
		LOOP loop_crea_riga_intera
		

fine_loop_creazione:
		NOP
		INC %EBX

		JMP loop_creazione


fine_creazione:

		POP %EBX
		POP %ECX
		POP %ESI
		RET

		
# =============================================================================

stampa_mappa:
		NOP
		PUSH %ESI
		PUSH %ECX
		PUSH %EDX
		PUSH %EAX

		CALL clear  # cancelliamo ciò che c'era prima
		
		MOV $0, %ESI  # funziona come indice del vettore

		MOV $0, %EDX  # serve per il loop principale

loop_stampa_mappa:
		CMP $18, %EDX
		JA fine_stampa_mappa

		MOV $19, %ECX
loop_stampa_riga:
		
		MOV mappa(%ESI), %AL
		CALL outchar
		MOV $' ', %AL
		CALL outchar
		
		INC %ESI

		LOOP loop_stampa_riga
		
		CALL newline

		INC %EDX
		JMP loop_stampa_mappa

fine_stampa_mappa:

		CALL refresh

		POP %EAX
		POP %EDX
		POP %ECX
		POP %ESI
		RET


# =============================================================================


# e' una lettura da tastiera, senza eco a video, per un intervallo di tempo
# quindi non blocca l'esecuzione del programma, aspettando che l'utente inserisca il carattere
# l'utente puo' inserire solo 'wasd' e 'q' che scrive in BL
# se il carattere inserito non e' valido, allora non scrive BL
# se non viene scritto nessun carattere, allora non scrive BL

# l'utente puo' inserire piu' caratteri mentre scorre l'intervallo di tempo
# verra' considerato solo il primo che sia valido (wasd)
# pertanto nella durata di tempo rimanente gli altri caratteri inseriti non saranno considerati

inchar_delay:
		NOP
		PUSH %EDX
		PUSH %ECX
		PUSH %EAX

		/*
		# PER SICUREZZA SVUOTIAMOLO ANCHE ALL'INIZIO 
		MOV $0x0C, %AH  # "Pulisce il buffer di input e legge dal dispositivo di input", pero' non vogliamo leggere
		MOV $0x00, %AL  # basta che non sia 01h,06h,07h,08h, oppure 0Ah (perche' altrimenti avrebbe chiesto un carattere come input)
		INT $0x21
		*/ # PROVVISORIO

		CALL flushinp  # cancella l’input buffer di ncurses/terminale


		# campioniamo il tempo iniziale
		CALL ricava_tempo  # ritorna EDX secondi da Epoch, EAX microsecondi
		MOV %EDX, sec_iniziali
		MOV %EAX, usec_iniziali
		# ricaviamo i usec_totali
		MOV sec_iniziali, %EAX
		MOV $1000000, %ECX
		MUL %ECX # EDX|EAX = 1000000 * sec_iniziali
		MOV usec_iniziali, %EDX
		ADD %EDX, %EAX  # EAX = EAX + usec_iniziali
		MOV %EAX, usec_totali


		# nodelay(stdscr, TRUE) per avere una lettura non bloccante
		MOV $1, %EAX  # TRUE
		PUSH %EAX
		MOV stdscr, %EAX  # stdscr è una variabile globale
		PUSH %EAX
		CALL nodelay
		ADD $8, %ESP  # ripristino stack
		

		MOV $0, %EDX  # servira' per ignorare i caratteri inseriti dopo, rispetto al primo inserito valido (wasd)

loop_inchar_delay:
		NOP

		# a questo punto getch è non bloccante
		CALL getch  # ritorna carattere o ERR, che è -1
		CMP $-1, %EAX
		JE fine_loop_inchar_delay  # nessun carattere

		# altrimenti c'è il carattere
		JMP controllo_carattere

controllo_carattere:

		# ATTENZIONE! SE e' gia' stato letto un carattere valido (wasd)
		# ALLORA non leggiamo piu' nulla, ormai il risultato e' quello
		CMP $1, %EDX
		JE carattere_non_valido  # APPUNTO NON SI MODIFICA BL

		# -------------------------
		# controlliamo che sia tra 'wasd' o 'q'

		# setto il terzo bit a prescindere (converto a minuscolo)
        OR $0b00100000, %AL

        CMP $'w', %AL
        JNE controllo_a
        # altrimenti OK, AL = 'w'
        JMP carattere

controllo_a:
        CMP $'a', %AL
        JNE controllo_s
        # altrimenti OK, AL = 'a'
        JMP carattere

controllo_s:
        CMP $'s', %AL
        JNE controllo_d
        # altrimenti OK, AL = 's'
        JMP carattere

controllo_d:
        CMP $'d', %AL
        JNE controllo_q
        # altrimenti OK, AL = 'd'
		JMP carattere

controllo_q:
        CMP $'q', %AL
        JNE carattere_non_valido  # perche' non e' nessuno tra 'wasd' o 'q'
        # altrimenti OK, AL = 'q'
		JMP carattere

carattere:
		MOV %AL, %BL  # <----- SI MODIFICA BL, che e' il ritorno
		MOV $1, %EDX  # SERVE per sapere se si e' gia' letto il primo carattere valido (wasd)
		
		# -------------------------------

carattere_non_valido:
		
		# infine, poiche' il buffer sembra adottare una politica FIFO
		# credo che dovremmo sempre svuotarlo

		/*
		MOV $0x0C, %AH  # "Pulisce il buffer di input e legge dal dispositivo di input", pero' non vogliamo leggere
		MOV $0x00, %AL  # basta che non sia 01h,06h,07h,08h, oppure 0Ah
		INT $0x21
		*/  # PROVVISORIO

		# CALL flushinp  # cancella l’input buffer di ncurses/terminale

		# Note
		# Se AL non contiene uno dei seguenti valori 01h,06h,07h,08h, oppure 0Ah, il buffer viene pulito ma non viene chiamata alcuna funzione di input


fine_loop_inchar_delay:
		NOP

		# cotrolliamo il tempo che e' passato
		CALL ricava_tempo  # ritorna EDX secondi da Epoch, EAX microsecondi
		MOV %EDX, sec_ora
		MOV %EAX, usec_ora

		CMP sec_iniziali, %EDX
		JB caso_secondi_iniziali_maggiore

		JMP caso_secondi_iniziali_minore

caso_secondi_iniziali_maggiore:
		# caso assurdo
		# un giocatore dovrebbe giocare quando non si ha piu' spazio per il long (nel 2038)
		# 10^7 - usec_iniziali + usec campionati ora è maggiore di tempo ?
		# bo non mi va molto di farlo
		JMP fine_loop_inchar_delay

caso_secondi_iniziali_minore:
		# altrimenti siamo nel caso regolare in cui i secondi campionati ora sono maggiori o uguali ai sec_iniziali

		MOV sec_ora, %EAX
		MOV $1000000, %ECX
		MUL %ECX  # EDX|EAX = 1000000 * sec campionati ora
		ADD usec_ora, %EAX  # EAX = usec totali campionati ora
		
		SUB usec_totali, %EAX  # EAX = usec totali campionati ora - usec_totali (iniziali)
		CMP tempo, %EAX
		JB loop_inchar_delay

		# altrimenti e' passato il tempo
		JMP fine_inchar_delay
		

fine_inchar_delay:

		# nodelay(stdscr, FALSE) per avere una lettura bloccante
		MOV $0, %EAX  # FALSE
		PUSH %EAX
		MOV stdscr, %EAX  # stdscr è una variabile globale
		PUSH %EAX
		CALL nodelay
		ADD $8, %ESP  # ripristino stack

		POP %EAX
		POP %ECX
		POP %EDX
		RET


# =============================================================================

movimento:
		NOP
		# PUSH ???

		# il movimento di snake pero' non e' cosi' semplice
		# perche' sa va verso destra, non puo' andare a sinistra
		# per andare a sinistra deve andare su (o sotto) e poi a sinistra (o destra)

		# si aspetta in ingresso BL che contiene w, a, s oppure d
		# i seguenti 'movimenti' modificheranno EAX, che appunto sara' ritornato da questo sottoprogramma

		# si ha DL che e' il movimento vecchio (anch'esso e' w, a, s oppure d)


		CMP $'w', %BL
        JNE controllo_a_mov
		# altrimenti OK, BL = 'w'
		# se il movimento vecchio era 's', allora non si fa movimento sopra
		CMP $'s', %DL
		JE movimento_vecchio_sotto
        CALL movimento_sopra
        JMP fine_movimento

controllo_a_mov:
        CMP $'a', %BL
        JNE controllo_s_mov
        # altrimenti OK, BL = 'a'
		# se il movimento vecchio era 'd', allora non si fa movimento sinistra
		CMP $'d', %DL
		JE movimento_vecchio_destra
		CALL movimento_sinistra
        JMP fine_movimento

controllo_s_mov:
        CMP $'s', %BL
        JNE controllo_d_mov
        # altrimenti OK, BL = 's'
		# se il movimento vecchio era 'w', allora non si fa movimento sotto
		CMP $'w', %DL
		JE movimento_vecchio_sopra
		CALL movimento_sotto
        JMP fine_movimento

controllo_d_mov:
        CMP $'d', %BL
        JNE ASSURDO  # NON PUO' ACCADERE CHE BL non contenga w, a, s oppure d
        # altrimenti OK, BL = 'd'
		# se il movimento vecchio era 'a', allora non si fa movimento destra
		CMP $'a', %DL
		JE movimento_vecchio_sinistra
		CALL movimento_destra
		JMP fine_movimento

ASSURDO:
		NOP
		MOV $0, %EAX  # SE accade un assurdo, interrompiamo il programma, ma non deve accadere



movimento_vecchio_sotto:
		# senno' poi dopo continua ad andare verso BL
		MOV %DL, %BL
		CALL movimento_sotto
		JMP fine_movimento

movimento_vecchio_destra:
		# senno' poi dopo continua ad andare verso BL
		MOV %DL, %BL
		CALL movimento_destra
		JMP fine_movimento

movimento_vecchio_sopra:
		# senno' poi dopo continua ad andare verso BL
		MOV %DL, %BL
		CALL movimento_sopra
		JMP fine_movimento

movimento_vecchio_sinistra:
		# senno' poi dopo continua ad andare verso BL
		MOV %DL, %BL
		CALL movimento_sinistra
		JMP fine_movimento


fine_movimento:

		# POP ???
		RET

# -------------------------------------------------------------------

disegna_posizione_attuale:
		NOP
		PUSH %EAX
		PUSH %ECX

		MOV $0, %EAX

		# nel vettore la posizione si ottiene con 19 * pos_y + pos_x

		# disegna il carattere inserito in DL nella posizione attuale
		# --> SCRIVIAMO DL NELLA POSIZIONE ATTUALE
        MOV $19, %AL
        MULB pos_y  # AX = 19 * pos_y

		# la griglia e' di 19 x 19 = 361 > 255
        # il risultato non sta su 8 bit

		MOV $0, %CX
		MOV pos_x, %CL  # estensione di campo

        ADD %CX, %AX
        
        MOV %DL, mappa(%EAX)  # scrivo il carattere

		POP %ECX
		POP %EAX
		RET

# -------------------------------------------------------------------

ritorna_carattere_mappa:
		NOP
		PUSH %EAX
		PUSH %ECX

		MOV $0, %EAX

		# nel vettore la posizione si ottiene con 19 * pos_y + pos_x

		# scrive il carattere della posizione attuale in DL

		# --> SCRIVIAMO DL NELLA POSIZIONE ATTUALE
        MOV $19, %AL
        MULB pos_y  # AX = 19 * pos_y

		# la griglia e' di 19 x 19 = 361 > 255
        # il risultato non sta su 8 bit

		MOV $0, %CX
		MOV pos_x, %CL  # estensione di campo

        ADD %CX, %AX
        
        MOV mappa(%EAX), %DL  # scrivo il carattere

		POP %ECX
		POP %EAX
		RET

# -------------------------------------------------------------------

movimento_sopra:
        NOP
        PUSH %EDX

		CALL push_mystack  # <--------- serve per segnare il movimento per la coda

        # conosco la posizione
        # se la posizione lungo y e' 1, allora non puo' andare sopra e bisogna quindi interrompere il programma

        CMPB $1, pos_y
        JE interruzione_movimento_sopra  # SALTA

		# se il carattere successivo e' parte del corpo, allora ha picchiato contro se' stesso e bisogna quindi interrompere il programma
		# se il carattere successivo e' un frutto allora bisogna modificare ECX (per dire alla coda di rimanere ferma)

		# --> AGGIORNIAMO LA POSIZIONE ATTUALE
		DECB pos_y

		# DOPO AVER MODIFICATO pos_y
		CALL ritorna_carattere_mappa  # il risultato e' la modifica di DL

		# DL e' parte del corpo (e' '0')? se si' allora il giocatore ha perso
		# DL e' un frutto (e' '1')? se si' allora la coda deve rimanere ferma
		CMP $personaggio, %DL
		JE interruzione_movimento_sopra

		CMP $frutto, %DL
		JNE continua_mov_sopra  # allora era semplicemente spazio vuoto

		# ALTRIMENTI SETTO ECX perche' ha mangiato un frutto
		# incremento il punteggio e disegno il nuovo frutto
		MOV $1, %ECX
		INCW punteggio
		# SE IL PUNTEGGIO E'((17 * 17) - 3)
		# ALLORA NON CI SONO PIU' POSTI LIBERI
		# IL GIOCATORE HA VINTO
		CMPW $286, punteggio
		JAE interruzione_movimento_sopra
		# altrimenti
		CALL random_position  # ---> se disegna nella testa, allora scompare perche' subito dopo scrive personaggio nella testa

		# guarda random_position
		# CASO 3): 1 <- 0000,  10000  praticamente disegna il frutto di nuovo nell'1, in cui pero' scrivero' la testa ('0')

continua_mov_sopra:
        MOV $personaggio, %DL
		CALL disegna_posizione_attuale

		JMP fine_movimento_sopra

interruzione_movimento_sopra:
		MOV $0, %EAX  # COSA RITORNA dobbiamo interrompere il programma

fine_movimento_sopra:
        NOP

        POP %EDX
        RET

# -------------------------------------------------------------------

movimento_sinistra:
        NOP
        PUSH %EDX

		CALL push_mystack  # <--------- serve per segnare il movimento per la coda

        # conosco la posizione
        # se la posizione lungo x e' 1, allora non puo' andare a sinistra e bisogna quindi interrompere il programma

        CMPB $1, pos_x
        JE interruzione_movimento_sinistra  # SALTA

		# se il carattere successivo e' parte del corpo, allora ha picchiato contro se' stesso e bisogna quindi interrompere il programma
		# se il carattere successivo e' un frutto allora bisogna modificare ECX (per dire alla coda di rimanere ferma)

		# --> AGGIORNIAMO LA POSIZIONE ATTUALE
		DECB pos_x

		# DOPO AVER MODIFICATO pos_x
		CALL ritorna_carattere_mappa  # il risultato e' la modifica di DL

		# DL e' parte del corpo (e' '0')? se si' allora il giocatore ha perso
		# DL e' un frutto (e' '1')? se si' allora la coda deve rimanere ferma
		CMP $personaggio, %DL
		JE interruzione_movimento_sinistra

		CMP $frutto, %DL
		JNE continua_mov_sinistra  # allora era semplicemente spazio vuoto

		# ALTRIMENTI SETTO ECX perche' ha mangiato un frutto
		# incremento il punteggio e disegno il nuovo frutto
		MOV $1, %ECX
		INCW punteggio
		# SE IL PUNTEGGIO E'((17 * 17) - 3)
		# ALLORA NON CI SONO PIU' POSTI LIBERI
		# IL GIOCATORE HA VINTO
		CMPW $286, punteggio
		JAE interruzione_movimento_sinistra
		# altrimenti
		CALL random_position

continua_mov_sinistra:
        MOV $personaggio, %DL
		CALL disegna_posizione_attuale

		JMP fine_movimento_sinistra

interruzione_movimento_sinistra:
		MOV $0, %EAX  # COSA RITORNA dobbiamo interrompere il programma

fine_movimento_sinistra:
        NOP

        POP %EDX
        RET


# -------------------------------------------------------------------

movimento_sotto:
        NOP
        PUSH %EDX

		CALL push_mystack  # <--------- serve per segnare il movimento per la coda

        # conosco la posizione
        # se la posizione lungo y e' 17, allora non puo' andare sotto e bisogna quindi interrompere il programma

        CMPB $17, pos_y
        JE interruzione_movimento_sotto  # SALTA

		# se il carattere successivo e' parte del corpo, allora ha picchiato contro se' stesso e bisogna quindi interrompere il programma
		# se il carattere successivo e' un frutto allora bisogna modificare ECX (per dire alla coda di rimanere ferma)

		# --> AGGIORNIAMO LA POSIZIONE ATTUALE
		INCB pos_y

		# DOPO AVER MODIFICATO pos_y
		CALL ritorna_carattere_mappa  # il risultato e' la modifica di DL

		# DL e' parte del corpo (e' '0')? se si' allora il giocatore ha perso
		# DL e' un frutto (e' '1')? se si' allora la coda deve rimanere ferma
		CMP $personaggio, %DL
		JE interruzione_movimento_sotto

		CMP $frutto, %DL
		JNE continua_mov_sotto  # allora era semplicemente spazio vuoto

		# ALTRIMENTI SETTO ECX perche' ha mangiato un frutto
		# incremento il punteggio e disegno il nuovo frutto
		MOV $1, %ECX
		INCW punteggio
		# SE IL PUNTEGGIO E'((17 * 17) - 3)
		# ALLORA NON CI SONO PIU' POSTI LIBERI
		# IL GIOCATORE HA VINTO
		CMPW $286, punteggio
		JAE interruzione_movimento_sotto
		# altrimenti
		CALL random_position

continua_mov_sotto:
        MOV $personaggio, %DL
		CALL disegna_posizione_attuale

		JMP fine_movimento_sotto

interruzione_movimento_sotto:
		MOV $0, %EAX  # COSA RITORNA dobbiamo interrompere il programma

fine_movimento_sotto:
        NOP

        POP %EDX
        RET

# -------------------------------------------------------------------

movimento_destra:
        NOP
        PUSH %EDX

		CALL push_mystack  # <--------- serve per segnare il movimento per la coda

        # conosco la posizione
        # se la posizione lungo x e' 17, allora non puo' andare a sinistra e bisogna quindi interrompere il programma

        CMPB $17, pos_x
        JE interruzione_movimento_destra  # SALTA

		# se il carattere successivo e' parte del corpo, allora ha picchiato contro se' stesso e bisogna quindi interrompere il programma
		# se il carattere successivo e' un frutto allora bisogna modificare ECX (per dire alla coda di rimanere ferma)

		# --> AGGIORNIAMO LA POSIZIONE ATTUALE
		INCB pos_x

		# DOPO AVER MODIFICATO pos_x
		CALL ritorna_carattere_mappa  # il risultato e' la modifica di DL

		# DL e' parte del corpo (e' '0')? se si' allora il giocatore ha perso
		# DL e' un frutto (e' '1')? se si' allora la coda deve rimanere ferma
		CMP $personaggio, %DL
		JE interruzione_movimento_destra

		CMP $frutto, %DL
		JNE continua_mov_destra  # allora era semplicemente spazio vuoto

		# ALTRIMENTI SETTO ECX perche' ha mangiato un frutto
		# incremento il punteggio e disegno il nuovo frutto
		MOV $1, %ECX
		INCW punteggio
		# SE IL PUNTEGGIO E'((17 * 17) - 3)
		# ALLORA NON CI SONO PIU' POSTI LIBERI
		# IL GIOCATORE HA VINTO
		CMPW $286, punteggio
		JAE interruzione_movimento_destra
		# altrimenti
		CALL random_position

continua_mov_destra:
        MOV $personaggio, %DL
		CALL disegna_posizione_attuale

		JMP fine_movimento_destra

interruzione_movimento_destra:
		MOV $0, %EAX  # COSA RITORNA dobbiamo interrompere il programma

fine_movimento_destra:
        NOP

        POP %EDX
        RET


# =============================================================================
# MY_STACK

push_mystack:
		NOP
		PUSH %EAX

		# scrive il movimento da BL
		MOV $0, %EAX
		MOV ind_testa, %AX  # estensione di campo
		MOV %BL, my_stack(%EAX)

		# se ind_testa = my_stack_dim - 1 va a 0, altrimenti lo incrementiamo
		CMPW $my_stack_dim-1, ind_testa
		JAE resetta_ind_testa

		# altrimenti
		INCW ind_testa

		JMP fine_push_mystack

resetta_ind_testa:
		MOVW $0, ind_testa

fine_push_mystack:
		POP %EAX
		RET


pop_mystack:
		NOP
		PUSH %EAX
		
		# preleviamo da my_stack e SCRIVIAMO IN BL!
		MOV $0, %EAX
		MOV ind_coda, %AX  # estensione di campo
		MOV my_stack(%EAX), %BL

		# se ind_coda = my_stack_dim - 1 va a 0, altrimenti lo incrementiamo
		CMPW $my_stack_dim-1, ind_coda
		JAE resetta_ind_coda

		# altrimenti
		INCW ind_coda

		JMP fine_pop_mystack

resetta_ind_coda:
		MOVW $0, ind_coda

fine_pop_mystack:
		POP %EAX
		RET

# =============================================================================

# MOVIMENTO CODA

movimento_coda:
		PUSH %EBX

		# chiaramente non dobbiamo fare i controlli della posizione
		# perche' e' la testa che picchia contro un ostacolo

		# si aspetta ECX
		# se ECX = 1 allora ha mangiato un frutto e NON DEVE FARE NULLA, deve solo azzerare ECX
		# altrimenti esegue il MOVIMENTO
		# si aspetta anche che nella pila ci siano i movimenti che deve eseguire
		# PROBLEMA: la pila e' LIFO (a noi servirebbe FIFO)
		# quindi usiamo my_stack

		CMP $1, %ECX
		JE fine_movimento_coda

		# altrimenti ECX = 0
		# quindi la coda deve muoversi
		CALL pop_mystack  # il risultato e' la modifica di BL! (per sicurezza ce lo salviamo, anche se non dovrebbe essere un problema sporcarlo. SI E' UN PROBLEMA)

		# BL contiene w, a, s oppure d

		CMP $'w', %BL
        JNE controllo_a_coda
		# altrimenti OK, BL = 'w'
        CALL movimento_sopra_coda
        JMP fine_movimento_coda

controllo_a_coda:
        CMP $'a', %BL
        JNE controllo_s_coda
        # altrimenti OK, BL = 'a'
		CALL movimento_sinistra_coda
        JMP fine_movimento_coda

controllo_s_coda:
        CMP $'s', %BL
        JNE controllo_d_coda
        # altrimenti OK, BL = 's'
		CALL movimento_sotto_coda
        JMP fine_movimento_coda

controllo_d_coda:
        CMP $'d', %BL
        # JNE ASSURDO2  # NON PUO' ACCADERE CHE BL non contenga w, a, s oppure d
        # altrimenti OK, BL = 'd'
		CALL movimento_destra_coda
		JMP fine_movimento_coda

fine_movimento_coda:
		MOV $0, %ECX  # a prescindere lo risettiamo a 0 per le volte dopo (importante)

		POP %EBX
		RET

# -------------------------------------------------------------------

disegna_posizione_coda:
		NOP
		PUSH %EAX
		PUSH %ECX

		MOV $0, %EAX

		# nel vettore la posizione si ottiene con 19 * pos_y_coda + pos_x_coda

		# disegna il carattere inserito in DL nella posizione attuale
		# --> SCRIVIAMO DL NELLA POSIZIONE ATTUALE
        MOV $19, %AL
        MULB pos_y_coda  # AX = 19 * pos_y_coda

		# la griglia e' di 19 x 19 = 361 > 255
        # il risultato non sta su 8 bit

		MOV $0, %CX
		MOV pos_x_coda, %CL  # estensione di campo

        ADD %CX, %AX
        
        MOV %DL, mappa(%EAX)  # scrivo il carattere

		POP %ECX
		POP %EAX
		RET

# -------------------------------------------------------------------

movimento_sopra_coda:
        NOP
        PUSH %EDX

        # modifico la matrice

		MOV $spazio, %DL
        CALL disegna_posizione_coda

		# --> AGGIORNIAMO LA POSIZIONE ATTUALE
		DECB pos_y_coda

        MOV $personaggio, %DL
		CALL disegna_posizione_coda

        POP %EDX
        RET

# -------------------------------------------------------------------

movimento_sinistra_coda:
        NOP
        PUSH %EDX

        # modifico la matrice

		MOV $spazio, %DL
        CALL disegna_posizione_coda

		# --> AGGIORNIAMO LA POSIZIONE ATTUALE
		DECB pos_x_coda

        MOV $personaggio, %DL
		CALL disegna_posizione_coda

        POP %EDX
        RET


# -------------------------------------------------------------------

movimento_sotto_coda:
        NOP
        PUSH %EDX

        # modifico la matrice

		MOV $spazio, %DL
        CALL disegna_posizione_coda

		# --> AGGIORNIAMO LA POSIZIONE ATTUALE
		INCB pos_y_coda

        MOV $personaggio, %DL
		CALL disegna_posizione_coda

        POP %EDX
        RET

# -------------------------------------------------------------------

movimento_destra_coda:
        NOP
        PUSH %EDX

        # modifico la matrice

		MOV $spazio, %DL
        CALL disegna_posizione_coda

		# --> AGGIORNIAMO LA POSIZIONE ATTUALE
		INCB pos_x_coda

        MOV $personaggio, %DL
		CALL disegna_posizione_coda

        POP %EDX
        RET


# =============================================================================

disegna_frutto:
		NOP
		PUSH %EAX
		PUSH %ECX

		MOV $0, %EAX

		# nel vettore la posizione si ottiene con 19 * pos_y_frutto + pos_x_frutto

		# --> SCRIVIAMO DL NELLA POSIZIONE ATTUALE
        MOV $19, %AL
        MULB pos_y_frutto  # AX = 19 * pos_y_frutto

		# la griglia e' di 19 x 19 = 361 > 255
        # il risultato non sta su 8 bit

		MOV $0, %CX
		MOV pos_x_frutto, %CL  # estensione di campo

        ADD %CX, %AX
        
        MOVB $frutto, mappa(%EAX)  # scrivo il carattere

		POP %ECX
		POP %EAX
		RET

# -------------------------------------------------------------------

/*
int rand_r (unsigned int *seed)
{
  unsigned int next = *seed;
  int result;

  next *= 1103515245;
  next += 12345;
  result = (unsigned int) (next / 65536) % 2048;

  next *= 1103515245;
  next += 12345;
  result <<= 10;
  result ^= (unsigned int) (next / 65536) % 1024;

  next *= 1103515245;
  next += 12345;
  result <<= 10;
  result ^= (unsigned int) (next / 65536) % 1024;

  *seed = next;

  return result;
}
*/

random_number:
        PUSH %ECX
        PUSH %EDX
        PUSH %EBX
        
        # si aspetta un seed
        MOV seed, %EAX
        
        # -------------------
		# next *= 1103515245;
  		# next += 12345;
        MOV $1103515245, %ECX
		MOV $0, %EDX # sanificazione di EDX
        MUL %ECX  # EDX|EAX = 1103515245 * seed
        ADD $12345, %EAX
        MOV %EAX, %EBX  # EBX = next
        
		# result = (unsigned int) (next / 65536) % 2048;
        MOV $65536, %ECX
		XOR %EDX, %EDX
        DIV %ECX  # EAX = next / 65536
		# EAX % 2048 significa che prendo le ultime 12 cifre meno significative
        AND $2047, %EAX
        MOV %EAX, %EDX  # EDX = result
        
        # -------------------
		# next *= 1103515245;
  		# next += 12345;
        MOV %EBX, %EAX
        MOV $1103515245, %ECX
		MOV $0, %EDX # sanificazione di EDX
        MUL %ECX  # EDX|EAX = 1103515245 * next
        ADD $12345, %EAX
        MOV %EAX, %EBX   # EBX = next
        
        SHL $10, %EDX  # result <<= 10
		# result ^= (unsigned int) (next / 65536) % 1024;
        MOV $65536, %ECX
		MOV $0, %EDX # sanificazione di EDX
        DIV %ECX  # EAX = next / 65536
        AND $1023, %EAX
        XOR %EAX, %EDX  # result ^= valore
        
        # -------------------
		# next *= 1103515245;
		# next += 12345;
        MOV %EBX, %EAX
        MOV $1103515245, %ECX
        MUL %ECX
        ADD $12345, %EAX

        MOV %EAX, seed  # AGGIORNA IL SEED (in quel momento EAX e' l'ultimo next)
        
        SHL $10, %EDX  # result <<= 10
        MOV $65536, %ECX
		MOV $0, %EDX # sanificazione di EDX
        DIV %ECX  # EAX = next / 65536
        AND $1023, %EAX
        XOR %EAX, %EDX  # result ^= valore
        
        MOV %EDX, %EAX  # Risultato in EAX

		# che numero puo' essere il risultato ?
		# mi piacerebbe fosse in un range tra 1 a 17 compresi

		# dividiamo per 17, sapendo che il resto puo' essere tra 0 a 16, e sommiamo 1
		MOV $0, %EDX # sanificazione di EDX
        MOV $17, %ECX
        DIV %ECX  # EDX = EAX % 17
        INC %EDX
        MOV %EDX, %EAX
        
        POP %EBX
        POP %EDX
        POP %ECX
        RET



random_position:
		NOP
		PUSH %EAX
		PUSH %EDX
		PUSH %ECX

		# modifica pos_x_frutto e pos_y_frutto

		# ATTENZIONE! NON PUO' SCRIVERE UN FRUTTO DOVE SI TROVA LA CODA DELLO SNAKE

		CALL random_number  # risultato in AL
		MOV %AL, pos_x_frutto

		CALL random_number  # risultato in AL
		MOV %AL, pos_y_frutto

		# 1) LA POSIZIONE SCELTA E' NELLO SNAKE ?
		# 2) LA POSIZIONE SCELTA E' IN "coda_vecchio" (perche' e' invisibile)
		# 3) LA POSIZIONE SCELTA E' GIA' IN UN FRUTTO ? guarda movimento

		# per ognuno di questi caso MODIFICHERO' la posizione scelta, prendendo il primo spazio disponibile, scorrendo la mappa

		MOV $0, %EAX
		# nel vettore la posizione si ottiene con 19 * pos_y_frutto + pos_x_frutto
        MOV $19, %AL
        MULB pos_y_frutto  # AX = 19 * pos_y_frutto
		# la griglia e' di 19 x 19 = 361 > 255
        # il risultato non sta su 8 bit
		MOV $0, %CX
		MOV pos_x_frutto, %CL  # estensione di campo
        ADD %CX, %AX 
        MOV mappa(%EAX), %DL  # scrivo il carattere

		# COSA CONTIENE DL ?

		# CASO 1)
		CMP $'0', %DL
		JE prima_posizione_libera

		# CASO 2)
		# :)

		# CASO 3)
		CMP $'1', %DL
		JE prima_posizione_libera

		# ALTRIMENTI
		CALL disegna_frutto  # disegno in modo tradizionale
		JMP fine_random_position

prima_posizione_libera:
		CALL trova_posizione_libera
		JMP fine_random_position

fine_random_position:
		POP %ECX
		POP %EDX
		POP %EAX
		RET

# -------------------------------------------------------------------

trova_posizione_libera:
		NOP
		PUSH %ECX

		MOV $0, %ECX

loop_trova_posizione:
		CMP $361, %ECX  # 19x19=361
		JE fine_main  # <--- ATTENTO! non si potrebbe proprio fare, ma non dovrebbe accadere perche' ci abbiamo pensato prima al fatto che non ci sia piu' spazio

		CMPB $spazio, mappa(%ECX)
		JE fine_trova_posizione_libera

		INC %ECX
		JMP loop_trova_posizione

fine_trova_posizione_libera:
		
		# ECX contiene l'indice della posizione libera
		MOVB $frutto, mappa(%ECX)  # NOTA CHE: ho disegnato senza modificare la posizione

		POP %ECX
		RET
