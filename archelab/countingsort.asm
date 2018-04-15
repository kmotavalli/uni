#counting sort, versione per soli numeri positivi
.data

    arrayMinMax:
        .word 0 0
    salvataggio_ra:
        .word 0
    stampainiziale:
        .asciiz "Array iniziale: "
    stampafinale:
        .asciiz "\nArray ordinato: "
    dim:
        .word 20
    A:
        .word 33 37 80 47 1 39 34 11 53 6 76 80 63 11 20 73 6 34 24 24
    B:
        .word 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0
#se il massimo non e' strettamente minore o uguale della dimensione dell'array, non so a priori quanto si estendera' in memoria l'array C, le cui posizioni dipendono dal valore numerico di A[i]. spero che mettendolo per ultimo in memoria non si vadano a sovrascrivere altri elementi.
#C:
#.word 0
#in realta' non funzionando bare-metal, uso la syscall 9 per chiede memoria al SO simulato da QtSPIM
.globl main
.text

main:
    #cerco elemento massimo nell'array A, passo alla procedura suo indirizzo in a0, dim in a1
    la $a0, A
    lw $a1, dim
    jal trovaEstremi
    #in $v0 ho l'indirizzo con la struttura di ritorno, nel secondo elemento il max
    #salvo il MAX in $s0
    lw $s0, 4($v0)
    #stampo stringa iniziale
    la $a0, stampainiziale
    addi $v0, $zero, 4
    syscall
    #stampo array A
    la $a0, A
    la $t1, dim
    lw $a1, 0($t1)
    jal stampa
    #salvo l'indirizzo di C in $s2
    
    add $t0, $zero, $s0
    sll $t0, $t0, 2
    add $a0, $zero, $t0
    addi $v0, $zero, 9
    syscall
    add $s2, $zero, $v0
    #inizializzo C a 0, da i = 0 .. MAX
    
    and $t0, $t0, $zero
    add $t1, $zero, $s2
    inizializzaC:
        beq $t0, $s0, fase1
        sw $zero, 0($t1)
        addi $t0, $t0, 1
        addi $t1, $t1, 4
        j inizializzaC


    fase1:
        #primo passo: quante volte un elemento di A si ripete?
        #for i = 0 .. dim -1 C[A[i]] = C[A[i]] + 1

        #ricarico dim in $s1
        add $s1, $zero, $a1
        #dim = dim -1
        addi $s1, $s1, -1

        #$t1 e' contatore i del ciclo for
        #$t2 il puntatore per l'accesso ad A[i]
        #$t3 il puntatore per l'accesso a C

        and $t1, $t1, $zero

        fase1_ciclo:
            #reimposto i due puntatori
            la $t2, A
            #la $t3, C
            and $t3, $t3, $zero
            add $t3, $t3, $s2
            beq $t1, $s1, fase2

            #calcolo l'indirizzo di A[i] sommando quattro volte il contatore
            add $t2, $t2, $t1
            add $t2, $t2, $t1
            add $t2, $t2, $t1
            add $t2, $t2, $t1

            #carico il valore contenuto in A[i] in $t4
            lw $t4, 0($t2)
            #calcolo l'indirizzo C[A[i]] in $t3
            sll $t6, $t4, 2
            add $t3, $t6, $s2
            beq $t4, $zero, salta_decremento
            addi $t3, $t3, -4
            #carico il valore corrente contenuto in C[A[i]], poi lo incremento avendo trovato una nuova occorrenza della chiave in A
            salta_decremento:
            lw $t5, 0($t3)
            addi $t5, $t5, 1
            #salvo il nuovo valore in C[A[i]]
            sw $t5, 0($t3)
            #rincomincio il ciclo
            addi $t1, $t1, 1
            j fase1_ciclo
            
    #quanti elementi piu' piccoli o uguali a quello scansionato sono presenti in A?
    #for i = 1 .. k C[i] = C[i - 1] + C[i]
    
    fase2:
        #imposto il contatore a 1
        addi $t1, $zero, 1
        #carico puntatori iniziali a C[i] e C[i - 1]
        #la $t2, C
        addi $t2, $s2, 4
        #la $t3, C
        add $t3, $zero, $s2
        #la chiave massima era in $s0
        fase2_ciclo:
            #indirizzo C[i] gia impostato in $t2, C[i -1] in $t3
            #prima di entrare o aggiornati a fine ciclo
            lw $t4, 0($t3)
            lw $t5, 0($t2)
            add $t6, $t4, $t5
            sw $t6, 0($t2)
            #incremento il contatore
            addi $t1, $t1, 1
            beq $t1, $s0, fase3
            #puntatore a C[i - 1] = puntatore a C[i]
            add $t3, $zero, $t2
            #incremento C[i]
            addi $t2, $t2, 4
            j fase2_ciclo
            
    fase3:
        #B[C[A[i]] = A[i]
        # i: $t0
        # &A: $t1
        # &A[i]: $t2
        # A[i]: $t3
        # &C[elema] = $t4
        # C[elema] = $t5
        # &B[elemc] = t6
        and $t0, $t0, $zero
        la $t1, A
        la $t2, A
        fase3_ciclo:
            #dim in $s1
            #carico A[i]
            lw $t3, 0($t2)
            add $t4, $zero, $s2
            beq $t3, $zero, carica
            #byte -> word
            sll $t7, $t3, 2
            add $t4, $t4, $t7
            addi $t4, $t4, -4
            carica:
            lw $t5, 0($t4)
            la $t6, B
            sll $t7, $t5, 2
            addi $t7, $t7, -4
            add $t7, $t7, $t6
            sw $t3, 0($t7)
            addi $t5, $t5, -1 
            sw $t5, 0($t4)
            addi $t0, $t0, 1
            beq $t0, $s1, fine_main
            #altrimenti
            #moltiplico il contatore per 4
            sll $t7, $t0, 2
            #calcolo &A[i]
            add $t2, $t1, $t7
            j fase3_ciclo
        
    fine_main:
        la $a0, stampafinale
        addi $v0, $zero, 4
        syscall
        #stampo array A
        la $a0, B
        la $t1, dim
        lw $a1, 0($t1)
        jal stampa
        #chiamo syscall exit
        addi $v0, $zero, 10
        syscall
        
