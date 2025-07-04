#########################################################################
#									#
#	Universidade de Brasilia - Instituto de Ciencias Exatas		#
#		  Departamento de Ciencia da Computacao  		#
#									#
#	     Introducao aos Sistemas Computacionais - 2024.1		#
#		    Professor: Marcus Vinicius Lamar			#
#									#
#	 Alunos: Elvis Miranda, Gustavo Alves e Pedro Marcinoni		#
#								        #
#		       	    DROID DEFENDER:		     		#
#			 Earth's Last Sentinel				#
#########################################################################

# OBS: devido ao curto periodo de produção, alguns comentarios e trechos de codigo podem ter ficado defasados/desorganizados.

.include "../System/MACROSv24.s" 	# permite a utilização dos ecalls "1xx"
	
.data			

# Dados das notas da melodia principal tocada no menu principal do jogo
NUM: .word 64

# lista das notas das melodias a serem tocadas no menu seguidas de suas respectivas durações
NOTAS: 66, 230, 61, 230, 78, 230, 61, 230, 73, 230, 61, 230, 76, 230, 78, 230, 73, 230, 76, 230, 73, 230, 76, 230, 78, 230, 61, 230, 78, 230, 61, 230, 76, 230, 64, 230, 71, 230, 62, 230, 71, 230, 64, 230, 73, 230, 76, 230, 73, 230, 71, 230, 73, 230, 61, 230, 73, 230, 61, 230, 73, 230, 61, 230, 69, 230, 64, 230, 66, 230, 61, 230, 57, 230, 61, 230, 57, 230, 61, 230, 69, 230, 64, 230, 66, 230, 61, 230, 57, 230, 61, 230, 76, 230, 78, 230, 73, 230, 71, 230, 73, 230, 57, 230, 73, 230, 57, 230, 64, 230, 57, 230, 73, 230, 57, 230, 73, 230, 57, 230, 64, 230, 57, 230, 73, 230, 57, 230 
NOTAS2: 42, 923, 49, 923, 42, 923, 49, 923, 44, 923, 52, 923, 45, 923, 49, 923, 42, 923, 49, 923, 42, 923, 49, 923, 45, 923, 52, 923, 45, 923, 52, 923 

# Dados diversos (strings para HUD, posições dos personagens no bitmap display, etc)

STR: .string "SCORE: "
STR2: .string "HS: "
STR3: .string "+200"
STR4: .string "    "

POS_ROBOZINHO: .word 0xFF00B4C8 	# endereco inicial da linha diretamente abaixo do Robozinho - posição inicial/atual do Robozinho
POS_BLINKY: .word 0xFF0078C8		# coordenada inicial/atual do alien verde claro (blinky)
POS_PINK: .word 0xFF009BC8		# coordenada inicial/atual do alien azul (pink)
POS_INKY: .word 0xFF009BB8		# coordenada inicial/atual do alien roxo (inky)
POS_CLYDE: .word 0xFF009BD8		# coordenada inicial/atual do alien laranja (clyde)

BUFFER: .word 0				# buffer para inputs do teclado (guarda a ultima tecla de movimentação pressionada)

CONTADOR_ASSUSTADO: .word -1		# contador da duração do frightened mode

PONTOS: .word 0				# contador de pontos do jogador atual
HIGH_SCORE: .word 0			# contador de highscore (maior pontuação ja alcançada por algum jogador previo)

ARQUIVO: .asciz "highscore.bin"		# buffer contendo string terminada em caracter nulo ('\0') "highscore.bin" (nome do arquivo binario a ser futuramente criado)

ZERO_WORD: .word 0x00000000		# buffer contendo uma word de valor 0x00000000 (ou seja, word contendo 0)

# inclusão das imagens 

.include "../DATA/mapa1.data"
.include "../DATA/mapa1colisao.data"
.include "../DATA/mapa2.data"
.include "../DATA/mapa2colisao.data"
.include "../DATA/menuprincipal.data"
.include "../DATA/telawin.data"
.include "../DATA/telalose.data"
.include "../DATA/Robozinho1.data"
.include "../DATA/Robozinho1forte.data"
.include "../DATA/Robozinho2.data"
.include "../DATA/Robozinho2forte.data"
.include "../DATA/Robozinhomorto.data"
.include "../DATA/Robozinho1preto.data"
.include "../DATA/Inimigo1.data"
.include "../DATA/Inimigo2.data"
.include "../DATA/Inimigo3.data"
.include "../DATA/Inimigo4.data"
.include "../DATA/InimigoAssustado.data"
.include "../DATA/Inimigobranco.data"
.include "../DATA/horpoint.data"
.include "../DATA/vertpoint.data"
.include "../DATA/inimigos1g.data"
.include "../DATA/inimigos2g.data"
.include "../DATA/inimigosscared1g.data"
.include "../DATA/inimigosscared2g.data"

.text

# Le o highscore da memoria secundaria (HD) para o segmento de dados (RAM). Se o arquivo "highscore.bin" ja existir, abre ele para leitura

	li a7,1024			# a7 = 1024 (numero do syscall para "open file")
	la a0,ARQUIVO			# a0 = endereço contendo o nome do arquivo (a label "ARQUIVO" contem a string terminada em caracter nulo "highscore.bin")
	li a1,0				# a1 = 0 (flag "read-only")
	ecall				# realiza o ecall
	
	mv t0,a0			# salva a0 (posição atual do fd -> inicio do arquivo) em t0
	
	blt a0,zero,CRIAR_ARQUIVO	# se o arquivo nao existir (file descriptor < 0), vá para CRIAR_ARQUIVO
	
	li a7,63			# a7 = 63 (numero do syscall "read", que le do fd para um buffer)
	mv a0,t0			# a0 = t0 (posição inicial do arquivo)
	la a1,HIGH_SCORE		# a1 = endereço do buffer de armazenamento do highscore
	li a2,4 			# numero de bytes a ler (4 bytes = word)
	ecall				# realiza o ecall
	
	li a7,57			# a7 = 57 (numero do syscall "fclose")
	mv a0,t0			# move o fd para o inicio do arquivo
	ecall				# realiza o ecall (fecha o arquivo)
	
	j START				# pula para START (inicio do programa de fato)
	
# Se o arquivo "highscore.bin" não existir, cria um novo arquivo de mesmo nome inicializado com 0 (abre-o para escrita)
	
CRIAR_ARQUIVO:	

	li a7,1024			# a7 = 1024 (numero do syscall para "open file")
	la a0,ARQUIVO			# a0 = endereço contendo o nome do arquivo (a label "ARQUIVO" contem a string terminada em caracter nulo "highscore.bin")
	li a1,1				# a1 = 0 (flag "write-only" -> quando o arquivo não existe, cria um novo)
	ecall				# realiza o ecall
		
	mv t0,a0			# salva o valor de a0 em t0 (a0 = inicio do arquivo)

	li a7,64 			# a7 = 64 (numero do syscall "write", que le do buffer e escreve na posição do fd)
	mv a0,t0			# a0 = t0 (posição inicial do arquivo)
	la a1,ZERO_WORD			# a1 = endereço do buffer carregado com 0x00000000
	li a2,4 			# numero de bytes a escrever (4 bytes = word)
	ecall				# realiza o ecall
	
	li a7,57			# a7 = 57 (numero do syscall "fclose")
	mv a0,t0			# move o fd para o inicio do arquivo
	ecall				# realiza o ecall (fecha o arquivo)
	
################################
#####  INICIO DO PROGRAMA  #####
#####	       ***  	   #####
##### CARREGAMENTO DE MENU #####
################################

# OBS: os registradores salvos serão utilizados de maneira arbitraria durante o carregamento de imagens e suas reais funções dentro do loop do jogo serão definidas posteriormente na label "SETUP_MAIN"

# Carrega na tela o menu principal
	
START:	li s1,0xFF000000	# s1 = endereço inicial da Memoria VGA - Frame 0
	li s2,0xFF012C00	# s2 = endereço final da Memoria VGA - Frame 0
	la s0,menuprincipal	# s0 = endereço dos dados do menu principal
	addi s0,s0,8		# s0 = endereço do primeiro pixel da imagem (depois das informações de nlin ncol)
	
LOOPM: 	beq s1,s2,SONG		# se s1 = ultimo endereço da Memoria VGA, saia do loop
	lw t0,0(s0)		# le uma word do endereço s0 (le 4 pixels da imagem)
	sw t0,0(s1)		# escreve a word na memoria VGA no endereço s1 (desenha 4 pixels na tela do Bitmap Display)
	addi s1,s1,4		# soma 4 ao endereço s1 
	addi s0,s0,4		# soma 4 ao endereço s0
	j LOOPM			# volta a verificar a condição do loop
	
# Inicia o loop da musica do menu principal
	
SONG:	la s0,NOTAS     	# s0 = endereço das notas da melodia principal (notas)

    	la t0,NUM       	# t0 = endereço que contem o numero de notas da melodia principal 
    	lw s1,0(t0)     	# s1 = numero de notas da melodia principal
    	
    	la s2,NOTAS2    	# s0 = endereço das notas da melodia acompanhamento (notas2)

    	li a2,32        	# a2 = instrumento de notas
    	li a4,128      		# a4 = instrumento de notas2 
    	li a3,70       		# a3 = volume da musica do jogo
    	
    	li s3,0	     		# s3 = 0 (s3 será utilizado como um contador para que uma nota de "notas2" seja tocada a cada 4 notas de "notas")
    	li s7,0			# s7 = 0 (zera o contador de notas tocadas da melodia principal)

# Toca uma nota de "notas2"

DOIS:	lw a0,0(s2)     	# a0 = nota de "notas2" a ser tocada 
    	lw a1,4(s2)     	# a1 = duração da nota a ser tocada
    	li a7,31        	# a7 = 31 (numero do syscall "MidiOut")
    	ecall            	# realiza o ecall (toca a nota)
    
   	li s3,0	     		# zera o contador s3
   	addi s2,s2,8   		# s2 = s2 + 8 (s2 = endereço da proxima nota de "notas2")
   	
# Verifica se uma tecla foi pressionada para o encerramento do loop da musica do menu

LOOP:   li t2,0xFF200000	# carrega o endereço de controle do KDMMIO ("teclado")
	lw t0,0(t2)		# le uma word a partir do endereço de controle do KDMMIO
	andi t0,t0,0x0001	# mascara todos os bits de t0 com exceçao do bit menos significativo
   	bne t0,zero,PRSKEY   	# se o BMS de t0 não for 0 (há tecla pressionada), pule para PRSKEY (tecla pressionada)
   	
# Se nenhuma tecla foi pressionada, verifica se deve tocar mais uma nota ou se deve reiniciar o loop da musica
	
	beq s7,s1,SONG		# se s7 = s1 (se todas as notas da melodia principal tiverem sido tocadas), vá para SONG (reinicia o loop da musica)
	
	li t0,4			# t0 = 4
 	beq t0,s3,DOIS    	# se s3 = 4 (se 4 notas de "notas" tiverem sido tocadas), vá para DOIS (toca uma nota de "notas2")
    
# Toca uma nota de "notas"

    	lw a0,0(s0)        	# a0 = nota de "notas" a ser tocada 
   	lw a1,4(s0)        	# a1 = duração da nota a ser tocada
   	li a7,31           	# a7 = 31 (numero do syscall "MidiOut")
    	ecall               	# realiza o ecall (toca a nota)

# Pausa pela duração da nota da melodia principal

    	addi a1,a1,-5	    	# reduz o tempo de pausa em 5ms pra evitar pausa abrupta nas notas
   	mv a0,a1           	# a0 = a1 (move o tempo de pausa para a0)
  	li a7,32           	# a7 = 32 (numero do syscall "Sleep")
   	ecall               	# realiza o ecall (pausa o programa por a0ms)
	
   	addi s0,s0,8      	# s0 = s0 + 8 (s0 = endereço da proxima nota de "notas")
   	
   	addi s3,s3,1      	# incrementa 1 no contador s3
   	addi s7,s7,1		# incrementa 1 no contador s7
   	 
   	j LOOP		    	# pule para LOOP
   	
# Toca efeito sonoro de tecla pressionada no menu
   	
PRSKEY:	li a0,100		# a0 = 100 (define 100 ms para pausa)
	li a7,32		# a7 = 32 (carrega em a7 o ecall "Sleep")
	ecall			# realiza o ecall (faz uma pausa de 100 ms no programa)
	
	li a0,73		# a0 = 73 (carrega re bemol para a0)
	li a1,200		# a1 = 200 (nota de duração de 200 ms)
	li a2,82		# a2 = 82 (timbre "ocarina")
	li a3,50		# a3 = 50 (volume da nota)
	li a7,31		# a7 = 31 (carrega em a7 o ecall "MidiOut")
	ecall			# realiza o ecall
	
	li a0,85		# a0 = 85 (carrega re bemol para a0)
	li a1,200		# a1 = 200 (nota de duração de 200 ms)
	li a2,82		# a2 = 82 (timbre "ocarina")
	li a3,50		# a3 = 50 (volume da nota)
	li a7,31		# a7 = 31 (carrega em a7 o ecall "MidiOut")
	ecall			# realiza o ecall
	
	li a0,100		# a0 = 100 (define 100 ms para pausa - tempo das notas)
	li a7,32		# a7 = 32 (carrega em a7 o ecall "Sleep")
	ecall			# realiza o ecall (faz uma pausa de 100 ms no programa)
	
	li a0,71		# a0 = 71 (carrega si para a0)
	li a1,200		# a1 = 200 (nota de duração de 200 ms)
	li a2,82		# a2 = 82 (timbre "ocarina")
	li a3,50		# a3 = 50 (volume da nota)
	li a7,31		# a7 = 31 (carrega em a7 o ecall "MidiOut")
	ecall			# realiza o ecall
	
	li a0,83		# a0 = 83 (carrega si para a0)
	li a1,200		# a1 = 200 (nota de duração de 200 ms)
	li a2,82		# a2 = 82 (timbre "ocarina")
	li a3,50		# a3 = 50 (volume da nota)
	li a7,31		# a7 = 31 (carrega em a7 o ecall "MidiOut")
	ecall			# realiza o ecall
	
	li a0,100		# a0 = 100 (define 100 ms para pausa - tempo das notas)
	li a7,32		# a7 = 32 (carrega em a7 o ecall "Sleep")
	ecall			# realiza o ecall (faz uma pausa de 100 ms no programa)
	
	li a0,73		# a0 = 73 (carrega re bemol para a0)
	li a1,400		# a1 = 400 (nota de duração de 400 ms)
	li a2,82		# a2 = 82 (timbre "ocarina")
	li a3,50		# a3 = 50 (volume da nota)
	li a7,31		# a7 = 31 (carrega em a7 o ecall "MidiOut")
	ecall			# realiza o ecall
	
	li a0,85		# a0 = 85 (carrega re bemol para a0)
	li a1,400		# a1 = 400 (nota de duração de 400 ms)
	li a2,82		# a2 = 82 (timbre "ocarina")
	li a3,50		# a3 = 50 (volume da nota)
	li a7,31		# a7 = 31 (carrega em a7 o ecall "MidiOut")
	ecall			# realiza o ecall
	
	li a0,400		# a0 = 400 (define 400 ms para pausa)
	li a7,32		# a7 = 32 (carrega em a7 o ecall "Sleep")
	ecall			# realiza o ecall (faz uma pausa de 400 ms no programa)
	
################################
#####  INICIO DO PROGRAMA  #####
#####	       ***  	   #####
##### ANIMAÇÃO APOS O MENU #####
################################

# OBS: Se voce estiver estudando o codigo, esse trecho da animação ficou bem desorganizado e com comentarios defasados. Como esse trecho eh somente uma
# animação que não influencia outras partes do codigo, apenas pule o estudo dessa parte do codigo
	
# Pinta a tela de preto

	li s1,0xFF000000	# s1 = endereco inicial da Memoria VGA - Frame 0
	li s2,0xFF012C00	# s2 = endereco final da Memoria VGA - Frame 0
	
TELAPRETA:
	beq s1,s2,ANIMATION_1	# se s1 = ultimo endereço da Memoria VGA, vá para ANIMATION_1
	sw zero,0(s1)		# escreve a word na memoria VGA no endereço s1 (desenha 4 pixels pretos na tela do Bitmap Display)
	addi s1,s1,4		# soma 4 ao endereço s1
	j TELAPRETA		# volta a verificar a condiçao do loop
	
# Mostra uma animação dos personagens do jogo na tela (Robozinho sendo perseguido entrando na tela)
	
ANIMATION_1:

	li s11,0		# s11 = 0 (zera o contador de paridade)
	li s1,0xFF00E5F0 	# ultimo pixel da linha 120 - 16 (64 linhas abaixo para fins de print) 
	li s2,0xFF00E600	# ultimo pixel da linha 120 (64 linhas abaixo para fins de print) 
	
RESET_ANI_1:

	sub s7,s2,s1		# s7 = s2 - s1 (guarda em s7 o offset entre o endereço s1 e o ultimo endereço da linha 120)
	li t0,320		# t0 = 320
	sub s7,t0,s7		# guarda em s7 a quantidade de pixels que tem que pular na imagem a ser printada
	
	li t2,20480		# t2 = 20480 (valor de 64 quebras de linha)
	sub s1,s1,t2		# volta t1 64 linhas
	mv t2,s1 		# t2 = s1
	addi t2,t2,320		 
	sub t2,t2,s7		# t2 = t2 + (320 - s7) -> (t2 = s1 + offset entre o endereço s1 e o ultimo endereço da linha 120) 
	
	li t4,2			# t4 = 2 (para verificar a paridade de s11)
	rem t3,s11,t4		# t3 = resto da divisão inteira s11/2
	
	beq t3,zero,PAR_ANI_1	# se t3 = 0, vá para PAR_ANI_1 (se s11 for par, imprime o inimigos1g, se for impar, imprime inimigos2g)
	
	li a0,34		# a0 = 40 (carrega mi para a0)
	li a1,100		# a1 = 100 (nota de duração de 100 ms)
	li a2,33		# a2 = 33 (timbre "acoustic bass")
	li a3,90		# a3 = 90 (volume da nota)
	li a7,31		# a7 = 31 (carrega em a7 o ecall "MidiOut")
	ecall			# realiza o ecall
	
	la t3,inimigos2g	# t3 = endereço dos dados de inimigos2g (Robozinho2 perseguido por aliens)
	j NEXT_ANI_1		# pula para NEXT_ANI_1
	
PAR_ANI_1:
	li a0,40		# a0 = 40 (carrega mi para a0)
	li a1,100		# a1 = 100 (nota de duração de 100 ms)
	li a2,33		# a2 = 33 (timbre "acoustic bass")
	li a3,90		# a3 = 90 (volume da nota)
	li a7,31		# a7 = 31 (carrega em a7 o ecall "MidiOut")
	ecall			# realiza o ecall
	
	la t3,inimigos1g	# t3 = endereço dos dados do inimigos1g (Robozinho1 perseguido por aliens)
	
NEXT_ANI_1:	
	addi t3,t3,8		# t3 = endereço do primeiro pixel da imagem (depois das informações de nlin ncol)

	li t5,0
	li t6,64		# reinicia contador para 64 quebras de linha	
	
LOOP_ANI_1: 	
	beq s1,t2,ENTER_ANI_1	# se s1 atingir o fim da linha de pixels, quebre linha
	lw t0,0(t3)		# le uma word do endereço t3 (le 4 pixels da imagem)
	sw t0,0(s1)		# escreve a word na memoria VGA no endereço s1 (desenha 4 pixels na tela do Bitmap Display)
	addi s1,s1,4		# soma 4 ao endereço s1
	addi t3,t3,4		# soma 4 ao endereço t3
	j LOOP_ANI_1		# volta a verificar a condiçao do loop
	
ENTER_ANI_1:
	add s1,s1,s7		# s1 pula para o pixel inicial da linha de baixo - offset entre s1 e s2
	addi t2,t2,320		# t2 pula para o pixel final da linha de baixo
	addi t5,t5,1            # atualiza o contador de quebras de linha
	beq t5,t6,FIM_FRAME_1	# termine o carregamento do frame se 64 quebras de linha ocorrerem
	add t3,t3,s7		# adiciona em t3 a quantidade de pixels a serem pulados da imagem
	j LOOP_ANI_1		# pula para LOOP_ANI_1
	
FIM_FRAME_1: 

	addi s1,s1,-16 		# subtrai 16 de s1 (proximo frame será printado 16 pixels a esquerda)
	addi s11,s11,1		# incrementa s11 

	li a7,32		# a7 = 32 (numero do ecall "Sleep")
	li a0, 80		# a0 = 80 (determina pausa de 80 ms)
	ecall			# realiza o ecall
	
	li t0,0			# t0 = 0
	beq s7,t0,ANIMATION_OUT	# se s7 = 0 (o frame contendo a imagem inteira foi printad0), vá para ANIMATION_OUT
	j RESET_ANI_1		# se não, reseta a animação e printa mais um frame
	
# Mostra uma animação dos personagens do jogo na tela (Robozinho sendo perseguido saindo da tela)

ANIMATION_OUT:

	li s1,0xFF00E5F0 	# ultimo pixel da linha 120 - 16 (64 linhas abaixo para fins de print)
	li s2,0xFF00E600	# ultimo pixel da linha 120 (64 linhas abaixo para fins de print)
	mv t1,s1		# t1 = s1

DELETEANIM_1:

	li t5,0	
	li t6,64		# reinicia o contador para 64 quebras de linha
	
	li t4,20480		# t4 = 20480 (valor de 64 quebras de linha)
	sub t1,t1,t4		# volta t1 64 linhas (pixel inicial da primeira linha)
	mv t2,t1 		# t2 = t1	
	addi t2,t2,16		# t2 = t1 + 16 (pixel final da primeira linha)
	
DELLOOP_ANI_1:

	beq t1,t2,ENTER_DANI_1	# se t1 atingir o fim da linha de pixels, quebre linha
	sw zero,0(t1)		# escreve o byte (pixel preto\invisivel) na memoria VGA
	addi t1,t1,4		# soma 1 ao endereço t1
	j DELLOOP_ANI_1		# volta a verificar a condiçao do loop
	
ENTER_DANI_1:	
	addi t1,t1,304		# t1 pula para o pixel inicial da linha de baixo na memoria VGA
	addi t2,t2,320		# t2 pula para o pixel final da linha de baixo na memoria VGA
	addi t5,t5,1          	# atualiza o contador de quebras de linha
	beq t5,t6,RESET_OANI_1	# termina o carregamento da imagem se 16 quebras de linha ocorrerem
	j DELLOOP_ANI_1		# pula para delloop

############# 
	
RESET_OANI_1:

	mv s1,t1		# s1 = t1 (pixel do print anterior)
	sub s7,s2,s1		# guarda em s7 a quantidade de pixels que tem que pular da imagem inicial
	li t0,320		# t0 = 320
	sub t4,t0,s7		# t4 = 320 - s7 (offset entre s1 e t2)
	sub s1,s1,t4		# volta s1 de acordo com o offset 		

	li t2,20480		# valor de 64 quebras de linha
	sub s1,s1,t2		# volta s1 64 linhas
	sub t2,s2,t2 		# t2 = s2 64 linhas acima
	sub t2,t2,s7		# t2 = s2 - s7 
	
	li t4,2			# t4 = 2 (para verificar a paridade de s0)
	rem t3,s11,t4		# t3 = resto da divisão inteira s0/2
	
	beq t3,zero,PAR_ANI2s	# se t3 = 0, va para PAR3 (se s0 for par, imprime o Robozinho1, se for impar, imprime o Robozinho2)
	
	li a0,34		# a0 = 40 (carrega mi para a0)
	li a1,100		# a1 = 100 (nota de duração de 100 ms)
	li a2,33		# a2 = 33 (timbre "acoustic bass")
	li a3,90		# a3 = 90 (volume da nota)
	li a7,31		# a7 = 31 (carrega em a7 o ecall "MidiOut")
	ecall			# realiza o ecall
	
	la t3,inimigos2g	# t3 = endereço dos dados do Robozinho2 (boca aberta)
	j NEXT_ANI2s			# pula para NEXT3
	
PAR_ANI2s:
	li a0,40		# a0 = 40 (carrega mi para a0)
	li a1,100		# a1 = 100 (nota de duração de 100 ms)
	li a2,33		# a2 = 33 (timbre "acoustic bass")
	li a3,90		# a3 = 90 (volume da nota)
	li a7,31		# a7 = 31 (carrega em a7 o ecall "MidiOut")
	ecall			# realiza o ecall
	
	la t3,inimigos1g	# t3 = endereço dos dados do Robozinho1 (boca fechada)
	
NEXT_ANI2s:	
	addi t3,t3,8		# t3 = endereço do primeiro pixel da imagem (depois das informações de nlin ncol)
	add t3,t3,s7
	
	li t5,0
	li t6,64		# reinicia contador para 16 quebras de linha	
	
LOOP_ANI2s: 	
	beq s1,t2,ENTER_ANI2s	# se t1 atingir o fim da linha de pixels, quebre linha
	lw t0,0(t3)		# le uma word do endereço t3 (le 4 pixels da imagem)
	sw t0,0(s1)		# escreve a word na memoria VGA no endereço t1 (desenha 4 pixels na tela do Bitmap Display)
	addi s1,s1,4		# soma 4 ao endereço t1
	addi t3,t3,4		# soma 4 ao endereço t3
	j LOOP_ANI2s		# volta a verificar a condiçao do loop
	
ENTER_ANI2s:
	li s9,320
	li s10,320
	sub s10,s10,s7
	sub s9,s9,s10	
	add s1,s1,s9		# t1 pula para o pixel inicial da linha de baixo
	addi t2,t2,320		# t2 pula para o pixel final da linha de baixo
	addi t5,t5,1            # atualiza o contador de quebras de linha
	beq t5,t6,FIM_ROB_ANIM2s	# termine o carregamento da imagem se 16 quebras de linha ocorrerem
	add t3,t3,s7
	j LOOP_ANI2s			# pula para loop 3
	
FIM_ROB_ANIM2s:
	mv t1,s1
	li t0, 320
	sub t0,t0,s7
	add t1,t1,t0
	addi t1,t1,-16
	addi s11,s11,1

	li a7,32
	li a0, 80
	ecall
	
	li t0,320		# t0 = 320
	sub t4,t0,s7		# t4 = 320 - s7 (offset entre s1 e t2)
	beq t4,zero,ROBO_ANI	#
	j DELETEANIM_1
	
#########################################################
	
ROBO_ANI:
	li a7,32
	li a0,250
	ecall
	
	li a0,56		# a0 = 56 (carrega sol sustenido para a0)
	li a1,300		# a1 = 100 (nota de duração de 100 ms)
	li a2,35		# a2 = 35 (timbre "electric bass")
	li a3,50		# a3 = 50 (volume da nota)
	li a7,31		# a7 = 31 (carrega em a7 o ecall "MidiOut")
	ecall			# realiza o ecall
	
	li a0,59		# a0 = 59 (carrega si para a0)
	li a1,300		# a1 = 100 (nota de duração de 100 ms)
	li a2,32		# a2 = 32 (timbre "guitar harmonic")
	li a3,50		# a3 = 50 (volume da nota)
	li a7,31		# a7 = 31 (carrega em a7 o ecall "MidiOut")
	ecall			# realiza o ecall
	
	li a0,64		# a0 = 64 (carrega mi para a0)
	li a1,300		# a1 = 100 (nota de duração de 100 ms)
	li a2,32		# a2 = 32 (timbre "guitar harmonic")
	li a3,50		# a3 = 50 (volume da nota)
	li a7,31		# a7 = 31 (carrega em a7 o ecall "MidiOut")
	ecall			# realiza o ecall
	
	li a7,32
	li a0,800
	ecall
	
	li s11,0
	li s1,0xFF00E4C0 	# primeiro pixel da linha 120 da tela 64 linhas abaixo 
	li s2,0xFF00E5FF	# ultimo pixel da linha 120 da tela 64 linhas abaixo 
	li s3,0xFF00E5D0	# primeiro pixel da linha 120 da tela + 304 64 linhas abaixo
	
RESET_ROB:
	sub s7,s1,s3		# guarda em s7 a quantidade de pixels que tem que pular da imagem inicial
	bge s7,zero,CHECK2
	neg s7,s7
	j NEXT_ANIM
	
CHECK2: li s7,0
	
NEXT_ANIM:
	li t2,20480		# valor de 64 quebras de linha
	sub s1,s1,t2		# volta t1 16 linhas e vai 4 pixels pra frente (pixel inicial + 4) 
	mv t2,s1 		# t2 = t1
	addi t2,t2,320		# t2 = t2 + 16 (pixel final da primeira linha + 4)
	sub t2,t2,s7
	
	li t4,2			# t4 = 2 (para verificar a paridade de s0)
	rem t3,s11,t4		# t3 = resto da divisão inteira s0/2
	
	beq t3,zero,PAR_ANI	# se t3 = 0, va para PAR3 (se s0 for par, imprime o Robozinho1, se for impar, imprime o Robozinho2)
	
	li a0,34		# a0 = 40 (carrega mi para a0)
	li a1,100		# a1 = 100 (nota de duração de 100 ms)
	li a2,33		# a2 = 33 (timbre "acoustic bass")
	li a3,90		# a3 = 90 (volume da nota)
	li a7,31		# a7 = 31 (carrega em a7 o ecall "MidiOut")
	ecall			# realiza o ecall
	
	la t3,inimigosscared1g	# t3 = endereço dos dados do Robozinho2 (boca aberta)
	j NEXT_ANI			# pula para NEXT3
	
PAR_ANI:
	li a0,40		# a0 = 40 (carrega mi para a0)
	li a1,100		# a1 = 100 (nota de duração de 100 ms)
	li a2,33		# a2 = 33 (timbre "acoustic bass")
	li a3,90		# a3 = 90 (volume da nota)
	li a7,31		# a7 = 31 (carrega em a7 o ecall "MidiOut")
	ecall			# realiza o ecall
		
	la t3,inimigosscared2g	# t3 = endereço dos dados do Robozinho1 (boca fechada)
	
NEXT_ANI:	
	addi t3,t3,8		# t3 = endereço do primeiro pixel da imagem (depois das informações de nlin ncol)
	add t3,t3,s7

	li t5,0
	li t6,64		# reinicia contador para 16 quebras de linha	
	
LOOP_ANI: 	
	beq s1,t2,ENTER_ANI	# se t1 atingir o fim da linha de pixels, quebre linha
	lw t0,0(t3)		# le uma word do endereço t3 (le 4 pixels da imagem)
	sw t0,0(s1)		# escreve a word na memoria VGA no endereço t1 (desenha 4 pixels na tela do Bitmap Display)
	addi s1,s1,4		# soma 4 ao endereço t1
	addi t3,t3,4		# soma 4 ao endereço t3
	j LOOP_ANI		# volta a verificar a condiçao do loop
	
ENTER_ANI:
	li s9,320
	li s10,320
	sub s10,s10,s7
	sub s9,s9,s10	
	add s1,s1,s9		# t1 pula para o pixel inicial da linha de baixo
	addi t2,t2,320		# t2 pula para o pixel final da linha de baixo
	addi t5,t5,1            # atualiza o contador de quebras de linha
	beq t5,t6,FIM_ROB_ANIM	# termine o carregamento da imagem se 16 quebras de linha ocorrerem
	add t3,t3,s7
	j LOOP_ANI			# pula para loop 3
	
FIM_ROB_ANIM: 
	addi s3,s3,-16
	addi s11,s11,1

	li a7,32
	li a0, 80
	ecall
	
	li t0,0
	beq s7,t0,ROBO_OUT2
	j RESET_ROB
	
ROBO_OUT2:
	li s1,0xFF00E4C0 	# primeiro pixel da linha 120 da tela 64 + 16 linhas abaixo 
	li s2,0xFF00E600	# ultimo pixel da linha 120 da tela 64 linhas abaixo
	mv t1,s1

DELETEANIM:

	li t5,0	
	li t6,64		# reinicia o contador para 16 quebras de linha
	
	li t4,20480		# valor de 64 quebras de linha
	sub t1,t1,t4		# volta t1 16 linhas (pixel inicial da primeira linha)
	mv t2,t1 		# t2 = POS_ROBOZINHO	
	addi t2,t2,16		# t2 = POS_ROBOZINHO + 16 (pixel final da primeira linha)
	
DELLOOPANI:
	beq t1,t2,ENTER2ANI	# se t1 atingir o fim da linha de pixels, quebre linha
	sw zero,0(t1)		# escreve o byte (pixel preto\invisivel) na memoria VGA
	addi t1,t1,4		# soma 1 ao endereço t1
	j DELLOOPANI		# volta a verificar a condiçao do loop
	
ENTER2ANI:	
	addi t1,t1,304		# t1 pula para o pixel inicial da linha de baixo na memoria VGA
	addi t2,t2,320		# t2 pula para o pixel final da linha de baixo na memoria VGA
	addi t5,t5,1          	# atualiza o contador de quebras de linha
	beq t5,t6,RESET_ROB2	# termina o carregamento da imagem se 16 quebras de linha ocorrerem
	j DELLOOPANI		# pula para delloop

############# 
	
RESET_ROB2:
	mv s1,t1
	addi s1,s1,16
	sub s7,s2,s1		# guarda em s7 a quantidade de pixels que tem que pular da imagem inicial
	li t0,320
	sub s7,t0,s7
	bge s1,s2,END
	j NEXT_ANIM2
	
NEXT_ANIM2:
	li t2,20480		# valor de 64 quebras de linha
	sub s1,s1,t2		# volta t1 16 linhas e vai 4 pixels pra frente (pixel inicial + 4) 
	sub t2,s2,t2 		# t2 = t1
	
	li t4,2			# t4 = 2 (para verificar a paridade de s0)
	rem t3,s11,t4		# t3 = resto da divisão inteira s0/2
	
	beq t3,zero,PAR_ANI2	# se t3 = 0, va para PAR3 (se s0 for par, imprime o Robozinho1, se for impar, imprime o Robozinho2)
	
	li a0,34		# a0 = 40 (carrega mi para a0)
	li a1,100		# a1 = 100 (nota de duração de 100 ms)
	li a2,33		# a2 = 33 (timbre "acoustic bass")
	li a3,90		# a3 = 90 (volume da nota)
	li a7,31		# a7 = 31 (carrega em a7 o ecall "MidiOut")
	ecall			# realiza o ecall
	
	la t3,inimigosscared1g	# t3 = endereço dos dados do Robozinho2 (boca aberta)
	j NEXT_ANI2			# pula para NEXT3
	
PAR_ANI2:
	li a0,40		# a0 = 40 (carrega mi para a0)
	li a1,100		# a1 = 100 (nota de duração de 100 ms)
	li a2,33		# a2 = 33 (timbre "acoustic bass")
	li a3,90		# a3 = 90 (volume da nota)
	li a7,31		# a7 = 31 (carrega em a7 o ecall "MidiOut")
	ecall			# realiza o ecall

	la t3,inimigosscared2g	# t3 = endereço dos dados do Robozinho1 (boca fechada)
	
NEXT_ANI2:	
	addi t3,t3,8		# t3 = endereço do primeiro pixel da imagem (depois das informações de nlin ncol)

	li t5,0
	li t6,64		# reinicia contador para 16 quebras de linha	
	
LOOP_ANI2: 	
	beq s1,t2,ENTER_ANI2	# se t1 atingir o fim da linha de pixels, quebre linha
	lw t0,0(t3)		# le uma word do endereço t3 (le 4 pixels da imagem)
	sw t0,0(s1)		# escreve a word na memoria VGA no endereço t1 (desenha 4 pixels na tela do Bitmap Display)
	addi s1,s1,4		# soma 4 ao endereço t1
	addi t3,t3,4		# soma 4 ao endereço t3
	j LOOP_ANI2		# volta a verificar a condiçao do loop
	
ENTER_ANI2:
	li s9,320
	li s10,320
	sub s10,s10,s7
	sub s9,s9,s10	
	add s1,s1,s9		# t1 pula para o pixel inicial da linha de baixo
	addi t2,t2,320		# t2 pula para o pixel final da linha de baixo
	addi t5,t5,1            # atualiza o contador de quebras de linha
	beq t5,t6,FIM_ROB_ANIM2	# termine o carregamento da imagem se 16 quebras de linha ocorrerem
	add t3,t3,s7
	j LOOP_ANI2			# pula para loop 3
	
FIM_ROB_ANIM2:
	mv t1,s1
	addi s11,s11,1

	li a7,32
	li a0,80
	ecall
	
	j DELETEANIM
	
END:	li a7,32
	li a0,1000
	ecall
	
###################################
#####      INICIO DO JOGO     #####
#####	        ***           #####
##### CARREGAMENTO DE IMAGENS #####
###################################

# OBS: os registradores salvos serão utilizados de maneira arbitraria durante o carregamento de imagens e suas reais funções dentro do loop do jogo serão definidas posteriormente na label "SETUP_MAIN"
	
# Carrega a imagem1 (mapa1) no frame 0
	
IMG1:	la t4, mapa1		# t4 cerrega endereço do mapa em t4 a fim de comparaçâo
	li s1,0xFF000000	# s1 = endereco inicial da Memoria VGA - Frame 0
	li s2,0xFF012C00	# s2 = endereco final da Memoria VGA - Frame 0
	la s0,mapa1		# s0 = endereço dos dados do mapa 1
	mv t3,s0		# t3 = endereço inicial armazenado a fins de comparação
	addi s0,s0,8		# s0 = endereço do primeiro pixel da imagem (depois das informações de nlin ncol)
	
LOOP1: 	beq s1,s2,IMAGEM	# se s1 = ultimo endereço da Memoria VGA, saia do loop
	lw t0,0(s0)		# le uma word do endereço s0 (le 4 pixels da imagem)
	sw t0,0(s1)		# escreve a word na memoria VGA no endereço s1 (desenha 4 pixels na tela do Bitmap Display)
	addi s1,s1,4		# soma 4 ao endereço s1 
	addi s0,s0,4		# soma 4 ao endereço s0
	j LOOP1			# volta a verificar a condiçao do loop

# Carrega a imagem2 (Robozinho1 - imagem 16x16) no frame 0

IMG2:	li s1,0xFF00A0C8	# s1 = endereco inicial da primeira linha do Robozinho - Frame 0
	li s2,0xFF00A0D8	# s2 = endereco final da primeira linha do Robozinho (inicial +16) - Frame 0
	la s0,Robozinho1	# s0 = endereço dos dados do Robozinho1 (boca fechada)
	mv t3,s0		# t3 = endereço inicial armazenado a fins de comparação
	addi s0,s0,8		# s0 = endereço do primeiro pixel da imagem (depois das informações de nlin ncol)
	j PRINT16
	
# Carrega a imagem3 (ALIEN1 - imagem16x16)

IMG3:	li s1,0xFF0064C8	# s1 = endereco inicial da primeira linha do alien 1 - Frame 0 
	li s2,0xFF0064D8	# s2 = endereco final da primeira linha do alien 1 (inicial +16) - Frame 0      
	la s0,Inimigo1          # s0 = endereço dos dados do alien1
	mv t3,s0		# t3 = endereço inicial armazenado a fins de comparação
	addi s0,s0,8		# s0 = endereço do primeiro pixel da imagem (depois das informações de nlin ncol)
	j PRINT16
	
