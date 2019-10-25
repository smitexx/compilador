##################
# Seccion de datos
	.data

_x:
	.word 0
_y:
	.word 0


###################
# Seccion de codigo
	.text
	.globl main
main:
	li $t0, 0
	sw $t0, _x
	li $t0, 9
	sw $t0, _y
et0
	lw $t0, _x
	li $t1, 1
	add $t2, $t0, $t1
	sw $t2, _x
	lw $t0, _y
	bneqz $t0, et0
##############
# Fin
	jr $ra
