#SUDOKU
#https://www.doc.ic.ac.uk/lab/secondyear/spim/node8.html

#La grille doit se trouver dans un fichier input.txt, avec le contenu en une seule ligne
#Si le fichier n'est pas trouve utiliser la grille definie en dur ligne 9 : enlevez le commentaire et mettez en un ligne 10

# ===== Section donnees =====  
.data
	#grille: .asciiz "120056789690078215587291463352180007416937528978625341831542976269713854745869132"
	grille: .space 81
	filename : .asciiz "input.txt"

	squares: .byte 0,3,6,27,30,33,54,57,60  #indice de chaque premier chiffre d'un carre
	offsets: .byte 0,1,2,9,10,11,18,19,20	# indice du decalage pour avoir chaque chiffre d'un seul carre


# ===== Section code =====  
.text
# ----- Main -----
__start:
main:
	jal 	recupGrille   	 
    
	jal 	transformAsciiValues
	la 	$t0 grille
	jal 	displayGrille
	jal 	addNewLine
    
    
	jal 	solve_sudoku
    
	jal 	exit




# ----- Fonctions -----

    
# ----- Fonction recupGrille -----
# objectif : recuperer la grille fournis dans le fichier
# resultat : la grille chargee dans $t0
# registres utilises: $v0, $a[0-2], $t0
recupGrille:
	li	$v0 13    	#appel systeme pour ouvrir un fichier
	li	$a1 0    	# initialise $a1 a 0
	la	$a0 filename	# charge le nom du fichier dans $a0
	syscall        	# ouvre le fichier
	move	$t0 $v0   	 
    
	li	$v0 14    	#appel systeme pour lire un fichier
	move	$a0 $t0    	#charge 13 dans $a0
	la	$a1 grille	#recupere l'espace de 81
	li	$a2 81    	#cree un compteur de 81
	syscall        	#Lit les 81 valeurs du fichier
    

	li	$v0 16    	#appel systeme pour fermer le fichier
	syscall
	jr $ra




# ----- Fonction addNewLine -----  
# objectif : Affiche un retour a la ligne a l'ecran
# Registres utilises : $v0, $a0
addNewLine:
    	sub 	$sp, $sp, 4	#deplace la pile et stocke la valeur de $ra
    	sw  	$ra, 0($sp)    
   	 
   	li  	$a0, 10    	#code ascii du \n
	li  	$v0, 11    	#affiche un caratere
	syscall
    
	lw  	$ra, 0($sp)	#recupeere la valeur de $ra et redeplace la pile
    	add 	$sp, $sp, 4
	jr $ra
    
    
# ----- Fonction addSpace -----  
# objectif : affiche un espace entre chaque chiffre a l'ecran
# Registres utilises : $v0, $a0
addSpace:
	add	$sp $sp -4
	sw	$ra 0($sp)
    
	li  	$a0, 32  	#code ascii de l'espace
	li  	$v0, 11    	#afficher un caractere
	syscall
    
	lw	$ra 0($sp)
	add 	$sp $sp 4
	jr  	$ra


# ----- Fonction addDash -----  
# objectif : affiche une ligne de tirets en-dessous de chaque carre
# Registres utilises : $v0, $a0, $a2
addDash:
	add 	$sp, $sp, -4    	# Sauvegarde de la reference du dernier jump
	sw  	$ra, 0($sp)
    
	li	$a2 0            	# initialise $a2 a 0
	jal 	addNewLine        	#retour a la ligne
    
	boucle_Dash:
	bge	$a2 20 Fin_Dash    	#boucle pour afficher 20 tirets
        	li  	$a0, 45      	#code ascci du '-'
        	li  	$v0, 11    	#appel systeme pour afficher un caractere
        	syscall
        	add	$a2 $a2 1    	#incremente $a2
        	j 	boucle_Dash
       	 
	Fin_Dash:
    	lw  	$ra, 0($sp)         	# On recharge la reference
    	add 	$sp, $sp, 4      	 
	jr  	$ra
    
    
