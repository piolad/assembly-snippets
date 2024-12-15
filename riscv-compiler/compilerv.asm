#########################################################################
# 			RISC-V compiler					#
#	compiles logic and arithmetic intructions in R and I format	#
#   assumes 'code.asm' to be present - prints code to standard output	#
#########################################################################


#########################################################################
# constants								#
#########################################################################

# ========== syscalls ==========
.eqv	SYS_EX0, 10
.eqv	SYS_PRT, 4	# print
.eqv	SYS_FOP, 1024	# open file
.eqv	SYS_FCLOSE, 57	# close file
.eqv	SYS_FRD, 63	# read file
.eqv	RDFLAG, 0	# flag for opening file in read-only mode

.eqv	BUFLEN, 2	# at least 2 - to also accomodate for "\0"

.data
# ========== error messages ==========
b_ins:	.asciz " # ERROR! Instruction mnemonic not recognized\n"
b_sntx:	.asciz " # ERROR! Wrong line syntax\n"
n_args:	.asciz " # ERROR! No arguments provided for instruction\n"

buf:	.space BUFLEN
fname:	.asciz "code.asm"

.text
#########################################################################
# one time initializations						#
#########################################################################
init:	
	# constants used a lot - saved to registers for efficiency
	li	s2, ' '
	li	s3, '\t'
	li	s4, '\n'
	li	s8, 'i'
	li	s9, 'x'
	
	# minimum number for 4 packed arguments
	li	s5, 2097152 	# 1 followed by 7*3=21 zeros
	

openfile:
	li	a7, SYS_FOP
	la	a0, fname
	li	a1, RDFLAG
	mv	a2, zero
	ecall
	mv 	s11, a0		# save the file descriptor
	call	refill_buffer	# prefill the buffer


start_read_inst:	# pack instructions
	mv	s0, zero	# instruction input data / 1st input data
	mv	s1, zero	# for immeidate indication
read_inst:
	lb	s7, (a1)
	bnez	s7, bufok
	
	# refill buffer if empty
	call    refill_buffer
bufok:
	addi	a1, a1, 1
	# check if whitespace character
	beq	s7, s2, whitespaceChar	# ' '
	beq	s7, s3, whitespaceChar	# '\t'
	
	# newline
	beq	s7, s4, newlineChar	# TODO: here we assume only LF, there maybe arror with CRLF ending
	
	# if instruction > bin(100000 00000000 00000000), 4 instructions already packed
	# so either instruction is wrong or sltiu edge case
	bgt	s0, s5, chk_sltiu
	
	# also add converting to lowercase and removing weird characters (e.g. CR, etc)
	# pack up to 4 bytes into 1 32bit register
	slli	s0, s0, 7
	add	s0, s0, s7
	
	j	read_inst

newlineChar:
	# if instruction is emty - skip char
	# otherwise error - instruction without arguments
	beqz	s0, read_inst
	# write error and jump
	#todo

whitespaceChar:
	beqz	s0, read_inst 	# if instruction empty - skip char
	
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
	li	s1, 1
	
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
	


	mv	s0, zero	# reset s0 for first argument
	
#================== 1st argument ================== 
f_x_before_1st_arg:
	lb	s7, (a1)
	bnez	s7, bufok1
	call	refill_buffer
	
bufok1:
	addi	a1, a1, 1
	# if space/tab - skip. if newline -  go to no_args. if anything else - syntax error
	
	beq	s7, s2, f_x_before_1st_arg	# ' '
	beq	s7, s3, f_x_before_1st_arg	# '\t'
	
	# newline - end of instruction - wrong instruction
	beq	s7, s4, no_args 	# TODO: here we assume only LF, there maybe arror with CRLF ending
	
	bne	s7, s9, syntax_e	# not whitespace, can only be 'x' or syntax error
		
	call	rd_int12b
	
	# check if returned value is <32
	li	t1, 32
	bgtu	a0, t1, syntax_e
	slli	a0, a0, 7
	add	a6, a6, a0	# encode destination register
	
	li	t1, ','
	beq	s7, t1, arg1comma_found	# maybe char that ended the num was a comma - then ok


f_comma_arg1:	
	lb	s7, (a1)
	bnez	s7, bufok_a1

	call	refill_buffer
	li	t1, ','		# t1 may get invalidated by jalr
bufok_a1:
	addi	a1, a1, 1
	# TODO: optimize branches, add newline recognition and removal
	beq	s7, t1, arg1comma_found
	
	beq	s7, s2, f_comma_arg1	# ' '
	beq	s7, s3, f_comma_arg1	# '\t'

	j	syntax_e

arg1comma_found:
#================== 2nd argument ================== 
f_x_before_2nd_arg:
	lb	s7, (a1)
	bnez	s7, bufok2
	call	refill_buffer
	
bufok2:
	addi	a1, a1, 1
	# if space/tab - skip. if newline -  go to no_args. if anything else - syntax error
	
	beq	s7, s2, f_x_before_2nd_arg	# ' '
	beq	s7, s3, f_x_before_2nd_arg	# '\t'
	
	# newline - end of instruction - wrong instruction
	beq	s7, s4, syntax_e 	# TODO: here we assume only LF, there maybe arror with CRLF ending
	
	bne	s7, s9, syntax_e	# not whitespace, can only be 'x' or syntax error
		
	call	rd_int12b
	
	# check if returned value is <32
	li	t1, 32
	bgtu	a0, t1, syntax_e
	slli	a0, a0, 15
	add	a6, a6, a0	# encode destination register
	
	li	t1, ','
	beq	s7, t1, arg2comma_found	# maybe char that ended the num was a comma - then ok

