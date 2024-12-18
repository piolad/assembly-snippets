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

.eqv	BUFLEN, 512	# at least 2 - to also accomodate for "\0"

.eqv	min24bitnumer, 0x1000000	# 1 followed by 8*3=24 zeros
.eqv	opcode_OP, 0x33
.eqv	opcode_OP_IMM, 0x13

.data
inst_table:	# instruction and combined func3-func7 code
	.ascii	"add\0"	
	.word	0
	.ascii	"and\0"
	.word	7
	.ascii	"or\0\0" # to keep same length
	.word	6
	.ascii	"sll\0"
	.word	1
	.ascii	"slt\0"
	.word	2
	.ascii	"sltu"
	.word	3
	.ascii	"sra\0"
	.half	5
	.half	1
	.ascii	"srl\0"
	.word	5
	.ascii	"xor\0"
	.word	4
	.ascii	"sub\0"
	.half	0
tb_end: .half	1
	
	
buf:	.space BUFLEN
fname:	.asciz "code.asm"

# ========== error messages ==========
b_ins:	.asciz " # ERROR! Instruction mnemonic not recognized or instruction not complete\n"
b_sntx:	.asciz " # ERROR! Wrong line syntax\n"
n_args:	.asciz " # ERROR! Not enough arguments\n"



#########################################################################
# .text section								#
#########################################################################
.text

# ========================== one time settings ======================== #
init:	
	# constants used a lot
	li	s2, ' '
	li	s3, '\t'
	li	s4, '\n'
	
openfile:
	li	a7, SYS_FOP
	la	a0, fname
	li	a1, RDFLAG
	mv	a2, zero
	ecall
	mv 	s11, a0		# save the file descriptor
	call	refill_buffer	# prefill the buffer


# ======================== pack instruction to s0 ========================
start_read_inst:	# reset data before loop
	mv	s0, zero	# instruction 
	mv	s1, zero	# immeidate flag
	mv	s8, zero	# shift amount
	
read_inst:		# loop for packing the mnemonic
	call	getch
	bltz	s7, inst_rd_eof
	
	# skip whitespace if before  mnemonic
	beq	s7, s2, whitespaceChar	# ' '
	beq	s7, s3, whitespaceChar	# '\t'
	
	# skip newline if before mnemonic - otherwise error
	beq	s7, s4, newlineChar
	
	# if instruction > bin(1 00000000 00000000 00000000), 4 instructions
	# already packed so either instruction is wrong or sltiu edge case
	li	t0, min24bitnumer
	bge	s0, t0, chk_sltiu
	
	# to lowercase:
	li	t0, 'A'
	blt	s0, t0, skip_lowercase
	li	t0, 'Z'
	bgt	s0, t0, skip_lowercase
	addi	s0, s0, 32

skip_lowercase:	
	# pack up to 4 bytes into 1 32bit register
	sll	s7, s7, s8
	add	s0, s0, s7
	addi,	s8, s8, 8
	
	j	read_inst # continue with loop
# ============================= end of loop



newlineChar:
	# if instruction is empty - skip char
	# otherwise error - instruction without arguments
	bnez	s0, bad_instr

whitespaceChar:
	beqz	s0, read_inst 	# if instruction empty - skip char
	# otherwise instruciton ready for interpretation


# ============= interpret packed mnemonic to binary ============== #
#								   #
# result: form without arguments -  x0, x0, x0 OR 0	  	   #
interpret_instruction:
	li	a6, opcode_OP
	mv	t5, zero	# for func3 code
	la	t0, inst_table
	la	t3, tb_end

	# check if last letter is 'i'
	li	t1, 'i'
	li	t4, 0xff	# mask bin(8x'1')
	addi	s8, s8, -8
	sll	t4, t4, s8	# move mask to last loaded byte
	and	t2, s0, t4
	srl	t2, t2,	s8
	bne	t2, t1, no_imm	
	
	# otherwise - 'i' is present - remove 
	li	a6, opcode_OP_IMM	# change opcdoe (opcode = OP-IMM)
	not	t4, t4		# invert mask
	and	s0, s0, t4	# remove 'i'
	li	s1, 1	
	
no_imm:
	lw	t1, (t0)
	beq	t1, s0, no_imm_end

	addi	t0, t0, 8
	bge	t0, t3, bad_instr

	j	no_imm

#todo: here also check for illegal subi instruction
no_imm_end:
	lw	t5, 4(t0)
	andi	t0, t5, 7 # get lower 3 bits
	sub	t5, t5, t0
	sgtz	t5, t5
	slli	t5, t5, 30
	# add func3
	slli	t0, t0, 12
	add	a6, a6, t0
	add	a6, a6, t5

process_args:
#======================= Processing the arguments =======================
	li	s6,	7	# preset shift length to 7 - for the first argument
