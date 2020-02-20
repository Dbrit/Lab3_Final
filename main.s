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
CYCLE_TIME_100Hz EQU 160000

;SIN_WAVE DCD 0,631,2513,5618,9895,15279,21683,29006,37134,45938,55279,65009,74977,85023,94991,104721,114062,122866,130994,138317,144721,150105,154382,157487,159369,160000,159369,157487,154382,150105,144721,138317,130994,122866,114062,104721,94991,85023,74977,65009,55279,45938,37134,29006,21683,15279,9895,5618,2513,631

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

    LDR R3, =GPIO_PORTF_LOCK_R
    LDR R4, =0x4C4F434B
    STR R4, [R3]
    LDR R3, =GPIO_PORTF_CR_R
    LDR R4, [R3]
    ORR R4, #1<<4
    STR R4, [R3]
    LDR R3, =GPIO_PORTF_DEN_R
    LDR R4, [R3]
    ORR R4, #1<<4
    STR R4, [R3]
    LDR R3, =GPIO_PORTF_DIR_R
    LDR R4, [R3]
    BIC R4, #1<<4
    STR R4, [R3]
    LDR R3, =GPIO_PORTF_PUR_R
    LDR R4, [R3]
    ORR R4, #1<<4
    STR R4, [R3]

    LDR R7, =4000000;2400000 "on" time

     CPSIE  I    ; TExaS voltmeter, scope runs on interrupts
loop  
; main engine goes here
    
    
    BL checkButton1
    BL checkButton2
    
    MOV R0, R7
    BL run_cycle
    B    loop

checkButton1
    PUSH {R4, R5, R6, LR}
    LDR R4, =GPIO_PORTE_DATA_R
    LDR R5, [R4]
    AND R5, #2
    CMP R5, #0
    BHI buttonPressed
    POP{R4,R5,R6,LR}
    BX LR
buttonPressed
    LDR R4, =GPIO_PORTE_DATA_R
    MOV R5, #0
    STR R5, [R4]
    BL incrementDutyCycle
    BL waitButton1Release
    POP {R4, R5, R6, LR}
    BX LR
    
    
incrementDutyCycle
    PUSH {R4,R5}
    LDR R4, =1600000
    ADD R7, R4
    LDR R4, =8000000
    CMP R7, R4
    BHI reset
    POP {R4,R5}
    BX LR
reset
    LDR R7, =800000
    POP {R4,R5}
    BX LR

waitButton1Release
    PUSH {R4,R5}
loopButton1Release
    LDR R4, =GPIO_PORTE_DATA_R
    LDR R5, [R4]
    AND R5, #2
    CMP R5, #0
    BHI loopButton1Release
    POP {R4,R5}
    BX LR

; R0 has delay
wait
    SUBS R0, #1
    CMP R0, #0
    BGT wait
    BX LR

; R0 has "on" time
run_cycle
    PUSH {R6, R4, R5, LR}

    LDR R6, =CYCLE_TIME
    SUB R4, R6, R0      ; R4 is "off" time
    
    LDR R6, =GPIO_PORTE_DATA_R  ; ON
    MOV R5, #4
    STR R5, [R6]
    BL wait
                       
    LDR R6, =GPIO_PORTE_DATA_R  ; OFF
    MOV R5, #0
    STR R5, [R6]
    MOV R0, R4
    BL wait    
    
    POP {LR, R5, R4, R6}
    BX LR
    
checkButton2
    PUSH {R4, R5, R7, LR}
    LDR R4, =GPIO_PORTF_DATA_R
    LDR R5, [R4]
    AND R5, #1<<4
    CMP R5, #1
    BLO buttonPressed2
    POP{R4,R5,R6,LR}
    BX LR
buttonPressed2
    LDR R4, =GPIO_PORTE_DATA_R
    MOV R5, #0
    STR R5, [R4]
    LDR R7, =16000
    LDR R6, =1000
    PUSH {R6, R4, R5, LR}
    BL breathe
    POP {R6,R4,R5,LR}
    POP {R4, R5, R7, LR}
    BX LR

breathe
    MOV R0, R7
    LDR R4, =GPIO_PORTF_DATA_R
    LDR R5, [R4]
    AND R5, #1<<4
    CMP R5, #1
    BLO keepBreathing
    BX LR
keepBreathing
    ADD R7, R7, R6
    LDR R4, =160000
    CMP R7, R4
    BHI reset1
    PUSH {LR, R11}
    BL run_cycle_100Hz
    POP {LR, R11}
    B breathe
reset1
    LDR R7, =16000
    PUSH {LR, R11}
    BL run_cycle_100Hz
    POP {LR, R11}
    B breathe

; R0 has "on" time
run_cycle_100Hz
    PUSH {LR, R5, R4, R6}
    LDR R6, =CYCLE_TIME_100Hz
    SUB R4, R6, R0      ; R4 is "off" time
    
    LDR R6, =GPIO_PORTE_DATA_R  ; ON
    MOV R5, #4
    STR R5, [R6]
    BL wait
                       
    LDR R6, =GPIO_PORTE_DATA_R  ; OFF
    MOV R5, #0
    STR R5, [R6]
    MOV R0, R4
    BL wait    
    
    POP {LR, R5, R4, R6}
    BX LR
    
    
     ALIGN      ; make sure the end of this section is aligned
     END        ; end of file