# ----- Fonction addPipe -----  
# objectif : affiche un pipe entre chaque carre
# Registres utilises : $v0, $a0
addPipe:
	add	$sp $sp -4
	sw	$ra 0($sp)
    
	li  	$a0, 124  	#code ascii du '|'
	li  	$v0, 11    	#appel systeme pour afficher un caractere
	syscall
    
	lw	$ra 0($sp)
	add 	$sp $sp 4
	jr  	$ra
    
    
# ----- Fonction zeroToSpace -----  
# objectif : Remplace les zeros par des espaces
# Registres utilises : $v0, $a[0-1]
zeroToSpace:
	add 	$sp $sp -4
	sw 	$ra 0($sp)
    
    	lb 	$a1, ($t2)        	# charge la valeur a l'adresse t2 dans a1
    	bne	$a1, $zero, NoZero	#si a1 != 0
    	li	$a0, 32        	#met 32 dans a0 (correspond a un espace)
    	li	$v0, 11        	#v0 = 11 pour print_char
    	syscall                	#affiche un espace
    	j	Fin_zeroToSpace
   	 
    	NoZero:
        	la	$a0 ($a1)	#met la valeur a l'adresse a1 dans a0
        	li  	$v0, 1   	# code pour l'affichage d'un entier
        	syscall    	#affiche l'entier a0
   	 
	Fin_zeroToSpace:
        	lw $ra 0($sp)
        	add $sp $sp 4
        	jr $ra


# ----- Fonction displayGrille -----   
# Objectif :Affiche la grille.
# Registres utilises : $v0, $a0, $t[0-2]
displayGrille:  
	add 	$sp, $sp, -4    	# Sauvegarde de la reference du dernier jump
	sw  	$ra, 0($sp)

	li  	$t1, 0
	jal addNewLine
	boucle_displayGrille:
    	bge 	$t1, 81, end_displayGrille 	# Si $t1 est plus grand ou egal a 81 alors branchement a end_displayGrille
        	add 	$t2, $t0, $t1       	# $t0 + $t1 -> $t2 ($t0 l'adresse du tableau et $t1 la position dans le tableau)
        	jal 	DisplaySudoku    	# Affiche un chiffre
        	jal    	addSpace    	# Affiche un espace
       	 
        	move	$a0, $t1    	# met la valeur de $t1 dans $a0
        	li  	$a1, 27        	# charge 27 dans $a1
        	jal 	getModulo    	# recupere le modulo de $a0 et $a1
        	beq 	$v0, 26 addDash  	# si l'indice dans la tableau modulo 27 fait 26 (= fin d'une ligne de carre) on affiche une ligne de tiret
            	 
        	add 	$t1, $t1, 1         	# $t1 += 1;
    	j boucle_displayGrille
   	 
	end_displayGrille:
	jal addNewLine
    	lw  	$ra, 0($sp)             	# On recharge la reference
    	add 	$sp, $sp, 4             	# du dernier jump
	jr 	$ra


# ----- Fonction DisplaySudoku -----
# Objectif : Affiche le sudoku
# Resultat aucun ce n'est que de l'affichage
# Registres utilises : $a[0-1], $t1, $v0
DisplaySudoku:
    	sub 	$sp, $sp, 4
    	sw  	$ra, 0($sp)
    	move  	$a0, $t1
   	 
    	#Divise la ligne en carre de 3 chiffre
    	li  	$a1, 9
    	jal 	getModulo
    	beq 	$v0, $zero, addNewLine
    
    	#Retour a la ligne au bout de trois carre   
    	li  	$a1, 3
    	jal 	getModulo
    	beq 	$v0, $zero, addPipe
   	 
    	jal	zeroToSpace    	#transforme les zero en espace    
           	 
    	lw  	$ra, 0($sp)
    	add 	$sp, $sp, 4
    	jr  	$ra
   	 