#=============== 1st argument
find_x_before_arg:
	call	getch
	bltz	s7, syntax_e
	
	beq	s7, s2, find_x_before_arg	# ' '
	beq	s7, s3, find_x_before_arg	# '\t'
	
	# newline - end of instruction - wrong instruction
	beq	s7, s4, ne_args 	

	li	t1, 'x'
	bne	s7, t1, syntax_e	# not whitespace, can only be 'x' or syntax error
		
	call	rd_int12b
	# check if returned value between 0 and 32
	li	t1, 32
	bgtu	a0, t1, syntax_e
	bltz	a0, syntax_e
	sll	a0, a0, s6
	add	a6, a6, a0	# register
	
	li	t1, 20	# if shift was alrady set to 20 - 3rd argument just got encoded. Instruction is finihsed
	beq	s6, t1, inst_end
	
	li	t1, ','
	beq	s7, t1, comma_found	# maybe char that ended the num was a comma - then ok

find_comma_after_arg:
	call	getch
	bltz	s7, syntax_e
	li	t1, ','		# t1 may get invalidated by function call

	beq	s7, t1, comma_found
	
	beq	s7, s2, find_comma_after_arg	# ' '
	beq	s7, s3, find_comma_after_arg	# '\t'

	j	syntax_e

comma_found:
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

# (1) 3rd arg is register:
# same as for args 1 and 2 with shift 20
	j	find_x_before_arg
inst_end:
	mv	a0, a6
	li	a7, SYS_HEXPRT
	ecall
	
	mv	a0, s4
	li	a7, 11
	ecall

	call 	skip_to_nline
	j	start_read_inst

# (2) 3rd arg is register:
arg3_immediate:
	# here there is no preceeding x - 
	call	rd_int12b
	li	t1, -2048
	bge	a0, t1, arg3_ok
	
	li	t1, -19999
	bne	a0, t1, syntax_e
	
	beq	s7, s2, arg3_immediate
	beq	s7, s3, arg3_immediate
	j	syntax_e

arg3_ok:
	slli	a0, a0, 20
	add	a6, a6, a0
	
	mv	a0, a6
	li	a7, SYS_HEXPRT
	ecall
	
	mv	a0, s4
	li	a7, 11
	ecall
	
	call 	skip_to_nline
	j	start_read_inst

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

	mv	s9, zero	# number of letters read
loop_rdint:
	mv	s10, ra		# non-leaf procedure - save the return address
	call	getch
	mv	ra, s10
	bltz	s7, end_rdint

	# fix constatnt temporary registers after call
	li	t3, 10
	li	t4, '-'
	li	t5, '0'
	li	t6, '9'
	beqz	a4, check_minus	# minus unset yet - allow to set it
	
	# check for minus in the middle of numer e.g. 102-23, --12, 1234-
	beq	s7, t4, err_rdint
	
convert_num:
	bgt	s7, t6, end_rdint
	blt	s7, t5, end_rdint
	
	mul	a3, a3, t3 	# multiply by 10
	add	a3, a3, s7
	sub	a3, a3, t5
	
	addi	s9, s9, 1
	# range check:
	bgtu	a3, a4, err_rdint
	
	j	loop_rdint
	
check_minus:
	li	a4, 2047
	bne	s7, t4, convert_num	# positive number -> continue with normal loop

	li	a4, 2048	# number is negative
	j 	loop_rdint	# skip minus - go to loop beginnig
	
end_rdint:
	beqz	s9, err_rdint_nochar	# no characters were read
	mv	a0, a3
	
	addi	a4, a4, -2047
	beqz	a4, ret_rdint
	
	sub	a0, zero, a0
ret_rdint:
	ret
err_rdint_nochar:
	li	a0, -19999
	ret
err_rdint_eof:
	li	a0, -15000
	ret
err_rdint:
	li	a0, -9999
	ret

#==================================================================	

inst_rd_eof:
	bnez	s0, syntax_e
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
getch:
	lb	s7, (a1)
	beqz	s7, refill_buffer	# if char is 0 - continue 
	addi	a1, a1, 1	# advance buf address
	ret

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
        li	s7, -1
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
	
	# here branching is less efficient - but helps with situation when \n is encounered
	# when function is called
	beq	s7, s4, nline_found	# '\n'	
	bltz	s7, exit
	# refill buffer if empty
	mv	s10, ra
	call    getch
	mv	ra, s10
	
	j skip_to_nline	# '\n'
nline_found:
	ret
#===========================================================
chk_sltiu:
	# only mnemonic with 5 letters
	# check if s7 is equal to 'u' and the following character is a whitespace
	# and if current content of s0 is stli
	# otherwise - bad_instr:
	li	t1, 242956905
	li	t2, 'u'
		
	bne	s7, t2, bad_instr
	
	call 	getch
	bltz	s7, bad_instr
	
	li	a6, 19	# change opcode to bin(0010011) (opcode = OP-IMM)
	li	t5, 3	# funct3 is bin(011)
	slli	t5, t5, 12
	add	a6, a6, t5
	li	s1, 1	# immediate
	beq	s7, s2, process_args	# ' '
	beq	s7, s3, process_args	# '\t'
#=====================================================

# wrong instruciton - print info and go to newline or end
bad_instr:
	la 	a0, b_ins
	li	a7, SYS_PRT
	ecall
	call	skip_to_nline
	j	start_read_inst


ne_args:
	la 	a0, n_args
	li	a7, SYS_PRT
	ecall
	call	skip_to_nline
	j	start_read_inst

syntax_e:
	la 	a0, b_sntx
	li	a7, SYS_PRT
	ecall
	bltz	s7, exit
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



