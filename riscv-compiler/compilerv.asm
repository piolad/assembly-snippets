#########################################################################
# 			RISC-V compiler					#
#	compiles logic and arithmetic intructions in R and I format	#
#   assumes 'code.asm' to be present - prints code to standard output	#
#########################################################################
# author - Piotr Łądkowski



#########################################################################
# constants and preinit data						#
#########################################################################
.eqv	SYS_EX0, 10
.eqv	SYS_PRT, 4	# print
.eqv	SYS_HEXPRT, 34	# print int in hex
.eqv	SYS_FOP, 1024	# open file
.eqv	SYS_FCLOSE, 57	# close file
.eqv	SYS_FRD, 63	# read files
.eqv	RDFLAG, 0	# flag for opening file in read-only mode

.eqv	BUFLEN, 2	# at least 2 - to also accomodate for "\0"

.data
buf:	.space BUFLEN
fname:	.asciz "code.asm"

# ========== error messages ==========
b_ins:	.asciz " # ERROR! Instruction mnemonic not recognized\n"
b_sntx:	.asciz " # ERROR! Wrong line syntax\n"
n_args:	.asciz " # ERROR! No arguments provided for instruction\n"



#########################################################################
# .text section								#
#########################################################################
.text

# ========================== one time settings ==========================
init:	
	# constants used a lot - saved to registers for efficiency
	li	s2, ' '
	li	s3, '\t'
	li	s4, '\n'
	li	s8, 'i'
	
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


# ======================== pack instruction to s0 ========================
# all instruction mnemonics (except 1 - stliu) are 4 characters long 
# - so they can be packed onto a register.
# ========================================================================
start_read_inst:	# reset data - before loop
	mv	s0, zero	# instruction input data / 1st input data
	mv	s1, zero	# for immeidate indication - used later
	li	a5, 3
	
read_inst:		# loop for packing the mnemonic
	lb	s7, (a1)
	bnez	s7, bufok	# if char is not 0 - continue 
	call    refill_buffer	# if 0 - end of buffer is reached
bufok:
	addi	a1, a1, 1	# advance buf address
	
	# whitespace handling - skip if before mnemonic or interpret mnemonic
	beq	s7, s2, whitespaceChar	# ' '
	beq	s7, s3, whitespaceChar	# '\t'
	
	# newline - skip if before mnemonic - otherwise no arguments - error
	beq	s7, s4, newlineChar
	
	# if instruction > bin(100000 00000000 00000000), 4 instructions
	# already packed so either instruction is wrong or sltiu edge case
	bgt	s0, s5, chk_sltiu
	
	# to lowercase conversion:
	li	t0, 'A'
	blt	s0, t0, skip_lowercase
	li	t0, 'Z'
	bgt	s0, t0, skip_lowercase
	addi	s0, s0, 32

skip_lowercase:	
	# pack up to 4 bytes into 1 32bit register
	slli	s0, s0, 7
	add	s0, s0, s7
	
	j	read_inst # continue with loop
# ============================= end of loop

chk_sltiu:
	# edge case of instruction interpretation - only mnemonic with 5 letters
	# check if s7 is equal to 'u' and the following character is a whitespace
	# and if current content of s0 is stli
	# otherwise - write error and go to next line
	li	t1, 242956905
	li	t2, 'u'
		
	bne	s7, t2, bad_instr
	lb	s7, (a1)
	bnez	s7, chk_wspc_sltiu
	call	refill_buffer
chk_wspc_sltiu:
	addi	a1, a1, 1
	li	a6, 19	# change opcode to bin(0010011) (opcode = OP-IMM)
	li	t5, 3	# funct3 is bin(011)
	li	s1, 1	# immediate
	beq	s7, s2, no_imm_end	# ' '
	beq	s7, s3, no_imm_end	# '\t'
	j	bad_instr
#=====================================================


newlineChar:
	# if instruction is emty - skip char
	# otherwise error - instruction without arguments
	bnez	s0, bad_instr

whitespaceChar:
	beqz	s0, read_inst 	# if instruction empty - skip char
	# otherwise instruciton ready for interpretation


# ============= interpret packed mnemonic to binary ============== #
#								   #
# result: form without arguments - image reflects  x0, x0, x0 OR 0 #
interpret_instruction:
	li	a6, 51		# for encoded instruction - initialized to bin(0110011) (opcode = OP)
	mv	t5, zero	# for func3 code
	
	# check if last letter is 'i'
	andi	t2, s0, 127 	# mask with bin(7x'1') - get last char in t2
	bne	t2, s8, no_imm	
	
	# otherwise - 'i' is present - remove 
	addi	a6, a6, -32	# remove bin(100000) - change opcode to bin(0010011) (opcode = OP-IMM)
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


#======================= Processing the arguments =======================
	li	s6,	7	# preset shift length to 7 - for the first argument
#=============== 1st argument
find_x_before_arg:
	lb	s7, (a1)
	bnez	s7, bufok_args
	call	refill_buffer
bufok_args:
	addi	a1, a1, 1
	# if space/tab - skip. if newline -  go to no_args. if anything else - syntax error
	
	beq	s7, s2, find_x_before_arg	# ' '
	beq	s7, s3, find_x_before_arg	# '\t'
	
	# newline - end of instruction - wrong instruction
	beq	s7, s4, no_args 	
	
	li	t1, 'x'
	bne	s7, t1, syntax_e	# not whitespace, can only be 'x' or syntax error
		
	call	rd_int12b
