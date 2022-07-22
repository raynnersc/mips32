#C�digo de teste do microcontrolador mips32 desenvolvido em LAOC
#Sequ�ncia de Fibonacci
#Mapa de mem�ria da arquitetura � diferente do mips original, ent�o se atentar para as instru��es J e JAL, que provavelmente gerar�o endere�os incorretos

#Configurando GPIOs
#Armazena no endereço 1 (GPIO - DIR_B) todos os bits em zero, configurando como saída(LEDs)
sw $0, 1($0)
#Configura DIR_A do GPIO para ser tudo entrada
addi $t1, $0, 255
sw $t1, 0($0)  


#O valor atual da sequ�ncia ser� armazenado em $s0
#O valor passado ser� armazenado em $s1
#Iniciar $s0 com 0 e $t0 com 1:

add $s0, $0, $0
addi $s1, $0, 1
add $s2, $0, $0

#Chamando fun��o de delay com 50 milh�o de ciclos de clock (clock de 50MHz -> 1 seg de delay)
#add $a0, $0, 50000
#add $a1, $0, 1
#jal delay

loop_fibonacci:

sw $s0, 5($0)		#Manda o valor para a saida do GPIO_B
add $s0, $s1, $s2	#Armazena o valor atual no registrador de valor passado para o proximo ciclo
add $s2, $s1, $0	#Move o penultimo para o antepenultimo
add $s1, $s0, $0	#Move o ultimo para o penultimo

#Chamando fun��o de delay com 50 milh�o de ciclos de clock (clock de 50MHz -> 1 seg de delay)
#add $a0, $0, 50000
#add $a1, $0, 1
#jal delay

addi $t0, $s0, -2000
bgtz $t0, end_fibonacci
j loop_fibonacci

end_fibonacci:	#Loop com nop pra encerrar
add $0, $0, $0
j end_fibonacci

#Delay por incremento de contador. Itera sobre $t0 de 0 at� o valor desejado especificado em $a0, com um fator 
#multiplicativo especificado em $a1. Existe um erro devido � ciclos de clock extras para fazer o setup dos registradores e 
#para administrar o loop externo
#delay:
#add $t0, $0, $0			#Conta o loop interno
#add $t1, $0, $0			#Conta o loop externo
#add $t2, $a0, $0		#Pega o target interno (divide por 3, porque tem 3 instru��es)
#addi $t4, $0, 3			#Carrega o divisor do target
#div $t2, $t4			#Divide target por 3, porque tem 3 instru��es no loop
#mflo $t2			#Pega o resultado do target e joga em $t2
#j loop_interno

#loop_externo:
#add $t0, $0, $0			#Zera contador interno
#addi $t1, $t1, 1		#Incrementa contador externo
#beq $t1, $a1, finish		#Se o loop externo chegou ao target, terminar, senao, segue para o loop interno

#loop_interno:
#addi $t0, $t0, 1		#Incrementa contador interno
#beq $t0, $t2, loop_externo	#Se o loop interno chegou ao target, ir para loop externo
#j loop_interno			#Senao, continua loop

#finish:
#jr $ra