# Carrega a imagem4 (ALIEN2 - imagem16x16)

IMG4:	li s1,0xFF0087C8	# s1 = endereco inicial da primeira linha do alien 2 - Frame 0
	li s2,0xFF0087D8	# s2 = endereco final da primeira linha do alien 2 - Frame 0
	la s0,Inimigo2          # s0 = endereço dos dados do alien2
	mv t3,s0		# t3 = endereço inicial armazenado a fins de comparação
	addi s0,s0,8		# s0 = endereço do primeiro pixel da imagem (depois das informações de nlin ncol)
	j PRINT16

# Carrega a imagem5 (ALIEN3 - imagem16x16)

IMG5:	li s1,0xFF0087B8	# s1 = endereco inicial da primeira linha do alien 3 - Frame 0
	li s2,0xFF0087C8	# s2 = endereco final da primeira linha do alien 3 - Frame 0
	la s0,Inimigo3          # s0 = endereço dos dados do alien3
	mv t3,s0		# t3 = endereço inicial armazenado a fins de comparação
	addi s0,s0,8		# s0 = endereço do primeiro pixel da imagem (depois das informações de nlin ncol)
	j PRINT16
	
# Carrega a imagem6 (ALIEN4 - imagem16x16)

IMG6:	li s1,0xFF0087D8	# s1 = endereco inicial da primeira linha do alien 4 - Frame 0
	li s2,0xFF0087E8	# s2 = endereco final da primeira linha do alien 4 - Frame 0
	la s0, Inimigo4         # s0 = endereço dos dados do alien4 
	mv t3,s0		# t3 = endereço inicial armazenado a fins de comparação
	addi s0,s0,8		# s0 = endereço do primeiro pixel da imagem (depois das informações de nlin ncol)
	j PRINT16
	
# Carrega a imagem7 (mapa1 - colisao) no frame 1
	
IMG7:	li s1,0xFF100000	# s1 = endereco inicial da Memoria VGA - Frame 1
	li s2,0xFF112C00	# s2 = endereco final da Memoria VGA - Frame 1
	la s0,mapa1colisao	# s0 = endereço dos dados da colisao do mapa 1
	mv t3,s0		# t3 = endereço inicial armazenado a fins de comparação
	addi s0,s0,8		# s0 = endereço do primeiro pixel da imagem (depois das informações de nlin ncol)
	
LOOPCOL:beq s1,s2,IMAGEM	# se s1 = ultimo endereço da Memoria VGA, saia do loop
	lw t0,0(s0)		# le uma word do endereço s0 (le 4 pixels da imagem)
	sw t0,0(s1)		# escreve a word na memoria VGA no endereço s1 (desenha 4 pixels na tela do Bitmap Display)
	addi s1,s1,4		# soma 4 ao endereço s1 
	addi s0,s0,4		# soma 4 ao endereço s0
	j LOOPCOL		# volta a verificar a condiçao do loop
	
# Carrega a imagem8 (colisao do Robozinho - quadrado verde no frame 1)

IMG8:	li s1,0xFF10A0C8	# s1 = endereco inicial da primeira linha do Robozinho - Frame 1
	li s2,0xFF10A0D8	# s2 = endereco final da primeira linha do Robozinho - Frame 1
	li s0,0x69696969        # s0 = word contendo 4 bytes 0x69 (4 pixels de cor verde) 
	mv t3,s0		# t3 = endereço inicial armazenado a fins de comparação
	j PRINT16_Q
	
# Carrega a imagem9 (colisao do ALIEN1 - quadrado verde no frame 1)

IMG9:	li s1,0xFF1064C8	# s1 = endereco inicial da primeira linha do alien1 - Frame 1
	li s2,0xFF1064D8	# s2 = endereco final da primeira linha do alien1 - Frame 1
	li s0,0x70707070       	# s0 = word contendo 4 bytes 0x70 (4 pixels de cor verde)  
	mv t3,s0		# t3 = endereço inicial armazenado a fins de comparação
	j PRINT16_Q

# Carrega a imagem10 (colisao do ALIEN2 - quadrado verde no frame 1)

IMG10:	li s1,0xFF1087C8	# s1 = endereco inicial da primeira linha do alien2 - Frame 1
	li s2,0xFF1087D8	# s2 = endereco final da primeira linha do alien2 - Frame 1
	li s0,0x71717171        # s0 = word contendo 4 bytes 0x71 (4 pixels de cor verde)
	mv t3,s0		# t3 = endereço inicial armazenado a fins de comparação
	j PRINT16_Q

# Carrega a imagem11 (colisao do ALIEN3 - quadrado verde no frame 1)

IMG11:	li s1,0xFF1087B8	# s1 = endereco inicial da primeira linha do alien3 - Frame 1
	li s2,0xFF1087C8	# s2 = endereco final da primeira linha do alien3 - Frame 1
	li s0,0x72727272        # s0 = word contendo 4 bytes 0x72 (4 pixels de cor verde) 
	mv t3,s0		# t3 = endereço inicial armazenado a fins de comparação
	j PRINT16_Q

# Carrega a imagem12 (colisao do ALIEN4 - quadrado verde no frame 1)

IMG12:	li s1,0xFF1087D8	# s1 = endereco inicial da primeira linha do alien4 - Frame 1
	li s2,0xFF1087E8	# s2 = endereco final da primeira linha do alien4 - Frame 1
	li s0,0x73737373        # s0 = word contendo 4 bytes 0x73 (4 pixels de cor verde) 
	mv t3,s0		# t3 = endereço inicial armazenado a fins de comparação
	j PRINT16_Q
	
# Carrega a imagem13 (contador de vidas com sprite do Robozinho) no frame 0

IMG13:	li s1,0xFF011584	# s1 = endereco inicial da primeira linha do Robozinho - Frame 0
	li s2,0xFF011594	# s2 = endereco final da primeira linha do Robozinho (inicial +16) - Frame 0
	la s0,Robozinho1	# s0 = endereço dos dados do Robozinho1 (boca fechada)
	li t3,-1		# t3 = -1 a fins de comparação
	addi s0,s0,8		# s0 = endereço do primeiro pixel da imagem (depois das informações de nlin ncol)
	j PRINT16
	
# Carrega a imagem14 (contador de vidas com sprite do Robozinho) no frame 0

IMG14:	li s1,0xFF011598	# s1 = endereco inicial da primeira linha do Robozinho - Frame 0
	li s2,0xFF0115A8	# s2 = endereco final da primeira linha do Robozinho (inicial +16) - Frame 0
	la s0,Robozinho1	# s0 = endereço dos dados do Robozinho1 (boca fechada)
	li t3,-2		# t3 = -2 a fins de comparação
	addi s0,s0,8		# s0 = endereço do primeiro pixel da imagem (depois das informações de nlin ncol)
	j PRINT16

# Carrega a imagem15 (contador de vidas com sprite do Robozinho) no frame 0
		
IMG15:	li s1,0xFF0115AC	# s1 = endereco inicial da primeira linha do Robozinho - Frame 0
	li s2,0xFF0115BC	# s2 = endereco final da primeira linha do Robozinho (inicial +16) - Frame 0
	la s0,Robozinho1	# s0 = endereço dos dados do Robozinho1 (boca fechada)
	li t3,-3		# t3 = -3 a fins de comparação
	addi s0,s0,8		# s0 = endereço do primeiro pixel da imagem (depois das informações de nlin ncol)
	j PRINT16
	
# Compara os endereços para ver qual a proxima imagem a ser printada

IMAGEM: beq t3,t4,IMG2 		# se t3 contiver o endereço "mapa1", vá para IMG2 (imprime a imagem2)
	
	la t4,Robozinho1	# t4 = endereço dos dados do Robozinho1
	beq t3,t4,IMG3		# se t3 contiver o endereço "Robozinho1", vá para IMG3 (imprime a imagem3)
	
	la t4,Inimigo1		# t4 = endereço dos dados do alien 1
	beq t3,t4,IMG4		# se t3 contiver o endereço "Inimigo1", vá para IMG4 (imprime a imagem4)
	
	la t4,Inimigo2		# t4 = endereço dos dados do alien 2
	beq t3,t4,IMG5		# se t3 contiver o endereço "Inimigo2", vá para IMG5 (imprime a imagem5)
	
	la t4,Inimigo3		# t4 = endereço dos dados do alien 3
	beq t3,t4,IMG6		# se t3 contiver o endereço "Inimigo3", vá para IMG6 (imprime a imagem6)
	
	la t4,Inimigo4		# t4 = endereço dos dados do alien 4
	beq t3,t4,IMG7		# se t3 contiver o endereço "Inimigo4", vá para IMG7 (imprime a imagem7)
	
	la t4,mapa1colisao	# t4 = endereço dos dados do mapa de colisao 1
	beq t3,t4,IMG8		# se t3 contiver o endereço "mapa1colisao", vá para IMG8 (imprime a imagem8)
	
	li t4,0x69696969	# t4 = 0x69696969
	beq t3,t4,IMG9		# se t3 = 0x69696969, vá para IMG9 (imprime a imagem9)
	
	li t4,0x70707070	# t4 = 0x70707070
	beq t3,t4,IMG10		# se t3 = 0x70707070, vá para IMG10 (imprime a imagem10)
	
	li t4,0x71717171	# t4 = 0x71717171
	beq t3,t4,IMG11		# se t3 = 0x71717171, vá para IMG11 (imprime a imagem11)
	
	li t4,0x72727272	# t4 = 0x72727272
	beq t3,t4,IMG12		# se t3 = 0x72727272, vá para IMG12 (imprime a imagem12)
	
	li t4,0x73737373	# t4 = 0x73737373
	beq t3,t4,IMG13		# se t3 = 0x73737373, vá para IMG13 (imprime a imagem13)
	
	li t4,-1		# t4 = -1
	beq t3,t4,IMG14		# se t3 = -1, vá para IMG14 (imprime a imagem14)
	
	li t4,-2		# t4 = -2
	beq t3,t4,IMG15		# se t3 = -2, vá para IMG15 (imprime a imagem15)
	
	li t4,-3		# t4 = -3
	beq t3,t4,SETUP_MAIN	# se t3 = -3, vá para SETUP_MAIN 
	
# Loop que imprime imagens 16x16

PRINT16:li t1,0
	li t2,16		#inicializa o contador de quebra de linha para 16 quebras de linha
	
LOOP2: 	beq s1,s2,ENTER		# se s1 atingir o fim da linha de pixels, quebre linha
	lw t0,0(s0)		# le uma word do endereço s0 (le 4 pixels da imagem)
	sw t0,0(s1)		# escreve a word na memoria VGA no endereço s1 (desenha 4 pixels na tela do Bitmap Display)
	addi s1,s1,4		# soma 4 ao endereço s1
	addi s0,s0,4		# soma 4 ao endereço s0
	j LOOP2 		# volta a verificar a condiçao do loop
	
ENTER:	addi s1,s1,304		# s1 pula para o pixel inicial da linha de baixo
	addi s2,s2,320		# s2 pula para o pixel final da linha de baixo
	addi t1,t1,1          	# atualiza o contador de quebras de linha
	beq t1,t2,IMAGEM	# termina o carregamento da imagem se 16 quebras de linha ocorrerem
	j LOOP2	
	
# Loop que imprime quadrados verdes 16x16 no frame 1

PRINT16_Q:
	li t1,0
	li t2,16		#inicializa o contador de quebra de linha para 16 quebras de linha
	
LOOP2Q: beq s1,s2,ENTERQ	# se s1 atingir o fim da linha de pixels, quebre linha
	sw s0,0(s1)		# escreve a word na memoria VGA no endereço s1 (desenha 4 pixels verdes na tela do Bitmap Display)
	addi s1,s1,4		# soma 4 ao endereço s1
	j LOOP2Q 		# volta a verificar a condiçao do loop
	
ENTERQ:	addi s1,s1,304		# s1 pula para o pixel inicial da linha de baixo
	addi s2,s2,320		# s2 pula para o pixel final da linha de baixo
	addi t1,t1,1          	# atualiza o contador de quebras de linha
	beq t1,t2,IMAGEM	# termina o carregamento da imagem se 16 quebras de linha ocorrerem
	j LOOP2Q
	
# Setup dos dados necessarios para o main loop

SETUP_MAIN:

	li s0,2			# s0 = 0 (zera o contador de movimentações do Robozinho)
	li s1,0			# s1 = 0 (zera o contador de pontos coletados)
	li s2,3			# s2 = 3 (inicializa o contador de vidas do Robozinho com 3)
	li s3,0			# s3 = 0 (zera o estado de movimentação atual do Robozinho)
	li s4,0			# s4 = 0 (zera o verificador de aliens)
	li s5,0			# s5 = 0 (zera o estado de persrguição dos aliens)
	li s6,1			# s6 = 1 (fase 1)
	li s7,17		# s7 = 17 (zera o estado de movimentação atual do inimigo1 : scatter_mode)
#	li s8,			# pode ser alterado pelo "SYSTEMv24.s", e por isso não sera utilizado no codigo como reg salvo
	li s9,17		# s9 = 17 (zera o estado de movimentação atual do inmimigo2 : scatter_mode)
	li s10,17 		# s10 = 17 (zera o estado de movimentação atual do inimigo3 : scatter_mode)
	li s11,17 		# s11 = 17 (zera o estado de movimentação atual do inimigo4 : scatter_mode)
	
##################################
#####     INICIO DO JOGO     #####
#####	        ***          #####
##### LOOP PRINCIPAL DO JOGO #####
##################################

#
# INFOS GERAIS:
#
# - o loop possui uma divisão principal em duas partes: a primeira lida com a movimentação/colisão dos aliens e a segunda com a do Robozinho
#
# - os aliens possuem 3 modos: scatter (espalha os aliens pelo mapa, cada um em um canto do labirinto), chase (os aliens perseguem o Robozinho de variadas formas) e frightened (assustado, movimento aleatorio)
#
# - a posição dos aliens e do Robozinho eh convencionada como o endereço do pixel de posição, que eh o pixel imediatamente abaixo da primeira coluna da imagem 16x16
#
# - a movimentação dos aliens eh baseada em perseguição de um "target" (pixel da tela). Eles calculam a menor distancia do pixel de posição ate o target e seguem esse caminho ate alcança-lo
#
# - a movimentação atual do alien (up = 0; left = 1; down = 2; right = 3) eh determinada pelo resto da divisão por 17 dos registradores s7, s9, s10 e s11
# - os modos de perseguição dos aliens (scatter = 1; chase = 2; frightened = 3) são determinados pelo quociente da divisão inteira por 17 dos registradores s7, s9, s10 e s11
# - ou seja, supondo que s10 = 20, temos que "s10%7 = 3" e "s10/17 = 1". Isso significa que o alien 3 (alien controlado pelo registrador s10) está com movimentação atual 3 (direita) e modo 1 (scatter)
#
# - em geral, os aliens não podem "virar 180 graus" (ex: se estiver indo para a esquerda, não pode virar para a direita; se for pra cima, não pode ir para baixo etc)
# - as unicas hipoteses em que esse tipo de movimentação acontece são quando os aliens entram em frightened mode ou quando a unica opção de movimentação disponivel eh virar 180 graus
#
# - formula base para calculo de coordenadas x e y: (endereço - 0xFF000000)/320 = linha(y), (endereço - 0xFF000000)%320 = coluna(x)
#
# - formula base para calculo da distancia ate o target (distancia de manhattan): (|x_alien - x_target|) + (|y_alien - y_target|)
#

MAINL:
	
# Setup dos dados do alien verde claro (blinky)

BLINKY:	li s4,1			# s4 = 1 (salva em s4 a informação de qual alien esta sendo movimentado)

	la t0,POS_BLINKY	# carrega o endereço de "POS_BLINKY" no registrador t0
	lw t1,0(t0)		# le a word guardada em "POS_BLINKY" para t1 (t1 = posição atual do Blinky)
	
	li t3,0xFF000000	# t3 = endereço base do Bitmap Display 
	li t4,320		# t4 = numero de colunas da tela
	
	sub t1,t1,t3		# subtrai de t1 o endereço base
	mv t2,t1		# carrega em t2 o valor de t1 (posição do alien sem o endereço base)
	rem t1,t1,t4		# t1 = posição x do alien (coluna do pixel de posição)
	div t2,t2,t4		# t2 = posição y do alien (linha do pixel de posição)
	
	mv a0,t1		# a0 = t1 (parametro da funçao CALCULO_TARGET)
	mv a1,t2		# a1 = t2 (parametro da funçao CALCULO_TARGET)
	mv a2,s7		# a2 = s7 (parametro da funçao CALCULO_TARGET)
	
	j CALCULO_TARGET 	# Pula para CALCULO_TARGET
	
# Setup dos dados do alien azul (pink)

PINK:	li s4,2			# s4 = 2 (salva em s4 a informação de qual alien esta sendo movimentado)

	la t0,POS_PINK		# carrega o endereço de "POS_PINK" no registrador t0
	lw t1,0(t0)		# le a word guardada em "POS_PINK" para t1 (t1 = posição atual do Pink)
	
	li t3,0xFF000000	# t3 = endereço base do Bitmap Display 
	li t4,320		# t4 = numero de colunas da tela
	
	sub t1,t1,t3		# subtrai de t1 o endereço base
	mv t2,t1		# carrega em t2 o valor de t1 (posição do alien sem o endereço base)
	rem t1,t1,t4		# t1 = posição x do alien (coluna do pixel de posição)
	div t2,t2,t4		# t2 = posição y do alien (linha do pixel de posição)
	
	mv a0,t1		# a0 = t1 (parametro da funçao CALCULO_TARGET)
	mv a1,t2		# a1 = t2 (parametro da funçao CALCULO_TARGET)
	mv a2,s9		# a2 = s7 (parametro da funçao CALCULO_TARGET)
	
	j CALCULO_TARGET 	# Pula para CALCULO_TARGET
	
# Setup dos dados do alien roxo (inky)

INKY:	li s4,3			# s4 = 3 (salva em s4 a informação de qual alien esta sendo movimentado)

	la t0,POS_INKY		# carrega o endereço de "POS_INKY" no registrador t0
	lw t1,0(t0)		# le a word guardada em "POS_INKY" para t1 (t1 = posição atual do Inky)
	
	li t3,0xFF000000	# t3 = endereço base do Bitmap Display 
	li t4,320		# t4 = numero de colunas da tela
	
	sub t1,t1,t3		# subtrai de t1 o endereço base
	mv t2,t1		# carrega em t2 o valor de t1 (posição do alien sem o endereço base)
	rem t1,t1,t4		# t1 = posição x do alien (coluna do pixel de posição)
	div t2,t2,t4		# t2 = posição y do alien (linha do pixel de posição)
	
	mv a0,t1		# a0 = t1 (parametro da funçao CALCULO_TARGET)
	mv a1,t2		# a1 = t2 (parametro da funçao CALCULO_TARGET)
	mv a2,s10		# a2 = s7 (parametro da funçao CALCULO_TARGET)
	
	
	j CALCULO_TARGET 	# Pula para CALCULO_TARGET
	
# Setup dos dados do alien laranja (clyde)

CLYDE:	li s4,4			# s4 = 4 (salva em s4 a informação de qual alien esta sendo movimentado)

	la t0,POS_CLYDE		# carrega o endereço de "POS_CLYDE" no registrador t0
	lw t1,0(t0)		# le a word guardada em "POS_CLYDE" para t1 (t1 = posição atual do Clyde)
	
	li t3,0xFF000000	# t3 = endereço base do Bitmap Display 
	li t4,320		# t4 = numero de colunas da tela
	
	sub t1,t1,t3		# subtrai de t1 o endereço base
	mv t2,t1		# carrega em t2 o valor de t1 (posição do alien sem o endereço base)
	rem t1,t1,t4		# t1 = posição x do alien (coluna do pixel de posição)
	div t2,t2,t4		# t2 = posição y do alien (linha do pixel de posição)
	
	mv a0,t1		# a0 = t1 (parametro da funçao CALCULO_TARGET)
	mv a1,t2		# a1 = t2 (parametro da funçao CALCULO_TARGET)
	mv a2,s11		# a2 = s7 (parametro da funçao CALCULO_TARGET)
	
	j CALCULO_TARGET 	# pula para CALCULO_TARGET
	
# Função que define o target a depender do estado do alien, ou seja, função que determina qual pixel da tela o alien deve perseguir
# Calculo de distancia ate o target (distancia de manhattan): (|x_alien - x_target|) + (|y_alien - y_target|)

# dependendo do estado do jogo o alien vai para o scatter (sX < 21 ou sX/17 = 1), chase (sX < 38 ou sX/17 = 2), ou frightened mode (sX < 55 ou sX/17 = 3)

CALCULO_TARGET:

	li t0,179		 	# t0 = 179
	rem t1,s0,t0			# t1 = s0%179
	beq t1,zero,TROCAR_MODO  	# se t1 = 0 (se a quantidade de movimentações do Robozinho atingir um multiplo de 179), troca o modo. Se não, continua a execução do modo atual
	
	li t0,21		 	# t0 = 21
	blt a2,t0,SCATTER_MODE 		# se a2(sX) < 21, o alien esta no scatter mode
	li t0, 38			# t0 = 38
	blt a2,t0,CHASE_MODE	 	# se não, se a2(sX) < 38, o alien esta no chase mode
	li t0, 55			# t0 = 55
	blt a2,t0,FRIGHTENED_VERIF	# se não, se a2(sX) < 55, o alien esta no frightened mode
	
# Troca o modo de movimentação do alien
	
TROCAR_MODO:

	li t0,21		 	# t0 = 21
	blt a2,t0,CHASE_MODE   		# se o alien esta no scatter mode, muda para o chase mode
	li t0,38			# t0 = 38
	blt a2,t0,SCATTER_MODE 		# se o alien esta no chase mode, muda para o scatter mode
	li t0,58			# t0 = 58
	blt a2,t0,FRIGHTENED_VERIF    	# se o alien esta no frightened, não muda o modo
	
# Se o alien esta no frightened mode, verifica se o tempo de duração do modo acabou
	
FRIGHTENED_VERIF:

	la t0,CONTADOR_ASSUSTADO	# carrega o valor de "CONTADOR_ASSUSTADO" no registrador t0	
	lw t1,0(t0)			# le a word guardada em "CONTADOR_ASSUSTADO" para t1 (t1 = contador do tempo no frightened mode)
	
	li t2,400			# t2 = 400 (seta para o modo durar cerca de 8 segundos)
	blt t1,t2,FRIGHTENED_MODE	# se t1 < 400 (se o tempo em "CONTADOR_ASSUSTADO" não tiver atingido 400), continua no frightened mode
	
	li t1,-1			# t1 = -1
	sw t1,0(t0)			# se o tempo tiver acabado, reseta o "CONTADOR_ASSUSTADO" para -1 e muda o modo de todos os aliens para o chase mode
	
	li t0,17			# t0 = 17
	rem t1,s7,t0			# t1 = s7%17 (salva em t1 o resto da divisão de s7 por 17 - movimentação atual do alien)
	li s7,34			# s7 = 34 (17 * 2 = valor base do chase mode)
	add s7,s7,t1			# adiciona em s7 o resto salvo em t1 (movimentação atual do alien)
	
	rem t1,s9,t0			# t1 = s9%17 (salva em t1 o resto da divisão de s9 por 17 - movimentação atual do alien)
	li s9,34			# s9 = 34 (17 * 2 = valor base do chase mode)
	add s9,s9,t1			# adiciona em s9 o resto salvo em t1 (movimentação atual do alien)
	
	rem t1,s10,t0			# t1 = s10%17 (salva em t1 o resto da divisão de s10 por 17 - movimentação atual do alien)
	li s10,34			# s10 = 34 (17 * 2 = valor base do chase mode)
	add s10,s10,t1			# adiciona em s10 o resto salvo em t1 (movimentação atual do alien)
	
	rem t1,s11,t0			# t1 = s11%17 (salva em t1 o resto da divisão de s11 por 17 - movimentação atual do alien)
	li s11,34			# s11 = 34 (17 * 2 = valor base do chase mode)
	add s11,s11,t1			# adiciona em s11 o resto salvo em t1 (movimentação atual do alien)
	
	li s0,2				# reseta o contador s0 para a temporização do chase mode
	
	j CHASE_MODE			# volta para o chase mode
	
# Inicia o scatter mode e verifica qual e o alien a ser movimentado

SCATTER_MODE: 

	li t0,1				# t0 = 1
	beq s4,t0,BLINKY_SCATTER	# se s4 = 1, então vai para BLINKY_SCATTER
	
	li t0,2				# t0 = 2
	beq s4,t0,PINK_SCATTER		# se s4 = 2, então vai para PINK_SCATTER
	
	li t0,3				# t0 = 3
	beq s4,t0,INKY_SCATTER		# se s4 = 3, então vai para INKY_SCATTER 
	
	li t0,4				# t0 = 4
	beq s4,t0,CLYDE_SCATTER		# se s4 = 4, então vai para CLYDE_SCATTER
	
# Inicia o chase mode e verifica qual e o alien a ser movimentado
	
CHASE_MODE: 

	li t0,1				# t0 = 1
	beq s4,t0,BLINKY_CHASE		# se s4 = 1, então vai para BLINKY_CHASE
	
	li t0,2				# t0 = 2
	beq s4,t0,PINK_CHASE		# se s4 = 2, então vai para PINK_CHASE
	
	li t0,3				# t0 = 3
	beq s4,t0,INKY_CHASE		# se s4 = 3, então vai para INKY_CHASE
	
	li t0,4				# t0 = 4
	beq s4,t0,CLYDE_CHASE		# se s4 = 4, então vai para CLYDE_CHASE
	
# Inicia o frightened mode e verifica qual e o alien a ser movimentado

FRIGHTENED_MODE:
		
	addi t1,t1,1			# adiciona 1 ao contador (t1 eh o registrador que contem o tempo atual do contador)
	sw t1,0(t0)			# atualiza o valor de CONTADOR_ASSUSTADO (t0 contem o endereço de "CONTADOR_ASSUSTADO")
	
	li t0,1				# t0 = 1
	beq s4,t0,BLINKY_FRIGHTENED	# se s4 = 1, então vai para BLINKY_CHASE
	
	li t0,2				# t0 = 2
	beq s4,t0,PINK_FRIGHTENED	# se s4 = 2, então vai para PINK_CHASE
	
	li t0,3				# t0 = 3
	beq s4,t0,INKY_FRIGHTENED	# se s4 = 3, então vai para INKY_CHASE
	
	li t0,4				# t0 = 4
	beq s4,t0,CLYDE_FRIGHTENED	# se s4 = 4, então vai para CLYDE_CHASE

# Inicializa os dados e o target do alien a ser movimentado (blinky)	 
	
BLINKY_SCATTER:			# target: canto superior direito
	
	li t4,0xFF00013F	# t4 = endereço do target do Blinky
	mv t6,s7		# t6 = movimentação atual do alien
	li s7,17		# s7 = 17 (volta s7 para o valor base do modo atual)
	
	la t0,POS_BLINKY	# carrega o endereço de "POS_BLINKY" no registrador t0
	lw a4,0(t0)		# le a word guardada em "POS_BLINKY" para a4 (a4 = posição atual do Blinky)
	
	la a6,Inimigo1		# a6 = label da imagem a ser impressa (parametro da função de movimentação)
	j SETUP_TARGET		# pula para SETUP_TARGET
	
BLINKY_CHASE:			# target: Robozinho
	
	la t0,POS_ROBOZINHO	# carrega o endereço de "POS_ROBOZINHO" no registrador t0
	lw t1,0(t0)		# le a word guardada em "POS_ROBOZINHO" para t1 (t1 = posição atual do Robozinho)
	
	mv t4,t1		# t4 = endereço do target do Blinky (Robozinho)	
	mv t6,s7		# t6 = movimentação atual do alien
	li s7,34		# s7 = 34 (volta s7 para o valor base do modo atual)	
	
	la t0,POS_BLINKY	# carrega o endereço de "POS_BLINKY" no registrador t0
	lw a4,0(t0)		# le a word guardada em "POS_BLINKY" para a4 (a4 = posição atual do Blinky)
	
	la a6, Inimigo1		# a6 = label da imagem a ser impressa (parametro da função de movimentação)
	j SETUP_TARGET		# pula para SETUP_TARGET
	
BLINKY_FRIGHTENED:		# target: aleatorio (exceto no primeiro movimento que inverte a direção do alien)

	la t0,POS_BLINKY	# carrega o endereço de "POS_BLINKY" no registrador t0
	lw a4,0(t0)		# le a word guardada em "POS_BLINKY" para a4 (a4 = posição atual do Blinky)
	
	mv t4,a4		# t4 = a4 (t4 = posição atual do alien. t4 será movido para a direção de movimentação desejada em funções futuras)		

	li t0,179		# t0 = 179
	rem t1,s0,t0		# t1 = s0%179
	beq t1,zero,INVERTE_B	# se esta no primeiro frame do movimento em frightened mode, va para INVERTE_B (inverte a direção do alien), se não, o alien toma uma direção pseudo-aleatoria
	
	li t0,823		# t0 = 823 (numero primo grande)
	mul t0,s0,t0		# t0 = s0*823
	li t1,4			# t1 = 4
	rem t1,t0,t1		# t1 = (s0*823)%4 (o resto guardado em t1 depende do valor de s0, que está em constante mudança, o que causa uma percepção de aleatoriedade)
	
	li t0,0			# t0 = 0 (up)
	beq t1,t0,UP_BLINKY 	# se t1 = 0, então o blinky vai pra cima
	
	addi t0,t0,1		# t0 = 1(left)
	beq t1,t0,ESQ_BLINKY  	# se t1 = 1, então o blinky vai pra esquerda
	
	addi t0,t0,1		# t0 = 2(down)
	beq t1,t0,DOWN_BLINKY   # se t1 = 2, então o blinky vai pra baixo
	
	addi t0,t0,1		# t0 = 3(right)
	beq t1,t0,DIR_BLINKY    # se t1 = 3, então o blinky vai pra direita	
	
# Inverte o movimento do alien durante o frightened mode ("vira 180 graus")

INVERTE_B:
	
	li t0, 17		# t0 = 17
	rem t1,s7,t0		# t1 = s7%17
	
	li t0,0			# t0 = 0(up)
	beq t1,t0,DOWN_BLINKY 	# se t1 = 0, blinky esta indo pra cima, logo ele inverte e vaii pra baixo (DOWN_BLINKY)
	addi t0,t0,1		# t0 = 1(left)
	beq t1,t0,DIR_BLINKY  	# se t1 = 1, blinky esta indo pra esquerda, logo ele inverte e vaii pra direita (DIR_BLINKY)
	addi t0,t0,1		# t0 = 2(down)
	beq t1,t0,UP_BLINKY   	# se t1 = 2, blinky esta indo pra baixo, logo ele inverte e vaii pra cima (UP_BLINKY)
	addi t0,t0,1		# t0 = 3(right)
	beq t1,t0,ESQ_BLINKY  	# se t1 = 3, blinky esta indo pra direita, logo ele inverte e vaii pra esquerda (ESQ_BLINKY)
	
# Move o target do alien (t4, que no caso do frightened é a propria posição do alien) para a direção de movimento escolhida

UP_BLINKY:

	li t0,5120		# t0 = 5120
	sub t4,t4,t0		# t4 = t4 - 5120 (target vai 16 linhas para cima)
	j SETUP_F_BLINKY	# pula para SETUP_F_BLINKY
	
ESQ_BLINKY:

	addi t4,t4,-16		# t4 = t4 - 16 (target vai 16 pixels para a esquerda)
	j SETUP_F_BLINKY 	# pula para SETUP_F_BLINKY
	
DOWN_BLINKY:

	li t0,5120		# t0 = 5120
	add t4,t4,t0		# t4 = t4 + 5120 (target vai 16 linhas para baixo)
	j SETUP_F_BLINKY	# pula para SETUP_F_BLINKY
	
DIR_BLINKY:

	addi t4,t4,16		# t4 = t4 + 16 (target vai 16 pixels para a direita)

# Inicializa os dados do alien para sua movimentação 

SETUP_F_BLINKY:

	la t0,CONTADOR_ASSUSTADO	# carrega o valor de "CONTADOR_ASSUSTADO" no registrador t0	
	lw t1,0(t0)			# le a word guardada em "CONTADOR_ASSUSTADO" para t1 (t1 = contador do tempo no frightened mode)
	
	li t2,350			# t2 = 350
	blt t1,t2,BLINKY_F_NORMAL	# se o valor de "CONTADOR_ASSUSTADO" for menor que 350, continua no print normal do frightened mode
	j BLINKY_F_ALTERNADO		# senão, para indicar que o tempo do modo frightened esta acabando, printa alternadamente o sprite normal do alien e o sprite branco do alien
	
# inicializa os dados do print normal do alien assustado

BLINKY_F_NORMAL:

	la a6,InimigoAssustado		# a6 = label da imagem a ser impressa (parametro da função de movimentação)
	mv t6,s7			# t6 = movimentação atual do alien + valor base do modo frightened
	li s7,51			# s7 = 51 (volta s7 para o valor base do modo atual)
	j SETUP_TARGET 			# pule para SETUP_TARGET

# inicializa os dados do print alternado entre azul e branco do alien assustado

BLINKY_F_ALTERNADO:	
	
	la t0,CONTADOR_ASSUSTADO	# carrega o valor de "CONTADOR_ASSUSTADO" no registrador t0	
	lw t1,0(t0)			# le a word guardada em "CONTADOR_ASSUSTADO" para t1 (t1 = contador do tempo no frightened mode)
	
	li t2,4				# t2 = 4
	div t0,t1,t2			# t0 = t1/4 (t0 = divisão do tempo decorrido por 4 -> o "CONTADOR_ASSUSTADO" cresce de 4 em 4 por serem 4 aliens)
	li t2,2				# t2 = 2
	rem t0,t0,t2			# t0 = t0/2 (divide t0 por 2 para verificar a paridade desse quociente)
	beq t0,zero,B_AZUL		# se t0 for par, printa azul
	la a6,Inimigobranco		# a6 = label da imagem a ser impressa (parametro da função de movimentação)
	mv t6,s7			# t6 = movimentação atual do alien
	li s7,51			# s7 = 51 (volta s7 para o valor base do modo atual)
	j SETUP_TARGET			# pule para SETUP_TARGET
	
B_AZUL: la a6,InimigoAssustado		# a6 = label da imagem a ser impressa (parametro da função de movimentação)
	mv t6,s7			# t6 = movimentação atual do alien + valor base do modo frightened
	li s7,51			# s7 = 51 (volta s7 para o valor base do modo atual)
	j SETUP_TARGET			# pule para SETUP_TARGET
	
# Inicializa os dados e o target do alien a ser movimentado (pink) 
	
PINK_SCATTER:			# target: canto superior esquerdo
	
	li t4,0xFF000000	# t4 = endereço do target do Pink 
	mv t6,s9		# t6 = movimentação atual do alien
	li s9,17		# volta s9 para 17 (volta s9 para o valor base do modo atual)
	
	la t0,POS_PINK		# carrega o endereço de "POS_PINK" no registrador t0
	lw a4,0(t0)		# le a word guardada em "POS_PINK" para a4 (a4 = posição atual do Pink)
	
	la a6,Inimigo2		# a6 = label da imagem a ser impressa (parametro da função de movimentação)
	
	j SETUP_TARGET		# pula para SETUP_TARGET
	
PINK_CHASE:			# target: frente do Robozinho (se o Robozinho esta indo para a direita, persegue a posição a direita do Robozinho; se está indo para baixo, persegue a posição abaixo do Robozinho etc)
	
	la t0,POS_ROBOZINHO	# carrega o endereço de "POS_ROBOZINHO" no registrador t0
	lw t1,0(t0)		# le a word guardada em "POS_ROBOZINHO" para t1 (t1 = posição atual do Robozinho)
	
	li t0,1			# t0 = 1
	beq s3,t0,ADD_ESQ	# se s3 = 1, entao o Robozinho esta indo para a esquerda
	
	li t0,2			# t0 = 2
	beq s3,t0,ADD_CIMA	# se s3 = 2, entao o Robozinho esta indo para cima
	
	li t0,3			# t0 = 3
	beq s3,t0,ADD_BAIXO	# se s3 = 3, entao o Robozinho esta indo para baixo
	
	li t0,4			# t0 = 4
	beq s3,t0,ADD_DIR	# se s3 = 4, entao o Robozinho esta indo para a direita
	
	jal CONT_PINK		# se o Robozinho nao esta se movendo, ele vai diretamente ate a posição dele
	
# adiciona ao endereço do target (t1, posição atual do Robozinho) um certo valor para mover o target para a posição desejada

ADD_ESQ:

	addi t1,t1,-16		# t1 = t1 - 16 
	jal CONT_PINK		# pule para CONT_PINK
	
ADD_CIMA:

	li t0,5120			
	sub t1,t1,t0		# t1 = t1 - 5120
	jal CONT_PINK	        # pule para CONT_PINK
	
ADD_BAIXO:

	li t0,5120		# t0 = 5120
	add t1,t1,t0		# t1 = t1 + 5120
	jal CONT_PINK		# pule para CONT_PINK
	
ADD_DIR:

	addi t1,t1,16		# t1 = t1 + 16
	
# verifica se, apos a soma, o endereço contido em t1 continua dentro dos limites da memoria VGA (0xFF000000 <= t1 <= 0xFF012BFF)
	
CONT_PINK:
	
	li t0,0xFF000000	# t1 = endereço minimo 0xFF000000
	blt t1,t0,FORA_MEM_P	# se o endereço estiver fora da memoria (menor que 0xff000000), então o valor de t1 se mantem como a posição do Robozinho
	li t0,0xFF012BFF	# t1 = endereço maximo 0xFF012BFF
	bge t1,t0,FORA_MEM_P	# se o endereço estiver fora da memoria (maior que 0xff012bff), então o valor de t1 se mantem como a posição do Robozinho
	j CONT_2_PINK		# pula para CONT_2_PINK caso o endereço esteja dentro da memoria
	
FORA_MEM_P:
	
	la t0,POS_ROBOZINHO	# carrega o endereço de "POS_ROBOZINHO" no registrador t0
	lw t1,0(t0)		# le a word guardada em "POS_ROBOZINHO" para t1 (t1 = posição atual do Robozinho)
	
# Apos o calculo do endereço do target, inicializa os dados para o calculo da distancia ate o target
	
CONT_2_PINK:

	mv t4,t1		# t4 = t1 (t4 = posição do target)
	mv t6,s9		# t6 = movimentação atual do alien
	li s9,34		# volta s9 para 34 (volta s9 para o valor base do modo atual)
	
	la t0,POS_PINK		# carrega o endereço de "POS_PINK" no registrador t0
	lw a4,0(t0)		# le a word guardada em "POS_PINK" para a4 (a4 = posição atual do Pink)
	
	la a6,Inimigo2		# a6 = label da imagem a ser impressa (parametro da função de movimentação)
	
	j SETUP_TARGET		# pula para SETUP_TARGET
	