#	ebreak
	# check if returned value between 0 and 32
	li	t1, 32
	bgtu	a0, t1, syntax_e
	bltz	a0, syntax_e
	sll	a0, a0, s6
	add	a6, a6, a0	# register
	
	li	t1, 20	# if shift was alrady set to 20 - 3rd argument just got encoded. Instruction is finihsed
	beq	s6, t1, inst_end
	
	li	t1, ','
	beq	s7, t1, arg1comma_found	# maybe char that ended the num was a comma - then ok

f_comma_arg1:	
	lb	s7, (a1)
	bnez	s7, bufok_a1
	
	addi	a5, a5, -1
	call	refill_buffer
	li	t1, ','		# t1 may get invalidated by function call
bufok_a1:
	addi	a1, a1, 1
	beq	s7, t1, arg1comma_found
	
	beq	s7, s2, f_comma_arg1	# ' '
	beq	s7, s3, f_comma_arg1	# '\t'

	j	syntax_e

arg1comma_found:
#================== 2nd argument ================== 
# the same as for the first argument - with the shift of 15
	li	t1, 15
	bge	s6, t1, arg3
	mv	s6, t1
	j	find_x_before_arg

#================== 3rd argument ================== 
#	either immediate or register
arg3:
	li	t1, 20
	mv	s6, t1
	bnez	s1, arg3_immediate

#=============== 3rd arg is register:
	j	find_x_before_arg	# same as for 1 and 2 with small adjustments
inst_end:
	mv	a0, a6
	li	a7, SYS_HEXPRT
	ecall
	
	mv	a0, s4
	li	a7, 11
	ecall

	call 	skip_to_nline
	j	start_read_inst

#=============== 3rd arg is immediate:
arg3_immediate:
	#ebreak
	lb	s7, (a1)
	bnez	s7, bufok_a3i

	call	refill_buffer
bufok_a3i:
	beq	s7, s2, cont_loop_a3i	#  ' '
	beq	s7, s3, cont_loop_a3i	#  '\t'
	beq	s7, s4, syntax_e	#  '\n'
	
	addi	a5, a5, -1
	call	rd_int12b
	slli	a0, a0, 20
	add	a6, a6, a0	# encode destination register
	
	mv	a0, a6
	li	a7, SYS_HEXPRT
	ecall
	
	mv	a0, s4
	li	a7, 11
	ecall
	
	call 	skip_to_nline
	j	start_read_inst

cont_loop_a3i:
	addi	a1, a1, 1
	j	arg3_immediate
	




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
	mv	s9, zero	# number of letters read
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
	
	addi	s9, s9, 1
	# range check:
	bgtu	a3, a4, syntax_e
	
	j	loop_rdint
	
check_minus:
	li	a4, 2047
	bne	s7, t4, convert_num	# positive number -> continue with normal loop

	li	a4, 2048	# number is negative
	j 	loop_rdint	# skip minus - go to loop beginnig
	
end_rdint:
	beqz	s9, syntax_e
	mv	a0, a3
	addi	a4, a4, -2047
	
	beqz	a4, ret_rdint
	sub	a0, zero, a0
ret_rdint:
	ret
#==================================================================	


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

        # if data was read - add \0 at ennd and reutrn
        bgtz    a0, refill_ok
        
        beqz	s0, exit	# jump to exit if s0 == 0 (instruction packing did not start yet)
        bnez	a5, syntax_e	# if s0 != 0 AND a5 != 0 - final instruction is not full
	# edge case - final instruction ok
	li	s7, '\n'
	ret
        
refill_ok:
        # Add '\0' after the last byte
        la      t0, buf        # t0 = address of buf
        add     t0, t0, a0     # t0 = buf + (number_of_bytes_read)
        sb      zero, (t0)    # *(buf + a0) = '\0'
       	lb	s7, (a1)
        ret
#===========================================================

# function: skip_to_nline
# find next line and restart the instruciton loading from beginning
skip_to_nline:
	# reset the indicators of instruction and the instruction ending
	mv	s0, zero
	li	a5, 3
#	ebreak
	bnez	s7, bufok_nline
	
	# refill buffer if empty
	mv	s10, ra
	call    refill_buffer
	mv	ra, s10
bufok_nline:
	beq	s7, s4, nlinefoun	# '\n'
	addi	a1, a1, 1
	lb	s7, (a1)
	j	skip_to_nline
nlinefoun:
	lb	s7, (a1)
	ret
#===========================================================
# wrong instruciton - print info and go to newline or end
bad_instr:
	la 	a0, b_ins
	li	a7, SYS_PRT
	ecall
	call	skip_to_nline
	j	start_read_inst


no_args:
	la 	a0, n_args
	li	a7, SYS_PRT
	ecall
	call	skip_to_nline
	j	start_read_inst

syntax_e:
#	ebreak
	la 	a0, b_sntx
	li	a7, SYS_PRT
	ecall
	call	skip_to_nline
	j	start_read_inst	
	
	
# copy of the content of code.asm - for inspecting the resulting codes
#slti x9, x, 45

   sub   x1,x3,x5
 add  x1, x7, x3
 sll x12, x5, x1
 slt x9, x0, x0
sltu x9, x12, x0

xor x1, x2, x3 
srl x2, x4, x10  

sra x10, x20,x31
or x21, x3, x1
and x0, x1, x3




addi  x1, x7, 12
 slli x12, x5, 10
 slti x9, x0, 45

xori x1, x2, 1234 
srli x2, x4, 7  

srai x10, x20,12
ori x21, x3, 2047
andi x0, x1, 124

#slti x8, x1, x3

#slti x9, x, 45