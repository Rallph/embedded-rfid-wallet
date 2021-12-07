.include "m328pdef.inc"


.equ LCD_RS = PORTB0	; arduino pin 8
.equ LCD_E = PORTB1		; arduino pin 9

.equ LCD_D4 = PORTD4	; arduino pin 4
.equ LCD_D5 = PORTD5	; arduino pin 5
.equ LCD_D6 = PORTD6	; arduino pin 6
.equ LCD_D7 = PORTD7	; arduino pin 7

; LCD commands
.equ LCD_INIT_SET = 0b00110000
.equ LCD_FUNCTION_SET = 0b00100000 ; set to 4 bit mode
.equ LCD_SET_LINES_FONT = 0b00101000 ; set 2 lines and 5x7 font
.equ LCD_DISPLAY_ON = 0b00001111 ; set display, cursor, and blink on
.equ LCD_DISPLAY_CLEAR = 0b00000001
.equ LCD_SET_ENTRY_MODE = 0b00000011 ; set increment mode and shift (move left to right)


start:
    ldi r16, 0xff
	out DDRB, r16 ; set all PORTB to output
	out DDRD, r16 ; set all PORTD to output
	ldi r16, HIGH(RAMEND) ; init stack
	out sph, r16
	ldi r16, LOW(RAMEND)
	out spl, r16

	; config timer0
	ldi r16, (1 << CS02) | (1 << CS00) ; set timer0 prescaler to clk/1024. will run at ~ 16 Khz
	out TCCR0B, r16

	; init lcd
	rcall lcd_init

	rjmp loop

; run init sequence to start LCD in 4 bit mode
lcd_init:
	ldi r17, 100
	rcall delay_n_ms ; wait 100 ms for power up

	cbi PORTB, LCD_RS
	cbi PORTB, LCD_E

	ldi r17, LCD_INIT_SET
	rcall lcd_write_4bit ; write init sequence
	ldi r17, 5
	rcall delay_n_ms ; wait > 4.1 ms
	
	ldi r17, LCD_INIT_SET
	rcall lcd_write_4bit
	rcall delay_1ms ; wait > 100 us

	ldi r17, LCD_INIT_SET
	rcall lcd_write_4bit
	rcall delay_1ms

	; set to 4 bit mode
	ldi r17, LCD_FUNCTION_SET
	rcall lcd_write_command
	rcall delay_1ms

	; datasheet says to do this again
	ldi r17, LCD_FUNCTION_SET
	rcall lcd_write_command
	rcall delay_1ms

	; set 2 lines, 5 x 7 font
	ldi r17, LCD_SET_LINES_FONT
	rcall lcd_write_command
	rcall delay_1ms

	; display off
	ldi r17, LCD_DISPLAY_ON
	rcall lcd_write_command
	rcall delay_1ms

	; clear display
	ldi r17, LCD_DISPLAY_CLEAR
	rcall lcd_write_command
	ldi r17, 2
	rcall delay_n_ms

	; set entry mode
	ldi r17, LCD_SET_ENTRY_MODE
	rcall lcd_write_command
	rcall delay_1ms


	sbi PORTB, PB5
	ret


; write character to lcd. pass 1 byte in r17. refer to datasheet for possible characters. seems to be ascii
lcd_write_char:
	sbi PORTB, LCD_RS ; set RS to high to select data
	cbi PORTB, LCD_E
	rcall lcd_write_4bit
	swap r17
	rcall lcd_write_4bit
	rcall delay_1ms
	ret


; write command to lcd. pass 1 byte command in r17. lcd commands defined above
lcd_write_command:
	cbi PORTB, LCD_RS
	cbi PORTB, LCD_E
	rcall lcd_write_4bit
	swap r17
	rcall lcd_write_4bit
	ret


; writes 4 bits to LCD ports and drives LCD enable high to write out. 
; takes r17 register as argument, with bits in 4-7 (upper nibble)
lcd_write_4bit:
	; data pin 7
	sbi PORTD, LCD_D7	; clear bit. if the bit in the argument register is set, we want to write it
	sbrs r17, 7			; so dont skip sbi instruction
	cbi PORTD, LCD_D7
	; data pin 6
	sbi PORTD, LCD_D6
	sbrs r17, 6
	cbi PORTD, LCD_D6
	; data pin 5
	sbi PORTD, LCD_D5
	sbrs r17, 5
	cbi PORTD, LCD_D5
	; data pin 4
	sbi PORTD, LCD_D4
	sbrs r17, 4
	cbi PORTD, LCD_D4
	
	; drive enable high then low to write out data to LCD
	sbi PORTB, LCD_E
	call delay_1ms
	cbi PORTB, LCD_E
	call delay_1ms
	ret

loop:
	rcall delay_1ms
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