# Fim real do "PINK_CHASE" 
	
PINK_FRIGHTENED:		# target: aleatorio (exceto no primeiro movimento que inverte a direção do alien)

	la t0,POS_PINK		# carrega o endereço de "POS_PINK" no registrador t0
	lw a4,0(t0)		# le a word guardada em "POS_PINK" para a4 (a4 = posição atual do PINK)
	
	mv t4,a4		# t4 = a4(t4 = posição atual do alien. t4 será movido para a direção de movimentação desejada em funções futuras)		

	li t0,179		# t0 = 179
	rem t1,s0,t0		# t1 = s0%179
	beq t1,zero,INVERTE_P	# se esta no primeiro frame do movimento em frightened mode, va para INVERTE_P (inverte a direção do alien), se não, o alien toma uma direção pseudo-aleatoria
	
	li t0,821		# t0 = 821 (numero primo grande)
	mul t0,s0,t0		# t0 = s0*821
	li t1,4			# t1 = 4
	rem t1,t0,t1		# t1 = (s0*823)%4 (o resto guardado em t1 depende do valor de s0, que está em constante mudança, o que causa uma percepção de aleatoriedade)
	
	li t0,0			# t0 = 0 (up)
	beq t1,t0,UP_PINK 	# se t1 = 0, então o pink vai pra cima
	
	addi t0,t0,1		# t0 = 1 (left)
	beq t1,t0,ESQ_PINK   	# se t1 = 1, então o pink vai pra esquerda
	
	addi t0,t0,1		# t0 = 2 (down)
	beq t1,t0,DOWN_PINK   	# se t1 = 2, então o pink vai pra baixo
	
	addi t0,t0,1		# t0 = 3 (right)
	beq t1,t0,DIR_PINK    	# se t1 = 3, então o pink vai pra direita
	
# Inverte o movimento do alien durante o frightened mode ("vira 180 graus")	
	
INVERTE_P:

	li t0,17		# t0 = 17
	rem t1,s9,t0		# t1 = s9%17
	
	li t0,0			# t0 = 0(up)
	beq t1,t0,DOWN_PINK 	# se t1 = 0, pink esta indo pra cima, logo ele inverte e vaii pra baixo (DOWN_PINK)
	addi t0,t0,1		# t0 = 1(left)
	beq t1,t0,DIR_PINK  	# se t1 = 1, então o pink esta indo pra esquerda, logo ele inverte e vai pra baixo (DIR_PINK)
	addi t0,t0,1		# t0 = 2(down)
	beq t1,t0,UP_PINK  	# se t1 = 2, então o pink esta indo pra baixo, logo ele inverte e vai pra baixo (UP_PINK)
	addi t0,t0,1		# t0 = 3(right)
	beq t1,t0,ESQ_PINK  	# se t1 = 3, então o pink esta indo pra direita, logo ele inverte e vai pra baixo (ESQ_PINK)

UP_PINK:
	li t0,5120		# t0 = 5120
	sub t4,t4,t0		# t4 = t4 - 5120
	j SETUP_F_PINK
ESQ_PINK:
	addi t4,t4,-64	# t4 = t4 - 64
	j SETUP_F_PINK
DOWN_PINK:
	li t0,5120		# t0 = 5120
	add t4,t4,t0		# t4 = t4 + 5120
	j SETUP_F_PINK
DIR_PINK:
	addi t4,t4,64		# t4 = t4 + 64
	
SETUP_F_PINK:

	la t0,CONTADOR_ASSUSTADO	# carrega o valor de "CONTADOR_ASSUSTADO" no registrador t0	
	lw t1,0(t0)			# le a word guardada em "CONTADOR_ASSUSTADO" para t1 (t1 = contador do tempo no frightened  mode)
	
	li t2,350			# alterna entre azul e branco
	blt t1,t2,PINK_F_NORMAL	#se for menor que 150, continua no print normal frightened mode
	j PINK_F_ALTERNADO
	
PINK_F_NORMAL:

	la a6,InimigoAssustado		# a6 = label da imagem a ser impressa (parametro da função de movimentação)
	mv t6,s9			# t6 = movimentação atual do alien
	li s9,51			# s7 = 51 (volta s7 para o valor base do modo atual)
	j SETUP_TARGET
	
PINK_F_ALTERNADO:	
	
	la t0,CONTADOR_ASSUSTADO	# carrega o valor de "CONTADOR_ASSUSTADO" no registrador t0	
	lw t1,0(t0)			# le a word guardada em "CONTADOR_ASSUSTADO" para t1 (t1 = contador do tempo no frightened mode)
	
	li t2,4		# t1 = 2
	div t0,t1,t2		# t0 = s0/t1
	li t2,2
	rem t0,t0,t2
	beq t0,zero,P_AZUL	# se s0 for par, printa azul
	la a6,Inimigobranco	# a6 = label da imagem a ser impressa (parametro da função de movimentação)
	mv t6,s9		# t6 = movimentação atual do alien
	li s9,51		# s7 = 51 (volta s7 para o valor base do modo atual)
	j SETUP_TARGET
	
P_AZUL:
	la a6,InimigoAssustado		# a6 = label da imagem a ser impressa (parametro da função de movimentação)
	mv t6,s9			# t6 = movimentação atual do alien
	li s9,51			# s7 = 51 (volta s7 para o valor base do modo atual)
	j SETUP_TARGET		
	
# Inicializa os dados e o traget do alien a ser movimentado (inky) 

INKY_SCATTER:			# target : canto inferior direito
	
	li t4,0xFF012BFF	# t4 = endereço do target do Inky 
	mv t6,s10		# t6 = movimentação atual do alien
	li s10,17		# volta s10 para 17(a movimentação ja esta guardada em t6 e o calculo ira adicionar em s10 posteriormente)
	
	la t0,POS_INKY		# carrega o endereço de "POS_INKY" no registrador t0
	lw a4,0(t0)		# le a word guardada em "POS_INKY" para t1 (t1 = posição atual do Inky)
	
	la a6,Inimigo3		# a6 = label da imagem a ser impressa (parametro da função de movimentação)
	
	j SETUP_TARGET		# pula para SETUP_TARGET
	
INKY_CHASE:			# target : "cerca" o Robozinho baseado na posição do blinky 		
	
	# t1: x robo t2: y robo t3: x blinky t4: y blinky
	
	la t0,POS_ROBOZINHO	# carrega o endereço de "POS_ROBOZINHO" no registrador t0
	lw t1,0(t0)		# le a word guardada em "POS_ROBOZINHO" para t1 (t1 = posição atual do Robozinho
	la t0,POS_BLINKY	# carrega o endereço de "POS_POS_BLINKY no registrador t0
	lw t3,0(t0)		# le a word guardada em "POS_BLINKY" para t3 (t3 = posição atual do BLINKY)
	
	mv t0,t1		# guarda em t0 o endereço hexa do Robozinho
	
	li t6,0xFF000000	# t1 = endereço base do Bitmap Display
	li t5,320		# t2 = numero de colunas da tela
	
	sub t1,t1,t6		# subtrai de t1 o endereço base
	mv t2,t1		# carrega em t2 o valor de t1 (posição do target sem o endereço base)
	rem t1,t1,t5 		# t1 = posição x do robo (coluna do pixel de posição)
	div t2,t2,t5		# t2 = posição y do robo (coluna do pixel de posição)
	
	sub t3,t3,t6		# subtrai de t3 o endereço base
	mv t4,t3		# carrega em t4 o valor de t3 (posição do target sem o endereço base)
	rem t3,t3,t5 		# t3 = posição x do alien (coluna do pixel de posição)
	div t4,t4,t5		# t4 = posição y do alien (coluna do pixel de posição)
	
	sub t5, t1, t3		# t5 = variação da posição X entre o robo(t1) e o alien(t3)
	neg t5, t5 		# inverte o vetor X que liga o Blinky ao robo

	sub t6, t2, t4		# t6 = variação da posição Y entre o robo(t2) e o alien(t4)
	neg t6, t6		# inverte o vetor Y que liga o Blinky ao robo
	
	add t0, t0, t5		# adiciona ao endereço base a coluna 
	li t1, 5120		# t1 = 5120(320*16)
	mul t6, t6, t1		# multiplica a quantidade de linhas abaixo/acima por 5120
	add t0, t0, t6		# adiciona ao endereço base a linha
	
	li t1, 0xFF000000	# t1 = endereço minimo 0xFF000000
	blt t0, t1, FORA_MEM	# se o endereço for para fora da memoria(ser menor que 0xff000000), então o INKY se aproxima do BLINKY
	li t1, 0xFF012BFF	# t1 = endereço maximo 
	bge t0, t1, FORA_MEM	# se o endereço for para fora da memoria(ser maior que 0xff012bff), então o INKY se aproxima do BLINKY
	
	mv t4, t0		# t4 = endereço do target do Inky	
	mv t6, s10		# t6 = movimentação atual do alien
	li s10, 34		# volta s10 para 34(a movimentação ja esta guardada em t6 e o calculo ira adicionar em s10 posteriormente)
	
	la t0,POS_INKY		# carrega o endereço de "POS_INKY" no registrador t0
	lw a4,0(t0)		# le a word guardada em "POS_INKY" para t1 (t1 = posição atual do Inky)
	
	la a6, Inimigo3		# a6 = label da imagem a ser impressa (parametro da função de movimentação)
	
	j SETUP_TARGET		# pula para SETUP_TARGET
	
 FORA_MEM:
 
 	la t0,POS_BLINKY	# carrega o endereço de "POS_ROBOZINHO" no registrador t0
	lw t1,0(t0)		# le a word guardada em "POS_ROBOZINHO" para t1 (t1 = posição atual do Robozinho)
	
	mv t4, t1		# t4 = endereço do target do Blinky(Robozinho) 	
	mv t6, s10		# t6 = movimentação atual do alien
	li s10, 34		# volta s10 para 34(a movimentação ja esta guardada em t6 e o calculo ira adicionar em s10 posteriormente)
	
	la t0,POS_INKY		# carrega o endereço de "POS_INKY" no registrador t0
	lw a4,0(t0)		# le a word guardada em "POS_INKY" para t1 (t1 = posição atual do Inky)
	
	la a6, Inimigo3		# a6 = label da imagem a ser impressa (parametro da função de movimentação)
	
	j SETUP_TARGET		# pula para SETUP_TARGET
	
INKY_FRIGHTENED:		# target: aleatorio(exceto no primeiro movimento que inverte a direção do alien)

	la t0,POS_INKY		# carrega o endereço de "POS_INKY" no registrador t0
	lw a4,0(t0)		# le a word guardada em "POS_INKY" para a4 (a4 = posição atual do INKY)
	
	mv t4, a4		# t4 = a4(t4 = posição atual do alien. t4 será movido para a direção de movimentação desejada em funções futuras)		

	li t0, 179		# t0 = 179
	rem t1, s0, t0		# t1 = so%179
	beq t1, zero, INVERTE_I	# se esta no primeiro frame do movimento em frightened mode, va para INVERTE_I (inverte a direção do alien), se não, o alien toma uma direção pseudo-aleatoria
	
	li t0, 811		# t0 = 811 (numero primo grande)
	mul t0, s0, t0		# t0 = s0*t0
	li t1, 4		# t1 = 4
	rem t1, t0, t1		# t1 = t0%t1
	
	li t0, 0		# t0 = 0(up)
	beq t1, t0, UP_INKY 	# se t1 = 0, então o inky vai pra cima
	addi t0, t0, 1		# t0 = 1(left)
	beq t1, t0, ESQ_INKY    # se t1 = 1, então o inky vai pra esquerda
	addi t0, t0, 1		# t0 = 2(down)
	beq t1, t0, DOWN_INKY   # se t1 = 2, então o inky vai pra baixo
	addi t0, t0, 1		# t0 = 3(right)
	beq t1, t0, DIR_INKY    # se t1 = 3, então o inky vai pra direita
	
# Inverte o movimento do alien durante o frightened mode ("vira 180 graus")	
	
INVERTE_I:
	li t0, 17		# t0 = 17
	rem t1,s10, t0		# t1 = s10%17
	li t0, 0		# t0 = 0(up)
	beq t1, t0, DOWN_INKY   # se t1 = 0, então o inky esta indo pra cima, logo ele inverte e vai pra baixo (DOWN_INKY)
	addi t0, t0, 1		# t0 = 1(left)
	beq t1, t0, DIR_INKY    # se t1 = 1, então o inky esta indo pra esquerda, logo ele inverte e vai pra baixo (DIR_INKY)
	addi t0, t0, 1		# t0 = 2(down)
	beq t1, t0, UP_INKY     # se t1 = 2, então o inky esta indo pra baixo, logo ele inverte e vai pra baixo (UP_INKY)
	addi t0, t0, 1		# t0 = 3(right)
	beq t1, t0, ESQ_INKY     # se t1 = 3, então o inky esta indo pra direita, logo ele inverte e vai pra baixo (ESQ_INKY)

UP_INKY:
	li t0, 5120		# t0 = 5120
	sub t4, t4, t0		# t4 = t4 - 5120
	j SETUP_F_INKY
ESQ_INKY:
	addi t4, t4, -64	# t4 = t4 - 64
	j SETUP_F_INKY
DOWN_INKY:
	li t0, 5120		# t0 = 5120
	add t4, t4, t0		# t4 = t4 + 5120
	j SETUP_F_INKY
DIR_INKY:
	addi t4, t4, 64		# t4 = t4 + 64
	
SETUP_F_INKY:

	la t0, CONTADOR_ASSUSTADO	# carrega o valor de "CONTADOR_ASSUSTADO" no registrador t0	
	lw t1, 0(t0)			# le a word guardada em "CONTADOR_ASSUSTADO" para t1 (t1 = contador do tempo no frightened  mode)
	
	li t2, 350			# alterna entre azul e branco
	blt t1, t2, INKY_F_NORMAL	#se for menor que 150, continua no print normal frightened mode
	j INKY_F_ALTERNADO
	
INKY_F_NORMAL:

	la a6, InimigoAssustado		# a6 = label da imagem a ser impressa (parametro da função de movimentação)
	mv t6, s10			# t6 = movimentação atual do alien
	li s10, 51			# s7 = 51 (volta s7 para o valor base do modo atual)
	j SETUP_TARGET
	
INKY_F_ALTERNADO:	
	
	la t0,CONTADOR_ASSUSTADO	# carrega o valor de "CONTADOR_ASSUSTADO" no registrador t0	
	lw t1,0(t0)			# le a word guardada em "CONTADOR_ASSUSTADO" para t1 (t1 = contador do tempo no frightened mode)
	
	li t2, 4		# t1 = 2
	div t0, t1, t2		# t0 = s0/t1
	li t2, 2
	rem t0,t0,t2
	beq t0, zero, I_AZUL	# se s0 for par, printa azul
	la a6, Inimigobranco	# a6 = label da imagem a ser impressa (parametro da função de movimentação)
	mv t6, s10		# t6 = movimentação atual do alien
	li s10, 51		# s7 = 51 (volta s7 para o valor base do modo atual)
	j SETUP_TARGET
	
I_AZUL:
	la a6, InimigoAssustado		# a6 = label da imagem a ser impressa (parametro da função de movimentação)
	mv t6, s10			# t6 = movimentação atual do alien
	li s10, 51			# s7 = 51 (volta s7 para o valor base do modo atual)
	j SETUP_TARGET		
	
# Inicializa os dados e o target do alien a ser movimentado (clyde)
	
CLYDE_SCATTER:			# target: canto inferior esquerdo

	li t4, 0xFF012B40	# t4 = endereço do target do Clyde
	mv t6, s11		# t6 = movimentação atual do alien
	li s11, 17		# volta s11 para 17(a movimentação ja esta guardada em t6 e o calculo ira adicionar em s11 posteriormente)
	
	la t0,POS_CLYDE		# carrega o endereço de "POS_CLYDE" no registrador t0
	lw a4,0(t0)		# le a word guardada em "POS_CLYDE" para t1 (t1 = posição atual do Clyde)
	
	la a6, Inimigo4		# a6 = label da imagem a ser impressa (parametro da função de movimentação)
	
	j SETUP_TARGET		# pula para SETUP_TARGET

CLYDE_CHASE:			# target: pac-man, quando chega perto de certo range escolhe uma direção aleatoria

	la t0,POS_ROBOZINHO	# carrega o endereço de "POS_ROBOZINHO" no registrador t0
	lw t1,0(t0)		# le a word guardada em "POS_ROBOZINHO" para t1 (t1 = posição atual do Robozinho
	
	li t6, 0xFF000000	# t1 = endereço base do Bitmap Display
	li t5, 320		# t2 = numero de colunas da tela
	
	sub t1, t1, t6		# subtrai de t1 o endereço base
	mv t2, t1		# carrega em t2 o valor de t1 (posição do target sem o endereço base)
	rem t1, t1, t5 		# t1 = posição x do robo (coluna do pixel de posição)
	div t2, t2, t5		# t2 = posição y do robo (coluna do pixel de posição)
	
	sub t1, t1, a0		# t1 = |t1 - a0|
	bge t1, zero, CONT_CLYDE 
	neg t1, t1		# se nao for maior que zero, deixa positivo o resultado
CONT_CLYDE:
	sub t2, t2, a1		# t2 = |t2 - a0|
	bge t2, zero, CONT_CLYDE2
	neg t2, t2		# se nao for maior que zero, deixa positivo o resultado
CONT_CLYDE2:
	
	li t0, 128		# t0 = 64
	add t1, t1, t2		# t1 = t1 + t2 = distancia total
	blt t1, t0, RANDOM	# se o clyde esta proximo do Robozinho, ele assume um movimento aleatorio, se nao, ele vai atras do Robozinho
	
	la t0,POS_ROBOZINHO	# carrega o endereço de "POS_ROBOZINHO" no registrador t0
	lw t1,0(t0)		# le a word guardada em "POS_ROBOZINHO" para t1 (t1 = posição atual do Robozinho)
	
	mv t4, t1		# t4 = endereço do target do Clyde(Robozinho)
	mv t6, s11		# t6 = movimentação atual do alien
	li s11, 34		# volta s11 para 34(a movimentação ja esta guardada em t6 e o calculo ira adicionar em s11 posteriormente)
	
	la t0,POS_CLYDE		# carrega o endereço de "POS_CLYDE" no registrador t0
	lw a4,0(t0)		# le a word guardada em "POS_CLYDE" para t1 (t1 = posição atual do Clyde)
	
	la a6, Inimigo4		# a6 = label da imagem a ser impressa (parametro da função de movimentação)
	
	j SETUP_TARGET		# pula para SETUP_TARGET
							
RANDOM:
	mv t4, a4		# guarda em t4 a posição atual do clyde
	
	mv t0, s0		# pega um numero aleatorio(contador)
	li t2, 4		# t2 = 4
	rem t1, t0, t2		# pega o resto pela divisao por 4 e armazena em t1
	
	li t0, 0
	beq t0, t1, TARGET_UP  	# se o resto der igual a 0, pega como target logo acima dele
	addi t0, t0, 1		# adiciona 1 em t0
	beq t0, t1, TARGET_L  	# se o resto der igual a 0, pega como target logo ÃƒÂ  esquerda dele
	addi t0, t0, 1		# adiciona 1 em t0
	beq t0, t1, TARGET_DW  	# se o resto der igual a 0, pega como target logo abaixo dele
	addi t0, t0, 1		# adiciona 1 em t0
	beq t0, t1, TARGET_R  	# se o resto der igual a 0, pega como target logo ÃƒÂ  direita dele
	
TARGET_UP:
	li t0, 5120		
	sub t4, t4, t0          # t4 = endereço do target target logo acima dele
	jal SETUP_RANDOM
TARGET_L:
	addi t4, t4, -16	# t4 = endereço do target logo ÃƒÂ  esquerda dele 
	jal SETUP_RANDOM
TARGET_DW:
	li t0, 5120		
	add t4, t4, t0          # t4 = endereço do target target logo acima dele
	jal SETUP_RANDOM
TARGET_R:
	addi t4, t4, 16		# t4 = endereço do target logo ÃƒÂ  direita dele

SETUP_RANDOM:

	mv t6, s11		# t6 = movimentação atual do alien
	li s11, 34		# volta s11 para 34(a movimentação ja esta guardada em t6 e o calculo ira adicionar em s11 posteriormente)
	
	la t0,POS_CLYDE		# carrega o endereço de "POS_CLYDE" no registrador t0
	lw a4,0(t0)		# le a word guardada em "POS_CLYDE" para t1 (t1 = posição atual do Clyde)
	
	la a6, Inimigo4		# a6 = label da imagem a ser impressa (parametro da função de movimentação)
	j SETUP_TARGET		# pula para SETUP_TARGET
	
CLYDE_FRIGHTENED:		# target: aleatorio(exceto no primeiro movimento que inverte a direção do alien)

	la t0,POS_CLYDE		# carrega o endereço de "POS_CLYDE" no registrador t0
	lw a4,0(t0)		# le a word guardada em "POS_CLYDE" para a4 (a4 = posição atual do CLYDE)
	
	mv t4, a4		# t4 = a4(t4 = posição atual do alien. t4 será movido para a direção de movimentação desejada em funções futuras)		

	li t0, 179		# t0 = 179
	rem t1, s0, t0		# t1 = so%179
	beq t1, zero, INVERTE_C	# se esta no primeiro frame do movimento em frightened mode, va para INVERTE_C (inverte a direção do alien), se não, o alien toma uma direção pseudo-aleatoria
	
	li t0, 811		# t0 = 809 (numero primo grande)
	mul t0, s0, t0		# t0 = s0*t0
	li t1, 4		# t1 = 4
	rem t1, t0, t1		# t1 = t0%t1
	
	li t0, 0		# t0 = 0(up)
	beq t1, t0, UP_CLYDE 	# se t1 = 0, então o clyde vai pra cima
	addi t0, t0, 1		# t0 = 1(left)
	beq t1, t0, ESQ_CLYDE   # se t1 = 1, então o clyde vai pra esquerda
	addi t0, t0, 1		# t0 = 2(down)
	beq t1, t0, DOWN_CLYDE  # se t1 = 2, então o clyde vai pra baixo
	addi t0, t0, 1		# t0 = 3(right)
	beq t1, t0, DIR_CLYDE   # se t1 = 3, então o clyde vai pra direita
	
# Inverte o movimento do alien durante o frightened mode ("vira 180 graus")	
	
INVERTE_C:
	li t0, 17		# t0 = 17
	rem t1,s11, t0		# t1 = s11%17
	li t0, 0		# t0 = 0(up)
	beq t1, t0, DOWN_CLYDE  # se t1 = 0, então o clyde esta indo pra cima, logo ele inverte e vai pra baixo (DOWN_CLYDE)
	addi t0, t0, 1		# t0 = 1(left)
	beq t1, t0, DIR_CLYDE   # se t1 = 1, então o clyde esta indo pra esquerda, logo ele inverte e vai pra baixo (DIR_CLYDE)
	addi t0, t0, 1		# t0 = 2(down)
	beq t1, t0, UP_CLYDE    # se t1 = 2, então o clyde esta indo pra baixo, logo ele inverte e vai pra baixo (UP_CLYDE)
	addi t0, t0, 1		# t0 = 3(right)
	beq t1, t0, ESQ_CLYDE   # se t1 = 3, então o clyde esta indo pra direita, logo ele inverte e vai pra baixo (ESQ_CLYDE)

UP_CLYDE:
	li t0, 5120		# t0 = 5120
	sub t4, t4, t0		# t4 = t4 - 5120
	j SETUP_F_CLYDE
ESQ_CLYDE:
	addi t4, t4, -64	# t4 = t4 - 64
	j SETUP_F_CLYDE
DOWN_CLYDE:
	li t0, 5120		# t0 = 5120
	add t4, t4, t0		# t4 = t4 + 5120
	j SETUP_F_CLYDE
DIR_CLYDE:
	addi t4, t4, 64		# t4 = t4 + 64
	
SETUP_F_CLYDE:

	la t0, CONTADOR_ASSUSTADO	# carrega o valor de "CONTADOR_ASSUSTADO" no registrador t0	
	lw t1, 0(t0)			# le a word guardada em "CONTADOR_ASSUSTADO" para t1 (t1 = contador do tempo no frightened  mode)
	
	li t2, 350			# alterna entre azul e branco
	blt t1, t2, CLYDE_F_NORMAL	# se for menor que 150, continua no print normal frightened mode
	j CLYDE_F_ALTERNADO
	
CLYDE_F_NORMAL:

	la a6, InimigoAssustado		# a6 = label da imagem a ser impressa (parametro da função de movimentação)
	mv t6, s11			# t6 = movimentação atual do alien
	li s11, 51			# s7 = 51 (volta s7 para o valor base do modo atual)
	j SETUP_TARGET
	
CLYDE_F_ALTERNADO:	
	
	la t0,CONTADOR_ASSUSTADO	# carrega o valor de "CONTADOR_ASSUSTADO" no registrador t0	
	lw t1,0(t0)			# le a word guardada em "CONTADOR_ASSUSTADO" para t1 (t1 = contador do tempo no frightened mode)
	
	li t2, 4		# t1 = 2
	div t0, t1, t2		# t0 = s0/t1
	addi t0,t0,1
	li t2, 2
	rem t0,t0,t2
	beq t0, zero, C_AZUL	# se s0 for par, printa azul
	la a6, Inimigobranco	# a6 = label da imagem a ser impressa (parametro da função de movimentação)
	mv t6, s11		# t6 = movimentação atual do alien
	li s11, 51		# s7 = 51 (volta s7 para o valor base do modo atual)
	j SETUP_TARGET
	
C_AZUL:
	la a6, InimigoAssustado		# a6 = label da imagem a ser impressa (parametro da função de movimentação)
	mv t6, s11			# t6 = movimentação atual do alien
	li s11, 51			# s7 = 51 (volta s7 para o valor base do modo atual)
	
# Inicializa os dados para o scatter mode, no qual sera calculado o caminho mais curto ate o target (|a0 - t4| + |a1 - t5|) = (|x_alien - x_target|) + (|y_alien - y_target|)

# Função que calcula o target do alien com relação a posição do Robozinho
# Calculo de distancia: distancia de manhattan : (|x_alien - x_target|) + (|y_alien - y_target|)
# t4: endereço do target
# t6 : estado de movimentação atual do alien
# a0 : endereço x do alien
# a1 : endereço y do alien
# a4 : posição hexa do alien
# a6 : label do inimigo	
	
SETUP_TARGET:

	li t1, 0xFF000000	# t1 = endereço base do Bitmap Display 
	li t2, 320		# t2 = numero de colunas da tela
	
	sub t4, t4, t1		# subtrai de t4 o endereço base
	mv t5, t4		# carrega em t5 o valor de t4 (posição do target sem o endereço base)
	rem t4, t4, t2 		# t4 = posição x do target (coluna do pixel de posição)
	div t5, t5, t2		# t5 = posição y do target (coluna do pixel de posição)
	
	addi a1, a1, -4		# a1 = posição y do alien 4 linhas acima
	jal ra, LOOP_TARGET	# calcula a distancia de manhattan entre o target e a direção de cima do alien e retorna em a2
	mv t0, a2		# guarda em t0 a distancia entre target e a posição acima do alien
	
	addi a1, a1, 4		# volta a1 para a posição original
	addi a0, a0, -4 	# a0 = posição x do alien 4 colunas a esquerda
	jal ra, LOOP_TARGET	# calcula a distancia de manhattan entre o target e a direção esquerda do alien e retorna em a2
	mv t1, a2		# guarda em t1 a distancia entre target e a posição a esquerda do alien
	
	addi a0, a0, 4		# volta a0 para a posição original
	addi a1, a1, 4		# a1 = posição y do alien 4 linhas abaixo
	jal ra, LOOP_TARGET	# calcula a distancia de manhattan entre o target e a direção esquerda do alien e retorna em a2
	mv t2, a2		# guarda em t2 a distancia entre target e a posição abaixo do alien
	
	addi a1, a1, -4		# volta a1 para a posição original
	addi a0, a0, 4 		# a0 = posição x do alien 4 colunas a direita
	jal ra, LOOP_TARGET 	# calcula a distancia de manhattan entre o target e a direção esquerda do alien e retorna em a2
	mv t3, a2		# guarda em t1 a distancia entre target e a posição a direita do alien
	
	addi a0, a0, -4		# volta a0 para a posição original
	
	
	li t5, 21
	blt t6, t5, VERIF_MOV2_X 	# se a2(sX) < 21, esta no scatter mode(nÃ¢o tira ele da caixa)
	li t5, 38
	blt t6, t5, CONT_TARGET	 	# se a2(sX) < 38, esta no chase mode(tira ele da caixa)

	li t4, 116			# verifica se o alien esta dentro da caixa(caso esteja, ele nao pode ir para baixo)
	ble a1, t4, VERIF_MOV1_XF	# se ele estiver acima d alinha da caixa, vamos ver se ele estÃ abaixo da outra linha da caixa(SERVE PRA TIRAR DA CAIXA)
	jal VERIF_MOV2_F		# se nÃ£o, pula pra segunda verificaÃ§Ã£o	
	
VERIF_MOV1_XF:
	li t4, 96			# verifica se o alien esta dentro da caixa(caso esteja, ele nao pode ir para baixo)
	bgt a1, t4, VERIF_MOV1_F	# se stiver, verifica se estÃ entre as colunas	
	jal VERIF_MOV2_F		# se nÃ£o, pula pra segunda verificaÃ§Ã£o

VERIF_MOV1_F:
	li t4, 216			# borda direita da caixa(200 + 16)
	li t5, 184			# borda esquerda da caixa(200 - 16)
	bge a0, t4, VERIF_MOV2_F	# se a0 esta na esquerda da borda esquerda, nao esta dentro da caixa
	blt a0, t5, VERIF_MOV2_F	# se a0 esta na direita da borda direita, nao esta dentro da caixa
	
	li t2, 560			# carrega em t2 um valor grande para ele nao ir para baixo
	jal VERIF_MOV			# pula para verificar o movimento(nÃ¢o pode inverter!)

VERIF_MOV2_F:

	la t5, CONTADOR_ASSUSTADO	# le o CONTADOR_ASSUSTADO
	lw t4, 0(t5)			# carrega em t4 o valor do CONTADOR_ASSUSTADO

	li t5, 4			# te = 4(proximo tick do primeiro alien)
	blt t4, t5, MENOR		# se ele estÃ em um dos primeiros ticks, alÃ©m de nÃ£o estar dentro da caixa, pode inverter, se nÃ£o, continua normalmente o calculo do target
	jal VERIF_MOV2_X
	
CONT_TARGET:
	
	li t4, 116			# verifica se o alien esta dentro da caixa(caso esteja, ele nao pode ir para baixo)
	ble a1, t4, VERIF_MOV1_X	# se ele estiver acima d alinha da caixa, vamos ver se ele estÃ abaixo da outra linha da caixa(SERVE PRA TIRAR DA CAIXA)
	jal VERIF_MOV2_X		# se nÃ£o, pula pra segunda verificaÃ§Ã£o	
	
VERIF_MOV1_X:
	li t4, 96			# verifica se o alien esta dentro da caixa(caso esteja, ele nao pode ir para baixo)
	bgt a1, t4, VERIF_MOV1		# se stiver, verifica se estÃ entre as colunas

VERIF_MOV2_X:	
	li t4, 96			#verifica se o alien esta logo em cima da caixa(caso esteja, ele nao pode ir para cima nem para baixo)
	beq a1, t4, VERIF_MOV2  	# se ele estiver na linha da caixa, vamos ver se ele esta entre as colunas
	jal VERIF_MOV

VERIF_MOV1:
	li t4, 216		# borda direita da caixa(200 + 16)
	li t5, 184		# borda esquerda da caixa(200 - 16)
	bge a0, t4, VERIF_MOV	# se a0 esta na esquerda da borda esquerda, nao esta dentro da caixa
	blt a0, t5, VERIF_MOV	# se a0 esta na direita da borda direita, nao esta dentro da caixa
	
	li t2, 560		# carrega em t2 um valor grande para ele nao ir para baixo
	jal VERIF_MOV		# pula para verificar o movimento
	
VERIF_MOV2:
	li t4, 216		# borda direita da caixa(200 + 16)
	li t5, 184		# borda esquerda da caixa(200 - 16)
	bge a0, t4, VERIF_MOV	# se a0 esta na esquerda da borda esquerda, nao esta dentro da parte de cima da caixa
	blt a0, t5, VERIF_MOV	# se a0 esta na direita da borda esquerda, nao esta dentro da parte de cima da caixa
	
	li t0, 560		# carrega em t0 um valor grande epara ele nao ir para cima
	li t2, 560		# carrega em t2 um valor grande para ele nao ir para baixo
	
VERIF_MOV:

	li t5, 17		# t5 = 17
	rem t6, t6, t5		# t6 = resto de t6 por 17(t6 guardava a movimentação do alien antes de resetar para 17/34/51 e agora esta setado para 0,1,2 ou 3)
	
	li t4, 0		# t4 = 0 significa que o alien esta andando para cima		
	beq t6, t4, N_BAIXO	# logo ele não pode ir pra baixo
	addi t4, t4, 1		# t4 = 1 significa que o alien esta andando para a esquerda	
	beq t6, t4, N_DIREITA   # logo ele não pode ir pra a direita
	addi t4, t4, 1		# t4 = 2 significa que o alien esta andando para baixo
	beq t6, t4, N_CIMA	# logo ele não pode ir pra cima
	addi t4, t4, 1		# t4 = 3 significa que o alien esta andando para a direita
	beq t6, t4, N_ESQUERDA  # logo ele não pode ir pra a esquerda
	
N_BAIXO:
	li t2, 560		# carrega em t2 um valor grand epara ele nao ir para baixo	
	j MENOR			# pula para MENOR (verifica o menor entre t0, t1, t2 e t3)
N_DIREITA:
	li t3, 560		# carrega em t3 um valor grand epara ele nao ir para a direita
	j MENOR			# pula para MENOR (verifica o menor entre t0, t1, t2 e t3)
N_CIMA:
	li t0, 560		# carrega em t0 um valor grand epara ele nao ir para cima
	j MENOR			# pula para MENOR (verifica o menor entre t0, t1, t2 e t3)
N_ESQUERDA:
	li t1, 560 		# carrega em t1 um valor grand epara ele nao ir para a esquerda
	j MENOR			# pula para MENOR (verifica o menor entre t0, t1, t2 e t3
	
# Calcula a distancia de cada posição relativa do alien ate o target

LOOP_TARGET:

	sub a2, a0, t4		# a2 = a0 - t4 (a2 = x_alien - x_target)
	bge a2, zero, CONT	# se a2 for positivo, vai para o calculo da subtração entre "y_alien" e "y_target"
	neg a2, a2		# calcula o modulo do resultado caso a subtração entre "x_alien" e "x_target" seja menor que zero
	
CONT:	sub a3, a1, t5		# a3 = a1 - t5 (a3 = y_alien - y_target)	
	bge a3, zero, CONT2	# se a3 for positivo, vai para o calculo da soma de a2 e a3
	neg a3, a3		# calcula o modulo do resultado caso a subtração entre "y_alien" e "y_target" seja menor que zero
	
CONT2:  add a2, a2, a3		# a2 = distancia de manhatan da posição acima, abaixo, a esquerda ou a direita do alien
	ret			# retorna para verificar outra posição

# Uma vez calculadas as distãncias entre o target e as possiveis direções de movimentação do alien, faz um condicional para ver qual o menor registrador entre os 4 (t0, t1, t2, t3)
# prioridades de opção em caso de empate: cima > esquerda > baixo > direita

MENOR:	blt t1, t0, COMP1	# continua se t0 eh menor
	blt t3, t2, COMP2	# continua se t2 eh menor
	blt t2, t0, VDCA	# se t2 eh menor, então o alien verifica colisão em baixo
	j VUCA			# se não, ele verifica colisão acima
	
COMP1:	blt t3, t2, COMP3	# ja que t1 eh menor, resta ver qual eh menor: t2 ou t3, se t3 for menor, cai no mesmo loop de COMP2, so que comparando com o t1
	blt t2, t1, VDCA	# se t2 eh menor que o t1, então verifica colisão em baixo
	j VLCA			# se não, ele verifica colisão na esquerda
	
COMP2:	blt t3, t0, VRCA	# ja que t3 eh menor, resta ver qual eh menor: t0 ou t3, se t3 for menor, o alien verifica colisão na direita
	j VUCA			# se não, verifica colisão acima
	
COMP3:	blt t3, t1, VRCA	# ja que t3 eh menor, resta ver qual eh menor: t1 ou t3, se t3 for menor, o alien verifica colisão na direita
	j VLCA			# se não, verifica colisão na esquerda

# Verifica a colisao do mapa (VLCA, VUCA, VDCA e VRCA carregam 5 ou 6 pixels de detecção de colisão em cada direção, e VERC_A verifica se algum desses pixels detectou uma colisão adiante)

#	   @7       @8          @9          @10         @11
#	@6 #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  @12
#	   #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  
#	   #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  
#	@5 #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  @13
#	   #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  
#	   #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  
#	@4 #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  @14
#	   #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #			# representação do alien 16x16 com "#"
#	   #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  			# os "@x" são os pixels de colisão carregados ao redor do alien (o endereço de "@x" eh calculado em relação ao endereço em POS_ALIEN, sendo "@22" igual a propria posição)
#	@3 #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  @15			# OBS: os pixels de colisão detectam colisões apenas em relação ao mapa desenhado no Frame 1 da memoria VGA (mapa de colisão)
#	   #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #			# se tiver colisão, carrega "tX" com o maior valor possivel e volta para o loop MENOR
#	   #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #
#	@2 #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  @16
#	   #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #
#	   #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #
#	@1 #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  @17
#	   @22(POS) @21	        @20         @19         @18

# Carrega pixels de colisão acima (@7, @8, @9, @10, @11)

VUCA:	li t6, 1		# t6 = 1 (indica que o alien esta verificando se e possivel ir para cima)
	mv a1, a4		# a1 = a4 (endereço da posição do alien)
	
	li a2, -5440		# a2 = -5440
	add a1,a1,a2		# volta a1 1 linha e 1 pixel (carrega em a1 o endereço do pixel "@1")
	jal a3, VERC_A		# vá para VERC_A (verifica se o pixel "@1" detectou uma colisão)
	
	li a2, -5437		
	add a1,a1,a2		# volta a1 4 linhas e 1 pixel (carrega em t5 o endereço do pixel "@2")
	jal a3, VERC_A		# vá para VERC_A (verifica se o pixel "@1" detectou uma colisão)
	
	li a2, -5433		# a2 = -2241
	add a1,a1,a2		# volta a1 7 linhas e 1 pixel (carrega em t5 o endereço do pixel "@3")
	jal a3, VERC_A		# vá para VERC_A (verifica se o pixel "@1" detectou uma colisão)
	
	li a2, -5429		# a2 = -3201
	add a1,a1,a2		# volta a1 10 linhas e 1 pixel (carrega em a1 o endereço do pixel "@4")
	jal a3, VERC_A		# vá para VERC_A (verifica se o pixel "@1" detectou uma colisão)
	
	li a2, -5425		# a2 = -5121
	add a1,a1,a2		# volta a1 13 linhas e 1 pixel (carrega em a1 o endereço do pixel "@5")
	jal a3, VERC_A		# vá para VERC_A (verifica se o pixel "@1" detectou uma colisão)
	
	beq t6, zero, CUA	# se t6 for igual a zero, então houve colisão
	j SETUP_DELETE		# se não, ele pode se mover tranquilamente
	
