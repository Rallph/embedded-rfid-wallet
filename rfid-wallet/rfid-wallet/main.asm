.include "m328pdef.inc"

.def delay_l = r26      ; low byte of delay counter
.def delay_h = r27      ; high inner byte of delay counter
.def delay_e = r16      ; high outer byte of delay counter

start:
    sbi DDRB, PB5       ; set bit 5 in PORTB as output

loop:
    sbi PINB, PB5       ; writing PB5 (0x20) into PINB register flips the PB5 bit in PORTB

    ; delay for 8 000 000 clock cycles (1 second)
    ldi delay_l, 0xFF   ; 1 clock cycle
    ldi delay_h, 0x69   ; 1 clock cycle
    ldi delay_e, 0x18   ; 1 clock cycle

    ; loop 0x1869FF (1 599 999) times
delay_loop:
    sbiw delay_l, 1     ; 2 clock cycles * 1 599 999 (subtract 1 from delay_l and delay_h register pair)
    sbci delay_e, 0     ; 1 clock cycle * 1 599 999

    brne delay_loop     ; 2 clock cycles * 1 599 598 + 1 clock cycle (when counter reaches 0)

    jmp loop            ; 3 clock cycles