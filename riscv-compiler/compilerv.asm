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
	
	mv	s0, zero # instruction input data
	mv	s1, zero # arguments input data
	
	li	s2, ' '
	li	s3, '\t'
	li	s4, '\n'
	li	s5, 2097152 	# 1 followed by 7*3=21 zeros
	
#=================

openfile:
	li	a7, SYS_FOP	# system call for open file
	la	a0, fname	#  file name
	li	a1, RDFLAG
	li	a2, 0
	ecall			# open a file
	mv 	s11, a0		# save the file descriptor
	
	
	
	call	refill_buffer

read_inst:
	lb	t1, (a1)
	addi	a1, a1, 1
	bnez	t1, bufok
	
	# refill buffer if empty
	call    refill_buffer
bufok:
		
	# check if whitespace character
	beq	t1, s2, whitespaceChar	# ' '
	beq	t1, s3, whitespaceChar	# '\t'
	
	# newline
	beq	t1, s4, newlineChar	# TODO: here we assume only LF, there maybe arror with CRLF ending
	
	# if instruction > bin(100000 00000000 00000000), 4 instructions already packed
	# so either instruction is wrong or sltiu edge case
	bgt	s0, s5, chk_sltiu
	
	
	# pack up to 4 bytes into 1 32bit register
	slli	s0, s0, 7
	add	s0, s0, t1
	
	j	read_inst

newlineChar:
	# if instruction is emty - skip char
	# otherwise error - instruction without arguments
	beqz	s0, read_inst
	# write error and jump
	#todo

whitespaceChar:
	# if instruction empty - skip char
	beqz	s0, read_inst
	
	# otherwise instruciton ready for interpretation

interpret_instruction:
	lb	t1, (a1)
	bnez	t1, bufok1
	
	call	refill_buffer
bufok1:
	# check for 'x' in current position. if space/tab - skip. if newline -  go to inst_ready

	# if arguments empty - set sth there and start interpreting instruciton
	# if aruments non-empty - read strings until 3 aruguments are read
	# if \n is read first - error and clear

	# we alsready have ' ' assured after instruction so we need to read arguments
	
	# add:
	# ...
	
	
	# last char - 'i'
	# ...

chk_sltiu:
	# (edge case of instruction interpretation)
	# check if t1 is equal to 'u'
	# and if current content of s0 is stli
	# otherwise - write error and go to next line
#	bne	s0, __, label
#	bne	t1, __, label
#	addi	s0, s0, 
#	j	write-error and sth

exit:
	li	a7, SYS_FCLOSE
	mv	a0, s11		# file descriptor to close
	ecall             	# close file
	
	li	a7, SYS_EX0
	ecall
	
	
refill_buffer:
	# assumption: s11 contains file descriptor

        # read data syscall
        mv	a0, s11
        li      a7, SYS_FRD
        la      a1, buf        # buffer address
        li      a2, BUFLEN
        addi    a2, a2, -1     # reserve space for trailing '\0'
        ecall

        # If no data read, return -1
        blez    a0, exit

        # Add '\0' after the last byte
        la      t0, buf        # t0 = address of buf
        add     t0, t0, a0     # t0 = buf + (number_of_bytes_read)
        sb      zero, 0(t0)    # *(buf + a0) = '\0'
        ret

#===========================================================