CUA:	li t0, 561		# carrega t0 com um valor que não consiga ser menor que t1, t2 ou t3
	j MENOR			# volta para calcular qual o menor entre t1, t2 e t3
	
# Carrega pixels de colisão a esquerda (@1, @2, @3, @4, @5, @6)

VLCA:	li t6, 2		# t6 = 2 (indica que o alien esta verificando se e possivel ir para a esquerda)
	mv a1, a4		# a1 = a4 (endereço da posição do alien) 	
	
	addi a1,a1,-321		# volta a1 1 linha e 1 pixel (carrega em a1 o endereço do pixel "@1")
	jal a3, VERC_A		# vá para VERC_A (verifica se o pixel "@1" detectou uma colisão)
			
	addi a1,a1,-1281	# volta a1 4 linhas e 1 pixel (carrega em t5 o endereço do pixel "@2")
	jal a3, VERC_A		# vá para VERC_A (verifica se o pixel "@1" detectou uma colisão)
	
	li a2,-2241		# a2 = -2241
	add a1,a1,a2		# volta a1 7 linhas e 1 pixel (carrega em t5 o endereço do pixel "@3")
	jal a3, VERC_A		# vá para VERC_A (verifica se o pixel "@1" detectou uma colisão)
	
	li a2,-3201		# a2 = -3201
	add a1,a1,a2		# volta a1 10 linhas e 1 pixel (carrega em a1 o endereço do pixel "@4")
	jal a3, VERC_A		# vá para VERC_A (verifica se o pixel "@1" detectou uma colisão)
	
	li a2,-4161		# a2 = -5121
	add a1,a1,a2		# volta a1 13 linhas e 1 pixel (carrega em a1 o endereço do pixel "@5")
	jal a3, VERC_A		# vá para VERC_A (verifica se o pixel "@1" detectou uma colisão)
	
	li a2,-5121		# a2 = -5121
	add a1,a1,a2		# volta a1 16 linhas e 1 pixel (carrega em a1 o endereço do pixel "@6")
	jal a3, VERC_A		# vá para VERC_A (verifica se o pixel "@1" detectou uma colisão)
	
	beq t6, zero, CLA	# se t6 for igual a zero, então houve colisão
	j SETUP_DELETE		# se não, ele pode se mover tranquilamente
	
CLA:	li t1, 561		# carrega t1 com um valor que não consiga ser menor que t0, t2 ou t3
	j MENOR			# volta para calcular qual o menor entre t0, t2 e t3

# Carrega pixels de colisão abaixo (@22, @21, @20, @19, @18)

VDCA:	li t6, 3		# t6 = 3 (indica que o alien esta verificando se e possivel ir para baixo)
	mv a1, a4		# a1 = a4 (endereço da posição do alien)
	jal a3, VERC_A		# vá para VERC_A (verifica se o pixel "@1" detectou uma colisão)
			
	addi a1,a1,3		# volta a1 4 linhas e 1 pixel (carrega em t5 o endereço do pixel "@2")
	jal a3, VERC_A		# vá para VERC_A (verifica se o pixel "@1" detectou uma colisão)
	
	addi a1,a1,7		# volta a1 7 linhas e 1 pixel (carrega em t5 o endereço do pixel "@3")
	jal a3, VERC_A		# vá para VERC_A (verifica se o pixel "@1" detectou uma colisão)
	
	addi a1,a1,11		# volta a1 10 linhas e 1 pixel (carrega em a1 o endereço do pixel "@4")
	jal a3, VERC_A		# vá para VERC_A (verifica se o pixel "@1" detectou uma colisão)
	
	addi a1,a1,15		# volta a1 13 linhas e 1 pixel (carrega em a1 o endereço do pixel "@5")
	jal a3, VERC_A		# vá para VERC_A (verifica se o pixel "@1" detectou uma colisão)
	
	beq t6, zero, CDA	# se t6 não for igual a zero, então houve colisão
	j SETUP_DELETE		# se não, ele pode se mover tranquilamente
	
CDA:	li t2, 561		# carrega t2 com um valor que não consiga ser menor que t0, t1 ou t3
	j MENOR			# volta para calcular qual o menor entre t0, t1 e t3
	
# Carrega pixels de colisão a direita (@17, @16, @15, @14, @13, @12)

VRCA:	li t6, 4		# t6 = 4 (indica que o alien esta verificando se e possivel ir para a direita)
	mv a1, a4		# a1 = a4 (endereço da posição do alien)
	
	addi a1,a1,-304		# volta a1 1 linha e 1 pixel (carrega em a1 o endereço do pixel "@1")
	jal a3, VERC_A		# vá para VERC_A (verifica se o pixel "@1" detectou uma colisão)
			
	addi a1,a1,-1264	# volta a1 4 linhas e 1 pixel (carrega em t5 o endereço do pixel "@2")
	jal a3, VERC_A		# vá para VERC_A (verifica se o pixel "@1" detectou uma colisão)
	
	li a2,-2224		# a2 = -2241
	add a1,a1,a2		# volta a1 7 linhas e 1 pixel (carrega em t5 o endereço do pixel "@3")
	jal a3, VERC_A		# vá para VERC_A (verifica se o pixel "@1" detectou uma colisão)
	
	li a2,-3184		# a2 = -3201
	add a1,a1,a2		# volta a1 10 linhas e 1 pixel (carrega em a1 o endereço do pixel "@4")
	jal a3, VERC_A		# vá para VERC_A (verifica se o pixel "@1" detectou uma colisão)
	
	li a2,-4144		# a2 = -5121
	add a1,a1,a2		# volta a1 13 linhas e 1 pixel (carrega em a1 o endereço do pixel "@5")
	jal a3, VERC_A		# vá para VERC_A (verifica se o pixel "@1" detectou uma colisão)
	
	li a2,-5104		# a2 = -5121
	add a1,a1,a2		# volta a1 16 linhas e 1 pixel (carrega em a1 o endereço do pixel "@6")
	jal a3, VERC_A		# vá para VERC_A (verifica se o pixel "@1" detectou uma colisão)
	
	beq t6, zero, CRA	# se t6 não for igual a zero, então houve colisão
	j SETUP_DELETE		# se não, ele pode se mover tranquilamente
	
CRA:	li t3, 561		# carrega t3 com um valor que não consiga ser menor que t0, t1 ou t2
	j MENOR			# volta para calcular qual o menor entre t0, t1 e t2
	
# Verifica a colisão em casa pixel

VERC_A:	li a0,0x100000		# a0 = 0x100000
	add a1,a1,a0		# soma 0x100000 a a1 (transforma o conteudo de a em um endereço do Frame 1)
	lbu a0,0(a1)		# carrega em a0 um byte do endereço a1 (cor do pixel de a1) -> OBS: o load byte deve ser "unsigned" 
				# Ex: 0d200 = 0xc8 = 0b11001000. como o MSB desse byte õ© 1, ele seria interpretado como -56 e não 200 (t6 = 0xffffffc8)
				
	li a1,0x69
	beq a0,a1, COLIDIU_R			
	li a1,200		# a1 = 200
	beq a0,a1, COLIDIU_A	# se a0 = 200, vá para COLIDIU_A (se a cor do pixel for azul, termina a iteração e impede movimento do Robozinho)
	li a1,3			# a1 = 3
	beq a0,a1, COLIDIU_A	# se a0 = 200, vá para COLIDIU_A (se a cor do pixel for azul, termina a iteração e impede movimento do Robozinho)
	li a1,7			# a1 = 7	
	beq a0,a1, COLIDIU_A	# se a0 = 200, vá para COLIDIU_A (se a cor do pixel for azul, termina a iteração e impede movimento do Robozinho)
	mv a1, a4		# a1 = a4
	jalr x0, a3, 0 		# retorna para verificar se outro pixel detectou colisão
	
COLIDIU_A:
	li t6, 0		# colidiu, logo t6 recebe o valor de 0
	mv a1, a4		# a1 = a4
	jalr x0, a3, 0 		# retorna para verificar se outro pixel detectou colisão
	
# Deleta o personagem caso haja movimento

SETUP_DELETE:
	
	mv t1,a4		# t1 = a4 (posição atual do alien - pixel inicial da linha)
	addi t2,a4,16		# t2 = a4 + 16 (posição atual do alien - pixel inicial da linha)
	mv a5,t6		# a5 = t6 (direção atual de movimentação do alien)
	
DELETE_A:

	li t5,0	
	li t6,16		# reinicia o contador para 16 quebras de linha
	
	li t4, 5120		# t4 = 5120
	sub t1, t1, t4		# volta t1 16 linhas (pixel inicial da primeira linha) 
	sub t2, t2, t4		# volta t2 16 linhas (pixel final da primeira linha)
	
	li t0,1
	beq s6,t0,DELFS1
	la t3,mapa2
	j DELFS2
DELFS1:	la t3,mapa1		# carrega em t3 o endereço dos dados do mapa1
DELFS2:	addi t3,t3,8		# t3 = endereço do primeiro pixel do mapa1 (depois das informações de nlin ncol)
	li t0,0xFF000000	# t0 = 0xFF000000 (carrega em t0 o endereço base da memoria VGA)
	sub t0,t1,t0		# t0 = t1 - 0xFF000000 (subtrai o endereço base de t1, posição atual do alien)
	add t3,t3,t0		# t3 = t3 + t0 (carrega em t3 o endereço do pixel do mapa1 no segmento de dados sobre o qual o alien esta localizado)
	
DELLOOP_A:
	beq t1,t2,ENTER2_A	# se t1 atingir o fim da linha de pixels, quebre linha
	lw t0,0(t3)		# le uma word do endereço t3 (le 4 pixels do mapa1 no segmento de dados)
	sw t0,0(t1)		# escreve a word (4 pixels do mapa1) na memoria VGA
	addi t1,t1,4		# soma 4 ao endereço t1
	addi t3,t3,4		# soma 4 ao endereço t3
	j DELLOOP_A		# volta a verificar a condiçao do loop

ENTER2_A:
	addi t1,t1,304		# t1 (a4) pula para o pixel inicial da linha de baixo da memoria VGA
	addi t3,t3,304		# t1 pula para o pixel inicial da linha de baixo do segmento de dados 
	addi t2,t2,320		# t2 (a4 + 16) pula para o pixel final da linha de baixo da memoria VGA
	addi t5,t5,1          	# atualiza o contador de quebras de linha
	beq t5,t6,SETUP_DELETE_COL	# termina o carregamento da imagem se 16 quebras de linha ocorrerem e vai para o loop de carregamento da imagem
	j DELLOOP_A		# pula para delloop
	
# Deleta o personagem caso haja movimento

SETUP_DELETE_COL:
	
	li t0,0x100000
	add t1,a4,t0
	addi t2,t1,16		# t2 = a4 + 16 (posição atual do alien - pixel inicial da linha)
	
DELETE_A_COL:

	li t5,0	
	li t6,16		# reinicia o contador para 16 quebras de linha
	
	li t4, 5120		# t4 = 5120
	sub t1, t1, t4		# volta t1 16 linhas (pixel inicial da primeira linha) 
	sub t2, t2, t4		# volta t2 16 linhas (pixel final da primeira linha)
	
	li t0,1
	beq s6,t0,DELFS1_COL
	la t3,mapa2colisao
	j DELFS2_COL
	
DELFS1_COL:	
	la t3,mapa1colisao		# carrega em t3 o endereço dos dados do mapa1

DELFS2_COL:	
	addi t3,t3,8		# t3 = endereço do primeiro pixel do mapa1 (depois das informações de nlin ncol)
	li t0,0xFF100000	# t0 = 0xFF000000 (carrega em t0 o endereço base da memoria VGA)
	sub t0,t1,t0		# t0 = t1 - 0xFF000000 (subtrai o endereço base de t1, posição atual do alien)
	add t3,t3,t0		# t3 = t3 + t0 (carrega em t3 o endereço do pixel do mapa1 no segmento de dados sobre o qual o alien esta localizado)
	
DELLOOP_A_COL:
	beq t1,t2,ENTER2_A_COL	# se t1 atingir o fim da linha de pixels, quebre linha
	lw t0,0(t3)		# le uma word do endereço t3 (le 4 pixels do mapa1 no segmento de dados)
	sw t0,0(t1)		# escreve a word (4 pixels do mapa1) na memoria VGA
	addi t1,t1,4		# soma 4 ao endereço t1
	addi t3,t3,4		# soma 4 ao endereço t3
	j DELLOOP_A_COL		# volta a verificar a condiçao do loop

ENTER2_A_COL:
	addi t1,t1,304		# t1 (a4) pula para o pixel inicial da linha de baixo da memoria VGA
	addi t3,t3,304		# t1 pula para o pixel inicial da linha de baixo do segmento de dados 
	addi t2,t2,320		# t2 (a4 + 16) pula para o pixel final da linha de baixo da memoria VGA
	addi t5,t5,1          	# atualiza o contador de quebras de linha
	beq t5,t6,SETUP_MOV	# termina o carregamento da imagem se 16 quebras de linha ocorrerem e vai para o loop de carregamento da imagem
	j DELLOOP_A_COL		# pula para delloop

# ve em qual direção foi o movimento para printar o personagem

SETUP_MOV:

	mv t3, a6		# volta o t3 com a label de a6
	addi t3, t3, 8		# s0 = endereço do primeiro pixel da imagem (depois das informações de nlin ncol)
	
	li t5,0
	li t6,16		# inicializa o contador de quebra de linha para 16 quebras de linha
	
	li t0, 1			# t0 = 1
	beq a5, t0, MOV_UP_A		# se a5 = 1, então vai para MOV_UP_A
	
	li t0, 2			# t0 = 2
	beq a5, t0, MOV_LEFT_A		# se a5 = 2, então vai para MOV_LEFT_A
	
	li t0, 3			# t0 = 3
	beq a5, t0, MOV_DOWN_A		# se a5 = 3, então vai para MOV_DOWN_A
	
	li t0, 4			# t0 = 4
	beq a5, t0, MOV_RIGHT_A		# se a5 = 4, então vai para MOV_RIGHT_A

MOV_UP_A: 

	mv t1, a4		# t1 = a4 (posição atual do alien - pixel inicial da linha)
	li t4, 0		# salva em t4 a movimentação atual do alien
	addi t2,a4,16		# t2 = a4 + 16 (posição atual do alien - pixel final da linha)
	
	li t0, 6400		# t0 = 6400
	sub t1,t1, t0		# volta t1 20 linhas (pixel inicial 4 linhas acima) 
	sub t2, t2, t0		# volta t2 20 linhas (pixel final 4 linhas acima)
	
	j LOOP2_MA		# pule para LOOP2_MA (loop que printa o alien na tela)
	
MOV_LEFT_A:

	mv t1, a4		# t1 = a4 (posição atual do alien - pixel inicial da linha)
	li t4, 1		# salva em t4 a movimentação atual do alien
	addi t2,a4,16		# t2 = a4 + 16 (posição atual do alien - pixel final da linha)
	
	li t0, 5124		# t0 = 5124
	sub t1,t1, t0		# volta t1 16 linhas e vai 4 pixels para a esquerda (pixel inicial - 4)
	sub t2, t2, t0		# volta t1 16 linhas e vai 4 pixels para a esquerda (pixel final - 4)
	
	j LOOP2_MA		# pule para LOOP2_MA (loop que printa o alien na tela)
	
MOV_DOWN_A:

	mv t1, a4		# t1 = a4 (posição atual do alien - pixel inicial da linha)
	li t4, 2		# salva em t4 a movimentação atual do alien
	addi t2,a4,16		# t2 = a4 + 16 (posição atual do alien - pixel final da linha)
	
	li t0, 3840		# t0 = 3840
	sub t1,t1, t0		# volta t1 12 linhas (pixel inicial 4 linhas abaixo) 
	sub t2, t2, t0		# volta t2 12 linhas (pixel final 4 linhas abaixo)
	
	j LOOP2_MA		# pule para LOOP2_MA (loop que printa o alien na tela)
	
MOV_RIGHT_A:

	mv t1, a4		# t1 = a4 (posição atual do alien - pixel inicial da linha)
	li t4, 3		# salva em t4 a movimentação atual do alien
	addi t2,a4,16		# t2 = a4 + 16 (posição atual do alien - pixel final da linha)
	
	li t0, 5116		# t0 = 5116
	sub t1,t1, t0		# volta t1 16 linhas e vai 4 pixels para a direita (pixel inicial + 4) 
	sub t2, t2, t0		# volta t1 16 linhas e vai 4 pixels para a direita (pixel final + 4)
	
	j LOOP2_MA		# pule para LOOP2_MA (loop que printa o alien na tela)

LOOP2_MA:
	beq t1,t2,ENTER_MA	# se t1 atingir o fim da linha de pixels, quebre linha
	lw t0,0(t3)		# le uma word do endereço t3 (le 4 pixels da imagem)
	sw t0,0(t1)		# escreve a word na memoria VGA no endereço t1 (desenha 4 pixels na tela do Bitmap Display)
	
	li t0,0x100000
	add t1,t1,t0
	
	li t0, 1			# t0 = 1
	beq s4, t0, PRINT70		# se a5 = 1, então vai para MOV_UP_A
	
	li t0, 2			# t0 = 2
	beq s4, t0, PRINT71		# se a5 = 2, então vai para MOV_LEFT_A
	
	li t0, 3			# t0 = 3
	beq s4, t0, PRINT72		# se a5 = 3, então vai para MOV_DOWN_A
	
	li t0, 4			# t0 = 4
	beq s4, t0, PRINT73		# se a5 = 4, então vai para MOV_RIGHT_A
	
PRINT70:li t0,0x70707070
	sw t0,0(t1) 
	j NXTSQR
	
PRINT71:li t0,0x71717171
	sw t0,0(t1)
	j NXTSQR
	
PRINT72:li t0,0x72727272
	sw t0,0(t1)
	j NXTSQR
	
PRINT73:li t0,0x73737373
	sw t0,0(t1)
	j NXTSQR
	
NXTSQR:	li t0,0x100000
	sub t1,t1,t0
	addi t1,t1,4		# soma 4 ao endereço t1
	addi t3,t3,4		# soma 4 ao endereço t3
	j LOOP2_MA 		# volta a verificar a condiçao do loop
	
ENTER_MA:
	addi t1,t1,304		# t1 pula para o pixel inicial da linha de baixo
	addi t2,t2,320		# t2 pula para o pixel final da linha de baixo
	addi t5,t5,1          	# atualiza o contador de quebras de linha
	beq t5,t6,FIM_MOV	# termina o carregamento da imagem se 16 quebras de linha ocorrerem
	j LOOP2_MA		# pule para LOOP2_MA

# Verifica qual alien foi movimentado baseado em s4, atualiza a posição dele e retorna para ver se mais um alien deve ser movimentado

FIM_MOV:

	li t0,1				# t0 = 1
	beq s4, t0, BLINKY_MOV		# se s4 = 1, então vai para BLINKY_MOV
	
	li t0,2				# t0 = 2
	beq s4, t0, PINK_MOV		# se s4 = 2, então vai para PINK_MOV
	
	li t0,3				# t0 = 3
	beq s4, t0, INKY_MOV		# se s4 = 3, então vai para INKY_MOV
	
	li t0,4				# t0 = 4
	beq s4, t0, CLYDE_MOV		# se s4 = 4, então vai para CLYDE_MOV
	
# Atualiza a posição do alien movimentado	
	
BLINKY_MOV:
	la t0, POS_BLINKY   	# carrega o endereço de "POS_ROBOZINHO" no registrador t0 
    	sw t1, 0(t0)       	# guarda a word armazenada em t1 (posição atual do Roboziho) em "POS_ROBOZINHO"
    	add s7, s7 ,t4		# adiciona ao movimento do alien o movimento atual(ex.: s7 = 17 + t4)	
	jal zero, PINK
PINK_MOV:
	la t0, POS_PINK   	# carrega o endereço de "POS_ROBOZINHO" no registrador t0 
    	sw t1, 0(t0)       	# guarda a word armazenada em t1 (posição atual do Roboziho) em "POS_ROBOZINHO"	
    	add s9, s9, t4		# adiciona ao movimento do alien o movimento atual(ex.: s9 = 17 + t4)
	jal zero, INKY
INKY_MOV:
	la t0, POS_INKY   	# carrega o endereço de "POS_ROBOZINHO" no registrador t0 
    	sw t1, 0(t0)       	# guarda a word armazenada em t1 (posição atual do Roboziho) em "POS_ROBOZINHO"	
    	add s10, s10, t4	# adiciona ao movimento do alien o movimento atual(ex.: s10 = 17 + t4)
	jal zero, CLYDE
CLYDE_MOV:
	la t0, POS_CLYDE   	# carrega o endereço de "POS_ROBOZINHO" no registrador t0 
    	sw t1, 0(t0)       	# guarda a word armazenada em t1 (posição atual do Roboziho) em "POS_ROBOZINHO"
    	add s11, s11, t4	# adiciona ao movimento do alien o movimento atual(ex.: s11 = 17 + t4)
    	
    	li a7,32		# carrega em a7 o serviço 32 do ecall (sleep - interrompe a execução do programa)
	li a0,80		# carrega em a0 o tempo pelo qual o codigo sera interrompido (2 ms)
	ecall			# realiza o ecall
	
	j ROBOZINHO
	
# Se o alien colidir com o Robozinho

COLIDIU_R:

	li t0,1				# t0 = 1
	beq s4, t0, BLINKY_COLIDIU	# se s4 = 1, então vai para BLINKY_COLIDIU
		
	li t0,2				# t0 = 2
	beq s4, t0, PINK_COLIDIU	# se s4 = 2, então vai para PINK_COLIDIU
		
	li t0,3				# t0 = 3
	beq s4, t0, INKY_COLIDIU	# se s4 = 3, então vai para INKY_COLIDIU
		
	li t0,4				# t0 = 4
	beq s4, t0, CLYDE_COLIDIU	# se s4 = 4, então vai para CLYDE_COLIDIU
	
	
BLINKY_COLIDIU:
	mv a1, s7			# a1 = s7
	jal zero, COLIDIU_R_2

PINK_COLIDIU:
	mv a1, s9			# a1 = s9
	jal zero, COLIDIU_R_2

INKY_COLIDIU:
	mv a1, s10			# a1 = s10
	jal zero, COLIDIU_R_2

CLYDE_COLIDIU:
	mv a1, s11			# a1 = s11
	
COLIDIU_R_2:
	li a0,38			# a0 = 38
	blt a1,a0,VERFASE		# se a1 for menor que o a0 entÃ£o o alien estava no sdcatter/chase mode, entÃ£o o robozino perdeu vida
	
VER_ALIEN_2:				# se nÃ£o, ve qual o alien e respawna ele
	
	la t0, PONTOS
	lw t1, 0(t0)
	addi t1,t1,200
	sw t1, 0(t0)
	
	mv t0,a4

	li a7,104		# carrega em a7 o serviço 101 do ecall (print integer on bitmap display)
	la a0,STR3		# carrega em a0 o valor do inteiro a ser printado (s1 = pontuação atual do jogador)
	li a1,56		# carrega em a1 a coluna a partir da qual o inteiro vai ser printado (coluna 60)
        li a2,11		# carrega em a1 a linha a partir da qual o inteiro vai ser printado (linha 2)
	li a3,0x00FF		# carrega em a3 a cor de fundo (0x00 - preto) e a cor dos caracteres (0xFF - branco)
	li a4,0			# carrega em a4 o frame onde o inteiro deve ser printado (Frame 0 da memoria VGA)
	ecall			# realiza o ecall
	
	li a0,61		# a0 = 76 (carrega mi para a0)
	li a1,200		# a1 = 100 (nota de duração de 100 ms)
	li a2,33		# a2 = 32 (timbre "guitar harmonic")
	li a3,80		# a3 = 50 (volume da nota)
	li a7,31		# a7 = 31 (carrega em a7 o ecall "MidiOut")
	ecall			# realiza o ecall
	
	li a0,73		# a0 = 76 (carrega mi para a0)
	li a1,200		# a1 = 100 (nota de duração de 100 ms)
	li a2,33		# a2 = 32 (timbre "guitar harmonic")
	li a3,80		# a3 = 50 (volume da nota)
	li a7,31		# a7 = 31 (carrega em a7 o ecall "MidiOut")
	ecall			# realiza o ecall
	
	li a0,100		# a3 = 50 (volume da nota)
	li a7,32		# a7 = 31 (carrega em a7 o ecall "MidiOut")
	ecall			# realiza o ecall
	
	li a7,104		# carrega em a7 o serviço 101 do ecall (print integer on bitmap display)
	la a0,STR4		# carrega em a0 o valor do inteiro a ser printado (s1 = pontuação atual do jogador)
	li a1,56		# carrega em a1 a coluna a partir da qual o inteiro vai ser printado (coluna 60)
        li a2,11		# carrega em a1 a linha a partir da qual o inteiro vai ser printado (linha 2)
	li a3,0x00FF		# carrega em a3 a cor de fundo (0x00 - preto) e a cor dos caracteres (0xFF - branco)
	li a4,0			# carrega em a4 o frame onde o inteiro deve ser printado (Frame 0 da memoria VGA)
	ecall			# realiza o ecall
	
	li a0,59		# a0 = 76 (carrega mi para a0)
	li a1,200		# a1 = 100 (nota de duração de 100 ms)
	li a2,33		# a2 = 32 (timbre "guitar harmonic")
	li a3,80		# a3 = 50 (volume da nota)
	li a7,31		# a7 = 31 (carrega em a7 o ecall "MidiOut")
	ecall			# realiza o ecall
	
	li a0,71		# a0 = 76 (carrega mi para a0)
	li a1,200		# a1 = 100 (nota de duração de 100 ms)
	li a2,33		# a2 = 32 (timbre "guitar harmonic")
	li a3,80		# a3 = 50 (volume da nota)
	li a7,31		# a7 = 31 (carrega em a7 o ecall "MidiOut")
	ecall			# realiza o ecall
	
	li a0,100		# a3 = 50 (volume da nota)
	li a7,32		# a7 = 31 (carrega em a7 o ecall "MidiOut")
	ecall			# realiza o ecall
	
	li a7,104		# carrega em a7 o serviço 101 do ecall (print integer on bitmap display)
	la a0,STR3		# carrega em a0 o valor do inteiro a ser printado (s1 = pontuação atual do jogador)
	li a1,56		# carrega em a1 a coluna a partir da qual o inteiro vai ser printado (coluna 60)
        li a2,11		# carrega em a1 a linha a partir da qual o inteiro vai ser printado (linha 2)
	li a3,0x00FF		# carrega em a3 a cor de fundo (0x00 - preto) e a cor dos caracteres (0xFF - branco)
	li a4,0			# carrega em a4 o frame onde o inteiro deve ser printado (Frame 0 da memoria VGA)
	ecall			# realiza o ecall
	
	li a0,61		# a0 = 76 (carrega mi para a0)
	li a1,200		# a1 = 100 (nota de duração de 100 ms)
	li a2,33		# a2 = 32 (timbre "guitar harmonic")
	li a3,80		# a3 = 50 (volume da nota)
	li a7,31		# a7 = 31 (carrega em a7 o ecall "MidiOut")
	ecall			# realiza o ecall
	
	li a0,73		# a0 = 76 (carrega mi para a0)
	li a1,200		# a1 = 100 (nota de duração de 100 ms)
	li a2,33		# a2 = 32 (timbre "guitar harmonic")
	li a3,80		# a3 = 50 (volume da nota)
	li a7,31		# a7 = 31 (carrega em a7 o ecall "MidiOut")
	ecall			# realiza o ecall
	
	li a0,200		# a3 = 50 (volume da nota)
	li a7,32		# a7 = 31 (carrega em a7 o ecall "MidiOut")
	ecall			# realiza o ecall
	
	li a7,104		# carrega em a7 o serviço 101 do ecall (print integer on bitmap display)
	la a0,STR4		# carrega em a0 o valor do inteiro a ser printado (s1 = pontuação atual do jogador)
	li a1,56		# carrega em a1 a coluna a partir da qual o inteiro vai ser printado (coluna 60)
        li a2,11		# carrega em a1 a linha a partir da qual o inteiro vai ser printado (linha 2)
	li a3,0x00FF		# carrega em a3 a cor de fundo (0x00 - preto) e a cor dos caracteres (0xFF - branco)
	li a4,0			# carrega em a4 o frame onde o inteiro deve ser printado (Frame 0 da memoria VGA)
	ecall			# realiza o ecall
	
	mv a4,t0
	
	li t0,1				# t0 = 1
	beq s4, t0, BLINKY_MORTE	# se s4 = 1, então vai para BLINKY_MORTE
		
	li t0,2				# t0 = 2
	beq s4, t0, PINK_MORTE		# se s4 = 2, então vai para PINK_MORTE
		
	li t0,3				# t0 = 3
	beq s4, t0, INKY_MORTE		# se s4 = 3, então vai para INKY_MORTE
		
	li t0,4				# t0 = 4
	beq s4, t0, CLYDE_MORTE		# se s4 = 4, então vai para CLYDE_MORTE

BLINKY_MORTE:

	li t0, 17			# t0 = 17
	rem t1, s7, t0			# t1 = resto da movimentaÃ§Ã£o
	li s7, 34			# s7 = 34 
	add s7, s7, t1			# s7 = 34 + t1
	
	li t0, 0xFF009BC8		# posiÃ§Ã£o dentro da caixa
	la t1, POS_BLINKY		# t1 = POS_BLINKY
	sw t0, 0(t1)			# POS_BLINKY = posiÃ§Ã£o dentro da caixa
	
	jal zero, SETUP_DELETE_MORTE
	
PINK_MORTE:

	li t0, 17			# t0 = 17
	rem t1, s9, t0			# t1 = resto da movimentaÃ§Ã£o
	li s9, 34			# s9 = 34 
	add s9, s9, t1			# s9 = 34 + t1
	
	li t0, 0xFF009BC8		# posiÃ§Ã£o dentro da caixa
	la t1, POS_PINK		# t1 = POS_PINK
	sw t0, 0(t1)			# POS_PINK = posiÃ§Ã£o dentro da caixa
	
	jal zero, SETUP_DELETE_MORTE
	
INKY_MORTE:

	li t0, 17			# t0 = 17
	rem t1, s10, t0			# t1 = resto da movimentaÃ§Ã£o
	li s10, 34			# s10 = 34 
	add s10, s10, t1		# s10 = 34 + t1
	
	li t0, 0xFF009BC8		# posiÃ§Ã£o dentro da caixa
	la t1, POS_INKY			# t1 = POS_INKY
	sw t0, 0(t1)			# POS_INKY = posiÃ§Ã£o dentro da caixa
	
	jal zero, SETUP_DELETE_MORTE
	
CLYDE_MORTE:
		
	li t0, 17			# t0 = 17
	rem t1, s11, t0			# t1 = resto da movimentaÃ§Ã£o
	li s11, 34			# s11 = 34 
	add s11, s11, t1		# s11 = 34 + t1
	
	li t0, 0xFF009BC8		# posiÃ§Ã£o dentro da caixa
	la t1, POS_CLYDE		# t1 = POS_CLYDE
	sw t0, 0(t1)			# POS_CLYDE = posiÃ§Ã£o dentro da caixa

SETUP_DELETE_MORTE:
	
	mv t1,a4		# t1 = a4 (posição atual do alien - pixel inicial da linha)
	addi t2,a4,16		# t2 = a4 + 16 (posição atual do alien - pixel inicial da linha)
	mv a5,t6		# a5 = t6 (direção atual de movimentação do alien)
	
DELETE_A_MORTE:

	li t5,0	
	li t6,16		# reinicia o contador para 16 quebras de linha
	
	li t4, 5120		# t4 = 5120
	sub t1, t1, t4		# volta t1 16 linhas (pixel inicial da primeira linha) 
	sub t2, t2, t4		# volta t2 16 linhas (pixel final da primeira linha)
	
	li t0,1
	beq s6,t0,DELFS1_MORTE
	la t3,mapa2
	j DELFS2_MORTE
DELFS1_MORTE:	
	la t3,mapa1		# carrega em t3 o endereço dos dados do mapa1
DELFS2_MORTE:	
	addi t3,t3,8		# t3 = endereço do primeiro pixel do mapa1 (depois das informações de nlin ncol)
	li t0,0xFF000000	# t0 = 0xFF000000 (carrega em t0 o endereço base da memoria VGA)
	sub t0,t1,t0		# t0 = t1 - 0xFF000000 (subtrai o endereço base de t1, posição atual do alien)
	add t3,t3,t0		# t3 = t3 + t0 (carrega em t3 o endereço do pixel do mapa1 no segmento de dados sobre o qual o alien esta localizado)
	
DELLOOP_A_MORTE:
	beq t1,t2,ENTER2_A_MORTE# se t1 atingir o fim da linha de pixels, quebre linha
	lw t0,0(t3)		# le uma word do endereço t3 (le 4 pixels do mapa1 no segmento de dados)
	sw t0,0(t1)		# escreve a word (4 pixels do mapa1) na memoria VGA
	addi t1,t1,4		# soma 4 ao endereço t1
	addi t3,t3,4		# soma 4 ao endereço t3
	j DELLOOP_A_MORTE	# volta a verificar a condiçao do loop

ENTER2_A_MORTE:
	addi t1,t1,304		# t1 (a4) pula para o pixel inicial da linha de baixo da memoria VGA
	addi t3,t3,304		# t1 pula para o pixel inicial da linha de baixo do segmento de dados 
	addi t2,t2,320		# t2 (a4 + 16) pula para o pixel final da linha de baixo da memoria VGA
	addi t5,t5,1          	# atualiza o contador de quebras de linha
	beq t5,t6,SETUP_DELETE_COL_MORTE # termina o carregamento da imagem se 16 quebras de linha ocorrerem e vai para o loop de carregamento da imagem
	j DELLOOP_A_MORTE		# pula para delloop
	
# Deleta o personagem caso ele morra

SETUP_DELETE_COL_MORTE:
	
	li t0,0x100000
	add t1,a4,t0
	addi t2,t1,16		# t2 = a4 + 16 (posição atual do alien - pixel inicial da linha)
	
DELETE_A_COL_MORTE:

	li t5,0	
	li t6,16		# reinicia o contador para 16 quebras de linha
	
	li t4, 5120		# t4 = 5120
	sub t1, t1, t4		# volta t1 16 linhas (pixel inicial da primeira linha) 
	sub t2, t2, t4		# volta t2 16 linhas (pixel final da primeira linha)
	
	li t0,1
	beq s6,t0,DELFS1_COL_MORTE
	la t3,mapa2colisao
	j DELFS2_COL_MORTE
	
DELFS1_COL_MORTE:	
	la t3,mapa1colisao		# carrega em t3 o endereço dos dados do mapa1

DELFS2_COL_MORTE:	
	addi t3,t3,8		# t3 = endereço do primeiro pixel do mapa1 (depois das informações de nlin ncol)
	li t0,0xFF100000	# t0 = 0xFF000000 (carrega em t0 o endereço base da memoria VGA)
	sub t0,t1,t0		# t0 = t1 - 0xFF000000 (subtrai o endereço base de t1, posição atual do alien)
	add t3,t3,t0		# t3 = t3 + t0 (carrega em t3 o endereço do pixel do mapa1 no segmento de dados sobre o qual o alien esta localizado)
	
DELLOOP_A_COL_MORTE:
	beq t1,t2,ENTER2_A_COL_MORTE	# se t1 atingir o fim da linha de pixels, quebre linha
	lw t0,0(t3)		# le uma word do endereço t3 (le 4 pixels do mapa1 no segmento de dados)
	sw t0,0(t1)		# escreve a word (4 pixels do mapa1) na memoria VGA
	addi t1,t1,4		# soma 4 ao endereço t1
	addi t3,t3,4		# soma 4 ao endereço t3
	j DELLOOP_A_COL_MORTE		# volta a verificar a condiçao do loop

ENTER2_A_COL_MORTE:
	addi t1,t1,304		# t1 (a4) pula para o pixel inicial da linha de baixo da memoria VGA
	addi t3,t3,304		# t1 pula para o pixel inicial da linha de baixo do segmento de dados 
	addi t2,t2,320		# t2 (a4 + 16) pula para o pixel final da linha de baixo da memoria VGA
	addi t5,t5,1          	# atualiza o contador de quebras de linha
	beq t5,t6,FIM_MORTE	# termina o carregamento da imagem se 16 quebras de linha ocorrerem e vai para o loop de carregamento da imagem
	j DELLOOP_A_COL_MORTE	# pula para delloop
	
FIM_MORTE:
	jal ROBOZINHO 		# vai para a movimentaÃ§Ã£o do Robozinho

VERFASE:li t2,5120
	la t0,POS_ROBOZINHO	# carrega o endereço de "POS_ROBOZINHO" no registrador t0
	lw t1,0(t0)		# le a word guardada em "POS_ROBOZINHO" para t1 (t1 = posição atual do Robozinho)
	sub t1,t1,t2		# volta t1 16 linhas e vai 4 pixels pra frente (pixel inicial + 4) 
	mv t2,t1 		# t2 = t1
	addi t2,t2,16		# t2 = t2 + 16 (pixel final da primeira linha + 4)
	
	la t3,Robozinhomorto	# t3 = endereço dos dados do Robozinho1 (boca fechada)
	addi t3,t3,8		# t3 = endereço do primeiro pixel da imagem (depois das informações de nlin ncol)

	li t5,0
	li t6,16		# reinicia contador para 16 quebras de linha	
	
LOOP_MRT: 	
	beq t1,t2,ENTER_MRT	# se t1 atingir o fim da linha de pixels, quebre linha
	lw t0,0(t3)		# le uma word do endereço t3 (le 4 pixels da imagem)
	sw t0,0(t1)		# escreve a word na memoria VGA no endereço t1 (desenha 4 pixels na tela do Bitmap Display)
	addi t1,t1,4		# soma 4 ao endereço t1
	addi t3,t3,4		# soma 4 ao endereço t3
	j LOOP_MRT			# volta a verificar a condiçao do loop
	
ENTER_MRT:	
	addi t1,t1,304		# t1 pula para o pixel inicial da linha de baixo
	addi t2,t2,320		# t2 pula para o pixel final da linha de baixo
	addi t5,t5,1            # atualiza o contador de quebras de linha
	beq t5,t6,AFTER		# termine o carregamento da imagem se 16 quebras de linha ocorrerem
	j LOOP_MRT			# pula para loop 3

