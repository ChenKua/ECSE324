.section .vectors, "ax"
B _start
B SERVICE_UND       // undefined instruction vector
B SERVICE_SVC       // software interrupt vector
B SERVICE_ABT_INST  // aborted prefetch vector
B SERVICE_ABT_DATA  // aborted data vector
.word 0 // unused vector
B SERVICE_IRQ       // IRQ interrupt vector
B SERVICE_FIQ       // FIQ interrupt vector

PB_int_flag :
    .word 0x0
	
tim_int_flag :
    .word 0x0
	
HEX_CHARA: .word 0x3f,0x6,0x5b, 0x4F,0x66, 0x6d, 0x7d,0x7,0x7f,0x67,0x77,0x7c,0x39,0x5e,0x79,0x71

Time_Data: .word 0,0,0,0,0,0		//this correspond to mili second/sec/minute

//timer
.equ LOAD, 0xFFFEC600
.equ CONTROL, 0xFFFEC608
.equ INTERRUPT, 0xFFFEC60C	
//push button
.equ data_R, 0xFF200050
.equ interrupt_R, 0xFF200058
.equ edgecapture_R, 0xFF20005C
.equ HEX_3210, 0xFF200020
.equ HEX_54, 0xFF200030
	
.text
.global _start

_start:
	BL Initial_Hex
	BL ARM_TIM_config_ASM
    /* Set up stack pointers for IRQ and SVC processor modes */
    MOV        R1, #0b11010010      // interrupts masked, MODE = IRQ
    MSR        CPSR_c, R1           // change to IRQ mode
    LDR        SP, =0xFFFFFFFF - 3  // set IRQ stack to A9 onchip memory
    /* Change to SVC (supervisor) mode with interrupts disabled */
    MOV        R1, #0b11010011      // interrupts masked, MODE = SVC
    MSR        CPSR, R1             // change to supervisor mode
    LDR        SP, =0x3FFFFFFF - 3  // set SVC stack to top of DDR3 memory
    BL     CONFIG_GIC           // configure the ARM GIC
    // To DO: write to the pushbutton KEY interrupt mask register
    // Or, you can call enable_PB_INT_ASM subroutine from previous task
    // to enable interrupt for ARM A9 private timer, use ARM_TIM_config_ASM subroutine
    LDR        R0, =0xFF200050      // pushbutton KEY base address
    MOV        R1, #0xF             // set interrupt mask bits
    STR        R1, [R0, #0x8]       // interrupt mask register (base + 8)
    // enable IRQ interrupts in the processor
    MOV        R0, #0b01010011      // IRQ unmasked, MODE = SVC
    MSR        CPSR_c, R0
IDLE:
	LDR R0, =PB_int_flag
	LDR R6, [R0]
	LDR R0, =tim_int_flag
	LDR R7, [R0]
	LDR R0, =CONTROL
	LDR R8, [R0]

    B IDLE // This is where you write your objective task
			
	//Honestly, I dont see why we need to write out objective task here
	//becuase I will handle everything during the interrupt.
	//Isn't this the purpose of interrupt? To handle everything during interrupt
	
	
	
SERVICE_UND:
    B SERVICE_UND
/*--- Software interrupts ------------------------------------------- */
SERVICE_SVC:
    B SERVICE_SVC
/*--- Aborted data reads -------------------------------------------- */
SERVICE_ABT_DATA:
    B SERVICE_ABT_DATA
/*--- Aborted instruction fetch ------------------------------------- */
SERVICE_ABT_INST:
    B SERVICE_ABT_INST
/*--- IRQ ----------------------------------------------------------- */
SERVICE_IRQ:
    PUSH {R0-R7, LR}
/* Read the ICCIAR from the CPU Interface */
    LDR R4, =0xFFFEC100
    LDR R5, [R4, #0x0C] // read from ICCIAR

/* To Do: Check which interrupt has occurred (check interrupt IDs)
   Then call the corresponding ISR
   If the ID is not recognized, branch to UNEXPECTED
   See the assembly example provided in the De1-SoC Computer_Manual on page 46 */

Timer_check:
	CMP R5,#29
	BNE Pushbutton_check	
	PUSH {LR}
	BL ARM_TIM_ISR
	POP {LR}
	B EXIT_IRQ
Pushbutton_check:
    CMP R5, #73
UNEXPECTED:
    BNE EXIT_IRQ      // if not recognized, stop here
    BL KEY_ISR

//Timer_check:
//	CMP R5,#29
//	BNE Pushbutton_check
//	BL ARM_TIM_ISR
	
EXIT_IRQ:
/* Write to the End of Interrupt Register (ICCEOIR) */
    STR R5, [R4, #0x10] // write to ICCEOIR
    POP {R0-R7, LR}
SUBS PC, LR, #4
/*--- FIQ ----------------------------------------------------------- */
SERVICE_FIQ:
    B SERVICE_FIQ
	
CONFIG_GIC:
    PUSH {LR}
/* To configure the FPGA KEYS interrupt (ID 73):
* 1. set the target to cpu0 in the ICDIPTRn register
* 2. enable the interrupt in the ICDISERn register */
/* CONFIG_INTERRUPT (int_ID (R0), CPU_target (R1)); */
/* To Do: you can configure different interrupts
   by passing their IDs to R0 and repeating the next 3 lines */
    MOV R0, #73            // KEY port (Interrupt ID = 73)
    MOV R1, #1             // this field is a bit-mask; bit 0 targets cpu0
    BL CONFIG_INTERRUPT
	
	MOV R0, #29				//TIMER ID = 29
    MOV R1, #1          
    BL CONFIG_INTERRUPT
	
/* configure the GIC CPU Interface */
    LDR R0, =0xFFFEC100    // base address of CPU Interface
/* Set Interrupt Priority Mask Register (ICCPMR) */
    LDR R1, =0xFFFF        // enable interrupts of all priorities levels
    STR R1, [R0, #0x04]
/* Set the enable bit in the CPU Interface Control Register (ICCICR).
* This allows interrupts to be forwarded to the CPU(s) */
    MOV R1, #1
    STR R1, [R0]
/* Set the enable bit in the Distributor Control Register (ICDDCR).
* This enables forwarding of interrupts to the CPU Interface(s) */
    LDR R0, =0xFFFED000
    STR R1, [R0]
    POP {PC}

/*
* Configure registers in the GIC for an individual Interrupt ID
* We configure only the Interrupt Set Enable Registers (ICDISERn) and
* Interrupt Processor Target Registers (ICDIPTRn). The default (reset)
* values are used for other registers in the GIC
* Arguments: R0 = Interrupt ID, N
* R1 = CPU target
*/
CONFIG_INTERRUPT:
    PUSH {R4-R5, LR}
/* Configure Interrupt Set-Enable Registers (ICDISERn).
* reg_offset = (integer_div(N / 32) * 4
* value = 1 << (N mod 32) */
    LSR R4, R0, #3    // calculate reg_offset
    BIC R4, R4, #3    // R4 = reg_offset
    LDR R2, =0xFFFED100
    ADD R4, R2, R4    // R4 = address of ICDISER
    AND R2, R0, #0x1F // N mod 32
    MOV R5, #1        // enable
    LSL R2, R5, R2    // R2 = value
/* Using the register address in R4 and the value in R2 set the
* correct bit in the GIC register */
    LDR R3, [R4]      // read current register value
    ORR R3, R3, R2    // set the enable bit
    STR R3, [R4]      // store the new register value
/* Configure Interrupt Processor Targets Register (ICDIPTRn)
* reg_offset = integer_div(N / 4) * 4
* index = N mod 4 */
    BIC R4, R0, #3    // R4 = reg_offset
    LDR R2, =0xFFFED800
    ADD R4, R2, R4    // R4 = word address of ICDIPTR
    AND R2, R0, #0x3  // N mod 4
    ADD R4, R2, R4    // R4 = byte address in ICDIPTR
/* Using register address in R4 and the value in R2 write to
* (only) the appropriate byte */
    STRB R1, [R4]
    POP {R4-R5, PC}
	
	
KEY_ISR:
    LDR R0, =0xFF200050    // base address of pushbutton KEY port
    LDR R1, [R0, #0xC]     // read edge capture register
    MOV R2, #0xF
    STR R2, [R0, #0xC]     // clear the interrupt
	LDR R2, =PB_int_flag
    					   //LDR R0, =0xFF200020    // based address of HEX display
CHECK_KEY0:
    MOV R3, #0x1
    ANDS R3, R3, R1        // check for KEY0
    BEQ CHECK_KEY1
	//write edge regsiter to  PB_int_flag
	STR R3, [R2]
	PUSH {LR}
	BL PB_clear_edgecp_ASM
	POP {LR}
	PUSH {LR}
	BL ARM_TIM_START
	POP {LR}
    B END_KEY_ISR
CHECK_KEY1:
    MOV R3, #0x2
    ANDS R3, R3, R1        
    BEQ CHECK_KEY2
    STR R3, [R2]			
    PUSH {LR}
	BL PB_clear_edgecp_ASM
	POP {LR}
	PUSH {LR}
	BL ARM_TIM_STOP			//stop the timer
	POP {LR}
    B END_KEY_ISR
CHECK_KEY2:
    MOV R3, #0x4
    ANDS R3, R3, R1        
    BEQ IS_KEY3
   	STR R3, [R2]
	PUSH {LR}
	BL PB_clear_edgecp_ASM
	POP {LR}
	push {lr}
	BL ARM_TIM_RESET
	POP {LR}
    B END_KEY_ISR  
IS_KEY3:
    MOV R3,#0X8
    STR R3, [R2]
	PUSH {LR}
	BL PB_clear_edgecp_ASM
	POP {LR}
END_KEY_ISR:
    BX LR

//////////////////////////////////////////////////////////////	

ARM_TIM_ISR:
	LDR R1, =INTERRUPT	
	MOV R0, #0X1
	STR R0, [R1]	//clear interrupt
	LDR R1, =tim_int_flag
	STR R0, [R1]
	push {LR}
	bl INCREASE
	pop {lr}
	BX LR

ARM_TIM_STOP:
	PUSH {R4-R5}
	LDR R4, =CONTROL
	LDR R5, [R4]		//R1 is now the value of control register
	AND R5, R5, #0XFFFFFFFE	//clear the E bit first bit by 1110 
	STR R5, [R4]
	pop {r4-r5}
	BX LR
	
ARM_TIM_START:
	PUSH {R4-R5}
	LDR R4, =CONTROL
	LDR R5, [R4]		//R1 is now the value of control register
	AND R5, R5, #0XFFFFFFFE	//clear the E bit first bit by 1110 
	ADD R5,R5,#1
	STR R5, [R4]
	pop {r4-r5}
	BX LR
	
ARM_TIM_RESET:
	PUSH {R0-R1}
	
	LDR R0, =Time_Data
	MOV R1,#0
 	STR R1, [R0]
	STR R1, [R0,#4]
	STR R1, [R0,#8]
	STR R1, [R0,#12]
	STR R1, [R0,#16]
	STR R1, [R0,#20]
	
	MOV R0,#127
	MOV R1,#0
	PUSH {LR}
	BL HEX_write_ASM
	POP {LR}
	
	
	PUSH {LR}
	BL ARM_TIM_START
	POP {LR}
	
	POP {R0-R1}
	BX LR
//////////////////////////////////////////////////////////////	

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

/////////////////////////////////////////////////////////////

PB_clear_edgecp_ASM:
	push {R2,R3}
	LDR R2, =edgecapture_R
	MOV R3, #15
	STR R3, [R2]
	pop {R2,R3}
	BX LR

/////////////////////////////////////////////////////////////

ARM_TIM_config_ASM:
	LDR R0, =#0x1E8480	//200M for 1 sec, 2M for 10 million second
	LDR R2, =LOAD		
	STR R0, [R2]
	LDR R2, =CONTROL
	LDR R3, [R2]		//R1 is now the value of control register
	AND R3, R1, #0XFFFFFFF8	//clear the first three bits by AND 1111-1111-1000
	ADD R3, R1, #0X6 //ADD 0110 make sure first three bits are 110 
	STR R3, [R2]		//not strat yet
	BX LR	

/////////////////////////////////////////////////////////////

Initial_Hex:
	MOV R0,#127
	MOV R1,#0
	PUSH {LR}
	BL HEX_write_ASM
	POP {LR}
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
	
//increase the value of each hex//////////
INCREASE:		
	//Store the value of time in array Time_date
	
HEX_0_INCREASE:
	PUSH {R0-R1}
	LDR R0,=Time_Data		//staring of array	0,0,0,0,0,0
	LDR R1, [R0]
	ADD R1,R1, #1
	CMP R1,#10
	BLT NO_CARRY_0		//NOT carry
	
	SUB R1, R1,#10		//if r1 is 10 then mode r1 by 10
	STR R1, [R0]	//store back the value
	PUSH {LR}
	MOV R0, #1
	BL HEX_write_ASM	//update HEX_0
	POP {LR}
	B HEX_1_INCREASE	//there is carry!
	
NO_CARRY_0:		//JUST update 1 hex
	STR R1, [R0]
	PUSH {LR}
	MOV R0, #1
	BL HEX_write_ASM
	POP {LR}
	B BACK_INCREASE
			
HEX_1_INCREASE:		
	LDR R0,=Time_Data
	LDR R1, [R0,#4]		//Second element in the array
	ADD R1, R1, #1
	CMP R1, #10
	BLT NO_CARRY_1
	
	SUB R1, R1,#10
	STR R1, [R0,#4]
	PUSH {LR}
	MOV R0, #2
	BL HEX_write_ASM
	POP {LR}
	B HEX_2_INCREASE
NO_CARRY_1:
	STR R1, [R0,#4]
	PUSH {LR}
	MOV R0, #2
	BL HEX_write_ASM
	POP {LR}
	B BACK_INCREASE
	
HEX_2_INCREASE:
	LDR R0,=Time_Data
	LDR R1, [R0,#8]
	ADD R1, R1, #1
	CMP R1, #10
	BLT NO_CARRY_2
	
	SUB R1, R1,#10
	STR R1, [R0,#8]
	PUSH {LR}
	MOV R0, #4
	BL HEX_write_ASM
	POP {LR}
	B HEX_3_INCREASE
NO_CARRY_2:
	STR R1, [R0,#8]
	PUSH {LR}
	MOV R0, #4
	BL HEX_write_ASM
	POP {LR}
	B BACK_INCREASE
	
HEX_3_INCREASE:
	LDR R0, =Time_Data
	LDR R1, [R0,#12]
	ADD R1, R1, #1
	CMP R1, #6
	BLT NO_CARRY_3
	
	SUB R1, R1,#6
	STR R1, [r0,#12]
	PUSH {LR}
	MOV R0, #8
	BL HEX_write_ASM
	POP {LR}
	B HEX_4_INCREASE
	
NO_CARRY_3:
	STR R1, [r0,#12]
	PUSH {LR}
	MOV R0, #8
	BL HEX_write_ASM
	POP {LR}
	B BACK_INCREASE
	
	
HEX_4_INCREASE:
	ldr r0,=Time_Data
	LDR R1, [r0,#16]
	ADD R1, R1, #1
	CMP R1, #10
	BLT NO_CARRY_4
	
	SUB R1, R1,#10
	STR R1, [r0,#16]
	PUSH {LR}
	MOV R0, #0X10
	BL HEX_write_ASM
	POP {LR}
	B HEX_5_INCREASE
NO_CARRY_4:
	STR R1, [r0,#16]
	PUSH {LR}
	MOV R0, #0X10
	BL HEX_write_ASM
	POP {LR}
	B BACK_INCREASE
	
	
HEX_5_INCREASE:
	LDR R0, =Time_Data
	LDR R1, [R0,#20]
	ADD R1, R1, #1
	CMP R1, #10
	BLT NO_CARRY_5
	
	SUB R1, R1,#10
	STR R1, [R0,#20]
	PUSH {LR}
	MOV R0, #0X20
	BL HEX_write_ASM
	POP {LR}
	B BACK_INCREASE
NO_CARRY_5:
	STR R1, [R0,#20]
	PUSH {LR}
	MOV R0, #0X20
	BL HEX_write_ASM
	POP {LR}
	B BACK_INCREASE

BACK_INCREASE:
	pop {r0-r1}
	BX LR

	