# ----- Fonction transformAsciiValues -----   
# Objectif : transforme la grille de ascii a integer
# Registres utilises : $t[0-3]
transformAsciiValues:  
	add 	$sp, $sp, -4
	sw  	$ra, 0($sp)
    
	la  	$t3, grille    	#charge la grille en $t3
	li  	$t0, 0        	#initialise $t0 a 0
	boucle_transformAsciiValues:
    	bge 	$t0, 81, end_transformAsciiValues	#tant que $t0<81
        	add 	$t1, $t3, $t0        	# recupere le bit de la valeur a l'indice $t0
        	lb  	$t2, ($t1)        	# recupere la valeur
        	sub 	$t2, $t2, 48        	#soustrait 48
        	sb  	$t2, ($t1)        	#enregistre cette nouvelle valeur
        	add 	$t0, $t0, 1        	#incremente $t0 de 1
    	j boucle_transformAsciiValues    
   	 
	end_transformAsciiValues:
	lw  	$ra, 0($sp)
	add 	$sp, $sp, 4
	jr $ra


# ----- Fonction getModulo -----
# Objectif : Fait le modulo (a mod b)
#   $a0 represente le nombre a (doit etre positif)
#   $a1 represente le nombre b (doit etre positif)
# Resultat dans : $v0
# Registres utilises : $a0
getModulo:
	sub 	$sp, $sp, 4
	sw  	$ra, 0($sp)
    
	boucle_getModulo:
    	blt 	$a0, $a1, end_getModulo    	#Tant que $a0 > $a1
        	sub 	$a0, $a0, $a1    	# $a0 = $a0 - $a1
    	j boucle_getModulo
	end_getModulo:
	move	$v0, $a0        	#charge la valeur de $a0 dans $v0
    
	lw  	$ra, 0($sp)
	add 	$sp, $sp, 4
	jr $ra
    
    
# ----- Fonction check_n_row -----
# Objectif : verifie s'il y a des doublons dans la n-ieme ligne
#   $a0 en entree pour la n ligne ($a0 de 0 a 8)
#   $t0 en entree pour la grille
#   Resultat dans $v0 (1 si la ligne est juste, 0 sinon)
# Registres utilises : $t[1-3], $t[8-9], $a2, $a0, $v0
check_n_row:
	add	$sp $sp -4    
	sw 	$ra 0($sp)	#stocke l'adresse de retour dans la pile
	add	$sp $sp -10	#abaisse la pile de 10 pour stocker les nombres deja vus
    
	li	$t9 0    	#$t9 : i=0
	boucle_byte_row:    	#remplit la pile de 10 zeros
	bge	$t9 10 suite_row    	#tant que i<10
	add 	$t8 $sp $t9        	#$t8: la case a l'indice
	sb	$zero	($t8)    	#on met un zero a la case d'indice $t8
	add	$t9 $t9 1        	#incremente $t9
	j	boucle_byte_row
    
	suite_row:
	mul 	$t1 $a0 9	#t1 : i = premier indice a la ligne $a0
	addi 	$a0 $t1 9	# a0 = i + 9 pour parcourir uniquement 9 fois dans la boucle
	li	$v0, 1
	boucle_check_n_row:
        	bge 	$t1 $a0 end_check_n_row	# tant que i<81 (taille max)
        	add 	$t2 $t0 $t1    	# $t2 : indice du nombre
        	lb 	$t3, ($t2)    	# $t3 : valeur du nombre
       	 
        	add 	$t8 $sp $t3	# $t8 : adresse dans la pile correspondant a la valeur de t3
        	lb	$a2	($t8)	# a2 : valeur a l'adresse t8 (a2 = 0 si c'est la premiere fois qu'on voit t3)

        	bgtz	$a2 doubler	#si different de 0 --> doublon
        	sb	$t3 ($t8)	#sinon on marque sa presence dans la pile (ignore si on est a l'indice 0)
           	addi 	$t1, $t1, 1	#incrementation pour la boucle
        	j 	boucle_check_n_row
 
    	doubler:      	 
    	li	$v0, 0    	# v0 = faux
       	 
	end_check_n_row:
	add $sp $sp 10    	#fermeture de la pile
    	lw 	$ra 0($sp)	#rechargement de l'adresse de retour
    	add 	$sp $sp 4
    	jr 	$ra
   	 