AFTER:	li t0,1
	beq s6,t0,FASE1C
	jal zero, RESET_FASE2
##################################
DERROTAC: jal zero, DERROTA
VITORIAC: jal zero, VITORIA
FASE1C: jal zero, FASE1
FASE2C: jal zero, FASE2
##################################
# Parte do codigo que lida com a movimentação do Robozinho

ROBOZINHO:

	li a7,104		# carrega em a7 o serviço 104 do ecall (print string on bitmap display)
	la a0,STR		# carrega em a0 o endereço da string a ser printada (STR: "SCORE: ")
	li a1,3			# carrega em a1 a coluna a partir da qual a string vai ser printada (coluna 0)
       	li a2,2			# carrega em a2 a linha a partir da qual a string vai ser printada (linha 2)
	li a3,0x00FF		# carrega em a3 a cor de fundo (0x00 - preto) e a cor dos caracteres (0xFF - branco)
	li a4,0 		# carrega em a4 o frame onde a string deve ser printada (Frame 0 da memoria VGA)
	ecall			# realiza o ecall
	
	la t1, PONTOS
	lw t0, 0(t1)
	
	li a7,101		# carrega em a7 o serviço 101 do ecall (print integer on bitmap display)
	mv a0,t0		# carrega em a0 o valor do inteiro a ser printado (s1 = pontuação atual do jogador)
	li a1,55		# carrega em a1 a coluna a partir da qual o inteiro vai ser printado (coluna 60)
        li a2,2			# carrega em a1 a linha a partir da qual o inteiro vai ser printado (linha 2)
	li a3,0x00FF		# carrega em a3 a cor de fundo (0x00 - preto) e a cor dos caracteres (0xFF - branco)
	li a4,0			# carrega em a4 o frame onde o inteiro deve ser printado (Frame 0 da memoria VGA)
	ecall			# realiza o ecall
	
	li a7,104		# carrega em a7 o serviço 104 do ecall (print string on bitmap display)
	la a0,STR2		# carrega em a0 o endereço da string a ser printada (STR: "HS: ")
	li a1,4			# carrega em a1 a coluna a partir da qual a string vai ser printada (coluna 0)
       	li a2,210		# carrega em a2 a linha a partir da qual a string vai ser printada (linha 2)
	li a3,0x00FF		# carrega em a3 a cor de fundo (0x00 - preto) e a cor dos caracteres (0xFF - branco)
	li a4,0 		# carrega em a4 o frame onde a string deve ser printada (Frame 0 da memoria VGA)
	ecall			# realiza o ecall
	
	la t1, HIGH_SCORE
	lw t2, 0(t1)
	
	bgt t0,t2,NEW_HS
	
	li a7,101		# carrega em a7 o serviço 101 do ecall (print integer on bitmap display)
	mv a0,t2		# carrega em a0 o valor do inteiro a ser printado (s1 = pontuaÃ§ao maxima)
	li a1,32		# carrega em a1 a coluna a partir da qual o inteiro vai ser printado (coluna 60)
        li a2,210		# carrega em a1 a linha a partir da qual o inteiro vai ser printado (linha 2)
	li a3,0x00FF		# carrega em a3 a cor de fundo (0x00 - preto) e a cor dos caracteres (0xFF - branco)
	li a4,0			# carrega em a4 o frame onde o inteiro deve ser printado (Frame 0 da memoria VGA)
	ecall			# realiza o ecall
	j DER
	
NEW_HS:	li a7,101		# carrega em a7 o serviço 101 do ecall (print integer on bitmap display)
	mv a0,t0		# carrega em a0 o valor do inteiro a ser printado (s1 = pontuaÃ§ao maxima)
	li a1,32		# carrega em a1 a coluna a partir da qual o inteiro vai ser printado (coluna 60)
        li a2,210		# carrega em a1 a linha a partir da qual o inteiro vai ser printado (linha 2)
	li a3,0x00FF		# carrega em a3 a cor de fundo (0x00 - preto) e a cor dos caracteres (0xFF - branco)
	li a4,0			# carrega em a4 o frame onde o inteiro deve ser printado (Frame 0 da memoria VGA)
	ecall			# realiza o ecall
	
DER:	beq s2,zero,DERROTAC
	
	li t0,1
	beq s6,t0,VERVIC1
	j VERVIC2
	
VERVIC1:li t0,103
	bge s1,t0,FASE2C
	j FASE
	
VERVIC2:li t0,140
	bge s1,t0,VITORIAC
	j FASE
	
FASE:	li t0,0xFF200000	# carrega o endereÃƒÂ§o de controle do KDMMIO ("teclado")
	lw t1,0(t0)		# le uma word a partir do endereÃƒÂ§o de controle do KDMMIO
	andi t1,t1,0x0001	# mascara todos os bits de t1 com exceÃƒÂ§ao do bit menos significativo
	li t2,1			# t2 = 1 (significa que o movimento a ser verificado veio de uma aÃƒÂ§ÃƒÂ£o do jogador)
   	beq t1,zero,VER_MOV   	# se o BMS de t1 for 0 (nÃƒÂ£o ha¡ tecla pressionada), pule para MOVE (continua o movimento atual do Robozinho)
 
  	lw t1,4(t0)		# le o valor da tecla pressionada e guarda em t1
  	
  	li t0,97		# carrega 97 (valor hex de "a") para t0		
  	beq t1,t0,SET_BUF		# se t1 for igual a 97 (valor hex de "a"), vÃƒÂ¡ para VLCO (verify left colision)
  	
  	li t0,119		# carrega 119 (valor hex de "w") para t0
  	beq t1,t0,SET_BUF		# se t6 for igual a 119 (valor hex de "w"), vÃƒÂ¡ para VUCO (verify up colision)
  	
  	li t0,115		# carrega 115 (valor hex de "s") para t0
  	beq t1,t0,SET_BUF		# se t1 for igual a 115 (valor hex de "s"), vÃƒÂ¡ para VDCO (verify down colision)
  	
  	li t0,100  		# carrega 100 (valor hex de "d") para t0
	bne t1,t0,HACK1		# se t1 for igual a 100 (valor hex de "d"), vÃƒÂ¡ para VRCO (verify right colision)
  	
SET_BUF:la t0,BUFFER
  	sw t1,0(t0)
  	j VER_MOV
  	
HACK1:  li t0,72		# carrega 97 (valor hex de "a") para t0		
  	bne t1,t0,SKP_HACK1	# se t1 for igual a 97 (valor hex de "a"), vÃƒÂ¡ para VLCO (verify left colision)
  	
  	addi s1,s1,102
  	
SKP_HACK1:

	li t0,75		# carrega 97 (valor hex de "a") para t0		
  	bne t1,t0,SKP_HACK2	# se t1 for igual a 97 (valor hex de "a"), vÃƒÂ¡ para VLCO (verify left colision)
  	
  	addi s1,s1,139
  	
SKP_HACK2:

VER_MOV:la t0,BUFFER
	lw t1,0(t0)

	li t0,97		# carrega 97 (valor hex de "a") para t0		
  	beq t1,t0,VLCO		# se t1 for igual a 97 (valor hex de "a"), vÃƒÂ¡ para VLCO (verify left colision)
  	
  	li t0,119		# carrega 119 (valor hex de "w") para t0
  	beq t1,t0,VUCO		# se t6 for igual a 119 (valor hex de "w"), vÃƒÂ¡ para VUCO (verify up colision)
  	
  	li t0,115		# carrega 115 (valor hex de "s") para t0
  	beq t1,t0,VDCO		# se t1 for igual a 115 (valor hex de "s"), vÃƒÂ¡ para VDCO (verify down colision)
  	
  	li t0,100  		# carrega 100 (valor hex de "d") para t0
	beq t1,t0,VRCO		# se t1 for igual a 100 (valor hex de "d"), vÃƒÂ¡ para VRCO (verify right colision)
	
MOVE:  	li t2,2			# t2 = 2 (significa que o movimento a ser verificado não veio de uma ação do jogador)

	li t0,0			# carrega 0 para t0
  	beq s3,t0,FIM		# se s3 for igual a 0 (valor de movimento atual nulo), va para FIM
  	
  	li t0,1			# carrega 1 para t0
  	beq s3,t0,VLCO		# se s3 for igual a 1 (valor de movimento atual para a esquerda), va para VLCO (verify left colision)
  	
  	li t0,2			# carrega 2 para t0
  	beq s3,t0,VUCO		# se s3 for igual a 2 (valor de movimento atual para cima), va para VUCO (verify up colision)
  	
  	li t0,3  		# carrega 3 para t0
	beq s3,t0,VDCO		# se s3 for igual a 3 (valor de movimento atual para baixo), va para VDCO (verify down colision)
	
	li t0,4  		# carrega 4 para t0
	beq s3,t0,VRCO		# se s3 for igual a 4 (valor de movimento atual para a direita), va para VRCO (verify right colision)
	
# Verifica a colisao do mapa (VLCO, VUCO, VDCO e VRCO carregam 5 ou 6 pixels de detecção de colisão em cada direção, e VERC verifica se algum desses pixels detectou uma colisão adiante)

#	   @7       @8          @9          @10         @11
#	@6 #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  @12
#	   #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  
#	   #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  
#	@5 #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  @13
#	   #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  
#	   #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  
#	@4 #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  @14
#	   #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #			# representação do Robozinho 16x16 com "#"
#	   #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  			# os "@x" são os pixels de colisão carregados ao redor do Robozinho (o endereço de "@x" eh calculado em relação ao endereço em POS_ROBOZINHO, sendo "@22" igual a propria posição)
#	@3 #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  @15			# OBS: os pixels de colisão detectam colisões apenas em relação ao mapa desenhado no Frame 1 da memoria VGA (mapa de colisão)
#	   #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #
#	   #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #
#	@2 #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  @16
#	   #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #
#	   #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #
#	@1 #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  @17
#	   @22(POS) @21	        @20         @19         @18

# Carrega pixels de colisão a esquerda (@1, @2, @3, @4, @5, @6)

VLCO:   la t0,POS_ROBOZINHO	# carrega o endereço de "POS_ROBOZINHO" no registrador t0
	lw t1,0(t0)		# le a word guardada em "POS_ROBOZINHO" para t1 (t1 = posição atual do Robozinho)
	addi t1,t1,-321		# volta t1 1 linha e 1 pixel (carrega em t1 o endereço do pixel "@1")
	jal ra, VERC		# va para VERC (verifica se o pixel "@1" detectou uma colisão)
			
	addi t1,t1,-1281	# volta t1 4 linhas e 1 pixel (carrega em t1 o endereço do pixel "@2")
	jal ra, VERC		# va para VER (verifica se o pixel "@2" detectou uma colisão)
	
	li t0,-2241		# t0 = -2241
	add t1,t1,t0		# volta t1 7 linhas e 1 pixel (carrega em t1 o endereço do pixel "@3")
	jal ra, VERC		# va para VERC (verifica se o pixel "@3" detectou uma colisão)
	
	li t0,-3201		# t0 = -3201
	add t1,t1,t0		# volta t1 10 linhas e 1 pixel (carrega em t1 o endereço do pixel "@4")
	jal ra, VERC		# va para VERC (verifica se o pixel "@4" detectou uma colisão)
	
	li t0,-4161		# t0 = -5121
	add t1,t1,t0		# volta t1 13 linhas e 1 pixel (carrega em t1 o endereço do pixel "@5")
	jal ra, VERC		# va para VERC (verifica se o pixel "@5" detectou uma colisão)
	
	li t0,-5121		# t0 = -5121
	add t1,t1,t0		# volta t1 16 linhas e 1 pixel (carrega em t1 o endereço do pixel "@6")
	jal ra, VERC		# va para VERC (verifica se o pixel "@6" detectou uma colisão)
	
	li s3,1			# se nenhuma colisão foi detectada, movimentação atual = 1 (esquerda)
	j VLP			# se nenhuma colisão foi detectada, va para VLP (Verify Left Point)
	
# Carrega pixels de colisão acima (@7, @8, @9, @10, @11)

VUCO:	la t0,POS_ROBOZINHO	# carrega o endereço de "POS_ROBOZINHO" no registrador t0
	lw t1,0(t0)		# le a word guardada em "POS_ROBOZINHO" para t1 (t1 = posição atual do Robozinho)
	li t0,-5440		# t0 = -5440
	add t1,t1,t0		# volta t1 17 linhas (carrega em t1 o endereço do pixel "@7")
	jal ra, VERC		# va para VERC (verifica se o pixel "@7" detectou uma colisão)
	
	li t0,-5437		# t0 = -5437
	add t1,t1,t0		# t1 volta 17 linhas e vai 3 pixels pra frente (carrega em t1 o endereço do pixel "@8")
	jal ra, VERC		# va para VERC (verifica se o pixel "@8" detectou uma colisão)
	
	li t0,-5433		# t0 = -5433
	add t1,t1,t0		# t1 volta 17 linhas e vai 7 pixels pra frente (carrega em t1 o endereço do pixel "@9")
	jal ra, VERC		# va para VERC (verifica se o pixel "@9" detectou uma colisão)
	
	li t0,-5429		# t0 = -5429
	add t1,t1,t0		# t1 volta 17 linhas e vai 11 pixels pra frente (carrega em t1 o endereço do pixel "@10")
	jal ra, VERC		# va para VERC (verifica se o pixel "@10" detectou uma colisão)
	
	li t0,-5425		# t0 = -5425
	add t1,t1,t0		# t1 volta 17 linhas e vai 15 pixels pra frente (carrega em t1 o endereço do pixel "@11")
	jal ra, VERC		# va para VERC (verifica se o pixel "@11" detectou uma colisão)

	li s3,2			# se nenhuma colisão foi detectada, movimentação atual = 2 (cima)
	j VUP			# se nenhuma colisão foi detectada, va para VUP (Verify Up Point)
	
# Carrega pixels de colisão abaixo (@22, @21, @20, @19, @18)
 
VDCO:	la t0,POS_ROBOZINHO	# carrega o endereço de "POS_ROBOZINHO" no registrador t0
	lw t1,0(t0)		# le a word guardada em "POS_ROBOZINHO" para t1 (t1 = posição atual do Robozinho)
	jal ra, VERC		# va para VERC (verifica se o pixel "@22" detectou uma colisão)
	
	addi t1,t1,3		# t1 vai 3 pixels pra frente (carrega em t1 o endereço do pixel "@21")
	jal ra, VERC		# va para VERC (verifica se o pixel "@21" detectou uma colisão)
	
	addi t1,t1,7		# t1 vai 7 pixels pra frente (carrega em t1 o endereço do pixel "@20")
	jal ra, VERC		# va para VERC (verifica se o pixel "@20" detectou uma colisão)
	
	addi t1,t1,11		# t1 vai 11 pixels pra frente (carrega em t1 o endereço do pixel "@19")
	jal ra, VERC		# va para VERC (verifica se o pixel "@19" detectou uma colisão)
	
	addi t1,t1,15		# t1 vai 15 pixels pra frente (carrega em t1 o endereço do pixel "@18")
	jal ra, VERC		# va para VERC (verifica se o pixel "@18" detectou uma colisão)
	
	li s3,3			# se nenhuma colisão foi detectada, movimentação atual = 3 (baixo)
	j VDP			# se nenhuma colisão foi detectada, va para VDP (Verify Down Point)
	
# Carrega pixels de colisão a direita (@17, @16, @15, @14, @13, @12)
 
VRCO:	la t0,POS_ROBOZINHO	# carrega o endereço de "POS_ROBOZINHO" no registrador t0
	lw t1,0(t0)		# le a word guardada em "POS_ROBOZINHO" para t1 (t1 = posição atual do Robozinho)
	addi t1,t1,-304		# t1 volta 1 linha e vai 16 pixels pra frente (carrega em t1 o endereço do pixel "@17")
	jal ra, VERC		# va para VERC (verifica se o pixel "@17" detectou uma colisão)
	
	addi t1,t1,-1264	# t1 volta 4 linhas e vai 16 pixels pra frente (carrega em t1 o endereço do pixel "@16")
	jal ra, VERC 		# va para VERC (verifica se o pixel "@16" detectou uma colisão)
	
	li t0,-2224		# t0 = -2224
	add t1,t1,t0		# t1 volta 7 linhas e vai 16 pixels pra frente (carrega em t1 o endereço do pixel "@15")
	jal ra, VERC		# va para VERC (verifica se o pixel "@15" detectou uma colisão)
	
	li t0,-3184		# t0 = -3184
	add t1,t1,t0		# t1 volta 10 linhas e vai 16 pixels pra frente (carrega em t1 o endereço do pixel "@14")
	jal ra, VERC		# va para VERC (verifica se o pixel "@14" detectou uma colisão)
	
	li t0,-4144		# t0 = -4144
	add t1,t1,t0		# t1 volta 13 linhas e vai 16 pixels pra frente (carrega em t1 o endereço do pixel "@13")
	jal ra, VERC		# va para VERC (verifica se o pixel "@13" detectou uma colisão)
	
	li t0,-5104		# t0 = -5104
	add t1,t1,t0		# t1 volta 16 linhas e vai 16 pixels pra frente (carrega em t1 o endereço do pixel "@12")
	jal ra, VERC		# va para VERC (verifica se o pixel "@12" detectou uma colisão)
	
	li s3,4			# se nenhuma colisão foi detectada, movimentação atual = 4 (direita)
	j VRP			# se nenhuma colisão foi detectada, va para VRP (Verify Right Point)
	
# Verifica se algum dos pixels de colisão detectou alguma colisão
 
VERC:	li t0,0x100000		# t0 = 0x100000
	add t1,t1,t0		# soma 0x100000 a t1 (transforma o conteudo de t1 em um endereço do Frame 1)
	lbu t0,0(t1)		# carrega em t0 um byte do endereço t1 (cor do pixel de t1) -> OBS: o load byte deve ser "unsigned" 
				# Ex: 0d200 = 0xc8 = 0b11001000. como o MSB desse byte eh 1, ele seria interpretado como -56 e não 200 (t0 = 0xffffffc8)
				
	li t1,0x70		# t1 = 200
	beq t0,t1,COL_BLINKY	# se t0 = 200, va para VERWAY (se a cor do pixel for azul, verifica se o movimento do Robozinho foi causado ou não pelo jogador)
	
	li t1,0x71		# t1 = 200
	beq t0,t1,COL_PINK	# se t0 = 200, va para VERWAY (se a cor do pixel for azul, verifica se o movimento do Robozinho foi causado ou não pelo jogador)
	
	li t1,0x72		# t1 = 200
	beq t0,t1,COL_INKY	# se t0 = 200, va para VERWAY (se a cor do pixel for azul, verifica se o movimento do Robozinho foi causado ou não pelo jogador)
	
	li t1,0x73		# t1 = 200
	beq t0,t1,COL_CLYDE	# se t0 = 200, va para VERWAY (se a cor do pixel for azul, verifica se o movimento do Robozinho foi causado ou não pelo jogador)
	
	li t1,200		# t1 = 200
	beq t0,t1,VERWAY	# se t0 = 200, va para VERWAY (se a cor do pixel for azul, verifica se o movimento do Robozinho foi causado ou não pelo jogador)
	
	li t1,240		# t1 = 240
	beq t0,t1,VERWAY	# se t0 = 240, va para VERWAY (se a cor do pixel for o da porta da caixa dos aliens, verifica se o movimento do Robozinho foi causado ou não pelo jogador)
	
	li t1,3			# t1 = 3
	beq t0,t1,LPORTAL	# se t0 = 3, va para LPORTAL (se a cor do pixel for vermelho-3, o Robozinho teletransporta)
	
	li t1,7			# t1 = 7
	beq t0,t1,RPORTAL	# se t0 = 7, va para RPORTAL (se a cor do pixel for vermelho-7, o Robozinho teletransporta)
	
	la t0,POS_ROBOZINHO	# carrega o endereço de "POS_ROBOZINHO" no registrador t0
	lw t1,0(t0)		# le a word guardada em "POS_ROBOZINHO" para t1 (t1 = posição atual do Robozinho)
	ret 			# retorna para verificar se outro pixel detectou colisão
	
# Verifica se o movimento atual do Robozinho foi ou não causado pelo jogador. Se foi, vai para uma segunda checagem de colisão (se a direção escolhida pelo jogador não eh permitida, o jogo verifica se a direção atual de movimento do Robozinho ainda eh permitida)

VERWAY: li t0,2			# t0 = 2
	beq t2,t0,FIM		# se t2 = 2 (movimento não causado pelo jogador), va para FIM (não precisa checar segunda colisão)
	
	li t2,2			# atualiza o valor de t2 para indicar que o movimento a ser checado não eh mais causado pelo jogador
  	
  	li t0,0
  	beq s3,t0,FIM
  	
  	li t0,1			# carrega 1 para t0
  	beq s3,t0,VLCO		# se s3 for igual a 1 (valor de movimento atual para a esquerda), va para VLCO (verify left colision)
  	
  	li t0,2			# carrega 2 para t0
  	beq s3,t0,VUCO		# se s3 for igual a 2 (valor de movimento atual para cima), va para VUCO (verify up colision)
  	
  	li t0,3  		# carrega 3 para t0
	beq s3,t0,VDCO		# se s3 for igual a 3 (valor de movimento atual para baixo), va para VDCO (verify down colision)
	
	li t0,4  		# carrega 4 para t0
	beq s3,t0,VRCO		# se s3 for igual a 4 (valor de movimento atual para a direita), va para VRCO (verify right colision)
	
# Realiza a movimentação do Robozinho atraves dos portais

LPORTAL:li a4,2121
	li s3,1			# se nenhuma colisão foi detectada, movimentação atual = 1 (esquerda)
	j VLP			# se nenhuma colisão foi detectada, va para VLP (Verify Left Point)

RPORTAL:li a4,2222
	li s3,4			# se nenhuma colisão foi detectada, movimentação atual = 4 (direita)
	j VRP			# se nenhuma colisão foi detectada, va para VRP (Verify Right Point)
	
# Verifica a colisão com pontos e incrementa o contador de pontos (extremamente não otimizado, mas eh oq ta tendo pra hj)

#		U
#          	@4
#          	@3
#	   	@2
#	   	@1      
#	   	#  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #
#	   	#  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  
#	   	#  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  
#	   	#  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  
#	   	#  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  
#	   	#  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  
#	   	#  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  
#	   	#  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #			# representação do Robozinho 16x16 com "#"
#	   	#  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  		# os "@x" são as linhas/colunas de detecção de pontos carregadas ao redor do Robozinho (o endereço de "@x" eh calculado em relação ao endereço em POS_ROBOZINHO)
#	   	#  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #
#	   	#  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #
#	   	#  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  
#	   	#  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #		 
#	   	#  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #		 
#    L @4@3@2@1 #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  @1@2@3@4 R
#	   	@1(POS)  				        
#	   	@2						
#	   	@3						
#	   	@4
#		D 

# Carrega colunas de detecção de pontos a esquerda (L - @1 @2 @3 @4)

VLP: 	la t0,POS_ROBOZINHO	# carrega o endereço de "POS_ROBOZINHO" no registrador t0
	lw t1,0(t0)		# le a word guardada em "POS_ROBOZINHO" para t1 (t1 = posição atual do Robozinho)
	li t0,-5120		# t0 = -5120
	addi t1,t1,-1		# volta t1 1 pixel (carrega em t1 o endereço inicial da coluna "@1" uma linha abaixo)
	add t0,t1,t0		# t0 = t1 - 5120 (carrega em t0 o endereço final da coluna "@1", pois volta t1 16 linhas)
	li t2,-320		# t2 = -320 (carrega em t2 o "offset" de um pixel para o outro)
	li t3,4			# t3 = 4 (carrega em t3 um contador para verificar apenas 4 colunas)
	jal ra, VERP		# va para VERP (verifica se ha ponto na coluna "@1")
	
	addi t1,t1,-2		# volta t1 2 pixels (carrega em t1 o endereço inicial da coluna "@2" uma linha abaixo)
	li t0,-5120		# t0 = -5120
	add t0,t1,t0		# t0 = t1 - 5120 (carrega em t0 o endereço final da coluna "@2", pois volta t1 16 linhas)
	jal ra, VERP		# va para VERP (verifica se ha ponto na coluna "@2")
	
	addi t1,t1,-3		# volta t1 3 pixels (carrega em t1 o endereço inicial da coluna "@3" uma linha abaixo)
	li t0,-5120		# t0 = -5120
	add t0,t1,t0		# t0 = t1 - 5120 (carrega em t0 o endereço final da coluna "@3", pois volta t1 16 linhas)
	jal ra, VERP		# va para VERP (verifica se ha ponto na coluna "@3")
	
	addi t1,t1,-4		# volta t1 4 pixels (carrega em t1 o endereço inicial da coluna "@4" uma linha abaixo)
	li t0,-5120		# t0 = -5120
	add t0,t1,t0		# t0 = t1 - 5120 (carrega em t0 o endereço final da coluna "@4", pois volta t1 16 linhas)
	jal ra, VERP		# va para VERP (verifica se ha ponto na coluna "@4")
	
# Carrega linhas de detecção de pontos acima (U - @1 @2 @3 @4)
	
VUP:	la t0,POS_ROBOZINHO	# carrega o endereço de "POS_ROBOZINHO" no registrador t0
	lw t1,0(t0)		# le a word guardada em "POS_ROBOZINHO" para t1 (t1 = posição atual do Robozinho)
	li t0, -5441		# t0 = -5441
	add t1,t1,t0		# volta t1 1 pixel e 17 linhas (carrega em t1 o endereço inicial da linha "@1" um pixel para a esquerda)
	addi t0,t1,16		# t0 = t1 + 16 (carrega em t0 o endereço final da linha "@1", pois avança t1 16 pixels)
	li t2,1			# t2 = 1 (carrega em t2 o "offset" de um pixel para o outro)
	li t3,4			# t3 = 4 (carrega em t3 um contador para verificar 4 linhas)
	jal ra, VERP		# va para VERP (verifica se ha ponto na linha "@1")
	
	li t0, -5761		# t0 = -5761
	add t1,t1,t0		# volta t1 1 pixel e 18 linhas (carrega em t1 o endereço inicial da linha "@2" um pixel para a esquerda)
	addi t0,t1,16		# t0 = t1 + 16 (carrega em t0 o endereço final da linha "@2", pois avança t1 16 pixels)
	jal ra, VERP		# va para VERP (verifica se ha ponto na linha "@2")
	
	li t0, -6081		# t0 = -6081
	add t1,t1,t0		# volta t1 1 pixel e 19 linhas (carrega em t1 o endereço inicial da linha "@3" um pixel para a esquerda)
	addi t0,t1,16		# t0 = t1 + 16 (carrega em t0 o endereço final da linha "@3", pois avança t1 16 pixels)
	jal ra, VERP		# va para VERP (verifica se ha ponto na linha "@3")
	
	li t0, -6401		# t0 = -6401
	add t1,t1,t0		# volta t1 1 pixel e 20 linhas (carrega em t1 o endereço inicial da linha "@4" um pixel para a esquerda)
	addi t0,t1,16		# t0 = t1 + 16 (carrega em t0 o endereço final da linha "@4", pois avança t1 16 pixels)
	jal ra, VERP		# va para VERP (verifica se ha ponto na coluna "@4")
	
# Carrega linhas de detecção de pontos abaixo (D - @1 @2 @3 @4)
	
VDP:	la t0,POS_ROBOZINHO	# carrega o endereço de "POS_ROBOZINHO" no registrador t0
	lw t1,0(t0)		# le a word guardada em "POS_ROBOZINHO" para t1 (t1 = posição atual do Robozinho)
	addi t1,t1,-1		# volta t1 1 pixel (carrega em t1 o endereço inicial da linha "@1" um pixel para a esquerda)
	addi t0,t1,16		# t0 = t1 + 16 (carrega em t0 o endereço final da linha "@1", pois avança t1 16 pixels)
	li t2,1			# t2 = 1 (carrega em t2 o "offset" de um pixel para o outro)
	li t3,4			# t3 = 4 (carrega em t3 um contador para verificar 4 linhas)
	jal ra, VERP		# va para VERP (verifica se ha ponto na linha "@1")
			
	addi t1,t1,319		# volta t1 1 pixel e avança t1 1 linha (carrega em t1 o endereço inicial da linha "@2" um pixel para a esquerda)
	addi t0,t1,16		# t0 = t1 + 16 (carrega em t0 o endereço final da linha "@2", pois avança t1 16 pixels)
	jal ra, VERP		# va para VERP (verifica se ha ponto na linha "@2")
			
	addi t1,t1,639		# volta t1 1 pixel e avança t1 2 linhas (carrega em t1 o endereço inicial da linha "@3" um pixel para a esquerda)
	addi t0,t1,16		# t0 = t1 + 16 (carrega em t0 o endereço final da linha "@3", pois avança t1 16 pixels)
	jal ra, VERP		# va para VERP (verifica se ha ponto na linha "@3")
			
	addi t1,t1,959		# volta t1 1 pixel e avança t1 3 linhas (carrega em t1 o endereço inicial da linha "@4" um pixel para a esquerda)
	addi t0,t1,16		# t0 = t1 + 16 (carrega em t0 o endereço final da linha "@4", pois avança t1 16 pixels)
	jal ra, VERP		# va para VERP (verifica se ha ponto na linha "@4")
	
# Carrega colunas de detecção de pontos a direita (R - @1 @2 @3 @4)

VRP:	la t0,POS_ROBOZINHO	# carrega o endereço de "POS_ROBOZINHO" no registrador t0
	lw t1,0(t0)		# le a word guardada em "POS_ROBOZINHO" para t1 (t1 = posição atual do Robozinho)
	addi t1,t1,16		# avança t1 16 pixels (carrega em t1 o endereço inicial da coluna "@1" uma linha abaixo)
	li t0,-5120		# t0 = -5120
	add t0,t1,t0		# t0 = t1 - 5120 (carrega em t0 o endereço final da coluna "@1", pois volta t1 16 linhas)
	li t2,-320		# t2 = -320 (carrega em t2 o "offset" de um pixel para o outro)
	li t3,4			# t3 = 4 (carrega em t3 um contador para verificar 4 colunas)
	jal ra, VERP		# va para VERP (verifica se ha ponto na coluna "@1")
	
	addi t1,t1,17		# avança t1 17 pixels (carrega em t1 o endereço inicial da coluna "@2" uma linha abaixo)
	li t0,-5120		# t0 = -5120
	add t0,t1,t0		# t0 = t1 - 5120 (carrega em t0 o endereço final da coluna "@2", pois volta t1 16 linhas)
	jal ra, VERP		# va para VERP (verifica se ha ponto na coluna "@2")
	
	addi t1,t1,18		# avança t1 18 pixels (carrega em t1 o endereço inicial da coluna "@3" uma linha abaixo)
	li t0,-5120		# t0 = -5120
	add t0,t1,t0		# t0 = t1 - 5120 (carrega em t0 o endereço final da coluna "@3", pois volta t1 16 linhas)
	jal ra, VERP		# va para VERP (verifica se ha ponto na coluna "@3")
	
	addi t1,t1,19		# avança t1 19 pixels (carrega em t1 o endereço inicial da coluna "@4" uma linha abaixo)
	li t0,-5120		# t0 = -5120
	add t0,t1,t0		# t0 = t1 - 5120 (carrega em t0 o endereço final da coluna "@4", pois volta t1 16 linhas)
	jal ra, VERP		# va para VERP (verifica se ha ponto na coluna "@4")

# Verifica se algum dos pixels de pontuação detectou algum ponto
 
VERP:	add t1,t1,t2		# t1 = t1 + offset (pula para o pixel seguinte da linha\coluna)
	lbu t4,0(t1)		# carrega em t4 um byte do endereço t1 (cor do pixel de t1)
	li t5,63		# t5 = 63 (cor amarela)
	beq t4,t5,PONTO		# se t4 = 63, va para PONTO (atualiza o contador de pontos e termina a busca por pontos a serem coletados)
	li t5,127
	beq t4,t5,SPRPNT
	beq t1,t0,NXTLINE	# se t1 = t0, va para NXTLINE (se o endereço analisado for o ultimo da linha/coluna, pule para a linha/coluna seguinte)
	j VERP			# pule para VERP (se nenhum ponto foi detectado, volte para o inÃƒÂ­cio do loop)
	
NXTLINE:addi t3,t3,-1		# t3 = t3 - 1 (reduz o contador de linhas/colunas analisadas)
	beq t3,zero,DELETE	# se t3 = 0, va para DELETE (se nenhum ponto for encontrado, apenas mova o Robozinho)
	la t0,POS_ROBOZINHO	# carrega o endereço de "POS_ROBOZINHO" no registrador t0
	lw t1,0(t0)		# le a word guardada em "POS_ROBOZINHO" para t1 (t1 = posição atual do Robozinho)
	ret 			# retorna para verificar se outro pixel detectou pontos 
	
PONTO:  addi s1,s1,1		# incrementa o contador de pontos (a sessão a seguir toca uma triade de mi maior para cada ponto coletado)

	la t5, PONTOS
	lw t6, 0(t5)
	addi t6,t6,10
	sw t6, 0(t5)
	
	li a0,68		# a0 = 68 (carrega sol sustenido para a0)
	li a1,100		# a1 = 100 (nota de duração de 100 ms)
	li a2,35		# a2 = 35 (timbre "electric bass")
	li a3,50		# a3 = 50 (volume da nota)
	li a7,31		# a7 = 31 (carrega em a7 o ecall "MidiOut")
	ecall			# realiza o ecall
	
	li a0,71		# a0 = 71 (carrega si para a0)
	li a1,100		# a1 = 100 (nota de duração de 100 ms)
	li a2,32		# a2 = 32 (timbre "guitar harmonic")
	li a3,50		# a3 = 50 (volume da nota)
	li a7,31		# a7 = 31 (carrega em a7 o ecall "MidiOut")
	ecall			# realiza o ecall
	
	li a0,76		# a0 = 76 (carrega mi para a0)
	li a1,100		# a1 = 100 (nota de duração de 100 ms)
	li a2,32		# a2 = 32 (timbre "guitar harmonic")
	li a3,50		# a3 = 50 (volume da nota)
	li a7,31		# a7 = 31 (carrega em a7 o ecall "MidiOut")
	ecall			# realiza o ecall
	
	addi t3,t3,-1		# t3 = t3 - 1 (reduz o contador de linhas/colunas analisadas)
	beq t3,zero,DELPNT	# se t3 = 0, va para DELPNT (se o ponto foi encontrado na ultima linha/coluna analisada, deve-se apagar o restante do ponto)
	j DELETE		# pule para DELETE (se o ponto foi encontrado nas 3 primeiras linhas/colunas, apenas mova o Robozinho)

DELPNT:	li t3,1			# carrega 1 para t3
  	beq s3,t3,DELLFT	# se s3 for igual a 1 (valor de movimento atual para a esquerda), va para DELLFT
  	
  	li t3,2			# carrega 2 para t3
  	beq s3,t3,DELUP		# se s3 for igual a 2 (valor de movimento atual para cima), va para DELUP
  	
  	li t3,3  		# carrega 3 para t3
	beq s3,t3,DELDWN	# se s3 for igual a 3 (valor de movimento atual para baixo), va para DELDWN
	
	li t3,4  		# carrega 4 para t3
	beq s3,t3,DELRGHT	# se s3 for igual a 4 (valor de movimento atual para a direita), va para DELRGHT
	
DELLFT: addi t1,t1,-1		# t1 = t1 - 1 (carrega o endereço do pixel inferior esquerdo do ponto detectado)
	sb zero,0(t1)		# grava 0 no conteudo do endereço t1 (apaga o pixel carregado anteriormente da memoria VGA/tela)
	addi t1,t1,-320		# t1 = t1 - 320 (carrega o endereço do pixel superior esquerdo do ponto detectado)
	sb zero,0(t1)		# grava 0 no conteudo do endereço t1 (apaga o pixel carregado anteriormente da memoria VGA/tela)
	
	li t3,0xFF000000	# t3 = 0xFF000000 (carrega em t3 o endereço base da memoria VGA)
	sub t3,t1,t3		# t3 = t1 - 0xFF000000 (subtrai o endereço base de t1, posição do pixel a ser apagado)
	
	li t4,1
	beq s6,t4,DELL1
	la t5,mapa2
	j DELL2
	
DELL1:	la t5,mapa1		# carrega em t5 o endereço dos dados do mapa1 
DELL2:	addi t5,t5,8		# t5 = endereço do primeiro pixel do mapa1 (depois das informações de nlin ncol)
	add t5,t5,t3		# t5 = t5 + t3 (carrega em t5 o endereço do pixel do mapa1 a ser apagado) 
	sb zero,0(t5)		# grava 0 no conteudo do endereço t5 (apaga o pixel carregado anteriormente do mapa1 no segmento de dados)
		
	addi t1,t1,320		# t1 = t1 + 320 (carrega o endereço do pixel inferior esquerdo do ponto detectado)
	li t3,0xFF000000	# t3 = 0xFF000000 (carrega em t3 o endereço base da memoria VGA)
	sub t3,t1,t3		# t3 = t1 - 0xFF000000 (subtrai o endereço base de t1, posição do pixel a ser apagado)
	
	li t4,1
	beq s6,t4,DELL3
	la t5,mapa2
	j DELL4
	
DELL3:	la t5,mapa1		# carrega em t5 o endereço dos dados do mapa1 
DELL4:	addi t5,t5,8		# t5 = endereço do primeiro pixel do mapa1 (depois das informações de nlin ncol)
	add t5,t5,t3		# t5 = t5 + t3 (carrega em t5 o endereço do pixel do mapa1 a ser apagado)
	sb zero,0(t5)		# grava 0 no conteudo do endereço t5 (apaga o pixel carregado anteriormente do mapa1 no segmento de dados)
	
	j DELETE 		# pule para DELETE
	
DELUP:	addi t1,t1,-320		# t1 = t1 - 320 (carrega o endereço do pixel superior esquerdo do ponto detectado)
	sb zero,0(t1)		# grava 0 no conteudo do endereço t1 (apaga o pixel carregado anteriormente da memoria VGA/tela)
	addi t1,t1,1		# t1 = t1 + 1 (carrega o endereço do pixel superior direito do ponto detectado)
	sb zero,0(t1)		# grava 0 no conteudo do endereço t1 (apaga o pixel carregado anteriormente da memoria VGA/tela)
	
	li t3,0xFF000000	# t3 = 0xFF000000 (carrega em t3 o endereço base da memoria VGA)
	sub t3,t1,t3		# t3 = t1 - 0xFF000000 (subtrai o endereço base de t1, posição do pixel a ser apagado)
	
	li t4,1
	beq s6,t4,DELU1
	la t5,mapa2
	j DELU2
	
