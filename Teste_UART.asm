# C�digo de teste do perif�rico UART do Microcontrolador desenvolvido na mat�ria de LAOC
#
#
# Mapa de mem�ria diferente do mapa do MIPS32

.text

#Habilita a interrup��o do RX da UART (TX e RX ser�o interconectados externamente)
addi	$t1, $zero, 1
mtc0	$t1, $9

#Informa o endere�o da rotina de tratamento de interrup��o
la	$t1, interrupt
mtc0	$t1, $0

#Configura o registrador reg_clock_pbit (clock/baud rate) --> baud rate = 250
addi	$t1, $zero, 4
sw	$t1, 10($zero)

#Envia o dado + bit de UART on
addi	$t2, $zero, 0x100  # (bit on = 1) + (dado = 0)
sw	$t2, 12($zero)

#Loop infinito
idle:
add	$zero, $zero, $zero
j	idle

#Rotina de interrup��o
interrupt:

#Limpa as flags de interrup��o da UART
addi	$t1, $zero, 1
sw	$t1, 14($zero)
sw	$t1, 15($zero)

#Coloca o valor recebido pela UART no GPIO PORT_B
lw	$t1, 11($zero) 
sw	$t1, 5($zero)

#Envia Dado = Dado + 1
addi	$t2, $t2, 1    
sw	$t2, 12($zero)

ack:
add	$zero, $zero, $zero




