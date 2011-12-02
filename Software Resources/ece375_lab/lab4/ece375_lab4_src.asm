;***********************************************************
;*
;*	Adding two 16-bit numbers (24-bits with carry)
;*	Then multiplying two 24-bit numbers
;*
;*	This is the skeleton file Lab 4 of ECE 375
;*
;***********************************************************
;*
;*	 Author: Anton Bilbaeno, Andrew
;*	   Date: 1/26/11
;*
;***********************************************************

.include "m128def.inc"			; Include definition file

;***********************************************************
;*	Internal Register Definitions and Constants
;***********************************************************
.def	mpr = r16				; Multipurpose register 
.def	rlo = r0				; Low byte of MUL result
.def	rhi = r1				; High byte of MUL result
.def	zero = r2				; Zero register, set to zero in INIT, useful for calculations
.def	A = r3					; An operand
.def	B = r4					; Another operand

.def	oloop = r17				; Outer Loop Counter
.def	iloop = r18				; Inner Loop Counter

.equ 	num1 = $0001;
.equ 	num2 = $0001;


// for 24-bit multiplication
.equ	addrA = $0100			; Beginning Address of Operand A data - 3 byes
.equ	addrB = $0103			; Beginning Address of Operand B data - 3 bytes
.equ	LAddrP = $0106			; Beginning Address of Product Result - 6 bytes
.equ	HAddrP = $0111			; End Address of Product Result


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
INIT:							; The initialization routine
		; Initialize Stack Pointer
		; TODO					; Init the 2 stack pointer registers

		ldi		mpr, HIGH(RAMEND)
		out		SPH, mpr
		ldi		mpr, LOW(RAMEND)
		out		SPL, mpr

		clr		zero			; Set the zero register to zero, maintain
								; these semantics, meaning, don't load anything
								; to it.

;-----------------------------------------------------------
; Main Program
;-----------------------------------------------------------
MAIN:	; The Main program
		; Setup the add funtion
		ldi		mpr, low(num1)		; Load the low byte of num1 into the MPR
		sts		addrA, mpr			; Now put that value @ low part of addrA 
		ldi		mpr, high(num1)		; Repeat for high byte
		sts		addrA + 1, mpr
		ldi		mpr, low(num2)		; Repeat again for num2
		sts		addrB, mpr
		ldi		mpr, high(num2)
		sts		addrB + 1, mpr

		; Add the two 16-bit numbers
		rcall	ADD16			; Call the add function

		; Setup the multiply function
		lds 	mpr, LAddrP			; Load the low byte of LAddrP into MPR
		sts 	addrA, mpr			; Put that low byte into addrA
		sts		addrB, mpr			; Same for addrB
		lds		mpr, LAddrP + 1		; Put next byte of LAddrP into MPR
		sts 	addrA + 1, mpr		; Repeat
		sts		addrB + 1, mpr
		lds		mpr, LAddrP + 2		; Put last byte of LAddrP into MPR
		sts		addrA + 2, mpr		; Repeat
		sts		addrB + 2, mpr
		
		; Multiply two 24-bit numbers
		rcall	MUL24			; Call the multiply function

DONE:	rjmp	DONE			; Create an infinite while loop to signify the 
								; end of the program.

;***********************************************************
;*	Functions and Subroutines
;***********************************************************