#### altre procedure ####   

trovaEstremi:
    #la $a0, arrayInteri
    #lw $a1, dimensioneArray
    #non necessario se parte di una procedura
    #puntatore
    add $t0, $zero, $a0
    #contatore
    and $t1, $t1, $zero
    sub $a1, $a1, 1
    #min = v[0]
    and $t2, $t2, $zero
    lw $t2, 0($t0)
    #max = v[0]
    and $t3, $t3, $zero
    lw $t3, 0($t0)

    inizio_trovaestremi:
        #ho raggiunto la fine dell'array?
        beq $t1, $a1, uscita_trovaestremi
        #carico v[i] in $t4 per i confronti
        lw $t4, 0($t0)
        #incremento qui contatore e...
        addi $t1, $t1, 1
        #puntatore
        addi $t0, $t0, 4

        blt $t4, $t2, nuovoMin
        bgt $t4, $t3, nuovoMax

        #se entrambe non sono verificate ho else
        j inizio_trovaestremi
        nuovoMax:
            move $t3, $t4
            j inizio_trovaestremi

        nuovoMin:
            move $t2, $t4
            j inizio_trovaestremi

        beq $t2, $a2, trovato
        #altrimenti incremento ed aggiorno
        add $t1, $t1, 1
        #aggiorno il puntatore
        add $t0, $t0, 4
        j inizio_trovaestremi

    uscita_trovaestremi:
        #popolo array e lo metto in $v0 se devo diventare procedura
        la $v0, arrayMinMax
        sw $t2, 0($v0)
        sw $t3, 4($v0)
        jr $ra

stampa:
    #in $a0 indirizzo array interi, in $a1 la dimensione contando da uno.
    and $t0, $t0, $zero
    add $t1, $zero, $a1
    addi $t1, $t1, -1
    #copio in $t2 indirizzo base
    add $t2, $zero, $a0

    #copio il RA in memoria, non serve stack
    #non so se syscall SPIM ripristinano il $ra
    la $t7, salvataggio_ra
    sw $ra, 0($t7)
    
    stampa_ciclo:
        lw $a0, 0($t2)
        addi $v0, $zero, 1
        syscall
        
        addi $v0, $zero, 11
        #spazio
        addi $a0, $zero, 32
        syscall 

        addi $t0, $t0, 1
        beq $t0, $t1, fine_stampa
        addi $t2, $t2, 4
        j stampa_ciclo

    fine_stampa:
        #newline char
        addi $a0, $zero, 10
        addi $v0, $zero, 11
        syscall
        la $t7, salvataggio_ra
        lw $ra, 0($t7)
        jr $ra
