HEX_CHARA: .word 0x3f,0x6,0x5b, 0x4F,0x66, 0x6d, 0x7d,0x7,0x7f,0x67,0x77,0x7c,0x39,0x5e,0x79,0x71
.global _start
_start:
	
	MOV R1, #0			//inital display
	BL HEX_write_ASM
	BL ARM_TIM_config_ASM	//start count
LOOP:
	BL ARM_TIM_read_INT_ASM	
	CMP R0,#0X1
	BNE LOOP
	BL INCREASE
	B LOOP

.equ HEX_3210, 0xFF200020
.equ LOAD, 0xFFFEC600
.equ CONTROL, 0xFFFEC608
.equ INTERRUPT, 0xFFFEC60C

ARM_TIM_config_ASM:
	LDR R0, =0xbebc200	//200M
	LDR R2, =LOAD		
	STR R0, [R2]
	LDR R2, =CONTROL
	LDR R3, [R2]		//R1 is now the value of control register
	AND R3, R1, #0XFFFFFFF8	//clear the first three bits by AND 1111-1111-1000
	ADD R3, R1, #0X7 //ADD 0111 make sure first three bits are 111
	STR R3, [R2]
	BX LR
ARM_TIM_read_INT_ASM:
	LDR R2, =INTERRUPT
	LDR R0, [R2]
	BX LR
ARM_TIM_clear_INT_ASM:
	LDR R2, =INTERRUPT
	MOV R3, #0X1
	STR R3, [R2]
	BX LR
	
HEX_write_ASM:
	push {r4-r11}
	LDR R2, =HEX_3210
	LDR R4, =HEX_CHARA  //table of hex-char
	MOV R5,R1
	LSL R5,R5, #2 //scale by 4
	ADD R4,R4,R5 //point to the hex character of R1,  R1 now is useless
	LDR R5, [R4] //HEX character TO DISPLAY
	
	AND R3, R3, #0xffffff00 //clear this hex
	ADD R3, R3, R5		//R1 is the character to display
	STR R3, [R2]

	pop {r4-r11}
	BX LR
	
INCREASE:	
	ADD R1,R1,#1
	CMP R1,#16
	BGE MODE
write:	
	push {LR}
	BL HEX_write_ASM	//UPDATE HEX
	POP {LR}
	
	PUSH {LR}
	BL ARM_TIM_clear_INT_ASM
	POP {LR}
	
	BX LR
	
MODE:
	SUB R1, R1,#16
	B write