f_comma_arg2:	
	lb	s7, (a1)
	bnez	s7, bufok_a1

	call	refill_buffer
	li	t1, ','		# t1 may get invalidated by jalr
bufok_a2:
	addi	a1, a1, 1
	# TODO: optimize branches
	beq	s7, t1, arg2comma_found

	beq	s7, s2, f_comma_arg2	# ' '
	beq	s7, s3, f_comma_arg2	# '\t'

	j	syntax_e

arg2comma_found:

#================== 3rd argument ================== 
#	either immediate or register
	bnez	s1, arg3_immediate

f_x_before_3rd_arg:
	lb	s7, (a1)
	bnez	s7, bufok3
	call	refill_buffer
	
bufok3:
	addi	a1, a1, 1
	# if space/tab - skip. if newline -  go to no_args. if anything else - syntax error
	
	beq	s7, s2, f_x_before_3rd_arg	# ' '
	beq	s7, s3, f_x_before_3rd_arg	# '\t'
	
	# newline - end of instruction - wrong instruction
	beq	s7, s4, syntax_e 	# TODO: here we assume only LF, there maybe arror with CRLF ending
	
	bne	s7, s9, syntax_e	# not whitespace, can only be 'x' or syntax error
		
	call	rd_int12b
	
	# check if returned value is <32
	li	t1, 32
	bgtu	a0, t1, syntax_e
	slli	a0, a0, 20
	add	a6, a6, a0	# encode destination register

# todo: here check unntil '\n'. if  '\t' or ' ' - skip. If '#' - go to new line. Otherwise - syntax error


arg3_immediate:

# here another wi


#===============================================================#
# 			Utility functions:			#
#===============================================================#

# function: rd_int12b
# Get first num, upto 12 bits long
# returns:
# 	a0 - signed 12bit number
rd_int12b:
	mv	a3, zero	# converted number
	mv	a4, zero	# sign_info: 0 - undefined. 2048 - negative, 2047 - positive. At the same indicates largest possible number in terms of abosolute value
	
	li	t3, 10
	li	t4, '-'
	li	t5, '0'
	li	t6, '9'
	
loop_rdint:
	lb	s7, (a1)
	bnez	s7, bufok_rdint
	

	mv	s10, ra		# non-leaf procedure - save the return address
	call	refill_buffer
	mv	ra, s10
	
	# fix constatnt temporary registers after call
	li	t3, 10
	li	t4, '-'
	li	t5, '0'
	li	t6, '9'
	
bufok_rdint:
	addi	a1, a1, 1
	beqz	a4, check_minus	# minus unset - allow to set it
	
	# check for minus in the middle of numer e.g. 102-23, --12, 1234-
	beq	s7, t4, syntax_e
	
convert_num:
	bgt	s7, t6, end_rdint
	blt	s7, t5, end_rdint
	
	mul	a3, a3, t3 	# multiply by 10
	add	a3, a3, s7
	sub	a3, a3, t5
	
	# range check:
	bgtu	a3, a4, syntax_e
	
	j	loop_rdint
	
check_minus:
	li	a4, 2047
	bne	s7, t4, convert_num	# positive number -> continue with normal loop

	li	a4, 2048	# number is negative
	j 	loop_rdint	# skip minus - go to loop beginnig
	
end_rdint:
	mv	a0, a3
	addi	a4, a4, -2047
	
	beqz	a4, ret_rdint
	sub	a0, zero, a0
ret_rdint:
	ret

#==================================================================	
	
	
chk_sltiu:

	# (edge case of instruction interpretation)
	# check if s7 is equal to 'u'
	# and if current content of s0 is stli
	# otherwise - write error and go to next line
#	bne	s0, __, label
#	bne	s7, __, label
#	addi	s0, s0, 
#	j	write-error and sth


# function: exit
# Close file and return 0.
# 	Assumption: s11 contains File Descriptor
exit:
	li	a7, SYS_FCLOSE
	mv	a0, s11		# file descriptor to close
	ecall             	# close file
	
	li	a7, SYS_EX0
	ecall
#==================================================================	


# function: refill_buffer
# refill the buffer containing the file contents
# assumption: s11 contains file descriptor
refill_buffer:
        # read data syscall
        mv	a0, s11
        li      a7, SYS_FRD
        la      a1, buf        # buffer address
        li      a2, BUFLEN
        addi    a2, a2, -1     # reserve space for trailing '\0'
        ecall

        # If no data read, return -1
        blez    a0, exit	# this will validatae ra but we do not care - this is only for exiting

        # Add '\0' after the last byte
        la      t0, buf        # t0 = address of buf
        add     t0, t0, a0     # t0 = buf + (number_of_bytes_read)
        sb      zero, 0(t0)    # *(buf + a0) = '\0'
       	lb	s7, (a1)
        ret
#===========================================================

skip_to_nline:
	
# todo: implement this

#===========================================================
# wrong instruciton - print info and go to newline or end
bad_instr:
	la 	a0, b_ins
	li	a7, SYS_PRT
	ecall
	call	skip_to_nline
	j	start_read_inst
f_nline:
	# todo: what if crlf is used?


no_args:
	la 	a0, n_args
	li	a7, SYS_PRT
	ecall
	call	skip_to_nline
	j	start_read_inst

syntax_e:
	la 	a0, b_sntx
	li	a7, SYS_PRT
	ecall
	call	skip_to_nline
	j	start_read_inst	