DELU1:	la t5,mapa1		# carrega em t5 o endereço dos dados do mapa1 
DELU2:	addi t5,t5,8		# t5 = endereço do primeiro pixel do mapa1 (depois das informações de nlin ncol)
	add t5,t5,t3		# t5 = t5 + t3 (carrega em t5 o endereço do pixel do mapa1 a ser apagado) 
	sb zero,0(t5)		# grava 0 no conteudo do endereço t5 (apaga o pixel carregado anteriormente do mapa1 no segmento de dados)
	
	addi t1,t1,-1		# t1 = t1 - 1 (carrega o endereço do pixel superior esquerdo do ponto detectado)
	li t3,0xFF000000	# t3 = 0xFF000000 (carrega em t3 o endereço base da memoria VGA)
	sub t3,t1,t3		# t3 = t1 - 0xFF000000 (subtrai o endereço base de t1, posição do pixel a ser apagado)
	
	li t4,1
	beq s6,t4,DELU3
	la t5,mapa2
	j DELU4
	
DELU3:	la t5,mapa1		# carrega em t5 o endereço dos dados do mapa1 
DELU4:	addi t5,t5,8		# t5 = endereço do primeiro pixel do mapa1 (depois das informações de nlin ncol)
	add t5,t5,t3		# t5 = t5 + t3 (carrega em t5 o endereço do pixel do mapa1 a ser apagado)
	sb zero,0(t5)		# grava 0 no conteudo do endereço t5 (apaga o pixel carregado anteriormente do mapa1 no segmento de dados)
	
	j DELETE 		# pule para DELETE
	
DELDWN:	addi t1,t1,320		# t1 = t1 + 320 (carrega o endereço do pixel inferior esquerdo do ponto detectado)
	sb zero,0(t1)		# grava 0 no conteudo do endereço t1 (apaga o pixel carregado anteriormente da memoria VGA/tela)
	addi t1,t1,1		# t1 = t1 + 1 (carrega o endereço do pixel inferior direito do ponto detectado)
	sb zero,0(t1)		# grava 0 no conteudo do endereço t1 (apaga o pixel carregado anteriormente da memoria VGA/tela)
	
	li t3,0xFF000000	# t3 = 0xFF000000 (carrega em t3 o endereço base da memoria VGA)
	sub t3,t1,t3		# t3 = t1 - 0xFF000000 (subtrai o endereço base de t1, posição do pixel a ser apagado)
	
	li t4,1
	beq s6,t4,DELD1
	la t5,mapa2
	j DELD2
	
DELD1:	la t5,mapa1		# carrega em t5 o endereço dos dados do mapa1 
DELD2:	addi t5,t5,8		# t5 = endereço do primeiro pixel do mapa1 (depois das informações de nlin ncol)
	add t5,t5,t3		# t5 = t5 + t3 (carrega em t5 o endereço do pixel do mapa1 a ser apagado) 
	sb zero,0(t5)		# grava 0 no conteudo do endereço t5 (apaga o pixel carregado anteriormente do mapa1 no segmento de dados)
	
	addi t1,t1,-1		# t1 = t1 - 1 (carrega o endereço do pixel inferior esquerdo do ponto detectado)
	li t3,0xFF000000	# t3 = 0xFF000000 (carrega em t3 o endereço base da memoria VGA)
	sub t3,t1,t3		# t3 = t1 - 0xFF000000 (subtrai o endereço base de t1, posição do pixel a ser apagado)
	
	li t4,1
	beq s6,t4,DELD3
	la t5,mapa2
	j DELD4
	
DELD3:	la t5,mapa1		# carrega em t5 o endereço dos dados do mapa1 
DELD4:	addi t5,t5,8		# t5 = endereço do primeiro pixel do mapa1 (depois das informações de nlin ncol)
	add t5,t5,t3		# t5 = t5 + t3 (carrega em t5 o endereço do pixel do mapa1 a ser apagado)
	sb zero,0(t5)		# grava 0 no conteudo do endereço t5 (apaga o pixel carregado anteriormente do mapa1 no segmento de dados)
	
	j DELETE 		# pule para DELETE

DELRGHT:addi t1,t1,1		# t1 = t1 + 1 (carrega o endereço do pixel inferior direito do ponto detectado)
	sb zero,0(t1)		# grava 0 no conteudo do endereço t1 (apaga o pixel carregado anteriormente da memoria VGA/tela)
	addi t1,t1,-320		# t1 = t1 + 1 (carrega o endereço do pixel superior direito do ponto detectado)
	sb zero,0(t1)		# grava 0 no conteudo do endereço t1 (apaga o pixel carregado anteriormente da memoria VGA/tela)
	
	li t3,0xFF000000	# t3 = 0xFF000000 (carrega em t3 o endereço base da memoria VGA)
	sub t3,t1,t3		# t3 = t1 - 0xFF000000 (subtrai o endereço base de t1, posição do pixel a ser apagado)
	
	li t4,1
	beq s6,t4,DELR1
	la t5,mapa2
	j DELR2
	
DELR1:	la t5,mapa1		# carrega em t5 o endereço dos dados do mapa1 
DELR2:	addi t5,t5,8		# t5 = endereço do primeiro pixel do mapa1 (depois das informações de nlin ncol)
	add t5,t5,t3		# t5 = t5 + t3 (carrega em t5 o endereço do pixel do mapa1 a ser apagado) 
	sb zero,0(t5)		# grava 0 no conteudo do endereço t5 (apaga o pixel carregado anteriormente do mapa1 no segmento de dados)
	
	addi t1,t1,320		# t1 = t1 + 320 (carrega o endereço do pixel inferior direito do ponto detectado)
	li t3,0xFF000000	# t3 = 0xFF000000 (carrega em t3 o endereço base da memoria VGA)
	sub t3,t1,t3		# t3 = t1 - 0xFF000000 (subtrai o endereço base de t1, posição do pixel a ser apagado)
	
	li t4,1
	beq s6,t4,DELR3
	la t5,mapa2
	j DELR4
	
DELR3:	la t5,mapa1		# carrega em t5 o endereço dos dados do mapa1 
DELR4:	addi t5,t5,8		# t5 = endereço do primeiro pixel do mapa1 (depois das informações de nlin ncol)
	add t5,t5,t3		# t5 = t5 + t3 (carrega em t5 o endereço do pixel do mapa1 a ser apagado)
	sb zero,0(t5)		# grava 0 no conteudo do endereço t5 (apaga o pixel carregado anteriormente do mapa1 no segmento de dados)
	
	j DELETE 		# pule para DELETE
	
SPRPNT:	addi s1,s1,1		# incrementa o contador de pontos (a sessão a seguir toca uma triade de mi maior para cada ponto coletado)
	
	li s0,-1
	
	la t5, PONTOS
	lw t6, 0(t5)
	addi t6,t6,10
	sw t6, 0(t5)
	
	la t0,CONTADOR_ASSUSTADO
	li t3,0		
	sw t3,0(t0)		
	
	li t0,17
	rem t3,s7,t0
	li s7, 51
	add s7,s7,t3
	
	li t0,17
	rem t3,s9,t0
	li s9, 51
	add s9,s9,t3
	
	li t0,17
	rem t3,s10,t0
	li s10, 51
	add s10,s10,t3
	
	li t0,17
	rem t3,s11,t0
	li s11, 51
	add s11,s11,t3
	
	li a0,56		# a0 = 56 (carrega sol sustenido para a0)
	li a1,100		# a1 = 100 (nota de duração de 100 ms)
	li a2,35		# a2 = 35 (timbre "electric bass")
	li a3,50		# a3 = 50 (volume da nota)
	li a7,31		# a7 = 31 (carrega em a7 o ecall "MidiOut")
	ecall			# realiza o ecall
	
	li a0,59		# a0 = 59 (carrega si para a0)
	li a1,100		# a1 = 100 (nota de duração de 100 ms)
	li a2,32		# a2 = 32 (timbre "guitar harmonic")
	li a3,50		# a3 = 50 (volume da nota)
	li a7,31		# a7 = 31 (carrega em a7 o ecall "MidiOut")
	ecall			# realiza o ecall
	
	li a0,64		# a0 = 64 (carrega mi para a0)
	li a1,100		# a1 = 100 (nota de duração de 100 ms)
	li a2,32		# a2 = 32 (timbre "guitar harmonic")
	li a3,50		# a3 = 50 (volume da nota)
	li a7,31		# a7 = 31 (carrega em a7 o ecall "MidiOut")
	ecall			# realiza o ecall
	
	li t3,1			# carrega 1 para t3
  	beq s3,t3,DELLFTS	# se s3 for igual a 1 (valor de movimento atual para a esquerda), va para DELLFT
  	
  	li t3,2			# carrega 2 para t3
  	beq s3,t3,DELUPS		# se s3 for igual a 2 (valor de movimento atual para cima), va para DELUP
  	
  	li t3,3  		# carrega 3 para t3
	beq s3,t3,DELDWNS	# se s3 for igual a 3 (valor de movimento atual para baixo), va para DELDWN
	
	li t3,4  		# carrega 4 para t3
	beq s3,t3,DELRGHTS	# se s3 for igual a 4 (valor de movimento atual para a direita), va para DELRGHT
	
DELLFTS: 
	addi t1,t1,-3		# t1 = t1 - 1 (carrega o endereço do pixel inferior esquerdo do ponto detectado)
	la t3,vertpoint		# carrega a imagem que vai sobrepor o Robozinho com pixels pretos
	addi t3,t3,8		# t3 = endereço do primeiro pixel da imagem (depois das informações de nlin ncol)

	li t5,0	
	li t6,4			# reinicia o contador para 16 quebras de linha
	
	li t4,960		# t4 = 5120
	sub t1,t1,t4		# volta t1 16 linhas (pixel inicial da primeira linha)
	mv t2,t1 		# t2 = POS_ROBOZINHO	
	addi t2,t2,2		# t2 = POS_ROBOZINHO + 16 (pixel final da primeira linha)
	
	mv t0,t1		# t0 = t1
	li t4,0xFF000000	# t4 = 0xFF000000 (carrega em t4 o endereço base da memoria VGA)
	sub t0,t0,t4		# t0 = t0 - 0xFF000000 (subtrai o endereço base de t0, posição atual do Robozinho)
	li t4,1
	beq s6,t4,LOAD1L
	la t4,mapa2
	j LOAD2L
LOAD1L:	la t4,mapa1		# carrega em t4 o endereço dos dados do mapa1
LOAD2L:	addi t4,t4,8		# t4 = endereço do primeiro pixel do mapa1 (depois das informações de nlin ncol)
	add t4,t4,t0		# t4 = t4 + t0 (carrega em t4 o endereço do pixel do mapa1 no segmento de dados sobre o qual o Robozinho esta localizado)
	
	
DELLOOPL:beq t1,t2,ENTER2L	# se t1 atingir o fim da linha de pixels, quebre linha
	lb t0,0(t3)		# le um byte de "Robozinho1preto" para t0
	sb t0,0(t1)		# escreve o byte (pixel preto\invisivel) na memoria VGA
	sb t0,0(t4)
	
	addi t1,t1,1		# soma 1 ao endereço t1
	addi t3,t3,1		# soma 1 ao endereço t3
	addi t4,t4,1		# soma 1 ao endereço t4
	j DELLOOPL		# volta a verificar a condiçao do loop
	
ENTER2L:addi t1,t1,318		# t1 pula para o pixel inicial da linha de baixo na memoria VGA
	addi t4,t4,318		# t4 pula para o pixel inicial da linha de baixo no segmento de dados
	addi t2,t2,320		# t2 pula para o pixel final da linha de baixo na memoria VGA
	addi t5,t5,1          	# atualiza o contador de quebras de linha
	beq t5,t6,DELETE	# termina o carregamento da imagem se 16 quebras de linha ocorrerem
	j DELLOOPL		# pula para delloop
	
DELUPS:	la t3,horpoint		# carrega a imagem que vai sobrepor o Robozinho com pixels pretos
	addi t3,t3,8		# t3 = endereço do primeiro pixel da imagem (depois das informações de nlin ncol)

	li t5,0	
	li t6,2			# reinicia o contador para 16 quebras de linha
	
	li t4,960		# t4 = 5120
	sub t1,t1,t4		# volta t1 16 linhas (pixel inicial da primeira linha)
	mv t2,t1 		# t2 = POS_ROBOZINHO	
	addi t2,t2,4		# t2 = POS_ROBOZINHO + 16 (pixel final da primeira linha)
	
	mv t0,t1		# t0 = t1
	li t4,0xFF000000	# t4 = 0xFF000000 (carrega em t4 o endereço base da memoria VGA)
	sub t0,t0,t4		# t0 = t0 - 0xFF000000 (subtrai o endereço base de t0, posição atual do Robozinho)
	li t4,1
	beq s6,t4,LOAD1U
	la t4,mapa2
	j LOAD2U
LOAD1U:	la t4,mapa1		# carrega em t4 o endereço dos dados do mapa1
LOAD2U:	addi t4,t4,8		# t4 = endereço do primeiro pixel do mapa1 (depois das informações de nlin ncol)
	add t4,t4,t0		# t4 = t4 + t0 (carrega em t4 o endereço do pixel do mapa1 no segmento de dados sobre o qual o Robozinho esta localizado)
	
	
DELLOOPU:beq t1,t2,ENTER2U	# se t1 atingir o fim da linha de pixels, quebre linha
	lb t0,0(t3)		# le um byte de "Robozinho1preto" para t0
	sb t0,0(t1)		# escreve o byte (pixel preto\invisivel) na memoria VGA
	sb t0,0(t4)
	
	addi t1,t1,1		# soma 1 ao endereço t1
	addi t3,t3,1		# soma 1 ao endereço t3
	addi t4,t4,1		# soma 1 ao endereço t4
	j DELLOOPU		# volta a verificar a condiçao do loop
	
ENTER2U:addi t1,t1,316		# t1 pula para o pixel inicial da linha de baixo na memoria VGA
	addi t4,t4,316		# t4 pula para o pixel inicial da linha de baixo no segmento de dados
	addi t2,t2,320		# t2 pula para o pixel final da linha de baixo na memoria VGA
	addi t5,t5,1          	# atualiza o contador de quebras de linha
	beq t5,t6,DELETE	# termina o carregamento da imagem se 16 quebras de linha ocorrerem
	j DELLOOPU		# pula para delloop
	
DELDWNS:la t3,horpoint		# carrega a imagem que vai sobrepor o Robozinho com pixels pretos
	addi t3,t3,8		# t3 = endereço do primeiro pixel da imagem (depois das informações de nlin ncol)

	li t5,0	
	li t6,2			# reinicia o contador para 16 quebras de linha
	
	li t4,640		# t4 = 5120
	add t1,t1,t4		# volta t1 16 linhas (pixel inicial da primeira linha)
	mv t2,t1 		# t2 = POS_ROBOZINHO	
	addi t2,t2,4		# t2 = POS_ROBOZINHO + 16 (pixel final da primeira linha)
	
	mv t0,t1		# t0 = t1
	li t4,0xFF000000	# t4 = 0xFF000000 (carrega em t4 o endereço base da memoria VGA)
	sub t0,t0,t4		# t0 = t0 - 0xFF000000 (subtrai o endereço base de t0, posição atual do Robozinho)
	li t4,1
	beq s6,t4,LOAD1D
	la t4,mapa2
	j LOAD2D
LOAD1D:	la t4,mapa1		# carrega em t4 o endereço dos dados do mapa1
LOAD2D:	addi t4,t4,8		# t4 = endereço do primeiro pixel do mapa1 (depois das informações de nlin ncol)
	add t4,t4,t0		# t4 = t4 + t0 (carrega em t4 o endereço do pixel do mapa1 no segmento de dados sobre o qual o Robozinho esta localizado)
	
	
DELLOOPD:beq t1,t2,ENTER2D	# se t1 atingir o fim da linha de pixels, quebre linha
	lb t0,0(t3)		# le um byte de "Robozinho1preto" para t0
	sb t0,0(t1)		# escreve o byte (pixel preto\invisivel) na memoria VGA
	sb t0,0(t4)
	
	addi t1,t1,1		# soma 1 ao endereço t1
	addi t3,t3,1		# soma 1 ao endereço t3
	addi t4,t4,1		# soma 1 ao endereço t4
	j DELLOOPU		# volta a verificar a condiçao do loop
	
ENTER2D:addi t1,t1,316		# t1 pula para o pixel inicial da linha de baixo na memoria VGA
	addi t4,t4,316		# t4 pula para o pixel inicial da linha de baixo no segmento de dados
	addi t2,t2,320		# t2 pula para o pixel final da linha de baixo na memoria VGA
	addi t5,t5,1          	# atualiza o contador de quebras de linha
	beq t5,t6,DELETE	# termina o carregamento da imagem se 16 quebras de linha ocorrerem
	j DELLOOPD		# pula para delloop

DELRGHTS:
	addi t1,t1,2		# t1 = t1 - 1 (carrega o endereço do pixel inferior esquerdo do ponto detectado)
	la t3,vertpoint		# carrega a imagem que vai sobrepor o Robozinho com pixels pretos
	addi t3,t3,8		# t3 = endereço do primeiro pixel da imagem (depois das informações de nlin ncol)

	li t5,0	
	li t6,4			# reinicia o contador para 16 quebras de linha
	
	li t4,960		# t4 = 5120
	sub t1,t1,t4		# volta t1 16 linhas (pixel inicial da primeira linha)
	mv t2,t1 		# t2 = POS_ROBOZINHO	
	addi t2,t2,2		# t2 = POS_ROBOZINHO + 16 (pixel final da primeira linha)
	
	mv t0,t1		# t0 = t1
	li t4,0xFF000000	# t4 = 0xFF000000 (carrega em t4 o endereço base da memoria VGA)
	sub t0,t0,t4		# t0 = t0 - 0xFF000000 (subtrai o endereço base de t0, posição atual do Robozinho)
	li t4,1
	beq s6,t4,LOAD1R
	la t4,mapa2
	j LOAD2R
LOAD1R:	la t4,mapa1		# carrega em t4 o endereço dos dados do mapa1
LOAD2R:	addi t4,t4,8		# t4 = endereço do primeiro pixel do mapa1 (depois das informações de nlin ncol)
	add t4,t4,t0		# t4 = t4 + t0 (carrega em t4 o endereço do pixel do mapa1 no segmento de dados sobre o qual o Robozinho esta localizado)
	
	
DELLOOPR:beq t1,t2,ENTER2R	# se t1 atingir o fim da linha de pixels, quebre linha
	lb t0,0(t3)		# le um byte de "Robozinho1preto" para t0
	sb t0,0(t1)		# escreve o byte (pixel preto\invisivel) na memoria VGA
	sb t0,0(t4)
	
	addi t1,t1,1		# soma 1 ao endereço t1
	addi t3,t3,1		# soma 1 ao endereço t3
	addi t4,t4,1		# soma 1 ao endereço t4
	j DELLOOPR		# volta a verificar a condiçao do loop
	
ENTER2R:addi t1,t1,318		# t1 pula para o pixel inicial da linha de baixo na memoria VGA
	addi t4,t4,318		# t4 pula para o pixel inicial da linha de baixo no segmento de dados
	addi t2,t2,320		# t2 pula para o pixel final da linha de baixo na memoria VGA
	addi t5,t5,1          	# atualiza o contador de quebras de linha
	beq t5,t6,DELETE	# termina o carregamento da imagem se 16 quebras de linha ocorrerem
	j DELLOOPR		# pula para delloop
	
# Printa preto em cima da posição do personagem (apaga o personagem anterior)
	
DELETE:	la t3,Robozinho1preto	# carrega a imagem que vai sobrepor o Robozinho com pixels pretos
	addi t3,t3,8		# t3 = endereço do primeiro pixel da imagem (depois das informações de nlin ncol)

	li t5,0	
	li t6,16		# reinicia o contador para 16 quebras de linha
	
	li t4,5120		# t4 = 5120
	la t0,POS_ROBOZINHO	# carrega o endereço de "POS_ROBOZINHO" no registrador t0
	lw t1,0(t0)		# le a word guardada em "POS_ROBOZINHO" para t1 (t1 = posição atual do Robozinho)
	sub t1,t1,t4		# volta t1 16 linhas (pixel inicial da primeira linha)
	mv t2,t1 		# t2 = POS_ROBOZINHO	
	addi t2,t2,16		# t2 = POS_ROBOZINHO + 16 (pixel final da primeira linha)
	
	mv t0,t1		# t0 = t1
	li t4,0xFF000000	# t4 = 0xFF000000 (carrega em t4 o endereço base da memoria VGA)
	sub t0,t0,t4		# t0 = t0 - 0xFF000000 (subtrai o endereço base de t0, posição atual do Robozinho)
	li t4,1
	beq s6,t4,LOAD1
	la t4,mapa2
	j LOAD2
LOAD1:	la t4,mapa1		# carrega em t4 o endereço dos dados do mapa1
LOAD2:	addi t4,t4,8		# t4 = endereço do primeiro pixel do mapa1 (depois das informações de nlin ncol)
	add t4,t4,t0		# t4 = t4 + t0 (carrega em t4 o endereço do pixel do mapa1 no segmento de dados sobre o qual o Robozinho esta localizado)
	
	
DELLOOP:beq t1,t2,ENTER2	# se t1 atingir o fim da linha de pixels, quebre linha
	lb t0,0(t3)		# le um byte de "Robozinho1preto" para t0
	sb t0,0(t1)		# escreve o byte (pixel preto\invisivel) na memoria VGA
	
	li a5,199		# a5 = 199 (valor de um pixel invisivel)
	bgeu t0, a5, INVSBL	# se t0 >= 199, ou seja, se t0 for um pixel invisivel, pule para INVSBL (note que t0 nunca sera realmente maior que 199, mas não existe "bequ")
	sb t0,0(t4)		# se t0 < 199, ou seja, se t0 for um pixel preto, escreve o byte (pixel preto) no endereço t4 do mapa1 no segmento de dados 
	
INVSBL:	addi t1,t1,1		# soma 1 ao endereço t1
	addi t3,t3,1		# soma 1 ao endereço t3
	addi t4,t4,1		# soma 1 ao endereço t4
	j DELLOOP		# volta a verificar a condiçao do loop
	
ENTER2:	addi t1,t1,304		# t1 pula para o pixel inicial da linha de baixo na memoria VGA
	addi t4,t4,304		# t4 pula para o pixel inicial da linha de baixo no segmento de dados
	addi t2,t2,320		# t2 pula para o pixel final da linha de baixo na memoria VGA
	addi t5,t5,1          	# atualiza o contador de quebras de linha
	beq t5,t6,DELETE_COL	# termina o carregamento da imagem se 16 quebras de linha ocorrerem
	j DELLOOP		# pula para delloop 
	
# Printa preto em cima da posição do personagem (apaga o personagem anterior)
	
DELETE_COL:
	li t5,0	
	li t6,16		# reinicia o contador para 16 quebras de linha
	
	li t4,5120		# t4 = 5120
	la t0,POS_ROBOZINHO	# carrega o endereço de "POS_ROBOZINHO" no registrador t0
	lw t1,0(t0)		# le a word guardada em "POS_ROBOZINHO" para t1 (t1 = posição atual do Robozinho)
	li t0,0x100000
	add t1,t1,t0
	sub t1,t1,t4		# volta t1 16 linhas (pixel inicial da primeira linha)
	mv t2,t1 		# t2 = POS_ROBOZINHO	
	addi t2,t2,16		# t2 = POS_ROBOZINHO + 16 (pixel final da primeira linha)
	
DELLOOP_COL:
	beq t1,t2,ENTER2_COL	# se t1 atingir o fim da linha de pixels, quebre linha
	sw zero,0(t1)		# escreve o byte (pixel preto\invisivel) na memoria VGA
	addi t1,t1,4		# soma 1 ao endereço t1
	j DELLOOP_COL		# volta a verificar a condiçao do loop
	
ENTER2_COL:	
	addi t1,t1,304		# t1 pula para o pixel inicial da linha de baixo na memoria VGA
	addi t2,t2,320		# t2 pula para o pixel final da linha de baixo na memoria VGA
	addi t5,t5,1          	# atualiza o contador de quebras de linha
	beq t5,t6,VERIFY	# termina o carregamento da imagem se 16 quebras de linha ocorrerem
	j DELLOOP_COL		# pula para delloop 
	
# Verifica qual a tecla pressionada para movimentar o Robozinho
	
VERIFY: addi s0,s0,1		# incrementa o contador de estados do Robozinho (se s0 for par -> Robozinho1; se s0 for impar -> Robozinho2)

	li t0,2			# t0 = 2
	rem t1,s0,t0		# t1 = resto da divisão s0/2 
	beq t1,zero,MI		# se t1 = 0 (se s0 for par), va para MI (toque a nota MI)
	
	li a0,34		# a0 = 34 (carrega si bemol para a0)
	li a1,100		# a1 = 100 (nota de duração de 100 ms)
	li a2,33		# a2 = 33 (timbre "acoustic bass")
	li a3,90		# a3 = 90 (volume da nota)
	li a7,31		# a7 = 31 (carrega em a7 o ecall "MidiOut")
	ecall			# realiza o ecall
	
	j SIB			# pule para SIB (acaba de tocar a nota SIb)
	
MI:	li a0,40		# a0 = 40 (carrega mi para a0)
	li a1,100		# a1 = 100 (nota de duração de 100 ms)
	li a2,33		# a2 = 33 (timbre "acoustic bass")
	li a3,90		# a3 = 90 (volume da nota)
	li a7,31		# a7 = 31 (carrega em a7 o ecall "MidiOut")
	ecall			# realiza o ecall

SIB:	li t0,2121		# carrega 1 para t0
  	beq a4,t0,PORLFT	# se s3 for igual a 1 (valor de movimento atual para a esquerda), va para MOVLFT
  	
  	li t0,2222		# carrega 1 para t0
  	beq a4,t0,PORRGHT	# se s3 for igual a 1 (valor de movimento atual para a esquerda), va para MOVLFT

	li t0,1			# carrega 1 para t0
  	beq s3,t0,MOVLFT	# se s3 for igual a 1 (valor de movimento atual para a esquerda), va para MOVLFT
  	
  	li t0,2			# carrega 2 para t0
  	beq s3,t0,MOVUP		# se s3 for igual a 2 (valor de movimento atual para cima), va para MOVUP
  	
  	li t0,3  		# carrega 3 para t0
	beq s3,t0,MOVDWN	# se s3 for igual a 3 (valor de movimento atual para baixo), va para MOVDWN
	
	li t0,4  		# carrega 4 para t0
	beq s3,t0,MOVRGHT	# se s3 for igual a 4 (valor de movimento atual para a direita), va para MOVRGHT
	
# Carrega em t2 o offset correspondente a cada direção de movimento

PORLFT:	li t2,4916		# t2 = 5124 (volta t1 16 linhas e vai 4 pixels para a esquerda -> pixel inicial - 4) 
	j MOVROB		# pule para MOVROB (movimenta o Robozinho)

PORRGHT:li t2,5324		# t2 = 5124 (volta t1 16 linhas e vai 4 pixels para a esquerda -> pixel inicial - 4) 
	j MOVROB		# pule para MOVROB (movimenta o Robozinho)
	
MOVLFT: li t2,5124		# t2 = 5124 (volta t1 16 linhas e vai 4 pixels para a esquerda -> pixel inicial - 4) 
	j MOVROB		# pule para MOVROB (movimenta o Robozinho)

MOVUP:	li t2,6400		# t2 = 6400 (volta t1 20 linhas -> pixel inicial 4 linhas acima)
	j MOVROB		# pule para MOVROB (movimenta o Robozinho)

MOVDWN:	li t2,3840		# t2 = 3840 (volta t1 12 linhas -> pixel inicial 4 linhas abaixo)
	j MOVROB		# pule para MOVROB (movimenta o Robozinho)

MOVRGHT:li t2,5116		# t2 = 5116 (volta t1 16 linhas e vai 4 pixels para a direita -> pixel inicial + 4)
	j MOVROB		# pule para MOVROB (movimenta o Robozinho)
		
# Printa o personagem de acordo com sua direção atual de movimento (definida pelo registrador t2)	
	
MOVROB:	la t0,POS_ROBOZINHO	# carrega o endereço de "POS_ROBOZINHO" no registrador t0
	lw t1,0(t0)		# le a word guardada em "POS_ROBOZINHO" para t1 (t1 = posição atual do Robozinho)
	sub t1,t1,t2		# volta t1 16 linhas e vai 4 pixels pra frente (pixel inicial + 4) 
	mv t2,t1 		# t2 = t1
	addi t2,t2,16		# t2 = t2 + 16 (pixel final da primeira linha + 4)
	
	li t4,2			# t4 = 2 (para verificar a paridade de s0)
	rem t3,s0,t4		# t3 = resto da divisão inteira s0/2
	
	la t0,CONTADOR_ASSUSTADO
	lw t5,0(t0)
	li t0,-1
	
	beq t3,zero,PAR3	# se t3 = 0, va para PAR3 (se s0 for par, imprime o Robozinho1, se for impar, imprime o Robozinho2)

	beq t5,t0,FRACO2
	la t3,Robozinho2forte
	j NEXT3
	
FRACO2:	la t3,Robozinho2	# t3 = endereço dos dados do Robozinho2 (boca aberta)
	j NEXT3			# pula para NEXT3
	
PAR3:	beq t5,t0,FRACO1
	la t3,Robozinho1forte
	j NEXT3
	
FRACO1:	la t3,Robozinho1	# t3 = endereço dos dados do Robozinho1 (boca fechada)
	
NEXT3:	addi t3,t3,8		# t3 = endereço do primeiro pixel da imagem (depois das informações de nlin ncol)

	li t5,0
	li t6,16		# reinicia contador para 16 quebras de linha	
	
LOOP3: 	beq t1,t2,ENTER3	# se t1 atingir o fim da linha de pixels, quebre linha
	lw t0,0(t3)		# le uma word do endereço t3 (le 4 pixels da imagem)
	sw t0,0(t1)		# escreve a word na memoria VGA no endereço t1 (desenha 4 pixels na tela do Bitmap Display)
	
	li t0,0x100000
	add t1,t1,t0
	
	li t0,0x69696969
	sw t0,0(t1)
	
	li t0,0x100000
	sub t1,t1,t0
	
	addi t1,t1,4		# soma 4 ao endereço t1
	addi t3,t3,4		# soma 4 ao endereço t3
	j LOOP3			# volta a verificar a condiçao do loop
	
ENTER3:	addi t1,t1,304		# t1 pula para o pixel inicial da linha de baixo
	addi t2,t2,320		# t2 pula para o pixel final da linha de baixo
	addi t5,t5,1            # atualiza o contador de quebras de linha
	beq t5,t6,FIMMOV	# termine o carregamento da imagem se 16 quebras de linha ocorrerem
	j LOOP3			# pula para loop 3
	
# Se o Robozinho tiver se movimentado, espera 80 ms para a proxima iteração (visa reduzir a velocidade do Robozinho)
    
FIMMOV:	la t0, POS_ROBOZINHO    # carrega o endereço de "POS_ROBOZINHO" no registrador t0 
    	sw t1, 0(t0)       	# guarda a word armazenada em t1 (posição atual do Roboziho) em "POS_ROBOZINHO"
    	
	jal zero, MAINL			# retorna ao loop principal
	
# Se o Robozinho não tiver se movimentado, espera 2 ms para a proxima iteração (visa reduzir o "flick" do contador de pontos)
	
FIM:	jal zero, MAINL			# retorna ao loop principal

# Se o Robozinho colidir com o Blinky ou vice-versa

COL_BLINKY:

	li a0,38			# a0 = 38
	blt s7,a0,VERFASE_B		# se a1 for menor que o a0 entÃ£o o alien estava no sdcatter/chase mode, entÃ£o o robozino perdeu vida
	la a0, POS_BLINKY		# a0 = pos_pink
	lw a1, 0(a0)			# a1 = lw a0
	mv a4, a1			# a4 = a1
	li s4,1
	jal VER_ALIEN_2		# se nÃ£o, o blinky morreu
	
# Se o Robozinho colidir com o Blinky ou vice-versa

COL_PINK:
	li a0,38			# a0 = 38
	blt s9,a0,VERFASE_B		# se a1 for menor que o a0 entÃ£o o alien estava no sdcatter/chase mode, entÃ£o o robozino perdeu vida
	la a0, POS_PINK		# a0 = pos_pink
	lw a1, 0(a0)			# a1 = lw a0
	mv a4, a1			# a4 = a1
	li s4,2
	jal VER_ALIEN_2		# se nÃ£o, o pink morreu

# Se o Robozinho colidir com o Pink ou vice-versa

COL_INKY:
	li a0,38			# a0 = 38
	blt s10,a0,VERFASE_B		# se a1 for menor que o a0 entÃ£o o alien estava no sdcatter/chase mode, entÃ£o o robozino perdeu vida
	la a0, POS_INKY		# a0 = pos_inky
	lw a1, 0(a0)			# a1 = lw a0
	mv a4, a1			# a4 = a1
	li s4,3
	jal VER_ALIEN_2			# se nÃ£o, o blinky morreu
	
# Se o Robozinho colidir com o Clyde ou vice-versa

COL_CLYDE:
	li a0,38			# a0 = 38
	blt s11,a0,VERFASE_B		# se a1 for menor que o a0 entÃ£o o alien estava no sdcatter/chase mode, entÃ£o o robozino perdeu vida
	la a0, POS_CLYDE		# a0 = pos_clyde
	lw a1, 0(a0)			# a1 = lw a0
	mv a4, a1			# a4 = a1
	li s4,4
	jal VER_ALIEN_2		# se nÃ£o, o blinky morreu
	

VERFASE_B:
	li t2,5120
	la t0,POS_ROBOZINHO	# carrega o endereço de "POS_ROBOZINHO" no registrador t0
	lw t1,0(t0)		# le a word guardada em "POS_ROBOZINHO" para t1 (t1 = posição atual do Robozinho)
	sub t1,t1,t2		# volta t1 16 linhas e vai 4 pixels pra frente (pixel inicial + 4) 
	mv t2,t1 		# t2 = t1
	addi t2,t2,16		# t2 = t2 + 16 (pixel final da primeira linha + 4)
	
	la t3,Robozinhomorto	# t3 = endereço dos dados do Robozinho1 (boca fechada)
	addi t3,t3,8		# t3 = endereço do primeiro pixel da imagem (depois das informações de nlin ncol)

	li t5,0
	li t6,16		# reinicia contador para 16 quebras de linha	
	
LOOP_MRTB: 	
	beq t1,t2,ENTER_MRTB	# se t1 atingir o fim da linha de pixels, quebre linha
	lw t0,0(t3)		# le uma word do endereço t3 (le 4 pixels da imagem)
	sw t0,0(t1)		# escreve a word na memoria VGA no endereço t1 (desenha 4 pixels na tela do Bitmap Display)
	addi t1,t1,4		# soma 4 ao endereço t1
	addi t3,t3,4		# soma 4 ao endereço t3
	j LOOP_MRTB			# volta a verificar a condiçao do loop
	
ENTER_MRTB:	
	addi t1,t1,304		# t1 pula para o pixel inicial da linha de baixo
	addi t2,t2,320		# t2 pula para o pixel final da linha de baixo
	addi t5,t5,1            # atualiza o contador de quebras de linha
	beq t5,t6,AFTERB		# termine o carregamento da imagem se 16 quebras de linha ocorrerem
	j LOOP_MRTB			# pula para loop 3
	
AFTERB:	li t0,1
	beq s6,t0,FASE1
	jal zero, RESET_FASE2
	
# Mostra a tela de derrota

DERROTA:lw t0, PONTOS
	lw t1, HIGH_SCORE
	
	bgt t0,t1,NEW_HIGH_SCORE_D
	j MENU_DER

NEW_HIGH_SCORE_D:
	
	li a7,1024
	la a0,ARQUIVO
	li a1,1
	ecall
	mv t0,a0
	
	li a7,64
	mv a0,t0
	la a1,PONTOS
	li a2,4
	ecall
	
	li a7,57
	mv a0,t0
	ecall

MENU_DER:	
	li s1,0xFF000000	# s1 = endereco inicial da Memoria VGA - Frame 0
	li s2,0xFF012C00	# s2 = endereco final da Memoria VGA - Frame 0
	la s0,telalose		# s0 = endereço dos dados do mapa 1
	addi s0,s0,8		# s0 = endereço do primeiro pixel da imagem (depois das informações de nlin ncol)

LOOPL: 	beq s1,s2,LOSESONG		# se s1 = ultimo endereço da Memoria VGA, saia do loop
	lw t0,0(s0)		# le uma word do endereço s0 (le 4 pixels da imagem)
	sw t0,0(s1)		# escreve a word na memoria VGA no endereço s1 (desenha 4 pixels na tela do Bitmap Display)
	addi s1,s1,4		# soma 4 ao endereço s1 
	addi s0,s0,4		# soma 4 ao endereço s0
	j LOOPL			# volta a verificar a condiçao do loop
	
