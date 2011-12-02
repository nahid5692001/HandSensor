;***********************************************************
;*
;*	ECE 375: Lab 6 - Freeze Tag Receive
;*
;*
;***********************************************************
;*
;*	 Author: Anton Bilbaeno, Mushfiqur Sarker
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
.def 	motorStatus = r20		; Register to store status of motors before being frozen
.def 	data = r24
.def	freezeCnt = r23
.def	correctID = r22
.def	recCheck = r21
.def	pkt = r25

; Constants for interactions such as
.equ	WskrR = 0				; Right Whisker Input Bit
.equ	WskrL = 1				; Left Whisker Input Bit
.equ	WTime = 50				; Time to wait in wait loop


; Using the constants from above, create the movement 
; commands, Forwards, Backwards, Stop, Turn Left, and Turn Right
.equ 	EngEnR = 4
.equ	EngEnL = 7
.equ 	EngDirR = 5
.equ 	EngDirL = 6

.equ	MovFwd = (1<<EngDirR|1<<EngDirL)
.equ 	MovBack = $00
.equ	TurnR = (1<<EngDirL)
.equ	TurnL = (1<<EngDirR)
.equ 	Halt = (1<<EngEnR|1<<EngEnL)
.equ	ToldFreeze = 0b01010101
.equ	TellFreeze = 0b11111000

.equ	BotID = 0b01100011; Unique XD ID (MSB = 0)

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
;- USART receive
.org 	$003C
		rcall		Receive
		reti

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
		ldi mpr, (1<<RXEN1)|(1<<RXCIE1)|(1<<TXEN1)
		sts UCSR1B, mpr

		;Set frame format: 2stop bit, 8data bits
		ldi mpr, (1<<USBS1)|(1<<UCSZ10)|(1<<UCSZ11);|(0<<UMSEL1)
		sts UCSR1C, mpr


		; Initialize Port B for output
		ldi 	mpr, (1<<EngEnL)|(1<<EngEnR)|(1<<EngDirR)|(1<<EngDirL)
		out		DDRB, mpr
		ldi		mpr, $00
		out		PORTB, mpr

		; Initialize Port D for input
		ldi 	mpr, 0b11111000				; pin 1,0 whiskers. pin 2 rx, pin 3 tx output
		out		DDRD, mpr
		ldi		mpr, 0b11110011
		out		PORTD, mpr
		
		; Initialize external interrupts
		; Set the Interrupt Sense Control for whiskers to low level
		ldi		mpr, (0<<ISC01)|(0<<ISC00)|(0<<ISC11)|(0<<ISC10)
		sts 	EICRA, mpr
		ldi		mpr, $00
		out		EICRB, mpr

		; NOTE: must initialize both EICRA and EICRB

		; Set the External Interrupt Mask
		ldi		mpr, (1<<INT0)|(1<<INT1)
		out		EIMSK, mpr

		; initialize freeze count to zero at start
		ldi		freezeCnt, $00

		ldi		data, MovFwd
				
		; Turn on interrupts
		sei
		; NOTE: This must be the last thing to do in the INIT function

;-----------------------------------------------------------
; Main Program
;-----------------------------------------------------------
MAIN:	; The Main program

		; Resume previous activity
		out		PORTB, data

		; That is all you should have in MAIN

		rjmp	MAIN			; Create an infinite while loop to signify the 
								; end of the program

Receive:
		lds		pkt, UDR1
		sbrc	pkt, 7			; check MSB
		rjmp	RCV_CMD			; will be skipped if MSB not set
		cpi		pkt, BotID
		breq	IDTrue
		cpi		pkt, ToldFreeze
		breq	FROZEN
		
		rjmp	RCV_COMPLETE

RCV_CMD:
		lsl		pkt
		cpi		pkt, TellFreeze
		breq	FRZ
		sbrc	correctID, 0
		mov		data, pkt

CLR_ID:
		clr		correctID
		rjmp	RCV_COMPLETE


FRZ: 	cpi		correctID, 1
		brne	CLR_ID

IDTrue:
		ldi		correctID, 1
		
		rjmp	RCV_COMPLETE

RCV_COMPLETE:
		ret




/*
Recieve:
		call	ReadData

		ldi		mpr, TellFreeze
		cp		mpr, data
		breq	Tag

		ldi		mpr, MovFwd
		cp		mpr, data
		breq	goForward

		ldi		mpr, MovBack
		cp		mpr, data
		breq	goBack

		ldi		mpr, TurnL
		cp		mpr, data
		breq	goLeft

		ldi		mpr, TurnR
		cp		mpr, data
		breq	goRight

		ldi		mpr, Halt
		cp		mpr, data
		breq	stop

		ldi		mpr, TellFreeze
		cp		mpr, data
		breq	Tag

		ldi		mpr, TellFreeze
		cp		mpr, data
		breq	Tag

		ret
		*/

Tag:
		push	mpr
		lds 	mpr, ToldFreeze
		sts		UDR1, mpr
		; now we are ready to transfer.. call that function from Transmit

Transfering: ; infinite loop if UDRE is not set, if UDRE is set, then UDR can be written to
		sbis 	UCSR0A, UDRE1	; ****** UCSR1A or UCSR0A? 
		rjmp 	Transfering		; Use zero because 1 is out of range?

		/*
		ldi		mpr, 0b00000000
		sts 	UDR1, mpr
		pop 	mpr
		*/

		ret

FROZEN:
		push 	mpr
		ldi		motorStatus, PINB
		inc 	freezeCnt
		cpi		freezeCnt, 0b00000011
		breq	Dead
		ldi		mpr, Halt
		out		PORTB, mpr
		rcall	wait
		pop		mpr
		out		PORTB, motorStatus
		
		rjmp 	MAIN

Dead:
		ldi		mpr, Halt
		out		PORTB, mpr
		rjmp 	Dead

goForward:
		ldi		mpr, MovFwd				
		out		PORTB, mpr
		
		rjmp	MAIN

goBack:
		ldi		mpr, MovBack				
		out		PORTB, mpr

		rjmp 	MAIN

goLeft:
		ldi		mpr, TurnL				
		out		PORTB, mpr

		rjmp 	MAIN

goRight:
		ldi		mpr, TurnR				
		out		PORTB, mpr
		rjmp 	MAIN

stop:
		ldi		mpr, Halt				
		out		PORTB, mpr

		rjmp 	MAIN



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
		ldi		mpr, MovBack
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
		ldi		mpr, MovBack
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
