.eqv	SYS_EX0, 10
.eqv	SYS_PRT, 4	# print
.eqv	SYS_FOP, 1024	# open file
.eqv	SYS_FCLOSE, 57	# close file
.eqv	SYS_FRD, 63	# read file
.eqv	RDFLAG, 0	# flag for opening file in read-only mode
.eqv	BUFLEN, 2	# at least 2 - to also retain "\0"


.data
b_ins:	.asciz " # ERROR! Instruction mnemonic not recognized\n"
b_sntx:	.asciz " # ERROR! Wrong line syntax\n"
n_args:	.asciz " # ERROR! No arguments provided for instruction\n"
buf:	.space BUFLEN
fname:	.asciz "code.asm"

.text

init:
	li	s2, ' '
	li	s3, '\t'
	li	s4, '\n'
	li	s8, 'i'
	li	s9, 'x'
	# minimum number for 4 arguments
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

start_read_inst:
	mv	s0, zero # instruction input data
	mv	s1, zero # argument 1 input data
	mv	s6, zero # argument 2 input data
	mv	s7, zero # argument 3 input data
read_inst:
	lb	t1, (a1)
	bnez	t1, bufok
	
	# refill buffer if empty
	call    refill_buffer
bufok:
	addi	a1, a1, 1
	# check if whitespace character
	beq	t1, s2, whitespaceChar	# ' '
	beq	t1, s3, whitespaceChar	# '\t'
	
	# newline
	beq	t1, s4, newlineChar	# TODO: here we assume only LF, there maybe arror with CRLF ending
	
	# if instruction > bin(100000 00000000 00000000), 4 instructions already packed
	# so either instruction is wrong or sltiu edge case
	bgt	s0, s5, chk_sltiu
	
	# also add converting to lowercase and removing weird characters (e.g. CR, etc)
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
	beqz	s0, read_inst # if instruction empty - skip char
	
	# otherwise instruciton ready for interpretation

interpret_instruction:
	li	a6, 51		# encoded instruction - initialized to bin(0110011)
	mv	t2, zero 	# for last character - 'i' check
	
	mv	t5, zero	# for func3 code
	# check if last letter is 'i'
	andi	t2, s0, 127 	# bin(7x'1') - get last char in t2
	bne	t2, s8, no_imm	
	
	addi	a6, a6, -32	# remove bin(100000) - indicate immediate operation 
	srli	s0, s0, 7 	# shift by 7 - get word without 'i'
	
no_imm:
	# add
	li	t3, 1602148
	li	t5, 0
	beq	s0, t3, no_imm_end
	
	# sll		
	li	t5, 1
	li	t3, 1898092
	beq	s0, t3, no_imm_end
	
	# slt
	li	t3, 1898100
	li	t5, 2
	beq	s0, t3, no_imm_end
	
	# sltu
	li	t3, 242956917
	li	t5, 3
	beq	s0, t3, no_imm_end
	
	# xor
	li	t3, 1980402
	li	t5, 4
	beq	s0, t3, no_imm_end
	
	# srl
	li	t3, 1898860
	li	t5, 5
	beq	s0, t3, no_imm_end
	
	# or
	li	t3, 14322
	li	t5, 6
	beq	s0, t3, no_imm_end
	
	# and
	li	t3, 1603428
	li	t5, 7
	beq	s0, t3, no_imm_end
	
	# only left possibilities sub, sra/srai
	# they all have 0100000 in funct7
	li 	t4, 1073741824	# 1 followed by 30 zeros
	add	a6, a6, t4	
	
	# sra
	li	t3, 1898849
	li	t5, 5
	beq	s0, t3, no_imm_end
	
	# sub
	beq	t2, s8, bad_instr # additional check - no 'subi' instruction
	li	t3, 1899234
	mv	t5, zero
	beq	s0, t3, no_imm_end
	
	j 	bad_instr


no_imm_end:
	# add func3
	slli	t5, t5, 12
	add	a6, a6, t5
	

###########################
# todo: rewrite (and finish) this as a function;
# fun will be called 2-3 times and accept separators of ',' and '\n' while saving last letter 
# after function call, comparison whether newline occured after e.g. only 2 args
###########################
f_x_before_1st_arg:
	lb	t1, (a1)
	bnez	t1, bufok1
	
	call	refill_buffer
	
bufok1:
	# check for 'x' in current position. if space/tab - skip. if newline -  go to no_args
	beq	t1, s9, rd_1st_arg
	
	beq	t1, s2, f_x_before_1st_arg	# ' '
	beq	t1, s3, f_x_before_1st_arg	# '\t'
	
	# newline - end of instruction - wrong instruction
	beq	t1, s4, no_args 	# TODO: here we assume only LF, there maybe arror with CRLF ending


rd_1st_arg:
	
	
	
	
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
	
	
refill_buffer:		# assumption: s11 contains file descriptor
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
       	lb	t1, (a1)
        ret

#===========================================================
# wrong instruciton - print info and go to newline or end
bad_instr:
	la 	a0, b_ins
	li	a7, SYS_PRT
	ecall
	j	start_read_inst
f_nline:
	# todo: what if crlf is used?


no_args:
	la 	a0, n_args
	li	a7, SYS_PRT
	ecall
	j	start_read_inst