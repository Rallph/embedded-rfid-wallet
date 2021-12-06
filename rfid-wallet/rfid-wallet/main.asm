.include "m328pdef.inc"

.def delay_l = r26      ; low byte of delay counter
.def delay_h = r27      ; high inner byte of delay counter
.def delay_e = r16      ; high outer byte of delay counter


.equ LCD_RS = PORTB0
.equ LCD_E = PORTB1
.equ LCD_RW = PORTB2

.equ LCD_D4 = PORTD4
.equ LCD_D5 = PORTD5
.equ LCD_D6 = PORTD6
.equ LCD_D7 = PORTD7


start:
    sbi DDRB, PB5       ; set bit 5 in PORTB as output
	ldi r16, HIGH(RAMEND) ; init stack
	out sph, r16
	ldi r16, LOW(RAMEND)
	out spl, r16

config_timer0:
	ldi r16, (1 << CS02) | (1 << CS00) ; set timer0 prescaler to clk/1024. will run at ~ 16 Khz
	out TCCR0B, r16

lcd_init:


; writes 4 bits to LCD ports and drives LCD enable high to write out. 
; takes r17 register as argument, with bits in 4-7 (upper nibble)
lcd_write_4bit:
	; data pin 7
	cbi PORTD, LCD_D7	; clear bit. if the bit in the argument register is set, we want to write it
	sbrc r17, 7			; so dont skip sbi instruction
	sbi PORTD, LCD_D7
	; data pin 6
	cbi PORTD, LCD_D6
	sbrc r17, 6
	sbi PORTD, LCD_D6
	; data pin 5
	cbi PORTD, LCD_D5
	sbrc r17, 5
	sbi PORTD, LCD_D5
	; data pin 4
	cbi PORTD, LCD_D4
	sbrc r17, 4
	sbi PORTD, LCD_D4
	
	; drive enable high then low to write out data to LCD
	sbi PORTB, LCD_E
	call delay_1ms
	cbi PORTB, LCD_E
	call delay_1ms
	ret



loop:
	nop
	rjmp loop

delay_1ms:
	clr r16
	out TCNT0, r16
delay_1ms_wait:
	in r16, TCNT0
	cpi r16, 0x11
	brlo delay_1ms_wait
	ret

delay_n_ms: ; function that delays n number of ms. argument in r17
	rcall delay_1ms
	dec r17
	brne delay_n_ms
	ret