
/*
This code will cause a TekBot connected to the AVR board to
move forward and when it touches an obsticle, it will reverse
and turn away from the obsticle and resume forward motion.

PORT MAP
Port B, Pin 4 -> Output -> Right Motor Enable
Port B, Pin 5 -> Output -> Right Motor Direction
Port B, Pin 7 -> Output -> Left Motor Enable
Port B, Pin 6 -> Output -> Left Motor Direction
Port D, Pin 1 -> Input -> Left Whisker
Port D, Pin 0 -> Input -> Right Whisker
*/

#define F_CPU 16000000
#include <avr/io.h> 
#include <util/delay.h> 
#include <stdio.h>

int main(void)
{

DDRB =0b11110000;	//Setup Port B for Input/Output
PORTB=0b11110000;	//Turn off motors at start
DDRD =0b00000000;	//Setup Port D for I/O, initialize off (active low)
//PORTD=0b00000000;	//Turn off pin 0,1 (active low)

while (1)		//Loop Forever
	{

		PORTB = 0b01100000;		//go forward

		if( ((PIND & 0b00000011) == 0b00000001) ) {			//If right bumper hit
			PORTB = 0b00000000;		//reverse
			_delay_ms(1000);		//for one secon
			PORTB = 0b01000000;		//spin left
			_delay_ms(1000);		//for one second
		}

		else if ( (PIND & 0b00000011) == 0b00000010 ) {		//If left bumper hit
			PORTB = 0b00000000;		//reverse
			_delay_ms(1000);		//for one second
			PORTB = 0b00100000;		//spin right
			_delay_ms(1000);		//for one second
		}
	};
}
