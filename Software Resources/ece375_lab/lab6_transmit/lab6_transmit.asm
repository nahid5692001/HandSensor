;***********************************************************
;*
;*	Lab 6: Remote Operated Vehicle
;*
;*	Enter the description of the program here
;*
;*	This is the TRANSMIT skeleton file for Lab 6 of ECE 375
;*
;***********************************************************
;*
;*	 Author: Anton Bilbaeno, Mushfiqur Sarker
;*	 Date: 2/9/11
;*
;***********************************************************

.include "m128def.inc"			; Include definition file

;***********************************************************
;*	Internal Register Definitions and Constants
;***********************************************************
.def	mpr = r16				; Multi-Purpose Register
.def	zero = r2				; Zero flag
.def 	ilcnt = r18
.def	olcnt = r19
.def	waitcnt = r17			; Wait Loop Counter

.equ	EngEnR = 4				; Right Engine Enable Bit
.equ	EngEnL = 7				; Left Engine Enable Bit
.equ	EngDirR = 5				; Right Engine Direction Bit
.equ	EngDirL = 6				; Left Engine Direction Bit

.equ	WTime = 50				; Time to wait in wait loop

; Use these commands between the remote and TekBot
; MSB = 1 thus:
; commands are shifted right by one and ORed with 0b10000000 = $80
.equ	MovFwd =  ($80|1<<(EngDirR-1)|1<<(EngDirL-1))	;0b10110000 Move Forwards Command
.equ	MovBck =  ($80|$00)								;0b10000000 Move Backwards Command
.equ	TurnR =   ($80|1<<(EngDirL-1))					;0b10100000 Turn Right Command
.equ	TurnL =   ($80|1<<(EngDirR-1))					;0b10010000 Turn Left Command
.equ	Halt =    ($80|1<<(EngEnR-1)|1<<(EngEnL-1))		;0b11001000 Halt Command
.equ	Freeze =  ($80|$F8)

.equ	BotID = 0b01100011; Unique XD ID (MSB = 0)
;***********************************************************
;*	Start of Code Segment
;***********************************************************
.cseg							; Beginning of code segment

;-----------------------------------------------------------
; Interrupt Vectors
;-----------------------------------------------------------
.org	$0000					; Beginning of IVs
		rjmp 	INIT			; Reset interrupt


.org	$0046					; End of Interrupt Vectors

;-----------------------------------------------------------
; Program Initialization
;-----------------------------------------------------------
INIT:
		;Stack Pointer (VERY IMPORTANT!!!!)
		ldi		mpr, HIGH(RAMEND)
		out		SPH, mpr
		ldi		mpr, LOW(RAMEND)
		out		SPL, mpr

		clr		zero

		;	Initialize PORTD for buttons
		ldi 	mpr, 0b00001000 ; DDR -> 0 is input except pin 3 output for transmit
		out		DDRD, mpr
		ldi		mpr, 0b11110111	; Set PORTD initially
		out		PORTD, mpr
		
		;	Initialize PORTB for lights
		ldi 	mpr, $00		; DDR -> 1 is output
		out 	DDRB, mpr
		ldi		mpr, $00		; Clear PORTB initally
		out		PORTB, mpr
	
		;USART1
		;Set baudrate at 2400bps
		ldi 	mpr, high(416)		// $01A0 = 416 for U2X = 0
		sts 	UBRR1H, mpr
		ldi 	mpr, low(416)
		sts 	UBRR1L, mpr

		;Enable transmitter
		ldi 	mpr, (1<<TXEN1)
		sts 	UCSR1B, mpr

		;Set frame format: 8data, 2 stop bit
		ldi mpr, (1<<USBS1)|(1<<UCSZ10)|(1<<UCSZ11);|(0<<UMSEL1)
		sts UCSR1C, mpr

		;Other

