;***********************************************************
;*
;*	ECE 375: Lab 5 - Simple Interrupts
;*
;*	Enter the description of the program here
;*
;*
;***********************************************************
;*
;*	 Author: Anton Bilbaeno, Andrew Sunada
;*	   Date: 2/2/11
;*
;***********************************************************

.include "m128def.inc"			; Include definition file

;***********************************************************
;*	Internal Register Definitions and Constants
;***********************************************************
.def	mpr = r16				; Multipurpose register 
.def	waitcnt = r17
.def 	ilcnt = r18
.def	olcnt = r19
.def	zero = r2				; Zero register, set to zero in INIT, useful for calculations
.def	cornerCheck1=r30		;Set checker for corner trap
.def	cornerCheck2=r31		;Set checker for corner trap

; Constants for interactions such as
.equ	WskrR = 1				; Right Whisker Input Bit
.equ	WskrL = 0				; Left Whisker Input Bit
.equ	WTime = 50				; Time to wait in wait loop


; Using the constants from above, create the movement 
; commands, Forwards, Backwards, Stop, Turn Left, and Turn Right
.equ 	EngEnR = 4
.equ	EngEnL = 7
.equ 	EngDirR = 5
.equ 	EngDirL = 6

.equ	MoveFwd = (1<<EngDirR|1<<EngDirL)
.equ 	MoveBack = $00
.equ	TurnR = (1<<EngDirL)
.equ	TurnL = (1<<EngDirR)

.equ 	Halt = (1<<EngEnR|1<<EngEnL)

;***********************************************************
;*	Start of Code Segment
;***********************************************************
.cseg							; Beginning of code segment

;-----------------------------------------------------------
; Interrupt Vectors
;-----------------------------------------------------------
.org	$0000					; Reset interrupt	
		rjmp 	INIT		

; Set up the interrupt vectors for the interrupts

.org	$0002
		rcall		HitRight
		reti

.org	$0004		
		rcall		HitLeft
		reti

.org	$0046					; End of Interrupt Vectors

;-----------------------------------------------------------
; Program Initialization
;-----------------------------------------------------------
INIT:	; The initialization routine
		; Initialize Stack Pointer
		ldi		mpr, HIGH(RAMEND)
		out		SPH, mpr
		ldi		mpr, LOW(RAMEND)
		out		SPL, mpr

		clr		zero

		; Initialize Port B for output
		ldi 	mpr, (1<<EngEnL)|(1<<EngEnR)|(1<<EngDirR)|(1<<EngDirL)
		out		DDRB, mpr
		ldi		mpr, $00
		out		PORTB, mpr

		; Initialize Port D for input
		ldi 	mpr, (0<<WskrL)|(0<<WskrR)
		out		DDRD, mpr
		ldi		mpr, (1<<WskrL)|(1<<WskrR)
		out		PORTD, mpr

		; Initialize external interrupts
		; Set the Interrupt Sense Control to low level detection
		ldi		mpr, (0<<ISC11)|(0<<ISC10)|(0<<ISC01)|(0<<ISC00)
		sts 	EICRA, mpr
		ldi		mpr, $00
		out		EICRB, mpr

		; NOTE: must initialize both EICRA and EICRB

		; Set the External Interrupt Mask
		ldi		mpr, (1<<INT0)|(1<<INT1)
		out		EIMSK, mpr

		ldi		cornerCheck1, 85
		ldi		cornerCheck2, 1

		; Turn on interrupts
		sei
		; NOTE: This must be the last thing to do in the INIT function

;-----------------------------------------------------------
; Main Program
;-----------------------------------------------------------
MAIN:	; The Main program

		; Send command to Move Robot Forward
		ldi		mpr, MoveFwd
		out		PORTB, mpr

		; That is all you should have in MAIN

		rjmp	MAIN			; Create an infinite while loop to signify the 
								; end of the program.

;***********************************************************
;*	Functions and Subroutines
;***********************************************************

;-----------------------------------------------------------
; You will probably need several functions, one to handle the 
; left whisker interrupt, one to handle the right whisker 
; interrupt, and maybe a wait function
;------------------------------------------------------------

HitRight:

		push 	mpr
		push 	waitcnt
		in		mpr, SREG
		push 	mpr
		cli

		; Move backwards for a second
		ldi		mpr, MoveBack
		out		PORTB, mpr
		ldi		waitcnt, WTime
		rcall 	Wait

		; Turn left for a second
		ldi		mpr, TurnL
		out		PORTB, mpr
		ldi		waitcnt, WTime
		rcall	Wait

		pop		mpr
		out 	SREG, mpr
		pop 	waitcnt
		pop 	mpr
		sei

		ret

HitLeft:

		push 	mpr
		push 	waitcnt
		in		mpr, SREG
		push 	mpr
		cli

		; Move backwards for a second
		ldi		mpr, MoveBack
		out		PORTB, mpr
		ldi		waitcnt, WTime
		rcall 	Wait

		; Turn right for a second
		ldi		mpr, TurnR
		out		PORTB, mpr
		ldi		waitcnt, WTime
		rcall	Wait

		pop		mpr
		out 	SREG, mpr
		pop 	waitcnt
		pop 	mpr
		sei
		
		ret

		
Wait:

Loop:
		ldi		r19, 224

OLoop:
		ldi		r18, 237

ILoop:
		dec		r18
		brne 	ILoop
		dec		r19
		brne	OLoop
		dec		waitcnt
		brne	Loop

		ret

;***********************************************************
;*	Stored Program Data
;***********************************************************

; Enter any stored data you might need here

;***********************************************************
;*	Additional Program Includes
;***********************************************************
; There are no additional file includes for this program
