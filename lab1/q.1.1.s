.global _start
_start:
	mov r0, #1//xi
	mov r1, #168//a= 168
	mov r2, #100 //cnt = 100
	mov r3,#0//i for the loop

sqrtIter:
	sub r5, r3, r2 //r5=i-cnt
	cmp r5, #0	//i-cent<0 Update CPSR code 
	bge END	//if i-cent>=0, end loop. Otherwise, continue
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

	sub r0,r0,r4	// xi = xi - grad;
	b sqrtIter
	
TooLarge:
	mov r4, #2
	B If
TooSmall:
	mov r4, #-2
	B If
	
END:
	b END
	