;-----------------------------------------------------------
; Main Program
;-----------------------------------------------------------
MAIN:	; check for button presses continuously

		/*
		in 			mpr, PIND
		andi 		mpr, 0b01000000	;mask input 
		cpi 		mpr, 0b00000000	;compare to 0's
		breq 		TForward		;if what we were looking for then jump

		in 			mpr, PIND
		andi 		mpr, 0b00100000
		cpi 		mpr, 0b00000000
		breq 		TBack

		in 			mpr, PIND
		andi 		mpr, 0b10000000
		cpi 		mpr, 0b00000000
		breq 		TLeft

		in 			mpr, PIND
		andi 		mpr, 0b00010000
		cpi 		mpr, 0b00000000
		breq 		TRight

		in 			mpr, PIND
		andi 		mpr, 0b00000010
		cpi 		mpr, 0b00000000
		breq 		THalt

		in 			mpr, PIND
		andi 		mpr, 0b00000001
		cpi 		mpr, 0b00000000
		breq 		TFreeze

		*/
		
		in 			mpr, PIND
		cpi 		mpr, 0b10111111	;compare to 0's
		breq 		TForward		;if what we were looking for then jump

		in 			mpr, PIND
		cpi 		mpr, 0b11011111	;compare to 0's
		breq 		TBack		;if what we were looking for then jump

		in 			mpr, PIND
		cpi 		mpr, 0b01111111	;compare to 0's
		breq 		TLeft		;if what we were looking for then jump

		in 			mpr, PIND
		cpi 		mpr, 0b11101111	;compare to 0's
		breq 		TRight		;if what we were looking for then jump

		rjmp 		MAIN

;***********************************************************
;*	Functions and Subroutines
;***********************************************************

ReadyCheck: ; infinite loop if UDRE is not set, if UDRE is set, then UDR can be written to
		lds		mpr, UCSR1A
		sbrs 	mpr, UDRE1		; ****** UCSR1A or UCSR0A? 
								; Use zero because 1 is out of range?
		rjmp 	ReadyCheck

		ret

TForward:
		push 	mpr				; save mpr first

		rcall	ReadyCheck		; wait now until ready to transfer again
		ldi 	mpr, BotID		; send out botID first
		sts 	UDR1, mpr

		rcall	ReadyCheck
		ldi		mpr, MovFwd		; load forward code into MPR and then UDR
		sts		UDR1, mpr

		pop 	mpr

		rjmp 	MAIN

TBack:
		push 	mpr				; save mpr first

		ldi 	mpr, BotID		; send out botID first
		sts 	UDR1, mpr
		rcall	ReadyCheck		; wait now until ready to transfer again

		ldi		mpr, MovBck		; load backward code into MPR and then UDR
		sts		UDR1, mpr
		rcall	ReadyCheck

		pop 	mpr

		rjmp 	MAIN

TLeft:
		push	mpr				; save mpr first

		ldi 	mpr, BotID		; send out botID first
		sts 	UDR1, mpr
		rcall	ReadyCheck		; wait now until ready to transfer again

		ldi		mpr, TurnL		; load left code into MPR and then UDR
		sts		UDR1, mpr
		rcall	ReadyCheck

		pop 	mpr

		rjmp 	MAIN

TRight:
		push mpr				; save mpr first

		ldi 	mpr, BotID		; send out botID first
		sts 	UDR1, mpr
		rcall	ReadyCheck		; wait now until ready to transfer again

		ldi		mpr, TurnR		; load right code into MPR and then UDR
		sts		UDR1, mpr
		rcall	ReadyCheck

		pop 	mpr

		rjmp 	MAIN

THalt:
		push 	mpr				; save mpr first

		ldi 	mpr, BotID		; send out botID first
		sts 	UDR1, mpr
		rcall	ReadyCheck		; wait now until ready to transfer again

		ldi		mpr, Halt		; load halt code into MPR and then UDR
		sts		UDR1, mpr
		rcall	ReadyCheck

		pop 	mpr

		rjmp 	MAIN

TFreeze:
		push 	mpr				; save mpr first

		ldi 	mpr, BotID		; send out botID first
		sts 	UDR1, mpr
		rcall	ReadyCheck		; wait now until ready to transfer again

		ldi		mpr, Freeze		; load freeze code into MPR and then UDR
		sts		UDR1, mpr
		rcall	ReadyCheck

		pop 	mpr

		rjmp 	MAIN

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


;***********************************************************
;*	Stored Program Data
;***********************************************************



;***********************************************************
;*	Additional Program Includes
;***********************************************************
