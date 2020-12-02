######################################################################
# 			     Jump Bug                                #
######################################################################
#               Feito por Manoel Ricardo e Rennan Dias               #
######################################################################
#	Este programa necessita do Keyboard and Display MMIO         #
#       e do  Bitmap Display conectados no MIPS.                     #
#								     #
#       Configurações Bitmap Displa                                  #
#	Unit Width: 8						     #
#	Unit Height: 8						     #
#	Display Width: 512					     #
#	Display Height: 512					     #
#	Base Address for Display: 0x10008000 ($gp)		     #
######################################################################

.data

#Informações do Núcleo do Jogo

#Tela 
screenWidth: 	.word 64
screenHeight: 	.word 64

#Cores
heroColor: 	.word	0xbf4c41	 # vermelho
backgroundColor:.word	0xffffff	 # branco
groundColor:    .word	0x809c6d	 # verdinho	
EnemyColor: 	.word	0xad1fbf	 # roxo

#Informações do Herói
heroHeadX: 	.word 16
heroHeadY:	.word 39

#Inimigo Terrestre
EnemyHeadX:	.word 48
EnemyHeadY:	.word 39

#Inimigo Voador
Enemy2HeadX:	.word 48
Enemy2HeadY:	.word 18

jump:		.word 119 #pulo

.text

main:
######################################################
# Preenche a tela com branco e o chão
######################################################
	lw $a0, screenWidth
	lw $a1, backgroundColor
	mul $a2, $a0, $a0 #total de pixels da tela
	mul $a2, $a2, 3 #alinhando endereços
	add $a2, $a2, $gp #endereço base da tela
	add $a0, $gp, $zero #laço para preencher
	
FillBackground:
	beq $a0, $a2, Ground
	sw $a1, 0($a0) #armazenando cor
	addiu $a0, $a0, 4 #incrementando contador
	j FillBackground

Ground:
	addi $t0, $a0, 0
	lw $a1, groundColor
	lw $a0, screenWidth
	mul $a2, $a0, $a0 #total de pixels da tela
	mul $a2, $a2, 4 #alinhando endereços
	add $a2, $a2, $gp #endereço base da tela
	add $a0, $t0, $zero #laço para preencher

FillGround:
	beq $a0, $a2, Init
	sw $a1, 0($a0) #armazenando cor
	addiu $a0, $a0, 4 #incrementando contador
	j FillGround
	
######################################################
# Inicializando Variáveis
######################################################
Init:
	li $t0, 16
	sw $t0, heroHeadX
	li $t0, 39
	sw $t0, heroHeadY
	li $t0, 119
	sw $t0, jump
	
ClearRegisters:

	li $v0, 0
	li $a0, 0
	li $a1, 0
	li $a2, 0
	li $a3, 0
	li $t0, 0
	li $t1, 0
	li $t2, 0
	li $t3, 0
	li $t4, 0
	li $t5, 0
	li $t6, 0
	li $t7, 0
	li $t8, 0
	li $t9, 0
	li $s0, 0
	li $s1, 0
	li $s2, 0
	li $s3, 0
	li $s4, 0

######################################################
# Desenhando personagem
######################################################
	lw $t5, heroColor
	addi $a2, $0, 0
	addi $a3, $0, 48
	jal DrawHero
	
	addi $t7, $0, 0
	lw $t5, EnemyColor
	addi $a2, $0, 0
	addi $a3, $0, 48
	jal DrawEnemy
######################################################
# Verificação do input no teclado
######################################################

#pegando a coordenada atual
inputCheck:
	
	#Pegando valor digitado no teclado
	li $t0, 0xffff0000 #salvando endereço do bit ready
	lw $t1, ($t0) #acessando bit ready
	andi $t1, $t1, 0x0001 #checando se o bit ready é 1 
	#beqz $t1, inputCheck #Se não tiver input, permanecer
	
	li $a0, 2000
	li $v0, 32
	syscall
	
	addi $a2, $0, 0
	addi $t7, $t7, 0
	addi $t6, $t6, 0
	lw $t5, backgroundColor
	
	jal DrawEnemy
	
	bne $t7, -48, CanGo
	addi $t7, $t7, 64

CanGo:	addi $a2, $0, 0
	addi $t7, $t7, -16
	addi $t6, $t6, -16
	lw $t5, EnemyColor
	
	jal DrawEnemy
	
		
	lw $t5, backgroundColor
	addi $a2, $0, -21
	addi $a3, $0, 48
	jal DrawHero
	
	lw $t5, heroColor
	addi $a2, $0, 0
	addi $a3, $0, 48
	jal DrawHero
	
######################################################
# Atualizando posição do personagem
######################################################	
	
DrawUp:
	#check for collision before moving to next pixel
	#lw $a0, snakeHeadX
	#lw $a1, snakeHeadY
	#lw $a2, direction
	#jal CheckGameEndingCollision
	
	lw $a1, 0xffff0004 #Guarda caractere digitado em $a1	
	lw $a0, jump # Carregando tecla de jump
	bne $a1, $a0, inputCheck
	sw $0, 0xffff0004
	#Se a tecla digitada for igual a tecla de jump, desenhar pulo
	lw $t5, backgroundColor
	addi $a2, $0, 0
	addi $a3, $0, 48
	jal DrawHero
	
	lw $t5, heroColor
	addi $a2, $0, -21
	addi $a3, $0, 48
	jal DrawHero
	
	addi $a2, $0, 0
	addi $t7, $t7, 0
	addi $t6, $t6, 0
	lw $t5, EnemyColor
	
	jal DrawEnemy
	
	#lw $a0, heroHeadX
	#addi $a1, $t1, 0
	
	#jal CoordinateToAddress
	#lw $a1, backgroundColor
	#add $a0, $v0, $0
	
	#Apagando posição antiga
	#addi $t2, $t2, 599
	
