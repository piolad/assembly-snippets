.eqv	SYS_EX0, 10
.eqv	SYS_PRT, 4	# print
.eqv	SYS_FOP, 1024	# open file
.eqv	SYS_FCLOSE, 57	# close file
.eqv	SYS_FRD, 63	# read file
.eqv	RDFLAG, 0	# flag for opening file in read-only mode
.eqv	BUFLEN, 2	# at least 2 - to also retain "\0"


.data
ermsg:	.asciz " # ERROR\n"
buf:	.space BUFLEN
fname:	.asciz "code.asm"

.text

init:
# assure \0 at last character of buf 
	la	a0, buf
	addi	a0,a0, -1
	li	a1, '\0'
	sb	a1, BUFLEN(a0)
#=================

openfile:
	li	a7, SYS_FOP	# system call for open file
	la	a0, fname	#  file name
	li	a1, RDFLAG
	li	a2, 0
	ecall			# open a file (file descriptor returned in a0)
	mv 	s11, a0		# save the file descriptor
	
bufempty:
	# read from file
	mv 	a0, s11 		# load the file descriptor
	li 	a7, SYS_FRD
	la	a1, buf
	li	a2, BUFLEN
	addi	a2, a2, -1	# to make space for ending \0
	ecall

	blez	a0, exit




	
	# print to STDOUT
	li	a7, SYS_PRT
	la	a0, buf
	ecall
	
	j	bufempty



exit:
	li	a7, SYS_FCLOSE
	mv	a0, s11		# file descriptor to close
	ecall             	# close file
	
	li	a7, SYS_EX0
	ecall
	
	
	
