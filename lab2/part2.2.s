HEX_CHARA: .word 0x3f,0x6,0x5b, 0x4F,0x66, 0x6d, 0x7d,0x7,0x7f,0x67,0x77,0x7c,0x39,0x5e,0x79,0x71
.global _start
_start:

	MOV R0,#127
	MOV R1, #0			//inital display
	PUSH {R1}		//number for HEX0
	PUSH {R1}		//number for HEX1
	PUSH {R1}		//number for HEX2
	PUSH {R1}		//number for HEX3
	PUSH {R1}		//number for HEX4
	PUSH {R1}		//number for HEX5
	BL HEX_write_ASM
	BL ARM_TIM_config_ASM	//start count
	
	
mainLoop:
	
	BL check_PB_0
	CMP R2, #1
	BEQ LOOP
	
	BL check_PB_2
	CMP R2, #1
	BEQ RESET
	
	B mainLoop

LOOP:
	
	BL check_PB_2
	CMP R2, #1
	BEQ RESET
	
	BL check_PB_1
	CMP R2, #1
	BEQ mainLoop
	
	BL ARM_TIM_read_INT_ASM	
	CMP R0,#0X1
	BNE LOOP
	BL INCREASE
	B LOOP


RESET:
	MOV R0,#127
	MOV R1, #0
	STR R1, [SP]
	STR R1, [SP,#4]
	STR R1, [SP,#8]
	STR R1, [SP,#12]
	STR R1, [SP,#16]
	STR R1, [SP,#20]
	BL HEX_write_ASM
	B LOOP
	

.equ LOAD, 0xFFFEC600
.equ CONTROL, 0xFFFEC608
.equ INTERRUPT, 0xFFFEC60C
.equ data_R, 0xFF200050
.equ interrupt_R, 0xFF200058
.equ edgecapture_R, 0xFF20005C
.equ HEX_3210, 0xFF200020
.equ HEX_54, 0xFF200030

check_PB_0:
	//check if edge is high. If edge is high display, otherwise nothing
	push {LR}
	MOV r0, #1 
	BL PB_edgecp_is_pressed_ASM	//return r2 as result
	pop {LR}
	CMP R2, #0X1
	BNE BACK_PB_0
	
	PUSH {LR}
	BL PB_clear_edgecp_ASM		//clear the edge.
	POP {LR}					//this is for second update
	
BACK_PB_0:
	BX LR
/////////////////////////////////////////////////////////////
check_PB_1:
	push {LR}
	MOV r0, #2 
	BL PB_edgecp_is_pressed_ASM	//return r2 as result
	pop {LR}
	CMP R2, #0X1
	BNE BACK_PB_1
	
	PUSH {LR}
	BL PB_clear_edgecp_ASM		//clear the edge.
	POP {LR}					//this is for second update
BACK_PB_1:
	BX LR
/////////////////////////////////////////////////////////////	
check_PB_2:
	push {LR}
	MOV r0, #4 
	BL PB_edgecp_is_pressed_ASM	//return r2 as result
	pop {LR}
	CMP R2, #0X1
	BNE BACK_PB_2
	
	PUSH {LR}
	BL PB_clear_edgecp_ASM		//clear the edge.
	POP {LR}					//this is for second update
BACK_PB_2:
	BX LR
/////////////////////////////////////////////////////////////
check_PB_3:
	PUSH {R0}
	MOV R1,R0		//copy the value will be displayed
	//check if edge is high. If edge is high display, otherwise nothing
	push {LR}
	MOV r0, #8
	BL PB_edgecp_is_pressed_ASM	//return r2 as result
	pop {LR}
	CMP R2, #0X1
	BNE BACK_PB_3
	MOV R0,#8		
	PUSH {LR}
	BL HEX_write_ASM //display the value
	POP {LR}
	
	PUSH {LR}
	BL PB_clear_edgecp_ASM		//clear the edge.
	POP {LR}					//this is for second update
	
BACK_PB_3:
	POP {R0}
	BX LR


ARM_TIM_config_ASM:
	LDR R0, =#0x1E8480	//200M for 1 sec, 2M for 10 million second
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
	MOV R0, #0
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
	LDR R3, [R2]		//value of hex register, where to update
	LDR R6, [R2,#0X10]	//second hex register
	LDR R4, =HEX_CHARA  //table of hex-char
	MOV R7, R1
	LSL R7,R7, #2 //scale by 4
	ADD R4,R4,R7 //point to the hex character of R1,  R1 now is useless
	LDR R7, [R4] //HEX character
	
HEX_0_write:
	AND R5, R0, #1		//check encoding
	CMP R5, #1			
	BNE HEX_1_write
	AND R3, R3, #0xffffff00 //clear this hex
	ADD R3, R3, R7		//R1 is the character to display
	STR R3, [R2]
	B HEX_1_write
	
HEX_1_write:
	LSL R7, R7, #8 //shift to the correct hex position
	AND R5, R0, #2
	CMP R5,#2
	BNE HEX_2_write
	AND R3, R3, #0XFFFF00FF //CLEAR	
	ADD R3, R3, R7
	STR R3, [R2]
	B HEX_2_write

HEX_2_write:
	LSL R7, R7, #8 //shift to the correct hex position
	AND R5, R0, #4
	CMP R5,#4
	BNE HEX_3_write
	AND R3, R3, #0XFF00FFFF //CLEAR
	ADD R3, R3, R7
	STR R3, [R2]
	B HEX_3_write
HEX_3_write:
	LSL R7, R7, #8 //shift to the correct hex position
	AND R5, R0, #8
	CMP R5,#8
	BNE HEX_4_write
	AND R3, R3, #0XFFFFFF //CLEAR, 00FF-FFFF
	ADD R3, R3, R7
	STR R3, [R2]
	B HEX_4_write
HEX_4_write:
	LSR R7, R7, #24 //shift back to the 0000-00xx
	AND R5, R0, #0X10
	CMP R5,#0X10
	BNE HEX_5_write
	AND R6, R6, #0XFFFFFF00 //CLEAR
	ADD R6, R6, R7
	STR R6, [R2,#0X10]
	B HEX_5_write
HEX_5_write:
	LSL R7, R7, #8 //shift to the correct hex position
	AND R5, R0, #0X20
	CMP R5,#0X20
	BNE BACK_WRITE
	AND R6, R6, #0XFFFF00FF //CLEAR
	ADD R6, R6, R7
	STR R6, [R2,#0X10]
	B BACK_WRITE

BACK_WRITE:
	pop {r4-r11}
	BX LR		


//increase the value of each hex
INCREASE:		
	//CLEAR F BIT first
	//STACK: r1-r1-r1-r1-r1-r1
	push {LR}
	BL ARM_TIM_clear_INT_ASM
	POP {LR}
	
HEX_0_INCREASE:
	LDR R1, [SP,#20]
	ADD R1,R1, #1
	CMP R1,#10
	BLT NO_CARRY_0		//NOT carry
	
	SUB R1, R1,#10		//if r1 is 10 then mode r1 by 10
	STR R1, [SP,#20]	//store back the value
	PUSH {LR}
	MOV R0, #1
	BL HEX_write_ASM	//update
	POP {LR}
	B HEX_1_INCREASE
	
NO_CARRY_0:		//JUST update 1 hex
	STR R1, [SP,#20]
	PUSH {LR}
	MOV R0, #1
	BL HEX_write_ASM
	POP {LR}
	B BACK_INCREASE
		
HEX_1_INCREASE:
	LDR R1, [SP,#16]
	ADD R1, R1, #1
	CMP R1, #10
	BLT NO_CARRY_1
	
	SUB R1, R1,#10
	STR R1, [SP,#16]
	PUSH {LR}
	MOV R0, #2
	BL HEX_write_ASM
	POP {LR}
	B HEX_2_INCREASE
NO_CARRY_1:
	STR R1, [SP,#16]
	PUSH {LR}
	MOV R0, #2
	BL HEX_write_ASM
	POP {LR}
	B BACK_INCREASE
	
HEX_2_INCREASE:
	LDR R1, [SP,#12]
	ADD R1, R1, #1
	CMP R1, #10
	BLT NO_CARRY_2
	
	SUB R1, R1,#10
	STR R1, [SP,#12]
	PUSH {LR}
	MOV R0, #4
	BL HEX_write_ASM
	POP {LR}
	B HEX_3_INCREASE
NO_CARRY_2:
	STR R1, [SP,#12]
	PUSH {LR}
	MOV R0, #4
	BL HEX_write_ASM
	POP {LR}
	B BACK_INCREASE
	
HEX_3_INCREASE:
	LDR R1, [SP,#8]
	ADD R1, R1, #1
	CMP R1, #6
	BLT NO_CARRY_3
	
	SUB R1, R1,#6
	STR R1, [SP,#8]
	PUSH {LR}
	MOV R0, #8
	BL HEX_write_ASM
	POP {LR}
	B HEX_4_INCREASE
	
NO_CARRY_3:
	STR R1, [SP,#8]
	PUSH {LR}
	MOV R0, #8
	BL HEX_write_ASM
	POP {LR}
	B BACK_INCREASE
	
	
HEX_4_INCREASE:
	LDR R1, [SP,#4]
	ADD R1, R1, #1
	CMP R1, #10
	BLT NO_CARRY_4
	
	SUB R1, R1,#10
	STR R1, [SP,#4]
	PUSH {LR}
	MOV R0, #0X10
	BL HEX_write_ASM
	POP {LR}
	B HEX_5_INCREASE
NO_CARRY_4:
	STR R1, [SP,#8]
	PUSH {LR}
	MOV R0, #0X10
	BL HEX_write_ASM
	POP {LR}
	B BACK_INCREASE
	
	
HEX_5_INCREASE:
	LDR R1, [SP]
	ADD R1, R1, #1
	CMP R1, #10
	BLT NO_CARRY_5
	
	SUB R1, R1,#10
	STR R1, [SP]
	PUSH {LR}
	MOV R0, #0X20
	BL HEX_write_ASM
	POP {LR}
	B BACK_INCREASE
NO_CARRY_5:
	STR R1, [SP]
	PUSH {LR}
	MOV R0, #0X20
	BL HEX_write_ASM
	POP {LR}
	B BACK_INCREASE

BACK_INCREASE:
	BX LR

/////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////
read_PB_data_ASM:
	LDR R2, =data_R
	LDR R0, [R2]
	BX LR
/////////////////////////////////////////////////////////////
PB_data_is_pressed_ASM:
	PUSH {R4-R11}
	LDR R2, =data_R
	LDR R3, [R2]  //GET data regsiter value
	AND R4,R3,R0 //CHECK if R3 & R0 =1 then, it is pressed
	CMP R4, R0 	
	BNE BACK_PRESS
	MOV R0, #0x00000001 
BACK_PRESS:
	POP {R4-R11}
	BX LR
/////////////////////////////////////////////////////////////
read_PB_edgecp_ASM:
	LDR R2, =edgecapture_R
	LDR R0, [R2]			// R0 as result
	BX LR
/////////////////////////////////////////////////////////////
PB_edgecp_is_pressed_ASM: //r0 is input, r2 is output
	PUSH {R4-R11}
	LDR R2, =edgecapture_R
	LDR R3, [R2]  //GET data regsiter value
	AND R4,R3,R0 //CHECK if R3 & R0 =1 then, it is pressed
	CMP R4, R0 	
	BNE BACK_EDGE
	MOV R2, #0x00000001 	//return to R2
BACK_EDGE:
	POP {R4-R11}
	BX LR
/////////////////////////////////////////////////////////////
PB_clear_edgecp_ASM:
	PUSH {R4}
	LDR R4, =edgecapture_R
	MOV R3, #15
	STR R3, [R4]
	POP {R4}
	BX LR	
/////////////////////////////////////////////////////////////
enable_PB_INT_ASM:	
	LDR R2, =interrupt_R
	MOV R3,#0XF
	STR R3, [R5]
	POP {R4-R11}
	BX LR	
/////////////////////////////////////////////////////////////
disable_PB_INT_ASM:
	LDR R5, =interrupt_R
	MOV R3, #0
	STR R3, [R2]
	BX LR
///////////////////////////////////////////////////////
///////////////////////////////////////////////////////		
		