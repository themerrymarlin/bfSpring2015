#########################################################################
# Brainfuck Interpreter
# John Tomko
# Dan Brotman
# David Merriman
# Joe Jensen
# Lucas Flowers
# Project UI
#########################################################################

.globl main

#########################################################################
# Data Variables
#########################################################################
.data

newLine: .asciiz "\n"
inputPrompt: .asciiz "Enter a valid brainfuck file path: "
fileErr: .asciiz "Oops! There was an error processing your input file!"

buffer: .space 512
data: .space 2048
instructions: .space 2048

ascii_instruction_table: 
	.word no_op # (null)
	.word no_op # (start of heading)
	.word no_op # (start of text)
	.word finish # (end of text)
	.word finish # (end of transmission)
	.word no_op # (enquiry)
	.word no_op # (acknowledge)
	.word no_op # (bell)
	.word no_op # (backspace)
	.word no_op # (horizontal tab)
	.word no_op # (NL line feed, new line)
	.word no_op # (vertical tab)
	.word no_op # (NP form feed, new page)
	.word no_op # (carriage return)
	.word no_op # (shift out)
	.word no_op # (shift in)
	.word no_op # (data link escape)
	.word no_op # (device control 1)
	.word no_op # (device control 2)
	.word no_op # (device control 3)
	.word no_op # (device control 4)
	.word no_op # (negative acknowledge)
	.word no_op # (synchronous idle)
	.word no_op # (end of transmission block)
	.word no_op # (cancel)
	.word no_op # (end of medium)
	.word no_op # (substitute)
	.word no_op # (escape)
	.word no_op # (file separator)
	.word no_op # (group separator)
	.word no_op # (record separator)
	.word no_op # (unit separator)
	.word no_op # (space)
	.word no_op # !
	.word no_op # "
	.word no_op # #
	.word no_op # $
	.word no_op # %
	.word no_op # &
	.word no_op # '
	.word no_op # (
	.word no_op # )
	.word no_op # *
	.word increment_data # +
	.word take_input # ,
	.word decrement_data # -
	.word print # .
	.word no_op # /
	.word no_op # 0
	.word no_op # 1
	.word no_op # 2
	.word no_op # 3
	.word no_op # 4
	.word no_op # 5
	.word no_op # 6
	.word no_op # 7
	.word no_op # 8
	.word no_op # 9
	.word no_op # :
	.word no_op # ;
	.word decrement_pointer # < 
	.word no_op # =
	.word increment_pointer # >
	.word no_op # ?
	.word no_op # @
	.word no_op # A
	.word no_op # B
	.word no_op # C
	.word no_op # D
	.word no_op # E
	.word no_op # F
	.word no_op # G
	.word no_op # H
	.word no_op # I
	.word no_op # J
	.word no_op # K
	.word no_op # L
	.word no_op # M
	.word no_op # N
	.word no_op # O
	.word no_op # P
	.word no_op # Q
	.word no_op # R
	.word no_op # S
	.word no_op # T
	.word no_op # U
	.word no_op # V
	.word no_op # W
	.word no_op # X
	.word no_op # Y
	.word no_op # Z
	.word start_loop # [
	.word no_op # \
	.word end_loop # ] 
	.word no_op # ^
	.word no_op # _
	.word no_op # `
	.word no_op # a
	.word no_op # b
	.word no_op # c
	.word no_op # d
	.word no_op # e
	.word no_op # f
	.word no_op # g
	.word no_op # h
	.word no_op # i
	.word no_op # j
	.word no_op # k
	.word no_op # l
	.word no_op # m
	.word no_op # n
	.word no_op # o
	.word no_op # p
	.word no_op # q
	.word no_op # r
	.word no_op # s
	.word no_op # t
	.word no_op # u
	.word no_op # v
	.word no_op # w
	.word no_op # x
	.word no_op # y
	.word no_op # z
	.word no_op # {
	.word no_op # |
	.word no_op # }
	.word no_op # ~
	.word no_op # (delete)

#########################################################################
# Code text
#
# Functions:
# Take input file path
# Open file at input path 
# Read file text
# Send program to correct functions based on input characters
#
# Registers used:
#	$s0: Characters in the file path string
#	$s1: The file descriptor
#	$s2: The number of characters in the .bf file
#	$s3: The end of the file data
#	$s4: The address of the data
#	$s5: The address of the input instructions
#
#	$t0: A counter counting how many characters are in the file path
#	$t1: Flag determining whether to end or not
#	$t2: The .bf character being handled
#	$t3: The literal 4
#	$t4: The weighted memory address of the current .bf character
#
#	$a0: Syscall parameters
#	$a1: Syscall parameters
#	$a2: Syscall parameters
#
#	$v0: Syscall commands
# 
# Storage of .bf-relevent info
#	At the end of the UI code, both $s5 and $a0 store the brainfuck
#		instructions.
#	$s4 and $a1 store the data address, which is brainfuck's
#		"pointer."
#	Each brainfuck command should increment $a0 and store that value
#		in $s5, which increments the instruction count so that
#		the program executes commands in order.
#	Incrementing or decrementing the pointer will require
#		adding 1 or -1 to $a1 and storing that value in $s4.
#	MAKE SURE TO INCREMENT $a0 AND STORE IT IN $s5. The program will
#		constantly execute the same brainfuck command otherwise.
#	Each brainfuck command section should copy $a1 into $s4 and jump
#		to loop as its final 2 commands.
#	See the no_op function as a template for what each command
#		should do.
#########################################################################
.text