# ----- Fonction check_rows-----
# Objectif : verifie chaque lignes
#   Resultat dans $v0 (0 ou 1 si lignes juste)
# Registres utilises : $t7 + ceux de check_n_row
check_rows:
	add $sp $sp -4
	sw $ra 0($sp)
	li $t7 0	# t7 : i = 0
	boucle_check_rows:
    	bge $t7 9 Fin_check_rows	#tant que i<9
        	move $a0 $t7    	# t7 dans a0 pour utiliser dans check_n_row
        	jal check_n_row    	#check la i-eme colonne
        	beq $v0 0 Fin_check_rows	# termine si la ligne est fausse
        	addi $t7 $t7 1    	# incrementation de t7 (i++)
        	j boucle_check_rows
       	 
	Fin_check_rows:
    	lw $ra 0($sp)
    	add $sp $sp 4
    	jr $ra
    
    
# ----- Fonction check_n_column -----
# Objectif : verifie s'il y a des doublons dans la n-ieme colonne
#   $a0 en entree pour la n colonne ($a0 de 0 a 8)
#   $t0 en entree pour la grille
#   Resultat dans $v0 (1 si la colonne est juste, 0 sinon)
# Registres utilises : $t[1-3], $t[8-9], $a2, $a0, $v0
check_n_column:
	add	$sp $sp -4
	sw 	$ra 0($sp)
	add	$sp $sp -10	#abaisse la pile de 10
    
	li	$t9 0    	#$t9 : i=0
	boucle_byte_column:    	#remplit la pile de 9 zeros
	bge	$t9 10 suite_column    
    	add 	$t8 $sp $t9    	#$t8: la case a l'indice
    	sb	$zero	($t8)	#on met un zero a la case d'indice $t8
    	addi	$t9 $t9 1    	#incremente $t9
    	j	boucle_byte_column
    
	suite_column:
    	li	$v0, 1        	# $v0: unique=1 (vrai)  
    	move	$t1 $a0 	 
    
	boucle_check_n_column:
    	bge 	$t1 81 end_check_n_column	# tant que i<81 (taille max)
        	add 	$t2 $t0 $t1    	# $t2 : indice du nombre
        	lb 	$t3, ($t2)    	# $t3 : valeur du nombre
       	 
        	add 	$t8 $sp $t3	# $t8 l'indice corespondant a la case $t3 dans la pile
        	lb	$a2	($t8)	# valeur a l'indice $t8
        	bgtz	$a2 double_column	#Si c'est different de zero alors la valeur est en double
        	sb	$t3	($t8)	#sinon on marque sa presence dans la pile
           	addi 	$t1, $t1, 9	#incremente $t1
        	j 	boucle_check_n_column

    	double_column:
        	li	$v0, 0
       	 
	end_check_n_column:
	add $sp $sp 10
    	lw 	$ra 0($sp)
    	add 	$sp $sp 4
    	jr 	$ra
    
# ----- Fonction check_columns -----
# Objectif : verifie chaque clonnes
#   Resultat dans $v0 (0 ou 1 si colonnes justes)
# Registres utilises : $t7 + ceux de check_n_columns
check_columns:
	add $sp $sp -4
	sw $ra 0($sp)
	li $t7 0	# t7 : i = 0
	boucle_check_columns:
    	bge $t7 9 Fin_check_columns	#tant que i<9
        	move $a0 $t7
        	jal check_n_column	#check la i-eme colonne
        	beqz $v0 Fin_check_columns	# faux s'il y a un doublon
        	addi $t7 $t7 1    	# incrementation de t7 (i++)
        	j boucle_check_columns
       	 
	Fin_check_columns:
    	lw $ra 0($sp)
    	add $sp $sp 4
    	jr $ra
   	 
