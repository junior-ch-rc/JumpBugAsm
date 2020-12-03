######################################################################
# 			     Jump Bug                                #
######################################################################
#               Feito por Manoel Ricardo e Rennan Dias               #
######################################################################
#	Este programa necessita do Keyboard and Display MMIO         #
#       e do  Bitmap Display conectados no MIPS.                     #
#								     #
#       Configurações Bitmap Display                                 #
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
ActualHeroX:	.word 16
ActualHeroY:	.word 39
life:		.word 3
collided:	.word 0

#Inimigo Terrestre
EnemyHeadX:	.word 48
EnemyHeadY:	.word 39
ActualEnemyX:	.word 48
ActualEnemyY:	.word 39

#Inimigo Voador
Enemy2HeadX:	.word 48
Enemy2HeadY:	.word 18

#Controles
jump:		.word 119 #pulo

#Mensagens
LostLife:	.asciiz "Você perdeu uma vida\0"
GameOver:	.asciiz "Game Over!"

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
	
	li $t0, 16
	sw $t0, ActualHeroX
	li $t0, 39
	sw $t0, ActualHeroY
	
	li $t0, 48
	sw $t0, EnemyHeadX
	li $t0, 39
	sw $t0, EnemyHeadY
	
	li $t0, 48
	sw $t0, ActualEnemyX
	li $t0, 39
	sw $t0, ActualEnemyY
	
	li $t0, 119
	sw $t0, jump
	li $t0, 3
	sw $t0, life
	
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

inputCheck:
	
	#Pegando valor digitado no teclado
	li $t0, 0xffff0000 #salvando endereço do bit ready
	lw $t1, ($t0) #acessando bit ready
	andi $t1, $t1, 0x0001 #checando se o bit ready é 1 
	#beqz $t1, inputCheck #Se não tiver input, permanecer
	
	#Configurando velocidade dos inimigos
	li $a0, 2000
	li $v0, 32
	syscall
	
	#Apagando inimigo
	addi $a2, $0, 0
	addi $t7, $t7, 0
	addi $t6, $t6, 0
	lw $t5, backgroundColor
	
	jal DrawEnemy
	
	#Se inimigo chegar no limite da tela, voltar ao início
	bne $t7, -48, CanGo
	addi $t7, $t7, 64

CanGo:	addi $a2, $0, 0
	addi $t7, $t7, -16
	addi $t6, $t6, -16
	lw $t5, EnemyColor
	
	jal DrawEnemy
	
	#Checando a colisão (se as coordenadas X do inimigo e herói são iguais)
	lw $t1, ActualHeroX
	lw $t2, ActualEnemyX
	seq $t1, $t1, $t2 #Se a posição X atual do inimigo for igual a 26, set 1 em $t1
	
	lw $t2, ActualHeroY
	lw $t3, ActualEnemyY
	seq $t2, $t2, $t3 #Se a posição Y atual do inimigo for igual a do herói, set 1 em $t1
	
	and $t1, $t1, $t2
	
	bne $t1, 1, Continue
	lw $t2, life
	addi $t2, $t2, -1 #Decrementando uma vida
	sw $t2, life #Salvando na memória a vida decrementada
	li $v0, 56 #Valor para caixa de diálogo
	la $a0, LostLife #Mensagem que perdeu vida
	#lw $a1, score	#get score
	syscall
	
	#Apagando herói na posição de cima, caso esteja	
Continue:
	lw $t5, backgroundColor
	addi $a2, $0, -21
	addi $a3, $0, 48
	jal DrawHero
	
	#Desenhando herói na posição de inicio
	lw $t5, heroColor
	addi $a2, $0, 0
	addi $a3, $0, 48
	jal DrawHero
	
######################################################
# Atualizando posição do personagem
######################################################	
	
DrawUp:	
	lw $a1, 0xffff0004 #Guarda caractere digitado em $a1	
	lw $a0, jump # Carregando tecla de jump
	bne $a1, $a0, inputCheck
	sw $0, 0xffff0004
	
	#Se a tecla digitada for igual a tecla de jump, desenhar pulo
	#Apagando herói da posição original
	lw $t5, backgroundColor
	addi $a2, $0, 0
	addi $a3, $0, 48
	jal DrawHero
	
	#Desenhando em cima
	lw $t5, heroColor
	addi $a2, $0, -21
	addi $a3, $0, 48
	jal DrawHero
	
	#Paralisando inimigo na mesma posição por um momento
	addi $a2, $0, 0
	addi $t7, $t7, 0
	addi $t6, $t6, 0
	lw $t5, EnemyColor
	
	jal DrawEnemy

exitDrawUp:
	j inputCheck #Voltar para entrada do teclado

##################################################################
#			FUNÇÕES					 #	
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
##################################################################
#Função DrawEnemy
# $a2 -> Valor para somar com a coordenada Y e fazer o inimigo ficar em cima
# $a3 -> Valor de referência para o tamanho do corpo do personagem
# $t7 -> Valor para somar com a coordenada X e fazer o inimigo andar
# $t6 -> Novo valor de refência para largura do personagem
##################################################################
# Sem retorno
##################################################################
DrawEnemy:
	lw $t0, EnemyHeadX #carregando coordenada temporaria x
	lw $t1, EnemyHeadY #carregando coordenada temporaria y

FillEnemyX:
	add $a0, $t0, $t7 #carregando coordenada x
	sw $a0, ActualEnemyX
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
	sw $a1, ActualEnemyY
		
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
# $a2 -> Valor para somar com a coordenada Y e fazer o herói pular
# $a3 -> Valor de referência para o tamanho do corpo do personagem
##################################################################
# Sem retorno
##################################################################
DrawHero:
	lw $t0, heroHeadX #carregando coordenada temporaria x
	lw $t1, heroHeadY #carregando coordenada temporaria y

FillHeroX:
	add $a0, $t0, $0 #carregando coordenada x
	sw $a0, ActualHeroX
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
	sw $a1, ActualHeroY
		
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