main: 
	# Prompt user for the input file path
	li $v0, 4
	la $a0, inputPrompt
	syscall

	# Read the input file path
	li $v0, 8
	la $a0, buffer
	li $a1, 512
	syscall

	# Initialize the count to zero
	add $t0, $zero, $zero

	j str_length

str_length:
	# Load next character
	lb $s0, 0($a0)

	# Exit loop if finished with string
	beqz $s0, open_file

	# Increment character and counter
	addi $a0, $a0, 1
	addi $t0, $t0, 1
	
	# Continue counting
	j str_length # return to the top of the loop

open_file:
	# Open the file
	li $v0, 13
	la $a0, buffer
	add $a1, $zero, $zero
	add $a2, $zero, $zero
	syscall
	
	# Store the file descriptor
	move $s1, $v0
	
	bgtz $s1, read_file

	j error

read_file:
	# Read the contents of the file
	li $v0, 14
	add $a0, $s1, $zero
	la $a1, instructions
	li $a2, 2048
	syscall

	# Branch if an error occurred
	blez $v0, error
	
	# Store the number of characters in the input file
	add $s2, $v0, $zero

	# Save the end of the file data
	add $s3, $s2, $a1

	j begin_brainfuck

begin_brainfuck:
	# The addresses of the data pointer and the instructions stored in registers
	la $s4, data
	la $s5, instructions

loop:
	# If the instructions left are less than how many are at the end, stop
	slt $t1, $s5, $s3
	beq $t1, $zero, finish
	
	# Get a brainfuck character
	lb $t2, 0($s5)

	# Store the location of the data pointer and instructions in new registers	
	move $a0, $s5
	move $a1, $s4
	
	# Adjust the position of the character to reflect its location in memory
	addi $t3, $zero, 4
	mul $t4, $t3, $t2

	# Get the brainfuck instruction to use for the character
	lw $t5, ascii_instruction_table($t4)

	# Perform that instruction
	jr $t5
	

error:
	# An error occurred
	li $v0, 4
	la $a0, fileErr
	syscall

	j finish

finish:
	li $v0, 10
	syscall	

############################################################################
# Brainfuck Commands
#
# no-op: No meaningful operation
# increment_pointer (>): Increments the position of the brainfuck pointer
# decrement_pointer (<): Decrements the position of the brainfuck pointer
# start_loop ([): Begins a while loop--while (byte at pointer /= 0)
# end_loop (]): End of while loop
# increment_data (+): Increments the data stored in the address the pointer
#		      is at
# decrement_data (-): Decrements the data stored in the address the pointer
#		      is at
# take_input (,): Allows the user to input a byte of data
# print (.): Prints the byte located at the current pointer location
############################################################################

no_op:
	# Increment the instruction
	addi $s5, $a0, 1

	# Keep the pointer where it is
	add $s4, $a1, $zero

	# Go to next instruction
	j loop

#############################################################################
# Remaining functions go here
#############################################################################
#left bracket '['
#using t5, t6, t7, t8
left_bracket:
	#check if current pointer value is 0, if yes find end bracket, otherwise execute loop
	lb $t5, 0($s4)
	bne $t5, $zero, found_matching_bracket
	#if 0, go to matching end bracket
	#t5 holds number of matching brackets required
	li $t5, 1 

find_matching_end_bracket:
	#increment instruction pointer
	addi $s5, $a0, 1

	#load value of instruction to t6
	lb $t6, 0($s5)
	
	#load ascii code for left, right brackets to t7 and t8
	li $t7, 91
	li $t8, 93
	beq $t6, $t7, found_left_begin
	beq $t6, $t8, found_right_begin

found_left_begin:
	#increment number of matching brackets required
	addi $t5, $t5, 1
	j find_matching_end_bracket

found_right_begin:
	#decrement number of matching brackets required
	addi $t5, $t5, -1

	#check if t5 is 0, else keep looking for brackets
	beq $t5, $zero, found_matching_bracket
	j find_matching_end_bracket

found_matching_bracket: 
	#increment instruction pointer
	addi $s5, $a0, 1

	#keep pointer static
	add $s4, $a1, $zero

	#jump to loop
	j loop
	



#right bracket ']'
#uses t5, t6, t7, t8
right_bracket:
	#load data byte into t5
	lb $t5, 0($s4)
	
	#check if byte is zero, exit loop if so, otherwise find beginning
	beq $t5, $zero, found_matching_bracket
	
	#t5 now stores the number of '[' needed
	li $t5, 1

find_matching_begin_bracket:
	#decrement instruction pointer
	addi $s5, $a0, -1
	
	#load byte val of instruction into t6
	lb $t6, 0($s5)
	
	#check instruction type, '[' in t7, '[' in t8
	li $t7, 91
	li $t8, 93
	beq $t6, $t7, found_left_end
	beq $t6, $t8, found_right_end

found_left_end:
	#decrement number of matching brackets required
	addi $t5, $t5, -1

	#check if t5 is 0, else keep looking for brackets
	beq $t5, $zero, found_matching_bracket
	j find_matching_begin_bracket

found_right_end:
	#increment number of matching brackets required
	addi $t5, $t5, -1
	j find_matching_begin_bracket
