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

	; LCD pins
	sbi DDRB, PB4
	sbi DDRB, PB3

	sbi DDRD, PD5
	sbi DDRD, PD4
	sbi DDRD, PD3
	sbi DDRD, PD2

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