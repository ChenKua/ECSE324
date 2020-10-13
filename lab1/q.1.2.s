.global _start
_start:
	mov r0, #1//xi
	mov r1, #168//a= 168
	mov r2, #100 //cnt = 100
	
	bl sqrtRecur

end:
	b end

sqrtRecur:	
	cmp r2, #0
	beq back	//stop recurrsive function call
	
	mul r3, r0, r0// r3 <- r0*r0 = xi*xi
	sub r3, r3, r1// r3 = xi*xi-a
	mul r3, r3, r0// r3 = (xi*xi-a)*xi
	asr r3, r3, #10// r3 divided by 2^k. Achieve that with ASR.r3=grad now
	
	push {lr}
	bl checkGrad
	pop {lr}
	
    sub r0, r0, r3  //xi = xi - grad;
	sub r2, r2, #1	//cnt = cnt-1
	
	push {lr}
	bl sqrtRecur
					//////////////////////	
					//go back to line 7
	
	pop {lr}
	bx lr
			
back:
	bx lr	//actually go back to line 28

checkGrad:
	cmp r3, #2
	bgt TooLarge
	cmp r3, #-2	
	blt TooSmall
	bx LR
	
TooLarge:
	mov r3, #2
	b checkGrad
TooSmall:
	mov r3, #-2
	b checkGrad
		