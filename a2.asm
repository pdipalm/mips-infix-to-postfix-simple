.globl main

.data
ibuffer: .space 256
obuffer: .space 256
str1:  .asciiz "Enter a fully parenthesized infix expression:\n"
str2: .asciiz "postfix: "
str3: .asciiz "\nresult: "

.text
main: 	la $a0, str1    
    	li $v0, 4	
    	syscall		# print prompt 1
    	li $a1, 256     # allocate 256bits for strings
	la $a0, ibuffer  
    	li $v0, 8       # scanf
    	syscall    	
    	move $t0, $a0   # t0 pointer to string start
    	la $t2, obuffer	# load t2 to output address
	li $t3, 0	# stack size
    	
    	#ASCII
    	#40 - (
    	#41 - )
    	#43 - +
    	#45 - -
    	#48-57 - 0-9
    	
    	addi $t0, $t0, -1	# t0=-1, so t0=0 when loop begins
scan:	addi $t0, $t0, 1	# t0 is inputString[i]
	lb $s0, 0($t0)		# s0 = inputString[i]
	beqz $s0, exitsc	# if s0 = \0, exit
	beq $s0, 10, exitsc	# if s0 = \n, exit (normal case)
	bgt $s0, 47, isDigit	# if s0 is digit, goto isDigit
	beq $s0, 40, isOP	# if s0 is (, +, -, goto isOP
	beq $s0, 43, isOP
	beq $s0, 45, isOP
	beq $s0, 41, isCP	# if s0 is ) goto isCP
	j scan
isDigit:sb $s0, 0($t2)		# store byte in outputString[t2]
	addi $t2, $t2, 1	# t2++
	j scan
isOP:	addi $sp, $sp, -8	# alloc 1 byte on stack
	sb $s0, 0($sp)		# stack.push(s0)
	addi $t3, $t3, 1	# stackSize++
	j scan
isCP:	jal stkPop		# jal stkPop, result in s1
	beq $s1, 40, scan	# if stackTop=40, return to loop beginning
	sb $s1, 0($t2)		# else outputString.append(s1)
	addi, $t2, $t2, 1	# t2++
	j isCP			# jump back to isCP (we are flushing the stack until a '(')
exitsc:	la $a0, str2    	
    	li $v0, 4	
    	syscall			# print prompt 2
	la $a0, obuffer
	li $v0, 4
	syscall			# print postfix string 
	la $t2, obuffer		# load t2 output[0]
	
	# postfix string processing below
	addi $t2, $t2, -1	# t2--
	#bnez $t3, stkclr	# if stackSize!=0, goto stack clear
eval:	addi $t2, $t2, 1	# t2++
	lb $s2, 0($t2)		# s2 = postfix[t2]
	beqz $s2, exitPg	# if s2 = 0
	bgt $s2, 47, evDigit	# if s2 > ascii.47 goto evDigit
	beq $s2, 43, evAdd	# if s2 = '+' goto evAdd
	beq $s2, 45, evSub	# if s2 = '-' goto evSub
evDigit:addi $s2, $s2, -48	# this is a digit, ascii.x - 48 = x
	addi $sp, $sp, -8 	# alloc 1b sp
	sb $s2, 0($sp)		# stack.push(s2)
	addi $t3, $t3, 1	# stackSize++
	j eval
evSub:	jal stkPop		# result in s1
	move $t8, $s1		# t8 = s1
	jal stkPop		# result in s1
	move $t9, $s1		# t9 = s1
	neg $t8, $t8		# t8 = -t8
	add $t8, $t8, $t9 	# t8 = t9 - t8
	j push
evAdd:	jal stkPop		# get top of stack to s1
	move $t8, $s1		# move s1 to t8 
	jal stkPop		
	move $t9, $s1
	add $t8, $t8, $t9	# t8 += t9
	j push			# push uses t8 as arg
exitPg:	jal stkPop		# this is the last item on the stack
	la $a0, str3    	
    	li $v0, 4	
    	syscall			# print prompt 3
    	li $v0, 1
    	move $a0, $s1
    	syscall			# printing int result
	
	li $v0, 10
	syscall			# exit 0

#t8 as argument
push:	addi $sp, $sp, -8	# alloc 1 byte to stack
	sb $t8, 0($sp)		# stack.push(t8)
	addi $t3, $t3, 1	# stackSize++
	j eval	

#result in s1	
stkPop:	lb $s1, 0($sp)		# s1 = stack.pop
	addi $sp, $sp, 8	# deallocate from stack
	addi $t3, $t3, -1	# stackSize--
	jr $ra			# return to called PC address
