HEX_CHARA: .word 0x3f,0x6,0x5b, 0x4F,0x66, 0x6d, 0x7d,0x7,0x7f,0x67,0x77,0x7c,0x39,0x5e,0x79,0x71
.global _start
.global _start
_start:

LOOP:

	BL read_slider_switches_ASM // r0 is the swtich register
	BL write_LEDs_ASM			
	BL check_SW9		//sw 9 is detected, only fouc sw0-sw3
	AND R1, R0, #0X200
	CMP R1,#0X200
	BEQ LOOP
	
	AND R0,R0,#0XF		//only sw0-sw3 left
	BL check_PB_0
	BL check_PB_1
	BL check_PB_2	
	BL check_PB_3	
	
	B LOOP

.equ data_R, 0xFF200050
.equ interrupt_R, 0xFF200058
.equ edgecapture_R, 0xFF20005C
.equ HEX_3210, 0xFF200020
.equ HEX_54, 0xFF200030

check_SW9:
	PUSH {R0}
	AND R1, R0, #0X200  //binary 10-0000-0000
	CMP R1, #0X200		
	BNE HEX5_HEX4_ON	//if SW9 is not 1, turn on HEX5,HEX4
						//otherwise, turn off all
	push {LR}
	MOV R0, #127
	BL HEX_clear_ASM
	pop {LR}
	B BACK_check_SW9
	
HEX5_HEX4_ON:
	MOV R0, #0X30   //0X10 + 0X20
	MOV R1, #8
	PUSH {LR}
	BL HEX_write_ASM
	pop {lr}
	B BACK_check_SW9
	
BACK_check_SW9:
	POP {R0}
	BX LR

check_PB_0:
	PUSH {R0}
	MOV R1,R0		//copy the value will be displayed
	//check if edge is high. If edge is high display, otherwise nothing
	push {LR}
	MOV r0, #1 
	BL PB_edgecp_is_pressed_ASM	//return r2 as result
	pop {LR}
	CMP R2, #0X1
	BNE BACK_PB_0
	MOV R0,#1		
	PUSH {LR}
	BL HEX_write_ASM //display the value
	POP {LR}
	
	PUSH {LR}
	BL PB_clear_edgecp_ASM		//clear the edge.
	POP {LR}					//this is for second update
	
BACK_PB_0:
	POP {R0}
	BX LR
/////////////////////////////////////////////////////////////
check_PB_1:
	PUSH {R0}
	MOV R1,R0		//copy the value will be displayed
	//check if edge is high. If edge is high display, otherwise nothing
	push {LR}
	MOV r0, #2 
	BL PB_edgecp_is_pressed_ASM	//return r2 as result
	pop {LR}
	CMP R2, #0X1
	BNE BACK_PB_1
	MOV R0,#2		
	PUSH {LR}
	BL HEX_write_ASM //display the value
	POP {LR}
	
	PUSH {LR}
	BL PB_clear_edgecp_ASM		//clear the edge.
	POP {LR}					//this is for second update
	
BACK_PB_1:
	POP {R0}
	BX LR
/////////////////////////////////////////////////////////////	
check_PB_2:
	PUSH {R0}
	MOV R1,R0		//copy the value will be displayed
	//check if edge is high. If edge is high display, otherwise nothing
	push {LR}
	MOV r0, #4 
	BL PB_edgecp_is_pressed_ASM	//return r2 as result
	pop {LR}
	CMP R2, #0X1
	BNE BACK_PB_2
	MOV R0,#4		
	PUSH {LR}
	BL HEX_write_ASM //display the value
	POP {LR}
	
	PUSH {LR}
	BL PB_clear_edgecp_ASM		//clear the edge.
	POP {LR}					//this is for second update
	
BACK_PB_2:
	POP {R0}
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
/////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////
// Sider Switches Driver
// returns the state of slider switches in R0
.equ SW_MEMORY, 0xFF200040
/* The EQU directive gives a symbolic name to a numeric constant,
a register-relative value or a PC-relative value. */
read_slider_switches_ASM:
    LDR R1, =SW_MEMORY
    LDR R0, [R1]
    BX  LR
	
// LEDs Driver
// writes the state of LEDs (On/Off state) in R0 to the LEDs memory location
.equ LED_MEMORY, 0xFF200000
write_LEDs_ASM:
    LDR R1, =LED_MEMORY
    STR R0, [R1]
    BX  LR
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
	LDR R2, =edgecapture_R
	MOV R3, #15
	STR R3, [R2]
	BX LR	
