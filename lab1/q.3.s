ARRAY: .word 3, 4, 5, 4
N: 	   .word 4
mean:   .word 0

.global _start
_start:
	ldr r0, =ARRAY
	ldr r1, N
	push {r0,r1}	// r0(address of array) ->>>> r1(4) ->>>>>ffff ffff stack
	
	bl log_2n		// after this, r2 is 2, log_2n
	bl calculate_mean	//r0(address)->r1(mean:4)  stack
	bl center		

	
end:
	b end
	
log_2n:
	push {r0-r3}//r0->r1->r2->r3->r0->r1
	mov r3, #1
	mov r2, #0 //log_2n
loop:
	lsl r3, r2 //left shfit r3 by 2^r2
	cmp r3,	r1 // r1 is N, if (1 << log2_n) < n	
	blt increment	
	str r2,[sp,#8]	//replace old r2 on stack
	pop {r0-r3}
	bx lr
increment:
	add r2, r2, #1	
	b loop
	
calculate_mean:
	push {r0-r3} //r0->r1->r2(2)->r3->r0->r1 stack
	ldr r1, [sp, #20] //load N from stack
	ldr r2, [sp, #16] //load r0 into r2, address of array[0]
	mov r0, #0 // clear r0	
LOOP:
	ldr r3, [r2], #4 //load array[0] into r3, and post-add: [r2]++4 after
	add r0, r0, r3 // mean += *ptr;
	subs r1,r1, #1	//decrement loop counter
	bgt LOOP
	ldr r2, [sp,#8] //get log_2n
	asr r0, r0, r2	//mean = mean >> log2_n;
	str r0, [sp,#20] //store mean on stack, replacing N
	pop {r0-r3}		//restore registers
	bx lr

center:
	push {r0-r3}	//r0->r1->r2(2)->r3->r0(address)->r1(mean)
	ldr r1, N		// size N
	ldr r2, [sp,#16]//load array[0]
	ldr r0, [sp,#20]//load mean
while:
	ldr r3, [r2]    //load array[0] into r3
	sub r3, r3, r0	//*ptr -= mean
	str r3, [r2]	//store value back to memory
	add r2, r2, #4	// pointing to the next element
	subs r1,r1, #1	//loop counter
	bgt while
	pop {r0-r3}
	bx lr
	
	
	