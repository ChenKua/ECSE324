.global _start
_start:
    mov r0, #4
    bl func

end:
	b end
	
func:
	subs r0,r0, #1
	cmp r0, #0
	beq back
 	
	push {lr}
	bl func
	
	pop {lr}
	bx lr
	
back:
	bx lr