ARRAY: .word 5, 6, 7, 8
N: 	   .word 4
tmp:   .word 0
norm:  .word 1


.global _start
_start:
	ldr r0, =ARRAY  //address of array[0]
	ldr r1, tmp		// is equal to 0
	ldr r2, N		
	mov r3, #1		
	bl log_2n		
	bl calculateNorm	// r0 = 5^2+6^2+7^2+8^2, r1 =2
	
	asr r0, r0, r1		// r0 = tmp = tmp >> log2_n;
	
	
	bl sqrtIter			//r1 has the value of norm^2 other registers
						//are not important
end:
	b end
	
log_2n:
	lsl r3, r1 //left shfit r3 by 2^r1
	cmp r3,	r2	
	blt increment	
	bx lr
increment:
	add r1, r1, #1	
	b log_2n
	
calculateNorm:				// r1 = log_2n, r2 = N=4, r3 and r0 is whatever
	push {r0,r1,r2,r3}		// r0 -> r1 -> r2 -> r3-> ffff ffff stack
	mov r0, #0			    // clear r0
	ldr r1, [sp]			// load r1 with the address of array[0]
loop:
	ldr r2,[r1],#4			// r2 = array[];
	mul r3, r2, r2			//r3 =r2*r2
	add r0, r0, r3			//r0 = r3+r0
	ldr r2, [SP, #8]		// get r2 from stack	
	subs r2, r2, #1			//r2--
	str r2, [SP, #8]		//update the stack with new value of r2
	bgt loop				// if r2>0 continue loop
	str r0, [sp]			// store r0 into stack where r0 used to be
							// r0 = tmp
	pop {r0-r3}				//
	bx lr

	
sqrtIter:
	push {r0,r1,r2,r3}  //r0->r1->r2->r3, r0 is tmp
	mov r0, #1//xi
	ldr r1, [sp]// r1 =r0, 2b
	mov r2, #100 //cnt = 100
	mov r3,#0//i for the loop
sqrt:
	sub r5, r3, r2 //r5=i-cnt
	cmp r5, #0	//i-cent<0 Update CPSR code 
	bge Back	//if i-cent>=0, end loop. Otherwise, continue
	add r3, r3, #1 //i++
	
	//r4 is the step
	mul r4, r0, r0// r4 <- r0*r0 = xi*xi
	sub r4, r4, r1// r4 = xi*xi-a
	mul r4, r4, r0// r4 = (xi*xi-a)*xi
	asr r4, r4, #0x0a// r4 divided by 2^k. Achieve that with ASR.r4=step now

If: subs r6,r4,#2 //r6=r4-2. Update CPSR code 
	bgt TooLarge //if r4>2 ->r6>0, set r4 to 2
	adds r7,r4,#2 //r7=r4+2	Update CPSR code 
	blt TooSmall//if r4<-2 ->r7<0, set r4 to -2

	sub r0,r0,r4	
	b sqrt
	
TooLarge:
	mov r4, #2
	B If
TooSmall:
	mov r4, #-2
	B If
Back:
	str r0, [sp]		// store value of norn to stach because later
	pop {r0,r1,r2,r3}	// we will pop stack	
 	bx lr
	
	
	
	