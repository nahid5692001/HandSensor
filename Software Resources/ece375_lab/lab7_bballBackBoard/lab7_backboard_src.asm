;***********************************************************
;*
;*	ECE 375: Lab 7 - Arcade Basketball
;*	
;*	Backboard Source Code
;*
;***********************************************************
;*
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
.def 	data = r24
.def	correctID = r22
.def	recCheck = r21
.def	sent = r25

; Constants for interactions such as
.equ	WskrR = 0				; Right Whisker Input Bit
.equ	WskrL = 1				; Left Whisker Input Bit
.equ	WTime = 25				; Time to wait in wait loop

.equ	HitID = 0b00110011

;***********************************************************
;*	Start of Code Segment
;***********************************************************
.cseg							; Beginning of code segment

;-----------------------------------------------------------
; Interrupt Vectors
;-----------------------------------------------------------
.org	$0000					; Reset interrupt	
		rjmp 	INIT

/*
.org	$0002
		rcall	Hit0
		reti

.org	$0004		
		rcall	Hit1
		reti
		
.org	$000A
		rcall	Hit0
		reti
		
.org	$000C
		rcall	Hit1
		reti		
*/

.org	$0046					; End of Interrupt Vectors

;-----------------------------------------------------------
; Program Initialization
;-----------------------------------------------------------
INIT:	
		; The initialization routine
		; Initialize Stack Pointer
		ldi		mpr, HIGH(RAMEND)
		out		SPH, mpr
		ldi		mpr, LOW(RAMEND)
		out		SPL, mpr

		clr		zero

		; Set baud rate at 2400bps
		ldi mpr, high(416)		// $01A0 = 416 for U2X = 0
		sts UBRR1H, mpr
		ldi mpr, low(416)
		sts UBRR1L, mpr

		;Enable receiver and enable receive interrupts
		ldi mpr, (1<<TXEN1)
		sts UCSR1B, mpr

		;Set frame format: 2stop bit, 8data bits
		ldi mpr, (1<<USBS1)|(1<<UCSZ10)|(1<<UCSZ11);|(0<<UMSEL1)
		sts UCSR1C, mpr

		; Initialize Port D for input
		ldi 	mpr, 0b11001000				; pin 4,5,1,0 whiskers. pin 2 rx, pin 3 tx output
		out		DDRD, mpr
		ldi		mpr, 0b11110011
		out		PORTD, mpr

		; Initialize Port B
		ldi 	mpr, 0b11111111
		out 	DDRB, mpr
		ldi 	mpr, 0b00000000
		out		PORTB, mpr
		
		
		; Initialize external interrupts
		; Set the Interrupt Sense Control for whiskers to RISING EDGE
		ldi		mpr, (1<<ISC01)|(0<<ISC00)|(1<<ISC11)|(0<<ISC10)
		sts 	EICRA, mpr
		ldi		mpr, (0<<ISC51)|(1<<ISC50)|(0<<ISC41)|(1<<ISC40)
		out		EICRB, mpr

		; NOTE: must initialize both EICRA and EICRB

		; Set the External Interrupt Mask
		ldi		mpr, (1<<INT0)|(1<<INT1)|(1<<INT4)|(1<<INT5)
		out		EIMSK, mpr

		sei

;-----------------------------------------------------------
; Main Program
;-----------------------------------------------------------
MAIN:	; The Main program
		
		
		; Constantly check if pin hit
		; PIN 0
		in			mpr, PIND
		cpi 		mpr, 0b11111110		;compare to 0's
		breq 		Hit0					;if what we were looking for then jump

		; PIN 1
		in 			mpr, PIND
		cpi 		mpr, 0b11111101		;compare to 0's
		breq 		Hit1				;if what we were looking for then jump
		
		ldi			waitcnt, WTime
		rcall		Wait

		rjmp		MAIN			; Create an infinite while loop to signify the 
									; end of the program

ReadyCheck: ; infinite loop if UDRE is not set, if UDRE is set, then UDR can be written to
		lds		mpr, UCSR1A
		sbrs 	mpr, UDRE1
					
		rjmp 	ReadyCheck

		ret

Hit0:		
		push 	mpr

		rcall 	ReadyCheck
		ldi		mpr, HitID
		sts		UDR1, mpr


		ldi		mpr, 0b01010101
		out		PORTB, mpr

		pop 	mpr
		

		ret

Hit1:	
		
		push 	mpr

		rcall 	ReadyCheck
		ldi		mpr, HitID
		sts		UDR1, mpr


		ldi		mpr, 0b10101010
		out		PORTB, mpr

		pop 	mpr
		

		ret

Wait:
		push	waitcnt			; Save wait register
		push	ilcnt			; Save ilcnt register
		push	olcnt			; Save olcnt register

Loop:	ldi		olcnt, 224		; load olcnt register
OLoop:	ldi		ilcnt, 237		; load ilcnt register
ILoop:	dec		ilcnt			; decrement ilcnt
		brne	ILoop			; Continue Inner Loop
		dec		olcnt			; decrement olcnt
		brne	OLoop			; Continue Outer Loop
		dec		waitcnt			; Decrement wait 
		brne	Loop			; Continue Wait loop	

		pop		olcnt			; Restore olcnt register
		pop		ilcnt			; Restore ilcnt register
		pop		waitcnt			; Restore wait register
		ret						; Return from subroutine