LOSESONG:
	li a0,100
	li a7,32           	# define a chamada de syscall para pausa
   	ecall               	# realiza uma pausa de 3 s
   	
   	li a0,69		# a0 = 76 (carrega mi para a0)
	li a1,1500		# a1 = 100 (nota de duração de 100 ms)
	li a2,32		# a2 = 32 (timbre "guitar harmonic")
	li a3,100		# a3 = 50 (volume da nota)
	li a7,31		# a7 = 31 (carrega em a7 o ecall "MidiOut")
	ecall			# realiza o ecall
	
	li a0,64		# a0 = 76 (carrega mi para a0)
	li a1,1500		# a1 = 100 (nota de duração de 100 ms)
	li a2,32		# a2 = 32 (timbre "guitar harmonic")
	li a3,100		# a3 = 50 (volume da nota)
	li a7,31		# a7 = 31 (carrega em a7 o ecall "MidiOut")
	ecall			# realiza o ecall
	
	li a0,60		# a0 = 76 (carrega mi para a0)
	li a1,1500		# a1 = 100 (nota de duração de 100 ms)
	li a2,32		# a2 = 32 (timbre "guitar harmonic")
	li a3,100		# a3 = 50 (volume da nota)
	li a7,31		# a7 = 31 (carrega em a7 o ecall "MidiOut")
	ecall			# realiza o ecall
	
	li a0,57		# a0 = 76 (carrega mi para a0)
	li a1,1500		# a1 = 100 (nota de duração de 100 ms)
	li a2,32		# a2 = 32 (timbre "guitar harmonic")
	li a3,100		# a3 = 50 (volume da nota)
	li a7,31		# a7 = 31 (carrega em a7 o ecall "MidiOut")
	ecall			# realiza o ecall
	
	li a0,52		# a0 = 76 (carrega mi para a0)
	li a1,1500		# a1 = 100 (nota de duração de 100 ms)
	li a2,32		# a2 = 32 (timbre "guitar harmonic")
	li a3,100		# a3 = 50 (volume da nota)
	li a7,31		# a7 = 31 (carrega em a7 o ecall "MidiOut")
	ecall			# realiza o ecall
	
	li a0,45		# a0 = 76 (carrega mi para a0)
	li a1,250		# a1 = 100 (nota de duração de 100 ms)
	li a2,33		# a2 = 32 (timbre "guitar harmonic")
	li a3,200		# a3 = 50 (volume da nota)
	li a7,31		# a7 = 31 (carrega em a7 o ecall "MidiOut")
	ecall			# realiza o ecall
	
	li a0,200
	li a7,32           	# define a chamada de syscall para pausa
   	ecall               	# realiza uma pausa de 3 s
	
	li a0,52		# a0 = 76 (carrega mi para a0)
	li a1,250		# a1 = 100 (nota de duração de 100 ms)
	li a2,33		# a2 = 32 (timbre "guitar harmonic")
	li a3,200		# a3 = 50 (volume da nota)
	li a7,31		# a7 = 31 (carrega em a7 o ecall "MidiOut")
	ecall			# realiza o ecall
	
	li a0,200
	li a7,32           	# define a chamada de syscall para pausa
   	ecall               	# realiza uma pausa de 3 s
	
	li a0,53		# a0 = 76 (carrega mi para a0)
	li a1,250		# a1 = 100 (nota de duração de 100 ms)
	li a2,33		# a2 = 32 (timbre "guitar harmonic")
	li a3,200		# a3 = 50 (volume da nota)
	li a7,31		# a7 = 31 (carrega em a7 o ecall "MidiOut")
	ecall			# realiza o ecall
	
	li a0,200
	li a7,32           	# define a chamada de syscall para pausa
   	ecall               	# realiza uma pausa de 3 s
	
	li a0,50		# a0 = 76 (carrega mi para a0)
	li a1,250		# a1 = 100 (nota de duração de 100 ms)
	li a2,33		# a2 = 32 (timbre "guitar harmonic")
	li a3,200		# a3 = 50 (volume da nota)
	li a7,31		# a7 = 31 (carrega em a7 o ecall "MidiOut")
	ecall			# realiza o ecall
	
	li a0,200
	li a7,32           	# define a chamada de syscall para pausa
   	ecall               	# realiza uma pausa de 3 s
	
	li a0,52		# a0 = 76 (carrega mi para a0)
	li a1,250		# a1 = 100 (nota de duração de 100 ms)
	li a2,33		# a2 = 32 (timbre "guitar harmonic")
	li a3,200		# a3 = 50 (volume da nota)
	li a7,31		# a7 = 31 (carrega em a7 o ecall "MidiOut")
	ecall			# realiza o ecall
	
	li a0,200
	li a7,32           	# define a chamada de syscall para pausa
   	ecall               	# realiza uma pausa de 3 s
	
	li a0,50		# a0 = 76 (carrega mi para a0)
	li a1,250		# a1 = 100 (nota de duração de 100 ms)
	li a2,33		# a2 = 32 (timbre "guitar harmonic")
	li a3,200		# a3 = 50 (volume da nota)
	li a7,31		# a7 = 31 (carrega em a7 o ecall "MidiOut")
	ecall			# realiza o ecall
	
	li a0,50
	li a7,32           	# define a chamada de syscall para pausa
   	ecall               	# realiza uma pausa de 3 s
   	
   	li a0,52		# a0 = 76 (carrega mi para a0)
	li a1,250		# a1 = 100 (nota de duração de 100 ms)
	li a2,33		# a2 = 32 (timbre "guitar harmonic")
	li a3,200		# a3 = 50 (volume da nota)
	li a7,31		# a7 = 31 (carrega em a7 o ecall "MidiOut")
	ecall			# realiza o ecall
	
	li a0,50
	li a7,32           	# define a chamada de syscall para pausa
   	ecall               	# realiza uma pausa de 3 s
   	
   	li a0,50		# a0 = 76 (carrega mi para a0)
	li a1,250		# a1 = 100 (nota de duração de 100 ms)
	li a2,33		# a2 = 32 (timbre "guitar harmonic")
	li a3,200		# a3 = 50 (volume da nota)
	li a7,31		# a7 = 31 (carrega em a7 o ecall "MidiOut")
	ecall			# realiza o ecall
	
	li a0,50
	li a7,32           	# define a chamada de syscall para pausa
   	ecall               	# realiza uma pausa de 3 s
   	
   	li a0,48		# a0 = 76 (carrega mi para a0)
	li a1,250		# a1 = 100 (nota de duração de 100 ms)
	li a2,33		# a2 = 32 (timbre "guitar harmonic")
	li a3,200		# a3 = 50 (volume da nota)
	li a7,31		# a7 = 31 (carrega em a7 o ecall "MidiOut")
	ecall			# realiza o ecall
	
	li a0,200
	li a7,32           	# define a chamada de syscall para pausa
   	ecall               	# realiza uma pausa de 3 s
   	
   	li a0,47		# a0 = 76 (carrega mi para a0)
	li a1,250		# a1 = 100 (nota de duração de 100 ms)
	li a2,33		# a2 = 32 (timbre "guitar harmonic")
	li a3,200		# a3 = 50 (volume da nota)
	li a7,31		# a7 = 31 (carrega em a7 o ecall "MidiOut")
	ecall			# realiza o ecall
	
	li a0,200
	li a7,32           	# define a chamada de syscall para pausa
   	ecall               	# realiza uma pausa de 3 s
   	
   	li a0,45		# a0 = 76 (carrega mi para a0)
	li a1,1000		# a1 = 100 (nota de duração de 100 ms)
	li a2,33		# a2 = 32 (timbre "guitar harmonic")
	li a3,200		# a3 = 50 (volume da nota)
	li a7,31		# a7 = 31 (carrega em a7 o ecall "MidiOut")
	ecall			# realiza o ecall
	
	li a0,200
	li a7,32           	# define a chamada de syscall para pausa
   	ecall               	# realiza uma pausa de 3 s

LOOPLOSE:li t2,0xFF200000	# carrega o endereço de controle do KDMMIO ("teclado")
	lw t0,0(t2)		# le uma word a partir do endereço de controle do KDMMIO
	andi t0,t0,0x0001	# mascara todos os bits de t0 com exceçao do bit menos significativo
   	bne t0,zero,CLSL   	# se o BMS de t0 nÃ£o for 0 (hÃ tecla pressionada), pule para MAPA1
   	j LOOPLOSE

CLSL:	li a7, 10
	ecall	
	
# Mostra a tela de vitoria
	
VITORIA:li a0,100
	li a7,32           	# define a chamada de syscall para pausa
   	ecall               	# realiza uma pausa de 3 s
	
	li a0,62		# a0 = 76 (carrega mi para a0)
	li a1,125		# a1 = 100 (nota de duração de 100 ms)
	li a2,32		# a2 = 32 (timbre "guitar harmonic")
	li a3,100		# a3 = 50 (volume da nota)
	li a7,31		# a7 = 31 (carrega em a7 o ecall "MidiOut")
	ecall			# realiza o ecall
	
	li a0,250
	li a7,32           	# define a chamada de syscall para pausa
   	ecall               	# realiza uma pausa de 3 s
	
	li a0,62		# a0 = 76 (carrega mi para a0)
	li a1,125		# a1 = 100 (nota de duração de 100 ms)
	li a2,32		# a2 = 32 (timbre "guitar harmonic")
	li a3,100		# a3 = 50 (volume da nota)
	li a7,31		# a7 = 31 (carrega em a7 o ecall "MidiOut")
	ecall			# realiza o ecall
	
	li a0,250
	li a7,32           	# define a chamada de syscall para pausa
   	ecall               	# realiza uma pausa de 3 s
	
	li a0,57		# a0 = 76 (carrega mi para a0)
	li a1,125		# a1 = 100 (nota de duração de 100 ms)
	li a2,32		# a2 = 32 (timbre "guitar harmonic")
	li a3,100		# a3 = 50 (volume da nota)
	li a7,31		# a7 = 31 (carrega em a7 o ecall "MidiOut")
	ecall			# realiza o ecall
	
	li a0,125
	li a7,32           	# define a chamada de syscall para pausa
   	ecall               	# realiza uma pausa de 3 s
	
	li a0,59		# a0 = 76 (carrega mi para a0)
	li a1,125		# a1 = 100 (nota de duração de 100 ms)
	li a2,32		# a2 = 32 (timbre "guitar harmonic")
	li a3,100		# a3 = 50 (volume da nota)
	li a7,31		# a7 = 31 (carrega em a7 o ecall "MidiOut")
	ecall			# realiza o ecall
	
	li a0,125
	li a7,32           	# define a chamada de syscall para pausa
   	ecall               	# realiza uma pausa de 3 s
	
	li a0,60		# a0 = 76 (carrega mi para a0)
	li a1,125		# a1 = 100 (nota de duração de 100 ms)
	li a2,32		# a2 = 32 (timbre "guitar harmonic")
	li a3,100		# a3 = 50 (volume da nota)
	li a7,31		# a7 = 31 (carrega em a7 o ecall "MidiOut")
	ecall			# realiza o ecall
	
	li a0,125
	li a7,32           	# define a chamada de syscall para pausa
   	ecall               	# realiza uma pausa de 3 s
	
	li a0,62		# a0 = 76 (carrega mi para a0)
	li a1,125		# a1 = 100 (nota de duração de 100 ms)
	li a2,32		# a2 = 32 (timbre "guitar harmonic")
	li a3,100		# a3 = 50 (volume da nota)
	li a7,31		# a7 = 31 (carrega em a7 o ecall "MidiOut")
	ecall			# realiza o ecall
	
	li a0,3000
	li a7,32           	# define a chamada de syscall para pausa
   	ecall               	# realiza uma pausa de 3 s

	lw t0, PONTOS
	lw t1, HIGH_SCORE
	
	bgt t0,t1,NEW_HIGH_SCORE
	j MENU_VIC

NEW_HIGH_SCORE:
	
	li a7,1024
	la a0,ARQUIVO
	li a1,1
	ecall
	mv t0,a0
	
	li a7,64
	mv a0,t0
	la a1,PONTOS
	li a2,4
	ecall
	
	li a7,57
	mv a0,t0
	ecall
	
MENU_VIC:li s1,0xFF000000	# s1 = endereco inicial da Memoria VGA - Frame 0
	li s2,0xFF012C00	# s2 = endereco final da Memoria VGA - Frame 0
	la s0,telawin		# s0 = endereço dos dados do mapa 1
	addi s0,s0,8		# s0 = endereço do primeiro pixel da imagem (depois das informações de nlin ncol)

LOOPV: 	beq s1,s2,VICSONG		# se s1 = ultimo endereço da Memoria VGA, saia do loop
	lw t0,0(s0)		# le uma word do endereço s0 (le 4 pixels da imagem)
	sw t0,0(s1)		# escreve a word na memoria VGA no endereço s1 (desenha 4 pixels na tela do Bitmap Display)
	addi s1,s1,4		# soma 4 ao endereço s1 
	addi s0,s0,4		# soma 4 ao endereço s0
	j LOOPV			# volta a verificar a condiçao do loop
	
VICSONG:li a0,65		# a0 = 76 (carrega mi para a0)
	li a1,200		# a1 = 100 (nota de duração de 100 ms)
	li a2,32		# a2 = 32 (timbre "guitar harmonic")
	li a3,100		# a3 = 50 (volume da nota)
	li a7,31		# a7 = 31 (carrega em a7 o ecall "MidiOut")
	ecall			# realiza o ecall
	
	li a0,60		# a0 = 76 (carrega mi para a0)
	li a1,200		# a1 = 100 (nota de duração de 100 ms)
	li a2,32		# a2 = 32 (timbre "guitar harmonic")
	li a3,100		# a3 = 50 (volume da nota)
	li a7,31		# a7 = 31 (carrega em a7 o ecall "MidiOut")
	ecall			# realiza o ecall
	
	li a0,57		# a0 = 76 (carrega mi para a0)
	li a1,200		# a1 = 100 (nota de duração de 100 ms)
	li a2,32		# a2 = 32 (timbre "guitar harmonic")
	li a3,100		# a3 = 50 (volume da nota)
	li a7,31		# a7 = 31 (carrega em a7 o ecall "MidiOut")
	ecall			# realiza o ecall
	
	li a0,53		# a0 = 76 (carrega mi para a0)
	li a1,200		# a1 = 100 (nota de duração de 100 ms)
	li a2,32		# a2 = 32 (timbre "guitar harmonic")
	li a3,100		# a3 = 50 (volume da nota)
	li a7,31		# a7 = 31 (carrega em a7 o ecall "MidiOut")
	ecall			# realiza o ecall
	
	li a0,48		# a0 = 76 (carrega mi para a0)
	li a1,200		# a1 = 100 (nota de duração de 100 ms)
	li a2,32		# a2 = 32 (timbre "guitar harmonic")
	li a3,100		# a3 = 50 (volume da nota)
	li a7,31		# a7 = 31 (carrega em a7 o ecall "MidiOut")
	ecall			# realiza o ecall
	
	li a0,41		# a0 = 76 (carrega mi para a0)
	li a1,200		# a1 = 100 (nota de duração de 100 ms)
	li a2,32		# a2 = 32 (timbre "guitar harmonic")
	li a3,100		# a3 = 50 (volume da nota)
	li a7,31		# a7 = 31 (carrega em a7 o ecall "MidiOut")
	ecall			# realiza o ecall
	
	li a0,250
	li a7,32           	# define a chamada de syscall para pausa
   	ecall               	# realiza uma pausa de 3 s
   	
   	li a0,67		# a0 = 76 (carrega mi para a0)
	li a1,100		# a1 = 100 (nota de duração de 100 ms)
	li a2,32		# a2 = 32 (timbre "guitar harmonic")
	li a3,100		# a3 = 50 (volume da nota)
	li a7,31		# a7 = 31 (carrega em a7 o ecall "MidiOut")
	ecall			# realiza o ecall
	
	li a0,62		# a0 = 76 (carrega mi para a0)
	li a1,100		# a1 = 100 (nota de duração de 100 ms)
	li a2,32		# a2 = 32 (timbre "guitar harmonic")
	li a3,100		# a3 = 50 (volume da nota)
	li a7,31		# a7 = 31 (carrega em a7 o ecall "MidiOut")
	ecall			# realiza o ecall
	
	li a0,59		# a0 = 76 (carrega mi para a0)
	li a1,100		# a1 = 100 (nota de duração de 100 ms)
	li a2,32		# a2 = 32 (timbre "guitar harmonic")
	li a3,100		# a3 = 50 (volume da nota)
	li a7,31		# a7 = 31 (carrega em a7 o ecall "MidiOut")
	ecall			# realiza o ecall
	
	li a0,55		# a0 = 76 (carrega mi para a0)
	li a1,100		# a1 = 100 (nota de duração de 100 ms)
	li a2,32		# a2 = 32 (timbre "guitar harmonic")
	li a3,100		# a3 = 50 (volume da nota)
	li a7,31		# a7 = 31 (carrega em a7 o ecall "MidiOut")
	ecall			# realiza o ecall
	
	li a0,50		# a0 = 76 (carrega mi para a0)
	li a1,100		# a1 = 100 (nota de duração de 100 ms)
	li a2,32		# a2 = 32 (timbre "guitar harmonic")
	li a3,100		# a3 = 50 (volume da nota)
	li a7,31		# a7 = 31 (carrega em a7 o ecall "MidiOut")
	ecall			# realiza o ecall
	
	li a0,43		# a0 = 76 (carrega mi para a0)
	li a1,100		# a1 = 100 (nota de duração de 100 ms)
	li a2,32		# a2 = 32 (timbre "guitar harmonic")
	li a3,100		# a3 = 50 (volume da nota)
	li a7,31		# a7 = 31 (carrega em a7 o ecall "MidiOut")
	ecall			# realiza o ecall
	
	li a0,100
	li a7,32           	# define a chamada de syscall para pausa
   	ecall               	# realiza uma pausa de 3 s
   	
   	li a0,67		# a0 = 76 (carrega mi para a0)
	li a1,100		# a1 = 100 (nota de duração de 100 ms)
	li a2,32		# a2 = 32 (timbre "guitar harmonic")
	li a3,100		# a3 = 50 (volume da nota)
	li a7,31		# a7 = 31 (carrega em a7 o ecall "MidiOut")
	ecall			# realiza o ecall
	
	li a0,62		# a0 = 76 (carrega mi para a0)
	li a1,100		# a1 = 100 (nota de duração de 100 ms)
	li a2,32		# a2 = 32 (timbre "guitar harmonic")
	li a3,100		# a3 = 50 (volume da nota)
	li a7,31		# a7 = 31 (carrega em a7 o ecall "MidiOut")
	ecall			# realiza o ecall
	
	li a0,59		# a0 = 76 (carrega mi para a0)
	li a1,100		# a1 = 100 (nota de duração de 100 ms)
	li a2,32		# a2 = 32 (timbre "guitar harmonic")
	li a3,100		# a3 = 50 (volume da nota)
	li a7,31		# a7 = 31 (carrega em a7 o ecall "MidiOut")
	ecall			# realiza o ecall
	
	li a0,55		# a0 = 76 (carrega mi para a0)
	li a1,100		# a1 = 100 (nota de duração de 100 ms)
	li a2,32		# a2 = 32 (timbre "guitar harmonic")
	li a3,100		# a3 = 50 (volume da nota)
	li a7,31		# a7 = 31 (carrega em a7 o ecall "MidiOut")
	ecall			# realiza o ecall
	
	li a0,50		# a0 = 76 (carrega mi para a0)
	li a1,100		# a1 = 100 (nota de duração de 100 ms)
	li a2,32		# a2 = 32 (timbre "guitar harmonic")
	li a3,100		# a3 = 50 (volume da nota)
	li a7,31		# a7 = 31 (carrega em a7 o ecall "MidiOut")
	ecall			# realiza o ecall
	
	li a0,43		# a0 = 76 (carrega mi para a0)
	li a1,100		# a1 = 100 (nota de duração de 100 ms)
	li a2,32		# a2 = 32 (timbre "guitar harmonic")
	li a3,100		# a3 = 50 (volume da nota)
	li a7,31		# a7 = 31 (carrega em a7 o ecall "MidiOut")
	ecall			# realiza o ecall
	
	li a0,100
	li a7,32           	# define a chamada de syscall para pausa
   	ecall               	# realiza uma pausa de 3 s
   	
   	li a0,67		# a0 = 76 (carrega mi para a0)
	li a1,100		# a1 = 100 (nota de duração de 100 ms)
	li a2,32		# a2 = 32 (timbre "guitar harmonic")
	li a3,100		# a3 = 50 (volume da nota)
	li a7,31		# a7 = 31 (carrega em a7 o ecall "MidiOut")
	ecall			# realiza o ecall
	
	li a0,62		# a0 = 76 (carrega mi para a0)
	li a1,100		# a1 = 100 (nota de duração de 100 ms)
	li a2,32		# a2 = 32 (timbre "guitar harmonic")
	li a3,100		# a3 = 50 (volume da nota)
	li a7,31		# a7 = 31 (carrega em a7 o ecall "MidiOut")
	ecall			# realiza o ecall
	
	li a0,59		# a0 = 76 (carrega mi para a0)
	li a1,100		# a1 = 100 (nota de duração de 100 ms)
	li a2,32		# a2 = 32 (timbre "guitar harmonic")
	li a3,100		# a3 = 50 (volume da nota)
	li a7,31		# a7 = 31 (carrega em a7 o ecall "MidiOut")
	ecall			# realiza o ecall
	
	li a0,55		# a0 = 76 (carrega mi para a0)
	li a1,100		# a1 = 100 (nota de duração de 100 ms)
	li a2,32		# a2 = 32 (timbre "guitar harmonic")
	li a3,100		# a3 = 50 (volume da nota)
	li a7,31		# a7 = 31 (carrega em a7 o ecall "MidiOut")
	ecall			# realiza o ecall
	
	li a0,50		# a0 = 76 (carrega mi para a0)
	li a1,100		# a1 = 100 (nota de duração de 100 ms)
	li a2,32		# a2 = 32 (timbre "guitar harmonic")
	li a3,100		# a3 = 50 (volume da nota)
	li a7,31		# a7 = 31 (carrega em a7 o ecall "MidiOut")
	ecall			# realiza o ecall
	
	li a0,43		# a0 = 76 (carrega mi para a0)
	li a1,100		# a1 = 100 (nota de duração de 100 ms)
	li a2,32		# a2 = 32 (timbre "guitar harmonic")
	li a3,100		# a3 = 50 (volume da nota)
	li a7,31		# a7 = 31 (carrega em a7 o ecall "MidiOut")
	ecall			# realiza o ecall
	
	li a0,100
	li a7,32           	# define a chamada de syscall para pausa
   	ecall               	# realiza uma pausa de 3 s
   	
   	li a0,67		# a0 = 76 (carrega mi para a0)
	li a1,100		# a1 = 100 (nota de duração de 100 ms)
	li a2,32		# a2 = 32 (timbre "guitar harmonic")
	li a3,100		# a3 = 50 (volume da nota)
	li a7,31		# a7 = 31 (carrega em a7 o ecall "MidiOut")
	ecall			# realiza o ecall
	
	li a0,62		# a0 = 76 (carrega mi para a0)
	li a1,100		# a1 = 100 (nota de duração de 100 ms)
	li a2,32		# a2 = 32 (timbre "guitar harmonic")
	li a3,100		# a3 = 50 (volume da nota)
	li a7,31		# a7 = 31 (carrega em a7 o ecall "MidiOut")
	ecall			# realiza o ecall
	
	li a0,59		# a0 = 76 (carrega mi para a0)
	li a1,100		# a1 = 100 (nota de duração de 100 ms)
	li a2,32		# a2 = 32 (timbre "guitar harmonic")
	li a3,100		# a3 = 50 (volume da nota)
	li a7,31		# a7 = 31 (carrega em a7 o ecall "MidiOut")
	ecall			# realiza o ecall
	
	li a0,55		# a0 = 76 (carrega mi para a0)
	li a1,100		# a1 = 100 (nota de duração de 100 ms)
	li a2,32		# a2 = 32 (timbre "guitar harmonic")
	li a3,100		# a3 = 50 (volume da nota)
	li a7,31		# a7 = 31 (carrega em a7 o ecall "MidiOut")
	ecall			# realiza o ecall
	
	li a0,50		# a0 = 76 (carrega mi para a0)
	li a1,100		# a1 = 100 (nota de duração de 100 ms)
	li a2,32		# a2 = 32 (timbre "guitar harmonic")
	li a3,100		# a3 = 50 (volume da nota)
	li a7,31		# a7 = 31 (carrega em a7 o ecall "MidiOut")
	ecall			# realiza o ecall
	
	li a0,43		# a0 = 76 (carrega mi para a0)
	li a1,100		# a1 = 100 (nota de duração de 100 ms)
	li a2,32		# a2 = 32 (timbre "guitar harmonic")
	li a3,100		# a3 = 50 (volume da nota)
	li a7,31		# a7 = 31 (carrega em a7 o ecall "MidiOut")
	ecall			# realiza o ecall
	
	li a0,250
	li a7,32           	# define a chamada de syscall para pausa
   	ecall               	# realiza uma pausa de 3 s
   	
   	li a0,69		# a0 = 76 (carrega mi para a0)
	li a1,200		# a1 = 100 (nota de duração de 100 ms)
	li a2,32		# a2 = 32 (timbre "guitar harmonic")
	li a3,100		# a3 = 50 (volume da nota)
	li a7,31		# a7 = 31 (carrega em a7 o ecall "MidiOut")
	ecall			# realiza o ecall
	
	li a0,64		# a0 = 76 (carrega mi para a0)
	li a1,200		# a1 = 100 (nota de duração de 100 ms)
	li a2,32		# a2 = 32 (timbre "guitar harmonic")
	li a3,100		# a3 = 50 (volume da nota)
	li a7,31		# a7 = 31 (carrega em a7 o ecall "MidiOut")
	ecall			# realiza o ecall
	
	li a0,61		# a0 = 76 (carrega mi para a0)
	li a1,200		# a1 = 100 (nota de duração de 100 ms)
	li a2,32		# a2 = 32 (timbre "guitar harmonic")
	li a3,100		# a3 = 50 (volume da nota)
	li a7,31		# a7 = 31 (carrega em a7 o ecall "MidiOut")
	ecall			# realiza o ecall
	
	li a0,57		# a0 = 76 (carrega mi para a0)
	li a1,200		# a1 = 100 (nota de duração de 100 ms)
	li a2,32		# a2 = 32 (timbre "guitar harmonic")
	li a3,100		# a3 = 50 (volume da nota)
	li a7,31		# a7 = 31 (carrega em a7 o ecall "MidiOut")
	ecall			# realiza o ecall
	
	li a0,52		# a0 = 76 (carrega mi para a0)
	li a1,200		# a1 = 100 (nota de duração de 100 ms)
	li a2,32		# a2 = 32 (timbre "guitar harmonic")
	li a3,100		# a3 = 50 (volume da nota)
	li a7,31		# a7 = 31 (carrega em a7 o ecall "MidiOut")
	ecall			# realiza o ecall
	
	li a0,45		# a0 = 76 (carrega mi para a0)
	li a1,200		# a1 = 100 (nota de duração de 100 ms)
	li a2,32		# a2 = 32 (timbre "guitar harmonic")
	li a3,100		# a3 = 50 (volume da nota)
	li a7,31		# a7 = 31 (carrega em a7 o ecall "MidiOut")
	ecall			# realiza o ecall
	
	li a0,250
	li a7,32           	# define a chamada de syscall para pausa
   	ecall               	# realiza uma pausa de 3 s
   	
   	li a0,69		# a0 = 76 (carrega mi para a0)
	li a1,1500		# a1 = 100 (nota de duração de 100 ms)
	li a2,32		# a2 = 32 (timbre "guitar harmonic")
	li a3,100		# a3 = 50 (volume da nota)
	li a7,31		# a7 = 31 (carrega em a7 o ecall "MidiOut")
	ecall			# realiza o ecall
	
	li a0,64		# a0 = 76 (carrega mi para a0)
	li a1,1500		# a1 = 100 (nota de duração de 100 ms)
	li a2,32		# a2 = 32 (timbre "guitar harmonic")
	li a3,100		# a3 = 50 (volume da nota)
	li a7,31		# a7 = 31 (carrega em a7 o ecall "MidiOut")
	ecall			# realiza o ecall
	
	li a0,61		# a0 = 76 (carrega mi para a0)
	li a1,1750		# a1 = 100 (nota de duração de 100 ms)
	li a2,32		# a2 = 32 (timbre "guitar harmonic")
	li a3,100		# a3 = 50 (volume da nota)
	li a7,31		# a7 = 31 (carrega em a7 o ecall "MidiOut")
	ecall			# realiza o ecall
	
	li a0,57		# a0 = 76 (carrega mi para a0)
	li a1,2000		# a1 = 100 (nota de duração de 100 ms)
	li a2,32		# a2 = 32 (timbre "guitar harmonic")
	li a3,100		# a3 = 50 (volume da nota)
	li a7,31		# a7 = 31 (carrega em a7 o ecall "MidiOut")
	ecall			# realiza o ecall
	
	li a0,52		# a0 = 76 (carrega mi para a0)
	li a1,2000		# a1 = 100 (nota de duração de 100 ms)
	li a2,32		# a2 = 32 (timbre "guitar harmonic")
	li a3,100		# a3 = 50 (volume da nota)
	li a7,31		# a7 = 31 (carrega em a7 o ecall "MidiOut")
	ecall			# realiza o ecall
	
	li a0,45		# a0 = 76 (carrega mi para a0)
	li a1,3000		# a1 = 100 (nota de duração de 100 ms)
	li a2,32		# a2 = 32 (timbre "guitar harmonic")
	li a3,100		# a3 = 50 (volume da nota)
	li a7,31		# a7 = 31 (carrega em a7 o ecall "MidiOut")
	ecall			# realiza o ecall
	
	li a0,125
	li a7,32           	# define a chamada de syscall para pausa
   	ecall               	# realiza uma pausa de 3 s

LOOPVIC:li t2,0xFF200000	# carrega o endereço de controle do KDMMIO ("teclado")
	lw t0,0(t2)		# le uma word a partir do endereço de controle do KDMMIO
	andi t0,t0,0x0001	# mascara todos os bits de t0 com exceçao do bit menos significativo
   	bne t0,zero,CLSV   	# se o BMS de t0 nÃ£o for 0 (hÃ tecla pressionada), pule para MAPA1
   	j LOOPVIC

CLSV:	li a7, 10
	ecall
	
###########################
##### DADOS DA FASE 1 #####
###########################
	
FASE1:  li s6,1

# Toca a musica de morte

	li a0,100
	li a7,32           	# define a chamada de syscall para pausa
   	ecall               	# realiza uma pausa de 3 s
   	
   	li a0,70		# a0 = 76 (carrega mi para a0)
	li a1,1000		# a1 = 100 (nota de duração de 100 ms)
	li a2,32		# a2 = 32 (timbre "guitar harmonic")
	li a3,100		# a3 = 50 (volume da nota)
	li a7,31		# a7 = 31 (carrega em a7 o ecall "MidiOut")
	ecall			# realiza o ecall
	
	li a0,65		# a0 = 76 (carrega mi para a0)
	li a1,1000		# a1 = 100 (nota de duração de 100 ms)
	li a2,32		# a2 = 32 (timbre "guitar harmonic")
	li a3,100		# a3 = 50 (volume da nota)
	li a7,31		# a7 = 31 (carrega em a7 o ecall "MidiOut")
	ecall			# realiza o ecall
	
	li a0,61		# a0 = 76 (carrega mi para a0)
	li a1,1000		# a1 = 100 (nota de duração de 100 ms)
	li a2,32		# a2 = 32 (timbre "guitar harmonic")
	li a3,100		# a3 = 50 (volume da nota)
	li a7,31		# a7 = 31 (carrega em a7 o ecall "MidiOut")
	ecall			# realiza o ecall
	
	li a0,58		# a0 = 76 (carrega mi para a0)
	li a1,1000		# a1 = 100 (nota de duração de 100 ms)
	li a2,32		# a2 = 32 (timbre "guitar harmonic")
	li a3,100		# a3 = 50 (volume da nota)
	li a7,31		# a7 = 31 (carrega em a7 o ecall "MidiOut")
	ecall			# realiza o ecall
	
	li a0,53		# a0 = 76 (carrega mi para a0)
	li a1,1000		# a1 = 100 (nota de duração de 100 ms)
	li a2,32		# a2 = 32 (timbre "guitar harmonic")
	li a3,100		# a3 = 50 (volume da nota)
	li a7,31		# a7 = 31 (carrega em a7 o ecall "MidiOut")
	ecall			# realiza o ecall
	
	li a0,46		# a0 = 76 (carrega mi para a0)
	li a1,1000		# a1 = 100 (nota de duração de 100 ms)
	li a2,32		# a2 = 32 (timbre "guitar harmonic")
	li a3,100		# a3 = 50 (volume da nota)
	li a7,31		# a7 = 31 (carrega em a7 o ecall "MidiOut")
	ecall			# realiza o ecall
	
	li a0,1000
	li a7,32           	# define a chamada de syscall para pausa
   	ecall               	# realiza uma pausa de 3 s
	
	li a0,70		# a0 = 76 (carrega mi para a0)
	li a1,1000		# a1 = 100 (nota de duração de 100 ms)
	li a2,32		# a2 = 32 (timbre "guitar harmonic")
	li a3,100		# a3 = 50 (volume da nota)
	li a7,31		# a7 = 31 (carrega em a7 o ecall "MidiOut")
	ecall			# realiza o ecall
	
	li a0,66		# a0 = 76 (carrega mi para a0)
	li a1,1000		# a1 = 100 (nota de duração de 100 ms)
	li a2,32		# a2 = 32 (timbre "guitar harmonic")
	li a3,100		# a3 = 50 (volume da nota)
	li a7,31		# a7 = 31 (carrega em a7 o ecall "MidiOut")
	ecall			# realiza o ecall
	
	li a0,63		# a0 = 76 (carrega mi para a0)
	li a1,1000		# a1 = 100 (nota de duração de 100 ms)
	li a2,32		# a2 = 32 (timbre "guitar harmonic")
	li a3,100		# a3 = 50 (volume da nota)
	li a7,31		# a7 = 31 (carrega em a7 o ecall "MidiOut")
	ecall			# realiza o ecall
	
	li a0,58		# a0 = 76 (carrega mi para a0)
	li a1,1000		# a1 = 100 (nota de duração de 100 ms)
	li a2,32		# a2 = 32 (timbre "guitar harmonic")
	li a3,100		# a3 = 50 (volume da nota)
	li a7,31		# a7 = 31 (carrega em a7 o ecall "MidiOut")
	ecall			# realiza o ecall
	
	li a0,51		# a0 = 76 (carrega mi para a0)
	li a1,1000		# a1 = 100 (nota de duração de 100 ms)
	li a2,32		# a2 = 32 (timbre "guitar harmonic")
	li a3,100		# a3 = 50 (volume da nota)
	li a7,31		# a7 = 31 (carrega em a7 o ecall "MidiOut")
	ecall			# realiza o ecall
	
	li a0,750
	li a7,32           	# define a chamada de syscall para pausa
   	ecall               	# realiza uma pausa de 3 s
	
	li a0,35		# a0 = 40 (carrega mi para a0)
	li a1,175		# a1 = 100 (nota de duração de 100 ms)
	li a2,33		# a2 = 33 (timbre "acoustic bass")
	li a3,200		# a3 = 90 (volume da nota)
	li a7,31		# a7 = 31 (carrega em a7 o ecall "MidiOut")
	ecall			# realiza o ecall
	
	li a0,175
	li a7,32           	# define a chamada de syscall para pausa
   	ecall               	# realiza uma pausa de 3 s
	
	li a0,31		# a0 = 40 (carrega mi para a0)
	li a1,175		# a1 = 100 (nota de duração de 100 ms)
	li a2,33		# a2 = 33 (timbre "acoustic bass")
	li a3,200		# a3 = 90 (volume da nota)
	li a7,31		# a7 = 31 (carrega em a7 o ecall "MidiOut")
	ecall			# realiza o ecall
	
	li a0,175
	li a7,32           	# define a chamada de syscall para pausa
   	ecall               	# realiza uma pausa de 3 s
	
	li a0,28		# a0 = 40 (carrega mi para a0)
	li a1,225		# a1 = 100 (nota de duração de 100 ms)
	li a2,33		# a2 = 33 (timbre "acoustic bass")
	li a3,200		# a3 = 90 (volume da nota)
	li a7,31		# a7 = 31 (carrega em a7 o ecall "MidiOut")
	ecall			# realiza o ecall

	li a0,2000
	li a7,32           	# define a chamada de syscall para pausa
   	ecall               	# realiza uma pausa de 3 s
   	
# Carrega a imagem1 (mapa2) no frame 0
	
IMG1_1:	la t4, mapa1		# t4 cerrega endereço do mapa a fim de comparação
	li t5,0xFF000000	# t5 = endereco inicial da Memoria VGA - Frame 0
	li t6,0xFF012C00	# t6 = endereco final da Memoria VGA - Frame 0
	la s0,mapa1		# s0 = endereço dos dados do mapa 1
	mv t3, s0		# t3 = endereço inicial armazenado a fins de comparação
	addi s0,s0,8		# s0 = endereço do primeiro pixel da imagem (depois das informações de nlin ncol)
	
LOOP1_1: 
	beq t5,t6,IMAGEM_1	# se t5 = ultimo endereço da Memoria VGA, saia do loop
	lw t0,0(s0)		# le uma word do endereço s0 (le 4 pixels da imagem)
	sw t0,0(t5)		# escreve a word na memoria VGA no endereço t5 (desenha 4 pixels na tela do Bitmap Display)
	addi t5,t5,4		# soma 4 ao endereço t5 
	addi s0,s0,4		# soma 4 ao endereço s0
	j LOOP1_1		# volta a verificar a condiçao do loop

# Carrega a imagem2 (Robozinho1 - imagem 16x16) no frame 0

IMG2_1:	li t5,0xFF00A0C8	# t5 = endereco inicial da primeira linha do Robozinho - Frame 0
	li t6,0xFF00A0D8	# t6 = endereco final da primeira linha do Robozinho (inicial +16) - Frame 0
	la s0,Robozinho1	# s0 = endereço dos dados do Robozinho1 (boca fechada)
	mv t3, s0		# t3 = endereço inicial armazenado a fins de comparação
	addi s0,s0,8		# s0 = endereço do primeiro pixel da imagem (depois das informações de nlin ncol)
	j PRINT16_1
	
# Carrega a imagem3 (ALIEN1 - imagem16x16)

IMG3_1:	li t5,0xFF0064C8	# t5 = endereco inicial da primeira linha do alien 1 - Frame 0 
	li t6,0xFF0064D8	# t6 = endereco final da primeira linha do alien 1 (inicial +16) - Frame 0      
	la s0,Inimigo1          # s0 = endereço dos dados do alien1
	mv t3, s0		# t3 = endereço inicial armazenado a fins de comparação
	addi s0,s0,8		# s0 = endereço do primeiro pixel da imagem (depois das informações de nlin ncol)
	j PRINT16_1
	
# Carrega a imagem4 (ALIEN2 - imagem16x16)

IMG4_1:	li t5,0xFF0087C8	# t5 = endereco inicial da primeira linha do alien 2 - Frame 0
	li t6,0xFF0087D8	# t6 = endereco final da primeira linha do alien 2 - Frame 0
	la s0,Inimigo2          # s0 = endereço dos dados do alien2
	mv t3, s0		# t3 = endereço inicial armazenado a fins de comparação
	addi s0,s0,8		# s0 = endereço do primeiro pixel da imagem (depois das informações de nlin ncol)
	j PRINT16_1

# Carrega a imagem5 (ALIEN3 - imagem16x16)

IMG5_1:	li t5,0xFF0087B8	# t5 = endereco inicial da primeira linha do alien 3 - Frame 0
	li t6,0xFF0087C8	# t6 = endereco final da primeira linha do alien 3 - Frame 0
	la s0,Inimigo3          # s0 = endereço dos dados do alien3
	mv t3, s0		# t3 = endereço inicial armazenado a fins de comparação
	addi s0,s0,8		# s0 = endereço do primeiro pixel da imagem (depois das informações de nlin ncol)
	j PRINT16_1
	
# Carrega a imagem6 (ALIEN4 - imagem16x16)

IMG6_1:	li t5,0xFF0087D8	# t5 = endereco inicial da primeira linha do alien 4 - Frame 0
	li t6,0xFF0087E8	# t6 = endereco final da primeira linha do alien 4 - Frame 0
	la s0, Inimigo4         # s0 = endereço dos dados do alien4 
	mv t3, s0		# t3 = endereço inicial armazenado a fins de comparação
	addi s0,s0,8		# s0 = endereço do primeiro pixel da imagem (depois das informações de nlin ncol)
	j PRINT16_1
	
# Carrega a imagem7 (mapa1 - colisao) no frame 1
	
IMG7_1:	li t5,0xFF100000	# t5 = endereco inicial da Memoria VGA - Frame 1
	li t6,0xFF112C00	# t6 = endereco final da Memoria VGA - Frame 1
	la s0,mapa1colisao	# s0 = endereço dos dados da colisao do mapa 1
	mv t3, s0		# t3 = endereço inicial armazenado a fins de comparação
	addi s0,s0,8		# s0 = endereço do primeiro pixel da imagem (depois das informações de nlin ncol)
	
