;***********************************************************
;*
;*	ECE 375: Lab 3 
;*
;*	Data Manipulation & LCD Display
;*
;***********************************************************
;*
;*	 Authors: Anton Bilbaeno, Jake Cray
;*	    Date: 1/19/10
;*
;***********************************************************

.include "m128def.inc"			; Include definition file

;***********************************************************
;*	Internal Register Definitions and Constants
;***********************************************************
.def	mpr = r16				; Multipurpose register required for LCD Driver
.def 	ReadCnt = r23;

;***********************************************************
;*	Start of Code Segment
;***********************************************************
.cseg							; Beginning of code segment

;-----------------------------------------------------------
; Interrupt Vectors
;-----------------------------------------------------------
.org	$0000					; Beginning of IVs
		rjmp INIT				; Reset interrupt

.org	$0046					; End of Interrupt Vectors

;-----------------------------------------------------------
; Program Initialization
;-----------------------------------------------------------
INIT:							; The initialization routine
		; Initialize stack pointer
		ldi		mpr, HIGH(RAMEND)
		out		SPH, mpr
		ldi		mpr, LOW(RAMEND)
		out		SPL, mpr
		
		; Initialize Port D for input

		; Initialize LCD Display
		rcall 	LCDInit

		; Move strings from Program Memory to Data Memory
								; A while loop will go here

		; NOTE that there is no RET or RJMP from INIT, this is
		; because the next instruction executed is the first for
		; the main program



; Init line 1 variable registers

		ldi		ZL, low(TXT0<<1)
		ldi		ZH, high(TXT0<<1)
		ldi		YL, low(LCDLn1Addr)
		ldi		YH, high(LCDLn1Addr)
		ldi		ReadCnt, LCDMaxCnt

INIT_LINE1:

		lpm		mpr, Z+			; Read Program memory
		st		Y+, mpr			; Store into memory
		dec		ReadCnt			; Decrement Read Counter
		brne	INIT_LINE1		; Continue until all data is read
	//	rcall 	LCDWrLn1		; WRITE LINE 1 DATA


; Init line 2 variable registers


		ldi		ZL, low(TXT1<<1);
		ldi		ZH, high(TXT1<<1);
		ldi		YL, low(LCDLn2Addr)
		ldi		YH, high(LCDLn2Addr)
		ldi		ReadCnt, LCDMaxCnt

INIT_LINE2:

		lpm		mpr, Z+			; Read Program memory
		st		Y+, mpr			; Store into memory
		dec		ReadCnt			; Decrement Read Counter
		brne	INIT_LINE2		; Continue until all data is read
	//	rcall 	LCDWrLn2		; WRITE LINE 2 DATA

;-----------------------------------------------------------
; Main Program
;-----------------------------------------------------------
MAIN:							; The Main program
		; Display the strings on the LCD Display


		rcall 	LCDWrite		; An RCALL statement
		
		
		
		rjmp	MAIN			; jump back to main and create an infinite
								; while loop.  Generally, every main program is an
								; infinite while loop, never let the main program
								; just run off

;***********************************************************
;*	Functions and Subroutines
;***********************************************************

;-----------------------------------------------------------
; Func: Template function header
; Desc: Cut and paste this and fill in the info at the 
;		beginning of your functions
;-----------------------------------------------------------		

;***********************************************************
;*	Stored Program Data
;***********************************************************

;----------------------------------------------------------
; An example of storing a string, note the preceeding and
; appending labels, these help to access the data
;----------------------------------------------------------
TXT0:
.DB		"Anton B         "		; Storing the string in Program Memory

TXT1:
.DB 	"Hello World     "

;***********************************************************
;*	Additional Program Includes
;***********************************************************
.include "LCDDriver.asm"		; Include the LCD Driver