/////////////////////////////////////////////////////////////
enable_PB_INT_ASM: //assume input R0	
	push {r4-r11}
	LDR R2, =interrupt_R
	AND R4,R0,#1	//indices 1 one-hot encoding
	CMP R4,#1
	BNE enable_PB_1
	LDR R4, [R2]	//Value of interrupt register
	AND R4, R4, #0Xfffffffe //11111...1110
	ADD R4,R4,	#1	//make sure the first bit is 1
	STR R4, [R2]
enable_PB_1:
	AND R4,R0,#2 //0010
	CMP R4,#2
	BNE enable_PB_2
	LDR R4, [R2]	//Value of interrupt register
	AND R4, R4, #0Xfffffffd //11111...1101
	ADD R4,R4,#2	//make sure the second bit is 1
	STR R4, [R2]
enable_PB_2:	
	AND R4,R0,#4 //0010
	CMP R4,#4
	BNE enable_PB_3
	LDR R4, [R2]	//Value of interrupt register
	AND R4, R4, #0Xfffffffb //11111...1011
	ADD R4,R4,#4	//make sure the third bit is 1
	STR R4, [R2]
enable_PB_3:	
	AND R4,R0,#8 //1000
	CMP R4,#8
	BNE back_enable_PB_3
	LDR R4, [R2]	//Value of interrupt register
	AND R4, R4, #0Xfffffff7 //11111...0111
	ADD R4,R4,#8	//make sure the fourth bit is 1
	STR R4, [R2]
back_enable_PB_3:	
	POP {R4-R11}
	BX LR	
/////////////////////////////////////////////////////////////
disable_PB_INT_ASM:
	push {r4-r11}
	LDR R2, =interrupt_R
	AND R4,R0,#1	//indices 1 one-hot encoding
	CMP R4,#0
	BNE disable_PB_1
	LDR R4, [R2]	//Value of interrupt register
	AND R4, R4, #0Xfffffffe //11111...1110
	STR R4, [R2]
disable_PB_1:
	AND R4,R0,#2 //0010
	CMP R4,#0
	BNE enable_PB_2
	LDR R4, [R2]	//Value of interrupt register
	AND R4, R4, #0Xfffffffd //11111...1101
	STR R4, [R2]
disable_PB_2:	
	AND R4,R0,#4 //0100
	CMP R4,#0
	BNE disable_PB_3
	LDR R4, [R2]	//Value of interrupt register
	AND R4, R4, #0Xfffffffb //11111...1011
	STR R4, [R2]
disable_PB_3:	
	AND R4,R0,#8 //1000
	CMP R4,#0
	BNE back_disable_PB_3
	LDR R4, [R2]	//Value of interrupt register
	AND R4, R4, #0Xfffffff7 //11111...0111
	STR R4, [R2]
back_disable_PB_3:	
	POP {R4-R11}
	BX LR	
///////////////////////////////////////////////////////
///////////////////////////////////////////////////////

	

/////////////////////////////////////////////////////////////
//HEX_3456: 00ff-ffff, ff00-ffff, ffff-00ff, ffff-ff00
//HEX_12:ffff-00ff, ffff-ff00
// use AND operation to turn-off
HEX_clear_ASM:
	push {r4-r11}
	LDR R1, =HEX_3210	//3,4,5,6 HEX
	LDR R6, [R1]		//value in register
	
	MOV R2, #0Xffffff00 		//leftmost
	MOV R3, #0Xffff00ff	//SECOND
	MOV R4, #0Xff00ffff	//third from left
	MOV R5, #0xffffff	//fourth from left is 00ff-ffff
	
HEX_6_clear:			//if  encoding find this 0001
	AND R7, R0, #1
	CMP R7, #1
	BNE HEX_5_clear		// not such encoding scheme
	AND R6,R6,R2		//
	STR R6, [R1]		//update display
	B HEX_5_clear
HEX_5_clear:			// 0010
	AND R7, R0, #2
	CMP R7, #2
	BNE HEX_4_clear
	AND R6,R6,R3		
	STR R6, [R1]
	B HEX_4_clear
HEX_4_clear:				//0100
	AND R7, R0, #4
	CMP R7, #4
	BNE HEX_3_clear
	AND R6,R6,R4		
	STR R6, [R1]
	B HEX_3_clear
HEX_3_clear:				//1000
	AND R7, R0, #8
	CMP R7, #8
	BNE HEX_2_clear
	AND R6,R6,R5		
	STR R6, [R1]
	B HEX_2_clear
	
//going to a next memory address, HEX divide into 2 memory address
HEX_2_clear:
	ADD R1, R1, #0X10
	LDR R6, [R1] 		// address 0xFF200030
	AND R7, R0, #0x00000010
	CMP R7,  #0x00000010
	BNE HEX_1_clear
	AND R6,R6,R2		
	STR R6, [R1]	
	B HEX_1_clear

