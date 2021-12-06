.include "m328pdef.inc"

.def delay_l = r26      ; low byte of delay counter
.def delay_h = r27      ; high inner byte of delay counter
.def delay_e = r16      ; high outer byte of delay counter


.equ LCD_RS = PINB4
.equ LCD_E = PINB3
.equ LCD_D4 = PIND5
.equ LCD_D5 = PIND4
.equ LCD_D6 = PIND3
.equ LCD_D7 = PIND2


start:
    sbi DDRB, PB5       ; set bit 5 in PORTB as output
	ldi r16, HIGH(RAMEND)
	out sph, r16
	ldi r16, LOW(RAMEND)
	out spl, r16

config_timer0:
	ldi r16, (1 << CS02) | (1 << CS00) ; set timer0 prescaler to clk/1024. will run at ~ 16 Khz
	out TCCR0B, r16

lcd_init:

	; set LCD pins
	sbi DDRB, PB4
	sbi DDRB, PB3

	sbi DDRD, PD5
	sbi DDRD, PD4
	sbi DDRD, PD3
	sbi DDRD, PD2
	
	; wait 50 ms
	ldi r17, 0x32
	rcall delay_n_ms
	cbi PINB, LCD_RS
	cbi PINB, LCD_E
	cbi PIND, LCD_D7
	cbi PIND, LCD_D6
	sbi PIND, LCD_D5
	sbi PIND, LCD_D4
	ldi r17, 0x10
	rcall delay_n_ms ; wait 16 ms just in case

	cbi PIND, LCD_D4
	sbi PIND, LCD_D7
	sbi PIND, LCD_D6
	clr r16
	out PIND, r16
	sbi PIND, LCD_D7
	cbi PIND, LCD_D7
	sbi PIND, LCD_D4
	cbi PIND, LCD_D4
	sbi PIND, LCD_D6
	sbi PIND, LCD_D5
	sbi PIND, LCD_D4

	
	 




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