LOOPCOL_1:
	beq t5,t6,IMAGEM_1	# se t5 = ultimo endereço da Memoria VGA, saia do loop
	lw t0,0(s0)		# le uma word do endereço s0 (le 4 pixels da imagem)
	sw t0,0(t5)		# escreve a word na memoria VGA no endereço t5 (desenha 4 pixels na tela do Bitmap Display)
	addi t5,t5,4		# soma 4 ao endereço t5 
	addi s0,s0,4		# soma 4 ao endereço s0
	j LOOPCOL_1		# volta a verificar a condiçao do loop
	
# Carrega a imagem6 (Robozinho - imagem16x16)

IMG8_1:	li t5,0xFF10A0C8	# t5 = endereco inicial da primeira linha do alien 4 - Frame 0
	li t6,0xFF10A0D8	# t6 = endereco final da primeira linha do alien 4 - Frame 0
	li s0,0x69696969        # s0 = endereço dos dados do alien4 
	mv t3, s0		# t3 = endereço inicial armazenado a fins de comparação
	j PRINT16_Q_1
	
# Carrega a imagem6 (ALIEN1 - imagem16x16)

IMG9_1:	li t5,0xFF1064C8	# t5 = endereco inicial da primeira linha do alien 4 - Frame 0
	li t6,0xFF1064D8	# t6 = endereco final da primeira linha do alien 4 - Frame 0
	li s0,0x70707070       	# s0 = endereço dos dados do alien4 
	mv t3, s0		# t3 = endereço inicial armazenado a fins de comparação
	j PRINT16_Q_1

# Carrega a imagem6 (ALIEN4 - imagem16x16)

IMG10_1:li t5,0xFF1087C8	# t5 = endereco inicial da primeira linha do alien 4 - Frame 0
	li t6,0xFF1087D8	# t6 = endereco final da primeira linha do alien 4 - Frame 0
	li s0,0x71717171        # s0 = endereço dos dados do alien4 
	mv t3, s0		# t3 = endereço inicial armazenado a fins de comparação
	j PRINT16_Q_1

# Carrega a imagem6 (ALIEN4 - imagem16x16)

IMG11_1:li t5,0xFF1087B8	# t5 = endereco inicial da primeira linha do alien 4 - Frame 0
	li t6,0xFF1087C8	# t6 = endereco final da primeira linha do alien 4 - Frame 0
	li s0,0x72727272        # s0 = endereço dos dados do alien4 
	mv t3, s0		# t3 = endereço inicial armazenado a fins de comparação
	j PRINT16_Q_1

# Carrega a imagem6 (ALIEN4 - imagem16x16)

IMG12_1:li t5,0xFF1087D8	# t5 = endereco inicial da primeira linha do alien 4 - Frame 0
	li t6,0xFF1087E8	# t6 = endereco final da primeira linha do alien 4 - Frame 0
	li s0,0x73737373        # s0 = endereço dos dados do alien4 
	mv t3, s0		# t3 = endereço inicial armazenado a fins de comparação
	j PRINT16_Q_1
	
# Carrega a imagem2 (Robozinho1 - imagem 16x16) no frame 0

IMG13_1:li t5,0xFF011584	# s1 = endereco inicial da primeira linha do Robozinho - Frame 0
	li t6,0xFF011594	# s2 = endereco final da primeira linha do Robozinho (inicial +16) - Frame 0
	la s0,Robozinho1	# s0 = endereço dos dados do Robozinho1 (boca fechada)
	li t3,-1
	addi s0,s0,8		# s0 = endereço do primeiro pixel da imagem (depois das informações de nlin ncol)
	j PRINT16_1
	
# Carrega a imagem2 (Robozinho1 - imagem 16x16) no frame 0

IMG14_1:li t0,3
	li t3,-2
	blt s2,t0,SKP_LIFE1_1

	li t5,0xFF011598	# s1 = endereco inicial da primeira linha do Robozinho - Frame 0
	li t6,0xFF0115A8	# s2 = endereco final da primeira linha do Robozinho (inicial +16) - Frame 0
	la s0,Robozinho1	# s0 = endereço dos dados do Robozinho1 (boca fechada)
	li t3,-2
	addi s0,s0,8		# s0 = endereço do primeiro pixel da imagem (depois das informações de nlin ncol)
	j PRINT16_1

# Carrega a imagem2 (Robozinho1 - imagem 16x16) no frame 0
		
IMG15_1:li t0,4
	li t3,-3
	blt s2,t0,SKP_LIFE2_1
	
	li t5,0xFF0115AC	# s1 = endereco inicial da primeira linha do Robozinho - Frame 0
	li t6,0xFF0115BC	# s2 = endereco final da primeira linha do Robozinho (inicial +16) - Frame 0
	la s0,Robozinho1	# s0 = endereço dos dados do Robozinho1 (boca fechada)
	li t3,-3
	addi s0,s0,8		# s0 = endereço do primeiro pixel da imagem (depois das informações de nlin ncol)
	j PRINT16_1
	
# Compara os endereços para ver qual a proxima imagem a ser printada

IMAGEM_1: 
	beq t3, t4, IMG2_1 	# se t3 contiver o endereço "mapa1", vá para IMG2 (imprime a imagem2)
	
	la t4, Robozinho1	# t4 = endereço dos dados do Robozinho1
	beq t3, t4, IMG3_1	# se t3 contiver o endereço "Robozinho1", vá para IMG3 (imprime a imagem3)
	
	la t4, Inimigo1		# t4 = endereço dos dados do alien 1
	beq t3, t4, IMG4_1	# se t3 contiver o endereço "Inimigo1", vá para IMG4 (imprime a imagem4)
	
	la t4, Inimigo2		# t4 = endereço dos dados do alien 2
	beq t3, t4, IMG5_1	# se t3 contiver o endereço "Inimigo2", vá para IMG5 (imprime a imagem5)
	
	la t4, Inimigo3		# t4 = endereço dos dados do alien 3
	beq t3, t4, IMG6_1	# se t3 contiver o endereço "Inimigo3", vá para IMG6 (imprime a imagem6)
	
	la t4, Inimigo4		# t4 = endereço dos dados do alien 4
	beq t3, t4, IMG7_1	# se t3 contiver o endereço "Inimigo4", vá para IMG7 (imprime a imagem7)
	
	la t4, mapa1colisao
	beq t3, t4, IMG8_1	# se t3 contiver o endereço "Inimigo4", vá para IMG7 (imprime a imagem7)
	
	li t4, 0x69696969
	beq t3, t4, IMG9_1	# se t3 contiver o endereço "Inimigo4", vá para IMG7 (imprime a imagem7)
	
	li t4, 0x70707070
	beq t3, t4, IMG10_1	# se t3 contiver o endereço "Inimigo4", vá para IMG7 (imprime a imagem7)
	
	li t4, 0x71717171
	beq t3, t4, IMG11_1	# se t3 contiver o endereço "Inimigo4", vá para IMG7 (imprime a imagem7)
	
	li t4, 0x72727272
	beq t3, t4, IMG12_1	# se t3 contiver o endereço "Inimigo4", vá para IMG7 (imprime a imagem7)
	
	li t4, 0x73737373
	beq t3, t4, IMG13_1	# se t3 contiver o endereço "Inimigo4", vá para IMG7 (imprime a imagem7)
	
	li t4, -1
	beq t3, t4, IMG14_1	# se t3 contiver o endereço "Inimigo4", vá para IMG7 (imprime a imagem7)
	
SKP_LIFE1_1:	
	li t4, -2
	beq t3, t4, IMG15_1	# se t3 contiver o endereço "Inimigo4", vá para IMG7 (imprime a imagem7)

SKP_LIFE2_1:	
	li t4, -3
	beq t3, t4, SETUP_MAIN_1	# se t3 contiver o endereço "Inimigo4", vá para IMG7 (imprime a imagem7)
	
# Loop que imprime imagens 16x16

PRINT16_1:
	li t1,0
	li t2,16		#inicializa o contador de quebra de linha para 16 quebras de linha
	
LOOP2_1: 	
	beq t5,t6,ENTER_1	# se t5 atingir o fim da linha de pixels, quebre linha
	lw t0,0(s0)		# le uma word do endereço s0 (le 4 pixels da imagem)
	sw t0,0(t5)		# escreve a word na memoria VGA no endereço t5 (desenha 4 pixels na tela do Bitmap Display)
	addi t5,t5,4		# soma 4 ao endereço t5
	addi s0,s0,4		# soma 4 ao endereço s0
	j LOOP2_1 		# volta a verificar a condiçao do loop
	
ENTER_1:	
	addi t5,t5,304		# t5 pula para o pixel inicial da linha de baixo
	addi t6,t6,320		# t6 pula para o pixel final da linha de baixo
	addi t1,t1,1          	# atualiza o contador de quebras de linha
	beq t1,t2,IMAGEM_1	# termina o carregamento da imagem se 16 quebras de linha ocorrerem
	j LOOP2_1

# Loop que imprime imagens 16x16

PRINT16_Q_1:
	li t1,0
	li t2,16		#inicializa o contador de quebra de linha para 16 quebras de linha
	
LOOP2Q_1: beq t5,t6,ENTERQ_1	# se t5 atingir o fim da linha de pixels, quebre linha
	sw s0,0(t5)		# escreve a word na memoria VGA no endereço t5 (desenha 4 pixels na tela do Bitmap Display)
	addi t5,t5,4		# soma 4 ao endereço t5
	j LOOP2Q_1		# volta a verificar a condiçao do loop
	
ENTERQ_1:	addi t5,t5,304		# t5 pula para o pixel inicial da linha de baixo
	addi t6,t6,320		# t6 pula para o pixel final da linha de baixo
	addi t1,t1,1          	# atualiza o contador de quebras de linha
	beq t1,t2,IMAGEM_1	# termina o carregamento da imagem se 16 quebras de linha ocorrerem
	j LOOP2Q_1
	
# Setup dos dados necessarios para o main loop

SETUP_MAIN_1:

	li s0,2			# s0 = 2 (zera o contador de movimentações do Robozinho)
	addi s2,s2,-1			
	li s3,0			# s3 = 0 (zera o estado de movimentação atual do Robozinho)
	li s4,0			# s4 = 0 (zera o verificador de aliens)
	li s5,0			# s5 = 0 (zera o estado de persrguição dos aliens)
	li s6,1			# s6 = 2 (fase 2)
	li s7,17		# s7 = 17 (zera o estado de movimentação atual do inimigo1 : chase_mode)
	li s9,17		# s9 = 17 (zera o estado de movimentação atual do inmimigo2 : chase_mode)
	li s10,17 		# s10 = 17 (zera o estado de movimentação atual do inimigo3 : chase_mode)
	li s11,17 		# s11 = 17 (zera o estado de movimentação atual do inimigo4 : chase_mode)
	
	la t0,CONTADOR_ASSUSTADO
	li t3,-1		
	sw t3,0(t0)
	
	li t1,0xFF00B4C8
	la t0,POS_ROBOZINHO    # carrega o endereço de "POS_ROBOZINHO" no registrador t0 
    	sw t1,0(t0)       	# guarda a word armazenada em t1 (posição atual do Roboziho) em "POS_ROBOZINHO"
    	
    	li t1,0xFF0078C8
	la t0,POS_BLINKY    # carrega o endereço de "POS_ROBOZINHO" no registrador t0 
    	sw t1,0(t0)       	# guarda a word armazenada em t1 (posição atual do Roboziho) em "POS_ROBOZINHO"
    	
    	li t1,0xFF009BC8
	la t0,POS_PINK    # carrega o endereço de "POS_ROBOZINHO" no registrador t0 
    	sw t1,0(t0)       	# guarda a word armazenada em t1 (posição atual do Roboziho) em "POS_ROBOZINHO"
    	
    	li t1,0xFF009BB8
	la t0,POS_INKY    # carrega o endereço de "POS_ROBOZINHO" no registrador t0 
    	sw t1,0(t0)       	# guarda a word armazenada em t1 (posição atual do Roboziho) em "POS_ROBOZINHO"
    	
    	li t1,0xFF009BD8
	la t0,POS_CLYDE    # carrega o endereço de "POS_ROBOZINHO" no registrador t0 
    	sw t1,0(t0)       	# guarda a word armazenada em t1 (posição atual do Roboziho) em "POS_ROBOZINHO"
	
	jal zero, MAINL

###########################
##### DADOS DA FASE 2 #####
###########################

FASE2:  addi s2,s2,1
	li s1,0
	
# Toca a musica de transicao de fase
	
	li a0,100
	li a7,32           	# define a chamada de syscall para pausa
   	ecall               	# realiza uma pausa de 3 s
	
	li a0,62		# a0 = 76 (carrega mi para a0)
	li a1,125		# a1 = 100 (nota de duração de 100 ms)
	li a2,32		# a2 = 32 (timbre "guitar harmonic")
	li a3,100		# a3 = 50 (volume da nota)
	li a7,31		# a7 = 31 (carrega em a7 o ecall "MidiOut")
	ecall			# realiza o ecall
	
	li a0,250
	li a7,32           	# define a chamada de syscall para pausa
   	ecall               	# realiza uma pausa de 3 s
	
	li a0,62		# a0 = 76 (carrega mi para a0)
	li a1,125		# a1 = 100 (nota de duração de 100 ms)
	li a2,32		# a2 = 32 (timbre "guitar harmonic")
	li a3,100		# a3 = 50 (volume da nota)
	li a7,31		# a7 = 31 (carrega em a7 o ecall "MidiOut")
	ecall			# realiza o ecall
	
	li a0,250
	li a7,32           	# define a chamada de syscall para pausa
   	ecall               	# realiza uma pausa de 3 s
	
	li a0,57		# a0 = 76 (carrega mi para a0)
	li a1,125		# a1 = 100 (nota de duração de 100 ms)
	li a2,32		# a2 = 32 (timbre "guitar harmonic")
	li a3,100		# a3 = 50 (volume da nota)
	li a7,31		# a7 = 31 (carrega em a7 o ecall "MidiOut")
	ecall			# realiza o ecall
	
	li a0,125
	li a7,32           	# define a chamada de syscall para pausa
   	ecall               	# realiza uma pausa de 3 s
	
	li a0,59		# a0 = 76 (carrega mi para a0)
	li a1,125		# a1 = 100 (nota de duração de 100 ms)
	li a2,32		# a2 = 32 (timbre "guitar harmonic")
	li a3,100		# a3 = 50 (volume da nota)
	li a7,31		# a7 = 31 (carrega em a7 o ecall "MidiOut")
	ecall			# realiza o ecall
	
	li a0,125
	li a7,32           	# define a chamada de syscall para pausa
   	ecall               	# realiza uma pausa de 3 s
	
	li a0,60		# a0 = 76 (carrega mi para a0)
	li a1,125		# a1 = 100 (nota de duração de 100 ms)
	li a2,32		# a2 = 32 (timbre "guitar harmonic")
	li a3,100		# a3 = 50 (volume da nota)
	li a7,31		# a7 = 31 (carrega em a7 o ecall "MidiOut")
	ecall			# realiza o ecall
	
	li a0,125
	li a7,32           	# define a chamada de syscall para pausa
   	ecall               	# realiza uma pausa de 3 s
	
	li a0,62		# a0 = 76 (carrega mi para a0)
	li a1,125		# a1 = 100 (nota de duração de 100 ms)
	li a2,32		# a2 = 32 (timbre "guitar harmonic")
	li a3,100		# a3 = 50 (volume da nota)
	li a7,31		# a7 = 31 (carrega em a7 o ecall "MidiOut")
	ecall			# realiza o ecall
	
	li a0,3000
	li a7,32           	# define a chamada de syscall para pausa
   	ecall               	# realiza uma pausa de 3 s
	
	j SKPSNG		# pula a musica de morte

RESET_FASE2:
	
# Toca a musica de morte
	
	li a0,100
	li a7,32           	# define a chamada de syscall para pausa
   	ecall               	# realiza uma pausa de 3 s
   	
   	li a0,70		# a0 = 76 (carrega mi para a0)
	li a1,1000		# a1 = 100 (nota de duração de 100 ms)
	li a2,32		# a2 = 32 (timbre "guitar harmonic")
	li a3,100		# a3 = 50 (volume da nota)
	li a7,31		# a7 = 31 (carrega em a7 o ecall "MidiOut")
	ecall			# realiza o ecall
	
	li a0,65		# a0 = 76 (carrega mi para a0)
	li a1,1000		# a1 = 100 (nota de duração de 100 ms)
	li a2,32		# a2 = 32 (timbre "guitar harmonic")
	li a3,100		# a3 = 50 (volume da nota)
	li a7,31		# a7 = 31 (carrega em a7 o ecall "MidiOut")
	ecall			# realiza o ecall
	
	li a0,61		# a0 = 76 (carrega mi para a0)
	li a1,1000		# a1 = 100 (nota de duração de 100 ms)
	li a2,32		# a2 = 32 (timbre "guitar harmonic")
	li a3,100		# a3 = 50 (volume da nota)
	li a7,31		# a7 = 31 (carrega em a7 o ecall "MidiOut")
	ecall			# realiza o ecall
	
	li a0,58		# a0 = 76 (carrega mi para a0)
	li a1,1000		# a1 = 100 (nota de duração de 100 ms)
	li a2,32		# a2 = 32 (timbre "guitar harmonic")
	li a3,100		# a3 = 50 (volume da nota)
	li a7,31		# a7 = 31 (carrega em a7 o ecall "MidiOut")
	ecall			# realiza o ecall
	
	li a0,53		# a0 = 76 (carrega mi para a0)
	li a1,1000		# a1 = 100 (nota de duração de 100 ms)
	li a2,32		# a2 = 32 (timbre "guitar harmonic")
	li a3,100		# a3 = 50 (volume da nota)
	li a7,31		# a7 = 31 (carrega em a7 o ecall "MidiOut")
	ecall			# realiza o ecall
	
	li a0,46		# a0 = 76 (carrega mi para a0)
	li a1,1000		# a1 = 100 (nota de duração de 100 ms)
	li a2,32		# a2 = 32 (timbre "guitar harmonic")
	li a3,100		# a3 = 50 (volume da nota)
	li a7,31		# a7 = 31 (carrega em a7 o ecall "MidiOut")
	ecall			# realiza o ecall
	
	li a0,1000
	li a7,32           	# define a chamada de syscall para pausa
   	ecall               	# realiza uma pausa de 3 s
	
	li a0,70		# a0 = 76 (carrega mi para a0)
	li a1,1000		# a1 = 100 (nota de duração de 100 ms)
	li a2,32		# a2 = 32 (timbre "guitar harmonic")
	li a3,100		# a3 = 50 (volume da nota)
	li a7,31		# a7 = 31 (carrega em a7 o ecall "MidiOut")
	ecall			# realiza o ecall
	
	li a0,66		# a0 = 76 (carrega mi para a0)
	li a1,1000		# a1 = 100 (nota de duração de 100 ms)
	li a2,32		# a2 = 32 (timbre "guitar harmonic")
	li a3,100		# a3 = 50 (volume da nota)
	li a7,31		# a7 = 31 (carrega em a7 o ecall "MidiOut")
	ecall			# realiza o ecall
	
	li a0,63		# a0 = 76 (carrega mi para a0)
	li a1,1000		# a1 = 100 (nota de duração de 100 ms)
	li a2,32		# a2 = 32 (timbre "guitar harmonic")
	li a3,100		# a3 = 50 (volume da nota)
	li a7,31		# a7 = 31 (carrega em a7 o ecall "MidiOut")
	ecall			# realiza o ecall
	
	li a0,58		# a0 = 76 (carrega mi para a0)
	li a1,1000		# a1 = 100 (nota de duração de 100 ms)
	li a2,32		# a2 = 32 (timbre "guitar harmonic")
	li a3,100		# a3 = 50 (volume da nota)
	li a7,31		# a7 = 31 (carrega em a7 o ecall "MidiOut")
	ecall			# realiza o ecall
	
	li a0,51		# a0 = 76 (carrega mi para a0)
	li a1,1000		# a1 = 100 (nota de duração de 100 ms)
	li a2,32		# a2 = 32 (timbre "guitar harmonic")
	li a3,100		# a3 = 50 (volume da nota)
	li a7,31		# a7 = 31 (carrega em a7 o ecall "MidiOut")
	ecall			# realiza o ecall
	
	li a0,750
	li a7,32           	# define a chamada de syscall para pausa
   	ecall               	# realiza uma pausa de 3 s
	
	li a0,35		# a0 = 40 (carrega mi para a0)
	li a1,175		# a1 = 100 (nota de duração de 100 ms)
	li a2,33		# a2 = 33 (timbre "acoustic bass")
	li a3,200		# a3 = 90 (volume da nota)
	li a7,31		# a7 = 31 (carrega em a7 o ecall "MidiOut")
	ecall			# realiza o ecall
	
	li a0,175
	li a7,32           	# define a chamada de syscall para pausa
   	ecall               	# realiza uma pausa de 3 s
	
	li a0,31		# a0 = 40 (carrega mi para a0)
	li a1,175		# a1 = 100 (nota de duração de 100 ms)
	li a2,33		# a2 = 33 (timbre "acoustic bass")
	li a3,200		# a3 = 90 (volume da nota)
	li a7,31		# a7 = 31 (carrega em a7 o ecall "MidiOut")
	ecall			# realiza o ecall
	
	li a0,175
	li a7,32           	# define a chamada de syscall para pausa
   	ecall               	# realiza uma pausa de 3 s
	
	li a0,28		# a0 = 40 (carrega mi para a0)
	li a1,225		# a1 = 100 (nota de duração de 100 ms)
	li a2,33		# a2 = 33 (timbre "acoustic bass")
	li a3,200		# a3 = 90 (volume da nota)
	li a7,31		# a7 = 31 (carrega em a7 o ecall "MidiOut")
	ecall			# realiza o ecall

	li a0,2000
	li a7,32           	# define a chamada de syscall para pausa
   	ecall               	# realiza uma pausa de 3 s

SKPSNG:	
   	
# Carrega a imagem1 (mapa2) no frame 0
	
IMG1_2:	la t4, mapa2		# t4 cerrega endereço do mapa a fim de comparação
	li t5,0xFF000000	# t5 = endereco inicial da Memoria VGA - Frame 0
	li t6,0xFF012C00	# t6 = endereco final da Memoria VGA - Frame 0
	la s0,mapa2		# s0 = endereço dos dados do mapa 1
	mv t3, s0		# t3 = endereço inicial armazenado a fins de comparação
	addi s0,s0,8		# s0 = endereço do primeiro pixel da imagem (depois das informações de nlin ncol)
	
LOOP1_2: 
	beq t5,t6,IMAGEM_2	# se t5 = ultimo endereço da Memoria VGA, saia do loop
	lw t0,0(s0)		# le uma word do endereço s0 (le 4 pixels da imagem)
	sw t0,0(t5)		# escreve a word na memoria VGA no endereço t5 (desenha 4 pixels na tela do Bitmap Display)
	addi t5,t5,4		# soma 4 ao endereço t5 
	addi s0,s0,4		# soma 4 ao endereço s0
	j LOOP1_2		# volta a verificar a condiçao do loop

# Carrega a imagem2 (Robozinho1 - imagem 16x16) no frame 0

IMG2_2:	li t5,0xFF00A0C8	# t5 = endereco inicial da primeira linha do Robozinho - Frame 0
	li t6,0xFF00A0D8	# t6 = endereco final da primeira linha do Robozinho (inicial +16) - Frame 0
	la s0,Robozinho1	# s0 = endereço dos dados do Robozinho1 (boca fechada)
	mv t3, s0		# t3 = endereço inicial armazenado a fins de comparação
	addi s0,s0,8		# s0 = endereço do primeiro pixel da imagem (depois das informações de nlin ncol)
	j PRINT16_2
	
# Carrega a imagem3 (ALIEN1 - imagem16x16)

IMG3_2:	li t5,0xFF0064C8	# t5 = endereco inicial da primeira linha do alien 1 - Frame 0 
	li t6,0xFF0064D8	# t6 = endereco final da primeira linha do alien 1 (inicial +16) - Frame 0      
	la s0,Inimigo1          # s0 = endereço dos dados do alien1
	mv t3, s0		# t3 = endereço inicial armazenado a fins de comparação
	addi s0,s0,8		# s0 = endereço do primeiro pixel da imagem (depois das informações de nlin ncol)
	j PRINT16_2
	
# Carrega a imagem4 (ALIEN2 - imagem16x16)

IMG4_2:	li t5,0xFF0087C8	# t5 = endereco inicial da primeira linha do alien 2 - Frame 0
	li t6,0xFF0087D8	# t6 = endereco final da primeira linha do alien 2 - Frame 0
	la s0,Inimigo2          # s0 = endereço dos dados do alien2
	mv t3, s0		# t3 = endereço inicial armazenado a fins de comparação
	addi s0,s0,8		# s0 = endereço do primeiro pixel da imagem (depois das informações de nlin ncol)
	j PRINT16_2

# Carrega a imagem5 (ALIEN3 - imagem16x16)

IMG5_2:	li t5,0xFF0087B8	# t5 = endereco inicial da primeira linha do alien 3 - Frame 0
	li t6,0xFF0087C8	# t6 = endereco final da primeira linha do alien 3 - Frame 0
	la s0,Inimigo3          # s0 = endereço dos dados do alien3
	mv t3, s0		# t3 = endereço inicial armazenado a fins de comparação
	addi s0,s0,8		# s0 = endereço do primeiro pixel da imagem (depois das informações de nlin ncol)
	j PRINT16_2
	
# Carrega a imagem6 (ALIEN4 - imagem16x16)

IMG6_2:	li t5,0xFF0087D8	# t5 = endereco inicial da primeira linha do alien 4 - Frame 0
	li t6,0xFF0087E8	# t6 = endereco final da primeira linha do alien 4 - Frame 0
	la s0, Inimigo4         # s0 = endereço dos dados do alien4 
	mv t3, s0		# t3 = endereço inicial armazenado a fins de comparação
	addi s0,s0,8		# s0 = endereço do primeiro pixel da imagem (depois das informações de nlin ncol)
	j PRINT16_2
	
# Carrega a imagem7 (mapa1 - colisao) no frame 1
	
IMG7_2:	li t5,0xFF100000	# t5 = endereco inicial da Memoria VGA - Frame 1
	li t6,0xFF112C00	# t6 = endereco final da Memoria VGA - Frame 1
	la s0,mapa2colisao	# s0 = endereço dos dados da colisao do mapa 1
	mv t3, s0		# t3 = endereço inicial armazenado a fins de comparação
	addi s0,s0,8		# s0 = endereço do primeiro pixel da imagem (depois das informações de nlin ncol)
	
LOOPCOL_2:
	beq t5,t6,IMAGEM_2	# se t5 = ultimo endereço da Memoria VGA, saia do loop
	lw t0,0(s0)		# le uma word do endereço s0 (le 4 pixels da imagem)
	sw t0,0(t5)		# escreve a word na memoria VGA no endereço t5 (desenha 4 pixels na tela do Bitmap Display)
	addi t5,t5,4		# soma 4 ao endereço t5 
	addi s0,s0,4		# soma 4 ao endereço s0
	j LOOPCOL_2		# volta a verificar a condiçao do loop
	
# Carrega a imagem6 (Robozinho - imagem16x16)

IMG8_2:	li t5,0xFF10A0C8	# t5 = endereco inicial da primeira linha do alien 4 - Frame 0
	li t6,0xFF10A0D8	# t6 = endereco final da primeira linha do alien 4 - Frame 0
	li s0,0x69696969        # s0 = endereço dos dados do alien4 
	mv t3, s0		# t3 = endereço inicial armazenado a fins de comparação
	j PRINT16_Q_2
	
# Carrega a imagem6 (ALIEN1 - imagem16x16)

IMG9_2:	li t5,0xFF1064C8	# t5 = endereco inicial da primeira linha do alien 4 - Frame 0
	li t6,0xFF1064D8	# t6 = endereco final da primeira linha do alien 4 - Frame 0
	li s0,0x70707070       	# s0 = endereço dos dados do alien4 
	mv t3, s0		# t3 = endereço inicial armazenado a fins de comparação
	j PRINT16_Q_2

# Carrega a imagem6 (ALIEN4 - imagem16x16)

IMG10_2:li t5,0xFF1087C8	# t5 = endereco inicial da primeira linha do alien 4 - Frame 0
	li t6,0xFF1087D8	# t6 = endereco final da primeira linha do alien 4 - Frame 0
	li s0,0x71717171        # s0 = endereço dos dados do alien4 
	mv t3, s0		# t3 = endereço inicial armazenado a fins de comparação
	j PRINT16_Q_2

# Carrega a imagem6 (ALIEN4 - imagem16x16)

IMG11_2:li t5,0xFF1087B8	# t5 = endereco inicial da primeira linha do alien 4 - Frame 0
	li t6,0xFF1087C8	# t6 = endereco final da primeira linha do alien 4 - Frame 0
	li s0,0x72727272        # s0 = endereço dos dados do alien4 
	mv t3, s0		# t3 = endereço inicial armazenado a fins de comparação
	j PRINT16_Q_2

# Carrega a imagem6 (ALIEN4 - imagem16x16)

IMG12_2:li t5,0xFF1087D8	# t5 = endereco inicial da primeira linha do alien 4 - Frame 0
	li t6,0xFF1087E8	# t6 = endereco final da primeira linha do alien 4 - Frame 0
	li s0,0x73737373        # s0 = endereço dos dados do alien4 
	mv t3, s0		# t3 = endereço inicial armazenado a fins de comparação
	j PRINT16_Q_2
	
# Carrega a imagem2 (Robozinho1 - imagem 16x16) no frame 0

IMG13_2:li t5,0xFF011584	# s1 = endereco inicial da primeira linha do Robozinho - Frame 0
	li t6,0xFF011594	# s2 = endereco final da primeira linha do Robozinho (inicial +16) - Frame 0
	la s0,Robozinho1	# s0 = endereço dos dados do Robozinho1 (boca fechada)
	li t3,-1
	addi s0,s0,8		# s0 = endereço do primeiro pixel da imagem (depois das informações de nlin ncol)
	j PRINT16_2
	
# Carrega a imagem2 (Robozinho1 - imagem 16x16) no frame 0

IMG14_2:li t0,3
	li t3,-2
	blt s2,t0,SKP_LIFE1

	li t5,0xFF011598	# s1 = endereco inicial da primeira linha do Robozinho - Frame 0
	li t6,0xFF0115A8	# s2 = endereco final da primeira linha do Robozinho (inicial +16) - Frame 0
	la s0,Robozinho1	# s0 = endereço dos dados do Robozinho1 (boca fechada)
	li t3,-2
	addi s0,s0,8		# s0 = endereço do primeiro pixel da imagem (depois das informações de nlin ncol)
	j PRINT16_2

# Carrega a imagem2 (Robozinho1 - imagem 16x16) no frame 0
		
IMG15_2:li t0,4
	li t3,-3
	blt s2,t0,SKP_LIFE2
	
	li t5,0xFF0115AC	# s1 = endereco inicial da primeira linha do Robozinho - Frame 0
	li t6,0xFF0115BC	# s2 = endereco final da primeira linha do Robozinho (inicial +16) - Frame 0
	la s0,Robozinho1	# s0 = endereço dos dados do Robozinho1 (boca fechada)
	li t3,-3
	addi s0,s0,8		# s0 = endereço do primeiro pixel da imagem (depois das informações de nlin ncol)
	j PRINT16_2
	
# Compara os endereços para ver qual a proxima imagem a ser printada

IMAGEM_2: 
	beq t3, t4, IMG2_2 	# se t3 contiver o endereço "mapa1", vá para IMG2 (imprime a imagem2)
	
	la t4, Robozinho1	# t4 = endereço dos dados do Robozinho1
	beq t3, t4, IMG3_2	# se t3 contiver o endereço "Robozinho1", vá para IMG3 (imprime a imagem3)
	
	la t4, Inimigo1		# t4 = endereço dos dados do alien 1
	beq t3, t4, IMG4_2	# se t3 contiver o endereço "Inimigo1", vá para IMG4 (imprime a imagem4)
	
	la t4, Inimigo2		# t4 = endereço dos dados do alien 2
	beq t3, t4, IMG5_2	# se t3 contiver o endereço "Inimigo2", vá para IMG5 (imprime a imagem5)
	
	la t4, Inimigo3		# t4 = endereço dos dados do alien 3
	beq t3, t4, IMG6_2	# se t3 contiver o endereço "Inimigo3", vá para IMG6 (imprime a imagem6)
	
	la t4, Inimigo4		# t4 = endereço dos dados do alien 4
	beq t3, t4, IMG7_2	# se t3 contiver o endereço "Inimigo4", vá para IMG7 (imprime a imagem7)
	
	la t4, mapa2colisao
	beq t3, t4, IMG8_2	# se t3 contiver o endereço "Inimigo4", vá para IMG7 (imprime a imagem7)
	
	li t4, 0x69696969
	beq t3, t4, IMG9_2	# se t3 contiver o endereço "Inimigo4", vá para IMG7 (imprime a imagem7)
	
	li t4, 0x70707070
	beq t3, t4, IMG10_2	# se t3 contiver o endereço "Inimigo4", vá para IMG7 (imprime a imagem7)
	
	li t4, 0x71717171
	beq t3, t4, IMG11_2	# se t3 contiver o endereço "Inimigo4", vá para IMG7 (imprime a imagem7)
	
	li t4, 0x72727272
	beq t3, t4, IMG12_2	# se t3 contiver o endereço "Inimigo4", vá para IMG7 (imprime a imagem7)
	
	li t4, 0x73737373
	beq t3, t4, IMG13_2	# se t3 contiver o endereço "Inimigo4", vá para IMG7 (imprime a imagem7)
	
	li t4, -1
	beq t3, t4, IMG14_2	# se t3 contiver o endereço "Inimigo4", vá para IMG7 (imprime a imagem7)
	
SKP_LIFE1:	
	li t4, -2
	beq t3, t4, IMG15_2	# se t3 contiver o endereço "Inimigo4", vá para IMG7 (imprime a imagem7)

SKP_LIFE2:	
	li t4, -3
	beq t3, t4, SETUP_MAIN_2	# se t3 contiver o endereço "Inimigo4", vá para IMG7 (imprime a imagem7)
	
# Loop que imprime imagens 16x16

PRINT16_2:
	li t1,0
	li t2,16		#inicializa o contador de quebra de linha para 16 quebras de linha
	
LOOP2_2: 	
	beq t5,t6,ENTER_2	# se t5 atingir o fim da linha de pixels, quebre linha
	lw t0,0(s0)		# le uma word do endereço s0 (le 4 pixels da imagem)
	sw t0,0(t5)		# escreve a word na memoria VGA no endereço t5 (desenha 4 pixels na tela do Bitmap Display)
	addi t5,t5,4		# soma 4 ao endereço t5
	addi s0,s0,4		# soma 4 ao endereço s0
	j LOOP2_2 		# volta a verificar a condiçao do loop
	
ENTER_2:	
	addi t5,t5,304		# t5 pula para o pixel inicial da linha de baixo
	addi t6,t6,320		# t6 pula para o pixel final da linha de baixo
	addi t1,t1,1          	# atualiza o contador de quebras de linha
	beq t1,t2,IMAGEM_2	# termina o carregamento da imagem se 16 quebras de linha ocorrerem
	j LOOP2_2

# Loop que imprime imagens 16x16

PRINT16_Q_2:
	li t1,0
	li t2,16		#inicializa o contador de quebra de linha para 16 quebras de linha
	
LOOP2Q_2: beq t5,t6,ENTERQ_2	# se t5 atingir o fim da linha de pixels, quebre linha
	sw s0,0(t5)		# escreve a word na memoria VGA no endereço t5 (desenha 4 pixels na tela do Bitmap Display)
	addi t5,t5,4		# soma 4 ao endereço t5
	j LOOP2Q_2 		# volta a verificar a condiçao do loop
	
ENTERQ_2:	addi t5,t5,304		# t5 pula para o pixel inicial da linha de baixo
	addi t6,t6,320		# t6 pula para o pixel final da linha de baixo
	addi t1,t1,1          	# atualiza o contador de quebras de linha
	beq t1,t2,IMAGEM_2	# termina o carregamento da imagem se 16 quebras de linha ocorrerem
	j LOOP2Q_2
	
# Setup dos dados necessarios para o main loop

SETUP_MAIN_2:

	li s0,2			# s0 = 2 (zera o contador de movimentações do Robozinho)
#	li s1,0			# s1 = 0 (zera o contador de pontos coletados)
	addi s2,s2,-1			# s2 = 3 (inicializa o contador de vidas do Robozinho com 3)
	li s3,0			# s3 = 0 (zera o estado de movimentação atual do Robozinho)
	li s4,0			# s4 = 0 (zera o verificador de aliens)
	li s5,0			# s5 = 0 (zera o estado de persrguição dos aliens)
	li s6,2			# s6 = 2 (fase 2)
	li s7,17		# s7 = 17 (zera o estado de movimentação atual do inimigo1 : chase_mode)
	li s9,17		# s9 = 17 (zera o estado de movimentação atual do inmimigo2 : chase_mode)
	li s10,17 		# s10 = 17 (zera o estado de movimentação atual do inimigo3 : chase_mode)
	li s11,17 		# s11 = 17 (zera o estado de movimentação atual do inimigo4 : chase_mode)
	
	la t0,CONTADOR_ASSUSTADO
	li t3,-1		
	sw t3,0(t0)
	
	li t1,0xFF00B4C8
	la t0,POS_ROBOZINHO    # carrega o endereço de "POS_ROBOZINHO" no registrador t0 
    	sw t1,0(t0)       	# guarda a word armazenada em t1 (posição atual do Roboziho) em "POS_ROBOZINHO"
    	
    	li t1,0xFF0078C8
	la t0,POS_BLINKY    # carrega o endereço de "POS_ROBOZINHO" no registrador t0 
    	sw t1,0(t0)       	# guarda a word armazenada em t1 (posição atual do Roboziho) em "POS_ROBOZINHO"
    	
    	li t1,0xFF009BC8
	la t0,POS_PINK    # carrega o endereço de "POS_ROBOZINHO" no registrador t0 
    	sw t1,0(t0)       	# guarda a word armazenada em t1 (posição atual do Roboziho) em "POS_ROBOZINHO"
    	
    	li t1,0xFF009BB8
	la t0,POS_INKY    # carrega o endereço de "POS_ROBOZINHO" no registrador t0 
    	sw t1,0(t0)       	# guarda a word armazenada em t1 (posição atual do Roboziho) em "POS_ROBOZINHO"
    	
    	li t1,0xFF009BD8
	la t0,POS_CLYDE    # carrega o endereço de "POS_ROBOZINHO" no registrador t0 
    	sw t1,0(t0)       	# guarda a word armazenada em t1 (posição atual do Roboziho) em "POS_ROBOZINHO"
	
	jal zero, MAINL
	
.data 

.include "../System/SYSTEMv24.s"	# permite a utilização dos ecalls "1xx"