FillBackground2:
	#beq $t1, $t2, exitDrawUp
	#sw $a1, 0($a0) #armazenando cor
	#addi $t1, $t1, 1
	#addiu $a0, $a0, 4 #incrementando contador
	
	#j FillBackground2
	
	#sw  $t1, heroHeadY
exitDrawUp:

	j inputCheck #Atualizado, voltar para verificar entrada do teclado

DrawDown:
	#check for collision before moving to next pixel
	#lw $a0, snakeHeadX
	#lw $a1, snakeHeadY
	#lw $a2, direction
	#jal CheckGameEndingCollision
	
	addi $a2, $0, 0
	addi $a3, $0, 48
	jal DrawHero
	
	#sw  $t1, heroHeadY
	j inputCheck #Atualizado, voltar para verificar entrada do teclado
	
##################################################################
# Função CoordinatesToAddress
# $a0 -> coordenada x
# $a1 -> coordenada y
##################################################################
# Retorna em $v0 o endereço no display Bitmap equivalente às coordenadas
##################################################################
CoordinateToAddress:
	lw $v0, screenWidth 	#Coloca a largura da tela em $v0
	mul $v0, $v0, $a1	#multiplica pela posição de y
	add $v0, $v0, $a0	#adiciona com a posição de x
	mul $v0, $v0, 4		#multiplica por 4
	add $v0, $v0, $gp	#adiciona ao endereço base da tela
	jr $ra			# retorna $v0
	
##################################################################
#Função DrawPixel
# $a0 -> Posição para desenhar
# $a1 -> Coloração do pixel
##################################################################
# Sem retorno
##################################################################
DrawPixel:	
	sw $a1, ($a0) 	#preenche a coordenada com o valor	
	jr $ra		#retorna
	
	
DrawEnemy:
	lw $t0, EnemyHeadX #carregando coordenada temporaria x
	lw $t1, EnemyHeadY #carregando coordenada temporaria y

FillEnemyX:
	add $a0, $t0, $t7 #carregando coordenada x
	add $a1, $t1, $a2 #carregando coordenada y
	addi $t6, $0, 58 #carregando valor final da coordenada x do inimigo
		
	beq $t0, $t6, Exit #comparando a largura do personagem
	
	addi $sp, $sp, -4 #salvando valor de $ra
	sw $ra, 0($sp)
			
	jal FillEnemyY #desenhar personagem
	
	lw $ra, 0($sp) #recuperando valor de $ra
	addi $sp, $sp, 4
	
	addi $t0, $t0, 1
	j FillEnemyX
			
FillEnemyY:	
	add $a0, $t0, $t7 #carregando coordenada x
	add $a1, $t1, $a2 #carregando coordenada y
		
	addi $sp, $sp, -4 #salvando valor de $ra
	sw $ra, 0($sp)
								
	jal CoordinateToAddress #pegando as coordenadas da tela
	
	lw $ra, 0($sp) #recuperando valor de $ra
	addi $sp, $sp, 4
	
	move $a0, $v0 #copiando coordenadas para $a0
	addi $a1, $t5, 0 #colocando a cor do herói em $a1
	
	beq $t1, $a3, stopFillEnemy #comparando se já chegou à altura do personagem

	addi $sp, $sp, -4 #salvando valor de $ra
	sw $ra, 0($sp)
			
	jal DrawPixel	#desenhar personagem
	
	lw $ra, 0($sp) #recuperando valor de $ra
	addi $sp, $sp, 4
	
	addi $t1, $t1, 1
	j FillEnemyY

stopFillEnemy:
	lw $t1, EnemyHeadY #carregando coordenada y
	jr $ra
	
##################################################################
#Função DrawHero
# $a2 -> Valor para deslocar a cabeça do herói
# $a3 -> Valor para percorrer iniciando da cabeça deslocada
##################################################################
# Sem retorno
##################################################################
DrawHero:
	lw $t0, heroHeadX #carregando coordenada temporaria x
	lw $t1, heroHeadY #carregando coordenada temporaria y

FillHeroX:
	add $a0, $t0, $0 #carregando coordenada x
	add $a1, $t1, $a2 #carregando coordenada y
		
	beq $t0, 26, Exit #comparando a largura do personagem
	
	addi $sp, $sp, -4 #salvando valor de $ra
	sw $ra, 0($sp)
			
	jal FillHeroY	#desenhar personagem
	
	lw $ra, 0($sp) #recuperando valor de $ra
	addi $sp, $sp, 4
	
	addi $t0, $t0, 1
	j FillHeroX
			
FillHeroY:	
	add $a0, $t0, $0 #carregando coordenada x
	add $a1, $t1, $a2 #carregando coordenada y
		
	addi $sp, $sp, -4 #salvando valor de $ra
	sw $ra, 0($sp)
								
	jal CoordinateToAddress #pegando as coordenadas da tela
	
	lw $ra, 0($sp) #recuperando valor de $ra
	addi $sp, $sp, 4
	
	move $a0, $v0 #copiando coordenadas para $a0
	addi $a1, $t5, 0 #colocando a cor do herói em $a1
	
	beq $t1, $a3, stopFill #comparando se já chegou à altura do personagem

	addi $sp, $sp, -4 #salvando valor de $ra
	sw $ra, 0($sp)
			
	jal DrawPixel	#desenhar personagem
	
	lw $ra, 0($sp) #recuperando valor de $ra
	addi $sp, $sp, 4
	
	addi $t1, $t1, 1
	j FillHeroY

stopFill:
	lw $t1, heroHeadY #carregando coordenada y
	jr $ra

Exit:
	jr $ra
