ARRAY:	.word 4, 2, 1, 4, -1
N:		.word 5

.global _start
_start:
	ldr r0, =ARRAY  //address of [0], is same as ptr
	ldr r1, N		// size of array
	ldr r8, N		//N
	push {r0,r1} //r0(address)->r1(size)-> stack
	b sort
	
end: 
	b end

//for (int i=0, i<n-1,i++)
sort:
	mov r2, #0  // r2 = i
	ldr r4, [sp,#4] // r4 = 5 = n
	sub r4, r4, #1  //r4 = n-1
	
loop:	
	cmp r2, r4 // i<n-1
	bge end	 //i>= n-1, go to end, program terminate
	ldr r7, [sp] //address of [0]
	ldr r3, [r7,r2,lsl#2]	// r3 = tmp =  *(ptr + i)
							// r2 lsl#2 because address increment by 4
	mov r0, r2				// r0 = cur_min_idx
	add r1, r2, #1  	//r1=j=i+1, r2=i
	bl inner_loop	// go to inner loop for (int j = i + 1; j < n; j++)
	b swap

//(int j = i + 1; j < n; j++)
inner_loop:
	push {r4-r11}
	cmp r1, #5			// j<n
	blt check			// go to if statement
	b back
back:
	pop {r4-r11}
	bx lr
increment:	
	add r1, r1, #1		// j++
	cmp r1, r8			// j<n
	blt check		//when j>=n go back to while
	b back
//if (tmp > *(ptr + j))	 tmp = r3, j = r1
check: 
	ldr r5, [r7,r1,lsl#2]  //r5=*(ptr + j)
	cmp r3, r5
	ble increment    //r3 <= r5 (tmp<= [j]), just increment j, nothing else
	//otherwise, 
	//tmp = [j]
	//idx = j
	mov r3, r5		//tmp = [j]// r3=tmp, r5=[j]
	mov r0, r1		//idx = j, r0 = idx	
	b increment

// tmp = *(ptr + i);
// *(ptr + i) = *(ptr + cur_min_idx);
// *(ptr + cur_min_idx) = tmp;
//i=r2, idx=r0
swap:
	ldr r3, [r7,r2,lsl#2]  // r3 =tmp = *(ptr + i);
	ldr r6, [r7,r0,lsl#2]  //r6 = *(ptr + cur_min_idx)
	str r6, [r7,r2,lsl#2]  //*(ptr + i) = *(ptr + cur_min_idx) ->r6
	str r3, [r7,r0,lsl#2]  //*(ptr + cur_min_idx) = tmp (r3);

	add r2, r2, #1  //i++
	b loop	