;***********************************************************
;*
;*	ECE 375: Lab 7 - Arcade Basketball
;*
;*	LCD Display Source Code
;*
;***********************************************************
;*
;*	 Authors: Anton Bilbaeno, Mushfiqur Sarker
;*	    Date: 3/5/11
;*
;***********************************************************

.include "m128def.inc"			; Include definition file

;***********************************************************
;*	Internal Register Definitions and Constants
;***********************************************************
.def	mpr = r16				; Multipurpose register 
.def 	zero = r2				; Zero flag
.def	counter = r4

; LCD Driver uses registers 17-22
.def 	ReadCnt = r23			; Register required for LCD Driver for writing to LCD Displays
.def	remTime = r24			
.def	curScore = r25

.equ	HitID = 0b0011001100
.equ	WaitTime = 100
.equ	writeSpace = $0200

;***********************************************************
;*	Start of Code Segment
;***********************************************************
.cseg							; Beginning of code segment

;-----------------------------------------------------------
; Interrupt Vectors
;-----------------------------------------------------------
.org	$0000					; Beginning of IVs
		rjmp INIT				; Reset interrupt

.org	$0002
		rcall		IncScore
		reti

.org	$0004		
		rcall		IncScore
		reti

;- USART receive
.org 	$003C
		rcall		Receive
		reti

.org	$0014
		rcall		Timer
		reti

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
		
		; Initialize Port D for input
		ldi 	mpr, 0b11111000				; pin 1,0 whiskers. pin 2 rx, pin 3 tx output
		out		DDRD, mpr
		ldi		mpr, 0b11110011
		out		PORTD, mpr

		; Initialize Port B
		ldi 	mpr, 0b11111111
		out 	DDRD, mpr
		ldi 	mpr, 0b00000000
		out		PORTD, mpr

		clr		curScore

		ldi		remTime, 61

; Timer/Counter2 initialization
		ldi		mpr, (1<<WGM21|1<<CS22|1<<CS21|1<<CS20)
		out		TCCR2, mpr
		ldi		mpr, $30
		out		OCR0, mpr

		ldi		mpr, (1<<OCIE2)
		out		TIMSK, mpr
		ldi		mpr, 0
		mov		counter, mpr

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

		; Initialize LCD Display
		rcall 	LCDInit

; Init line 1 variable registers

		ldi		ZL, low(INTRO1<<1)
		ldi		ZH, high(INTRO1<<1)
		ldi		YL, low(LCDLn1Addr)
		ldi		YH, high(LCDLn1Addr)
		ldi		ReadCnt, LCDMaxCnt

INIT_LINE1:

		lpm		mpr, Z+			; Read Program memory
		st		Y+, mpr			; Store into memory
		dec		ReadCnt			; Decrement Read Counter
		brne	INIT_LINE1		; Continue until all data is read
		rcall 	LCDWrLn1		; WRITE LINE 1 DATA


; Init line 2 variable registers

		ldi		ZL, low(INTRO2<<1);
		ldi		ZH, high(INTRO2<<1);
		ldi		YL, low(LCDLn2Addr)
		ldi		YH, high(LCDLn2Addr)
		ldi		ReadCnt, LCDMaxCnt

INIT_LINE2:

		lpm		mpr, Z+			; Read Program memory
		st		Y+, mpr			; Store into memory
		dec		ReadCnt			; Decrement Read Counter
		brne	INIT_LINE2		; Continue until all data is read
		rcall 	LCDWrLn2		; WRITE LINE 2 DATA

		sei

;-----------------------------------------------------------
; Main Program
;-----------------------------------------------------------
MAIN:							; The Main program

		; Display the strings on the LCD Display
		in 			mpr, PIND
		cpi 		mpr, 0b10111111	;compare to 0's
		breq 		Begin		;if what we were looking for then jump

		in 			mpr, PIND
		cpi 		mpr, 0b11011111	;compare to 0's
		breq 		Begin		;if what we were looking for then jump

		in 			mpr, PIND
		cpi 		mpr, 0b01111111	;compare to 0's
		breq 		Begin		;if what we were looking for then jump

		in 			mpr, PIND
		cpi 		mpr, 0b11101111	;compare to 0's
		breq 		Begin		;if what we were looking for then jump
		

		rjmp		MAIN			; jump back to main and create an infinite
								; while loop.  Generally, every main program is an
								; infinite while loop, never let the main program
								; just run off

