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


; Use these commands between the remote and TekBot
; MSB = 1 thus:
; commands are shifted right by one and ORed with 0b10000000 = $80
.equ	MovFwd =  ($80|1<<(EngDirR-1)|1<<(EngDirL-1))	;0b10110000 Move Forwards Command
.equ	MovBck =  ($80|$00)								;0b10000000 Move Backwards Command
.equ	TurnR =   ($80|1<<(EngDirL-1))					;0b10100000 Turn Right Command
.equ	TurnL =   ($80|1<<(EngDirR-1))					;0b10010000 Turn Left Command
.equ	Halt =    ($80|1<<(EngEnR-1)|1<<(EngEnL-1))		;0b11001000 Halt Command
.equ	Freeze =   ($80|$F8)
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

		;I/O Ports
		ldi 	mpr, 0b00000000 ; Port D used for input
		out		DDRD, mpr
		ldi		mpr, 0b00000000 ; Set to 0's initially
		out		PORTD, mpr

		;USART1
		;Set baudrate at 2400bps
		ldi mpr, $01		// $01A0 = 416 for U2X = 0
		sts UBRR1H, mpr
		ldi mpr, $A0
		sts UBRR1L, mpr

		;Enable transmitter
		ldi mpr, (1<<TXEN1)
		sts UCSR1B, mpr

		;Set frame format: 8data, 2 stop bit
		ldi mpr, (0<<UCSZ12)|(1<<UCSZ11)|(1<<UCSZ10)|(1<<USBS1)
		sts UCSR1C, mpr

		;Other

;-----------------------------------------------------------
; Main Program
;-----------------------------------------------------------
MAIN:	; check for button presses continuously

		; check for forward
		in 		mpr, PIND
		andi	mpr, 0b10000000
		cpi		mpr, 0b00000000
		breq	TransmitForward;

		; check for backward
		in		mpr, PIND
		andi	mpr, 0b01000000
		cpi		mpr, 0b00000000
		breq 	TransmitBackward;

		; check for left
		in		mpr, PIND
		andi	mpr, 0b00100000
		cpi		mpr, 0b00000000
		breq 	TransmitLeft;

		; check for right
		in		mpr, PIND
		andi	mpr, 0b00010000
		cpi		mpr, 0b00000000
		breq 	TransmitRight;

		; check for halt
		in		mpr, PIND
		andi	mpr, 0b00001000
		cpi		mpr, 0b00000000
		breq 	TransmitHalt;

		; check for freeze
		in		mpr, PIND
		andi	mpr, 0b00000100
		cpi		mpr, 0b00000000
		breq 	TransmitFreeze;
	
		rjmp 	MAIN

;***********************************************************
;*	Functions and Subroutines
;***********************************************************

Transfering: ; infinite loop if UDRE is not set, if UDRE is set, then UDR can be written to
		sbis 	UCSR1A, UDRE1
		rjmp 	Transfering

		ret

TransmitForward:
		push mpr				; save mpr first

		ldi 	mpr, BotID		; send out botID first
		sts 	UDR1, mpr
		rcall	Transfering		; wait now until ready to transfer again

		ldi		mpr, MovFwd		; load forward code into MPR and then UDR
		sts		UDR1, mpr
		rcall	Transfering

		pop mpr

		ret

TransmitBackward:
		push mpr				; save mpr first

		ldi 	mpr, BotID		; send out botID first
		sts 	UDR1, mpr
		rcall	Transfering		; wait now until ready to transfer again

		ldi		mpr, MovBck		; load backward code into MPR and then UDR
		sts		UDR1, mpr
		rcall	Transfering

		pop mpr

		ret

TransmitLeft:
		push mpr				; save mpr first

		ldi 	mpr, BotID		; send out botID first
		sts 	UDR1, mpr
		rcall	Transfering		; wait now until ready to transfer again

		ldi		mpr, TurnL		; load left code into MPR and then UDR
		sts		UDR1, mpr
		rcall	Transfering

		pop mpr

		ret

TransmitRight:
		push mpr				; save mpr first

		ldi 	mpr, BotID		; send out botID first
		sts 	UDR1, mpr
		rcall	Transfering		; wait now until ready to transfer again

		ldi		mpr, TurnR		; load right code into MPR and then UDR
		sts		UDR1, mpr
		rcall	Transfering

		pop mpr

		ret

TransmitHalt:
		push mpr				; save mpr first

		ldi 	mpr, BotID		; send out botID first
		sts 	UDR1, mpr
		rcall	Transfering		; wait now until ready to transfer again

		ldi		mpr, Halt		; load halt code into MPR and then UDR
		sts		UDR1, mpr
		rcall	Transfering

		pop mpr

		ret

TransmitFreeze:
		push mpr				; save mpr first

		ldi 	mpr, BotID		; send out botID first
		sts 	UDR1, mpr
		rcall	Transfering		; wait now until ready to transfer again

		ldi		mpr, Freeze		; load freeze code into MPR and then UDR
		sts		UDR1, mpr
		rcall	Transfering

		pop mpr

		ret

;***********************************************************
;*	Stored Program Data
;***********************************************************



;***********************************************************
;*	Additional Program Includes
;***********************************************************