# ----- Fonction check_n_square -----
# Objectif : verifie s'il y a des doublons dans le n-ieme carre
#   $a0 en entree pour le n carre ($a0 de 0 a 8)
#   $t0 en entree pour la grille
#   Resultat dans $v0 (1 si le carre est juste, 0 sinon)
# Registres utilises : $t[1-3], $t[8-9], $a2, $a0, $v0
check_n_square:
	add	$sp $sp -4
	sw 	$ra 0($sp)
	add	$sp $sp -10    	#abaissement de la pile pour stocker les nombres deka vus
    
	li 	$t9 0        	#t9 : i=0
	boucle_byte_square:    	#rempli la pile avec 10 zeros
	bge	$t9 10 suite_square    	#tant que i<10
    		add 	$t8 $sp $t9    	# t8 : la case a l'indice i
    		sb	$zero ($t8)    	# met un 0
    		addi 	$t9 $t9 1    	#incrementation (i++)
    		j	boucle_byte_square
	suite_square:
	li 	$v0 1    	#resultat = true
	li 	$t9 0    	#t9 : i=0
	la	$t1 squares    	# charge la liste des indices de departs de chaque case
	add 	$t1 $a0 $t1    	# t1 : adresse du n carre dans la liste squares
	lb	$t1 ($t1)    	#t1 : indice du premier carre dans la grille
	add	$t1 $t1 $t0    	#t1 : adresse du premier carre
	boucle_check_n_square:
	bge	$t9 9 end_check_n_square	#tant que i<9
    		la	$t3 offsets	# charge la liste des decalges a effectuer dans le carre
    		add	$t3 $t3 $t9	# t3 : adresse du i decalage
    		lb	$t3 ($t3)	#t3 : decalage a effectuer
    		add	$t3 $t3 $t1	#t3 : adresse courante du nombre a verifier
    		lb	$t3 ($t3)	#t3 : valeur de la case de la grille
   	 
    		add	$t8 $sp $t3	#t8 : adresse de Pile[t3]
    		lb	$a2 ($t8)	#a2 : valeur de Pile[t3]
    		bgtz	$a2 double_square	# si different de 0 (doublon)
    		sb	$t3 ($t8)    	#sinon on marque sa presence dans la pile
   	 
    		addi 	$t9 $t9 1	#incrementation (i++)
    		j	boucle_check_n_square
	double_square:
	li 	$v0 0    	# v0 = faux
   	 
	end_check_n_square:
	add 	$sp $sp 10    	#fermeture de la pile
    	lw 	$ra 0($sp)
    	add 	$sp $sp 4
    	jr 	$ra
    
# ----- Fonction check_squares -----
# Objectif : verifie chaque carre
#   Resultat dans $v0 (0 si faux ou 1 si juste)
# Registres utilises : $t7 + ceux de check_n_square    
check_squares:
	add $sp $sp -4
	sw $ra 0($sp)
	li $t7 0	# t7 : i = 0
	li $v0 1	# v0 = vrai
	boucle_check_squares:	# boucle pour verifier chaque carre
    	bge $t7 9 end_check_squares	#tant que i<9
        	move $a0 $t7    	# t7 dans a0 pour utiliser dans check_n_square
        	jal check_n_square	#check la i-eme colonne
        	beqz $v0 end_check_squares	# faux si'il y a un doublon
        	addi $t7 $t7 1    	# incrementation de t7 (i++)
        	j boucle_check_squares
       	 
	end_check_squares:
    	lw $ra 0($sp)
    	add $sp $sp 4
    	jr $ra
   	 
   	 