;***********************************************************
;*	Functions and Subroutines
;***********************************************************

;-----------------------------------------------------------
; Func: Start
; Desc: Once button is pressed, this is the main function of
; 		the program.
;-----------------------------------------------------------
Begin:
		cpi		remTime, 61
		breq	InitBoard
		
		rcall	UpdScore

		cpi		remTime, $00
		breq	MAIN

		rjmp 	Begin
		
;-----------------------------------------------------------
; Func: InitBoard
; Desc: When receive interrupt is triggerd, we go here to
;		update line 2 of the LDC Display
;-----------------------------------------------------------
InitBoard:
		clr		curScore

		ldi		ZL, low(TIMETXT<<1)
		ldi		ZH, high(TIMETXT<<1)
		ldi		YL, low(LCDLn1Addr)
		ldi		YH, high(LCDLn1Addr)
		ldi		ReadCnt, LCDMaxCnt

GAME_LINE1:

		lpm		mpr, Z+			; Read Program memory
		st		Y+, mpr			; Store into memory
		dec		ReadCnt			; Decrement Read Counter
		brne	GAME_LINE1		; Continue until all data is read
		rcall 	LCDWrLn1		; WRITE LINE 1 DATA


; Init line 2 variable registers

		ldi		ZL, low(SCORETXT<<1);
		ldi		ZH, high(SCORETXT<<1);
		ldi		YL, low(LCDLn2Addr)
		ldi		YH, high(LCDLn2Addr)
		ldi		ReadCnt, LCDMaxCnt

GAME_LINE2:

		lpm		mpr, Z+			; Read Program memory
		st		Y+, mpr			; Store into memory
		dec		ReadCnt			; Decrement Read Counter
		brne	GAME_LINE2		; Continue until all data is read
		rcall 	LCDWrLn2		; WRITE LINE 2 DATA
		
		rjmp 	Begin

;-----------------------------------------------------------
; Func: Score
; Desc: When receive interrupt is triggerd, we go here to
;		update line 2 of the LDC Display
;-----------------------------------------------------------
UpdScore:
		push 	ReadCnt
		push	line
		push 	count
		push	counter
		push	XH
		push	XL
		push 	mpr
		in		mpr, SREG
		push 	mpr

		ldi		XL, low(writeSpace)
		ldi		XH, high(writeSpace)
		ldi		YL, low(LCDLn2Addr)
		ldi		YH, high(LCDLn2Addr)
		ldi		count, 3
		ldi		mpr, ' '
ScoreLoadSpace:
		st		X+, mpr
		dec		count
		brne	ScoreLoadSpace



		mov		mpr, curScore
		ldi		XL, low(writeSpace)
		ldi		XH, low(writeSpace)
		ldi		YL, low(LCDLn2Addr)
		ldi		YH, high(LCDLn2Addr)
		rcall	Bin2ASCII




		ldi		ReadCnt, 3
		ldi		line, 2
		ldi  	count, 14
ScoreWrite:
		ld		mpr, X+
		rcall 	LCDWriteByte
		inc 	count
		dec		ReadCnt
		brne	ScoreWrite
		


		pop		mpr
		out		SREG, mpr
		pop 	mpr
		pop		XL
		pop		XH
		pop		counter
		pop		count
		pop		line
		pop		ReadCnt

		ret

;-----------------------------------------------------------
; Func: Timer
; Desc: 
;-----------------------------------------------------------
GG:		
		jmp MAIN