;-----------------------------------------------------------
; Func: ADD16
; Desc: Adds two 16-bit numbers and generates a 24-bit number
;		where the high byte of the result contains the carry
;		out bit.
;-----------------------------------------------------------
ADD16:

		; Save variable by pushing them to the stack
		push 	A				; Save A register
		push	B				; Save B register
		push	rhi				; Save rhi register
		push	rlo				; Save rlo register
		push	zero			; Save zero register
		push	XH				; Save X-ptr
		push	XL
		push	YH				; Save Y-ptr
		push	YL				
		push	ZH				; Save Z-ptr
		push	ZL
		push	oloop			; Save counters
	
		; Execute the function here
		clr		zero			; Maintain zero semantics
		
		; Set Y to beginning address of B
		ldi		YL, low(addrA)	; Load low byte
		ldi		YH, high(addrA)	; Load high byte

		; Set Z to begginning address of resulting Product
		ldi		ZL, low(LAddrP)	; Load low byte
		ldi		ZH, high(LAddrP); Load high byte

		; Set X to beginning address of A
		ldi		XL, low(addrB)	; Load low byte
		ldi		XH, high(addrB)	; Load high byte

// now add

		ld		A, X+			; Get byte of A operand
		ld		B, Y+			; Get byte of B operand
		add		A, B			; Add A and B, result goes into A
		st 		Z+,A			; Store result of add
		ld		A, X			; Load next byte of A operand, was post incremented already
		ld		B, Y			; Load next byte of B operand, was post incremented already
		adc		A, B			; Add A and B (WITH CARRY), result goes into A
		st		Z+, A			; Store result of add into Z register, was post incremented already
		mov		A, zero			; Clear A
		adc		A, zero			; If there is a carry, put it in A
		st		Z, A			; Store result of add into Z register, was post incremented already
		
		; Restore variable by popping them from the stack in reverse order
		pop		oloop
		pop		ZL				
		pop		ZH
		pop		YL
		pop		YH
		pop		XL
		pop		XH
		pop		zero
		pop		rlo
		pop		rhi
		pop		B
		pop		A

		ret						; End a function with RET

;-----------------------------------------------------------
; Func: MUL24
; Desc: Multiplies two 24-bit numbers and generates a 48-bit 
;		result.
;-----------------------------------------------------------
MUL24:
		; Save variable by pushing them to the stack
		push 	A				; Save A register
		push	B				; Save B register
		push	rhi				; Save rhi register
		push	rlo				; Save rlo register
		push	zero			; Save zero register
		push	XH				; Save X-ptr
		push	XL
		push	YH				; Save Y-ptr
		push	YL				
		push	ZH				; Save Z-ptr
		push	ZL
		push	oloop			; Save counters
		push	iloop	

		; Execute the function here		

		clr 	zero

		ldi		ZL, LOW(LaddrP)
		ldi		ZH, HIGH(LaddrP)

		st		Z+, zero
		st		Z+, zero
		st		Z+, zero
		st		Z+, zero
		st		Z+, zero
		st		Z+, zero

		; Execute the function here
		ldi		YL, LOW(addrB)
		ldi		YH, HIGH(addrB)

		ldi		ZL, LOW(LaddrP)
		ldi		ZH, HIGH(LaddrP)

		ldi		oloop, 3		; Outer loop counter

MUL24_OLOOP:
		ldi		XL, LOW(addrA)
		ldi		XH, HIGH(addrA)

		ldi		iloop, 3		; Inner loop counter
MUL24_ILOOP:
		ld		A, X+			; Get byte of A operand
		ld		B, Y			; Get byte of B operand
		mul		A, B			; Multiply
		ld		A, Z+			; Get a result byte from memory
		ld		B, Z+			; Get the next result byte from memory
		add		rlo, A			; rlo <= rlo + A
		adc		rhi, B			; rhi <= rhi + B + carry
		ld		A, Z			; Get a third byte from the result
		adc		A, zero			; Add carry to A
		st		Z, A			; Store third byte to memory
		st		-Z, rhi			; Store second byte to memory
		st		-Z, rlo			; Store third byte to memory

		adiw	ZH:ZL, 1		; Z <= Z + 1
		dec		iloop			; Decrement counter
		brne	MUL24_ILOOP		; Loop if iLoop != 0

		sbiw	ZH:ZL, 2		; Z <= Z - 2
		adiw	YH:YL, 1		; Y <= Y + 1
		dec		oloop			; Decrement counter
		brne	MUL24_OLOOP		; Loop if oLoop != 0
		
		; Restore variable by popping them from the stack in reverse order
		pop		iloop
		pop		oloop
		pop		ZL				
		pop		ZH
		pop		YL
		pop		YH
		pop		XL
		pop		XH
		pop		zero
		pop		rlo
		pop		rhi
		pop		B
		pop		A

		ret						; End a function with RET