HEX_1_clear:
	AND R7, R0, #0x00000020
	CMP R7,  #0x00000020
	BNE back_clear 
	AND R6,R6,R3		
	STR R6, [R1]
	B back_clear

back_clear:
	POP {R4-R11}
	BX LR

//////////////////////////////////////////////////////////////
HEX_flood_ASM:
	PUSH {R4-R11}
	LDR R1, =HEX_3210
	LDR R8, =HEX_54
	MOV R2, #127 //to make all segments on 6th
	LSL R3,R2,#8	//5th
	LSL R4,R3,#8	//4th
	LSL R5,R4,#8	//3th
	MOV R6,#0
	MOV R9,#0
	
HEX_6:				//if  encoding find this 0001
	AND R7, R0, #1	// if result of R0& 1 is 1, there is such encoding
	CMP R7, #1
	BNE HEX_5		// not such encoding scheme
	ADD R6,R6,R2
	B HEX_5
HEX_5:				// 0010
	AND R7, R0, #2
	CMP R7, #2
	BNE HEX_4
	ADD R6,R6,R3
	B HEX_4
HEX_4:				//0100
	AND R7, R0, #4
	CMP R7, #4
	BNE HEX_3
	ADD R6,R6,R4
	B HEX_3
HEX_3:				//1000
	AND R7, R0, #8
	CMP R7, #8
	BNE HEX_2
	ADD R6,R6,R5
	B HEX_2
	
//going to a next memory address, HEX divide into 2 memory address
HEX_2:
	STR R6, [R1]
	AND R7, R0, #0x00000010
	CMP R7,  #0x00000010
	BNE HEX_1
	ADD R9,R9,R2
	B HEX_1

HEX_1:
	AND R7, R0, #0x00000020
	CMP R7,  #0x00000020
	BNE back 
	ADD R9,R9,R3
	B back

back:
	STR R9, [R8]
	POP {R4-R11}
	BX LR
///////////////////////////////////////////////////////	
	
HEX_write_ASM:
	push {r4-r11}
	LDR R2, =HEX_3210
	LDR R3, [R2]		//value of hex register, where to update
	LDR R6, [R2,#0X10]	//second hex register
	LDR R4, =HEX_CHARA  //table of hex-char
	LSL R1,R1, #2 //scale by 4
	ADD R4,R4,R1 //point to the hex character of R1,  R1 now is useless
	LDR R1, [R4] //HEX character
	
HEX_0_write:
	AND R5, R0, #1		//check encoding
	CMP R5, #1			
	BNE HEX_1_write
	AND R3, R3, #0xffffff00 //clear this hex
	ADD R3, R3, R1		//R1 is the character to display
	STR R3, [R2]
	B HEX_1_write
	
HEX_1_write:
	LSL R1, R1, #8 //shift to the correct hex position
	AND R5, R0, #2
	CMP R5,#2
	BNE HEX_2_write
	AND R3, R3, #0XFFFF00FF //CLEAR
	
	ADD R3, R3, R1
	STR R3, [R2]
	B HEX_2_write

HEX_2_write:
	LSL R1, R1, #8 //shift to the correct hex position
	AND R5, R0, #4
	CMP R5,#4
	BNE HEX_3_write
	AND R3, R3, #0XFF00FFFF //CLEAR
	ADD R3, R3, R1
	STR R3, [R2]
	B HEX_3_write
HEX_3_write:
	LSL R1, R1, #8 //shift to the correct hex position
	AND R5, R0, #8
	CMP R5,#8
	BNE HEX_4_write
	AND R3, R3, #0XFFFFFF //CLEAR, 00FF-FFFF
	ADD R3, R3, R1
	STR R3, [R2]
	B HEX_4_write
HEX_4_write:
	LSR R1, R1, #24 //shift back to the 0000-00xx
	AND R5, R0, #0X10
	CMP R5,#0X10
	BNE HEX_5_write
	AND R6, R6, #0XFFFFFF00 //CLEAR
	ADD R6, R6, R1
	STR R6, [R2,#0X10]
	B HEX_5_write
HEX_5_write:
	LSL R1, R1, #8 //shift to the correct hex position
	AND R5, R0, #0X20
	CMP R5,#0X20
	BNE BACK_WRITE
	AND R6, R6, #0XFFFF00FF //CLEAR
	ADD R6, R6, R1
	STR R6, [R2,#0X10]
	B BACK_WRITE

BACK_WRITE:
	pop {r4-r11}
	BX LR		
	