Timer:
		push 	ReadCnt
		push	line
		push 	count
		push	counter
		push	XH
		push	XL
		push 	mpr
		in		mpr, SREG
		push 	mpr

		ldi		XL, low(writeSpace)
		ldi		XH, high(writeSpace)
		ldi		YL, low(LCDLn1Addr)
		ldi		YH, high(LCDLn1Addr)
		ldi		count, 3				; count defined by LCDDriver.asm
		ldi		mpr, ' '				; blank character

TimerLoadSpace:

		st		X+, mpr
		dec		count
		brne	TimerLoadSpace

		; Convert binary counter to ASCII
		
		dec		remTime
		mov		mpr, remTime
		cpi		remTime, 0
		breq	GG
/*
		push	ReadCnt			; Save wait register
		ldi		ReadCnt, 100
		rcall	Hang
*/
		ldi		XL, low(writeSpace)
		ldi		XH, high(writeSpace)
		ldi		YL, low(LCDLn1Addr)
		ldi		YH, high(LCDLn1Addr)
		rcall	Bin2ASCII

		; Write data to LCD Display
		ldi		ReadCnt, 3
		ldi		line, 1
		ldi		count, 14
TimerWrite:
		ld		mpr, X+
		rcall	LCDWriteByte
		inc		count
		dec		ReadCnt
		brne	TimerWrite

EndTime:
		pop		mpr
		out		SREG, mpr
		pop 	mpr
		pop		XL
		pop		XH
		pop		counter
		pop		count
		pop		line
		pop		ReadCnt

		ret

/*
Hang:
		push	curScore			; Save curScore register
		push	remTime			; Save remTime register

Loop:	ldi		remTime, 224		; load remTime register
OLoop:	ldi		curScore, 237		; load curScore register
ILoop:	dec		curScore			; decrement curScore
		brne	ILoop			; Continue Inner Loop
		dec		remTime			; decrement remTime
		brne	OLoop			; Continue Outer Loop
		dec		ReadCnt			; Decrement wait 
		brne	Loop			; Continue Wait loop	

		pop		remTime			; Restore remTime register
		pop		curScore			; Restore curScore register
		pop		ReadCnt			; Restore wait register
		ret	
*/
/*
GG:
; Restore initial game status

		ldi		ZL, low(INTRO1<<1)
		ldi		ZH, high(INTRO1<<1)
		ldi		YL, low(LCDLn1Addr)
		ldi		YH, high(LCDLn1Addr)
		ldi		ReadCnt, LCDMaxCnt

END_LINE1:

		lpm		mpr, Z+			; Read Program memory
		st		Y+, mpr			; Store into memory
		dec		ReadCnt			; Decrement Read Counter
		brne	END_LINE1		; Continue until all data is read
		rcall 	LCDWrLn1		; WRITE LINE 1 DATA


; Restore initial game status

		ldi		ZL, low(INTRO2<<1);
		ldi		ZH, high(INTRO2<<1);
		ldi		YL, low(LCDLn2Addr)
		ldi		YH, high(LCDLn2Addr)
		ldi		ReadCnt, LCDMaxCnt

END_LINE2:

		lpm		mpr, Z+			; Read Program memory
		st		Y+, mpr			; Store into memory
		dec		ReadCnt			; Decrement Read Counter
		brne	END_LINE2		; Continue until all data is read
		rcall 	LCDWrLn2		; WRITE LINE 2 DATA
		
		rjmp	MAIN
*/
;-----------------------------------------------------------
; Desc: Receive functions
;-----------------------------------------------------------		

Receive:
		push 	mpr
		lds		mpr, UDR1
		cpi		mpr, HitID
		breq 	IncScore
		rjmp	RCV_Complete
		
IncScore:
		inc		curScore
		rcall	UpdScore		

RCV_COMPLETE:
		pop 	mpr
		ret

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
INTRO1:
.DB		"Press button 4-8"		; Storing the string in Program Memory

INTRO2:
.DB 	"on PortD 2 start"

TIMETXT:
.DB		"Time left:      "

SCORETXT:
.DB		"Score:          "

; for testing
;		"Score:          "

;***********************************************************
;*	Additional Program Includes
;***********************************************************
.include "LCDDriver.asm"		; Include the LCD Driver
