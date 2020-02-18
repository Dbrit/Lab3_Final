;****************** main.s ***************
; Program written by: ***Your Names**update this***
; Date Created: 2/4/2017
; Last Modified: 1/17/2020
; Brief description of the program
;   The LED toggles at 2 Hz and a varying duty-cycle
; Hardware connections (External: One button and one LED)
;  PE1 is Button input  (1 means pressed, 0 means not pressed)
;  PE2 is LED output (1 activates external LED on protoboard)
;  PF4 is builtin button SW1 on Launchpad (Internal) 
;        Negative Logic (0 means pressed, 1 means not pressed)
; Overall functionality of this system is to operate like this
;   1) Make PE2 an output and make PE1 and PF4 inputs.
;   2) The system starts with the the LED toggling at 2Hz,
;      which is 2 times per second with a duty-cycle of 30%.
;      Therefore, the LED is ON for 150ms and off for 350 ms.
;   3) When the button (PE1) is pressed-and-released increase
;      the duty cycle by 20% (modulo 100%). Therefore for each
;      press-and-release the duty cycle changes from 30% to 70% to 70%
;      to 90% to 10% to 30% so on
;   4) Implement a "breathing LED" when SW1 (PF4) on the Launchpad is pressed:
;      a) Be creative and play around with what "breathing" means.
;         An example of "breathing" is most computers power LED in sleep mode
;         (e.g., https://www.youtube.com/watch?v=ZT6siXyIjvQ).
;      b) When (PF4) is released while in breathing mode, resume blinking at 2Hz.
;         The duty cycle can either match the most recent duty-
;         cycle or reset to 30%.
;      TIP: debugging the breathing LED algorithm using the real board.
; PortE device registers
GPIO_PORTE_DATA_R  EQU 0x400243FC
GPIO_PORTE_DIR_R   EQU 0x40024400
GPIO_PORTE_AFSEL_R EQU 0x40024420
GPIO_PORTE_DEN_R   EQU 0x4002451C
; PortF device registers
GPIO_PORTF_DATA_R  EQU 0x400253FC
GPIO_PORTF_DIR_R   EQU 0x40025400
GPIO_PORTF_AFSEL_R EQU 0x40025420
GPIO_PORTF_PUR_R   EQU 0x40025510
GPIO_PORTF_DEN_R   EQU 0x4002551C
GPIO_PORTF_LOCK_R  EQU 0x40025520
GPIO_PORTF_CR_R    EQU 0x40025524
GPIO_LOCK_KEY      EQU 0x4C4F434B  ; Unlocks the GPIO_CR register
SYSCTL_RCGCGPIO_R  EQU 0x400FE608

CYCLE_TIME EQU 8000000


       IMPORT  TExaS_Init
       THUMB
       AREA    DATA, ALIGN=2
;global variables go here


       AREA    |.text|, CODE, READONLY, ALIGN=2
       THUMB
       EXPORT  Start
Start
 ; TExaS_Init sets bus clock at 80 MHz
     BL  TExaS_Init ; voltmeter, scope on PD3
 ; Initialization goes here
    LDR R3, =SYSCTL_RCGCGPIO_R
    LDR R4, [R3]
    ORR R4, #3<<4
    STR R4, [R3]
    NOP
    NOP
    
    LDR R3, =GPIO_PORTE_DIR_R
    LDR R4, [R3]
    ORR R4, #4
    BIC R4, #2
    STR R4, [R3]
    LDR R3, =GPIO_PORTE_DEN_R
    LDR R4, [R3]
    ORR R4, #3<<1
    STR R4, [R3]

    LDR R3, =GPIO_PORTF_DIR_R
    LDR R4, [R3]
    BIC R4, #1<<4
    STR R4, [R3]
    LDR R3, =GPIO_PORTF_DEN_R
    LDR R4, [R3]
    ORR R4, #3
    STR R4, [R3]

     CPSIE  I    ; TExaS voltmeter, scope runs on interrupts
loop  
; main engine goes here
    
    LDR R0, =2000000
    BL run_cycle
     B    loop

; R0 has delay
wait
    SUBS R0, #1
    CMP R0, #0
    BGT wait
    BX LR

; R0 has "on" time
run_cycle
    PUSH {R3, R4, R5, LR}

    LDR R3, =CYCLE_TIME
    SUB R4, R3, R0      ; R4 is "off" time
    
    LDR R3, =GPIO_PORTE_DATA_R  ; ON
    MOV R5, #4
    STR R5, [R3]
    BL wait
                       
    LDR R3, =GPIO_PORTE_DATA_R  ; OFF
    STR R4, [R3]
    MOV R0, R4
    BL wait    
    
    POP {LR, R5, R4, R3}
    BX LR
     ALIGN      ; make sure the end of this section is aligned
     END        ; end of file