;-----------------------------------------------------------
; Func: MUL16
; Desc: An example function that multiplies two 16-bit numbers
;			A - Operand A is gathered from address $0101:$0100
;			B - Operand B is gathered from address $0103:$0102
;			Res - Result is stored in address 
;					$0107:$0106:$0105:$0104
;		You will need to make sure that Res is cleared before
;		calling this function.
;-----------------------------------------------------------
MUL16:
		push 	A				; Save A register
		push	B				; Save B register
		push	rhi				; Save rhi register
		push	rlo				; Save rlo register
		push	zero			; Save zero register
		push	XH				; Save X-ptr
		push	XL
		push	YH				; Save Y-ptr
		push	YL				
		push	ZH				; Save Z-ptr
		push	ZL
		push	oloop			; Save counters
		push	iloop

		clr		zero			; Maintain zero semantics

		; Set Y to beginning address of B
		ldi		YL, low(addrB)	; Load low byte
		ldi		YH, high(addrB)	; Load high byte

		; Set Z to begginning address of resulting Product
		ldi		ZL, low(LAddrP)	; Load low byte
		ldi		ZH, high(LAddrP); Load high byte

		; Begin outer for loop
		ldi		oloop, 2		; Load counter
MUL16_OLOOP:
		; Set X to beginning address of A
		ldi		XL, low(addrA)	; Load low byte
		ldi		XH, high(addrA)	; Load high byte

		; Begin inner for loop
		ldi		iloop, 2		; Load counter

MUL16_ILOOP:
		ld		A, X+			; Get byte of A operand
		ld		B, Y			; Get byte of B operand
		mul		A, B			; Multiply A and B
		ld		A, Z+			; Get a result byte from memory
		ld		B, Z+			; Get the next result byte from memory
		add		rlo, A			; rlo <= rlo + A
		adc		rhi, B			; rhi <= rhi + B + carry
		ld		A, Z			; Get a third byte from the result
		adc		A, zero			; Add carry to A
		st		Z, A			; Store third byte to memory
		st		-Z, rhi			; Store second byte to memory
		st		-Z, rlo			; Store third byte to memory
		adiw	ZH:ZL, 1		; Z <= Z + 1			
		dec		iloop			; Decrement counter
		brne	MUL16_ILOOP		; Loop if iLoop != 0
		; End inner for loop

		sbiw	ZH:ZL, 1		; Z <= Z - 1
		adiw	YH:YL, 1		; Y <= Y + 1
		dec		oloop			; Decrement counter
		brne	MUL16_OLOOP		; Loop if oLoop != 0
		; End outer for loop
		 		
		pop		iloop			; Restore all registers in reverves order
		pop		oloop
		pop		ZL				
		pop		ZH
		pop		YL
		pop		YH
		pop		XL
		pop		XH
		pop		zero
		pop		rlo
		pop		rhi
		pop		B
		pop		A
		ret						; End a function with RET

;-----------------------------------------------------------
; Func: Template function header
; Desc: Cut and paste this and fill in the info at the 
;		beginning of your functions
;-----------------------------------------------------------
FUNC:							; Begin a function with a label
		; Save variable by pushing them to the stack

		; Execute the function here
		
		; Restore variable by popping them from the stack in reverse order\
		ret						; End a function with RET


;***********************************************************
;*	Stored Program Data
;***********************************************************

; Enter any stored data you might need here

;***********************************************************
;*	Additional Program Includes
;***********************************************************
; There are no additional file includes for this program