# ----- Fonction check_Sudoku -----
# Objectif : verifie le sudoku en entier
#   Resultat dans $v0 (0  s'il a un doublon de chiffre ou 1 s'il est bon)
# Registres utilises : $t7 + ceux de check_n_columns  
check_Sudoku:
	add $sp $sp -4
	sw $ra 0($sp)
    
	jal 	check_rows	#test toutes les lignes
	beqz	$v0 Fin_check_sudoku	# si faux, on arrete
    
	jal 	check_columns	#test toutes les colonnes
	beqz	$v0 Fin_check_sudoku	# si faux, on arrete
    
	jal 	check_squares	#test touts les carres
	beqz	$v0 Fin_check_sudoku	# si faux, on arrete
    
	Fin_check_sudoku:
    	lw $ra 0($sp)
    	add $sp $sp 4
    	jr $ra
   	 
   	 
   	 
# ----- Fonction premier_zero -----
# Objectif : trouve le premier 0 dans la grille $t0   
# entree : la grille dans $t0
# sortie : $v0 indice du 1er zero (de 0 a 80) ou -1 si aucun
premier_zero:
	add 	$sp $sp -4
	sw 	$ra 0($sp)
    
	li	$v0 -1    	#v0 resultat initialise a -1
	li	$t9 0    	#t9 : i=0
	boucle_premier_zero:	#boucle pour parcourir chaque indice de la grille
	bge $t9 81 end_premier_zero	#tant que i<81
    		add 	$t8 $t0 $t9	#t8 : indice de la case
    		lb	$t7 ($t8)	#t7 : valeur dans la case
    		beqz	$t7 trouve_premier_zero    	#si t7 == 0
    		addi 	$t9 $t9 1	#i++
    		j boucle_premier_zero
	trouve_premier_zero:
	sub	$v0 $t8	$t0    	#met l'indice trouve dans le resulat
    
	end_premier_zero:
	lw 	$ra 0($sp)
	add 	$sp $sp 4
	jr $ra
       	 
  	 
         	 
# ----- Fonction solve_sudoku -----
# Objectif : affiche toutes les solutions d'un sudoku
# entree : la grille dans $t0

solve_sudoku:
	add 	$sp $sp -4
	sw 	$ra 0($sp)    	#sauvergarde de l'adresse de retour
	add	$sp $sp -12
	sw	$t5 0($sp)
	sw	$t6 4($sp)    	# pour sauvegarder t5 et t6 entre les appels recursifs
	sw	$s7 8($sp)
    
	jal premier_zero    	#trouver le premier 0 (mis dans $v0)
	bne 	$v0 -1 solve_sudoku_zero	#s'il n'y a pas de 0 dans la grille
    		jal	displayGrille    	#affiche grille comme solution
    		li	$v0 1        	# renvoie vrai
    		j	end_solve_sudoku
	solve_sudoku_zero:
	add	$t5 $v0 $t0    	#t5 : adresse du premier zero
	li	$t6 1        	#t6 : i=0
    
	li	$s7 0
	boucle_solve_sudoku:
	bge $t6 10 end_solve_sudoku	#Pour chaque chiffre de 1 a 9
    		sb	$t6 ($t5)    	#met i a la place du 0 dans la grille
    		jal	check_Sudoku
    		beqz	$v0 solve_sudoku_faux    	#si check_sudoku == vrai
        		jal 	solve_sudoku
   	 
    	solve_sudoku_faux:
    	sb	$zero ($t5)    	#retirer i de la grille (retro-propagation)
    	addi $t6 $t6 1
    	j boucle_solve_sudoku
   	end_solve_sudoku:
   	lw	$t5 0($sp)
   	lw	$t6 4($sp)    	#recharge t5 et t6
   	lw	$s7 8($sp)
   	add	$sp $sp 12
   	lw 	$ra 0($sp)    	#recharge l'adresse de retour
   	add	$sp $sp 4
   	jr $ra



exit:
	li $v0, 10
	syscall
