;*****************************************************************
;* This stationery serves as the framework for a                 *
;* user application (single file, absolute assembly application) *
;* For a more comprehensive program that                         *
;* demonstrates the more advanced functionality of this          *
;* processor, please see the demonstration applications          *
;* located in the examples subdirectory of the                   *
;* Freescale CodeWarrior for the HC12 Program directory          *
;*****************************************************************

; export symbols
            XDEF Entry, _Startup        ;export 'Entry' symbol
            ABSENTRY Entry     ;for absolute assembly: mark this as 
                               ;application entry point





PORTA       EQU  $0000
PORTB       EQU  $0001
PORTE       EQU  $0008
DDRA        EQU  $0002
DDRE        EQU  $0009
ROMStart    EQU  $4000  ; absolute address to place my code/constant data
RAMStart    EQU  $0800

; variable/data section

            ORG RAMStart
 ; Insert here your data definition.
LEDS        DS.B 1            ;LED output
direction   DS.B 1            ;shift direction (1-left, 0-right)
length      DS.B 1            ;sequence length
position    DS.B 1            ;index within LEDS
max         DS.B 1            ;maximum index
min         DS.B 1            ;minimum index
TSCR1       EQU  $0046        ;timer control system register 1
TSCR2       EQU  $004D        ;timer control system register 2
TFLG1       EQU  $004E        ;timer interrupt flag register 1
TIOS        EQU  $0040        ;timer input capture/output compare select
TCNT        EQU  $0044        ;timer counter
TC1         EQU  $0052        ;timer input capture/output compare channel 1
Bit7        EQU  %10000000    ;Bit masks
Bit1        EQU  %00000010
Bit2        EQU  %00000100
Bit0        EQU  %00000001
NumClk      EQU  20000        ;number of clocks for timer
INTCR       EQU  $001E        ;IRQ interrupt address
NumDelay    DS.B 1            ;number of times the delay subroutine 
                              ;will be called
DivNum      DC.B $F0          ;number used to determine NumDelay 
                              ;for various lengths
DelayCount  DS.B 1            ;used to track number of delays called
Key_flag    DS.B 1            ;set if new key is pressed and read
Key_value   DS.B 1            ;holds the value of new key
Mask        DC.B $FE,$FD,$FB,$F7,$EF    ;masks used for Key_ISR
clear_flag  DC.B 0            ;set if valid clear is triggered
StartValue  DS.B 1            ;starting value for current sequence

; code section
            ORG   ROMStart


Entry:
_Startup:

                lds     #$2000
                movb    #$FF,DDRA       ;Initialize ports and interrupts
                movb    #$FF,DDRE
                movb    #$40,INTCR
                cli
                movb    #0,PORTE
                

      loop:     clr     clear_flag       ;Waits for valid sequence value
                wai
                ldaa    Key_value         ;Checks if new key is 0-7
                cmpa    #7
                bgt     loop
                
                             
    new_value:  movb    Key_value,StartValue  ;Sets new key values as 
                clr     Key_flag              ;sequence start value
    repeat:     movb    #$1,direction         ;Makes sure intial direction 
                                              ;is always left
                movb    StartValue,position
                movb    #$1,LEDS
                jsr     find_maxmin   ;Finds max. min, and length
                tst     position      ;If position is zero, 
                                      ;skips shifting LEDS
                beq     zero_case1
                
                ldaa    position
  initial_pos:  lsl     LEDS               ;Sets LEDS to starting position
                dbne    a,initial_pos
                
                
                
  zero_case1:   tst     Key_flag         ;Tests if new key has been pressed
                beq     bypass
                ldab    Key_value
                cmpb    position          ;Checks if new key is same as 
                                          ;current sequence start value
                beq     bypass
                cmpb    #$7               ;Checks if key is less than or 
                                          ;equal to 7 for new 
                                          ;squence start value
                ble     new_value
                cmpb    #$B               ;Checks if pause key is pressed
                beq     Prog_stop
                clr     Key_flag
                bra     bypass
  Prog_stop:    jsr     StopProgram       ;If pause s pressed, goes to 
                                          ;StopProgram routine
                tst     clear_flag        ;Checks if valid clear has been 
                                          ;pressed after pause
                beq     bypass
                clr     LEDS
                movb    LEDS,PORTA
                bra     loop
         
  bypass:      
                movb    LEDS,PORTA      ;Outputs initial position to LEDS
                tst     length          ;If 0 or 7, goes into infinite loop
                beq     zero_case1      ;waiting for new key press
                
                movb    NumDelay,DelayCount
                
  delay_loop1:                                 ;Calls delay the caclulated 
                                               ;number of times
                jsr     delay
                dec     DelayCount
                bne     delay_loop1
                
                
                
                dec     length           ;Decrement length since we already
                                         ;have starting position in LEDS
  more:         jsr     update_LEDS      ;Changes LEDS to follow cycle
                
                tst     Key_flag         ;Tests if new key has been pressed
                beq     bypass3
                ldab    Key_value
                cmpb    position           ;Checks if new key is same as 
                                           ;current sequence start value
                beq     bypass3
                cmpb    #$7                ;Checks if key is less than or 
                                           ;equal to 7 for new 
                                           ;sequence start value
                lble    new_value
                cmpb    #$B                ;Checks if pause key is pressed
                beq     Prog_stop1
                clr     Key_flag
                bra     bypass3
  Prog_stop1:   jsr     StopProgram        ;If pause s pressed, goes to 
                                           ;StopProgram routine
                tst     clear_flag         ;Checks if valid clear has been 
                                           ;pressed after pause
                beq     bypass3
                clr     LEDS
                movb    LEDS,PORTA
                lbra    loop
                
  bypass3:      
                movb    LEDS,PORTA         ;Outputs to IO_LEDS
                movb    NumDelay,DelayCount
                
 delay_loop2:     
                jsr     delay
                dec     DelayCount          ;Calls delay the caclulated 
                                            ;number of times
                bne     delay_loop2
                
                
                dec     length           ;Repeats updating LEDS if needed
                bgt     more
   bypass2:     lbra    repeat
  
            RTS
            
      
            
  ;find_maxmin:
  ;Subroutine to determine sequence length, maximum, minimum, and
  ;number of delays to be used.
  ;Registers modified: A, B, X
  ;Variables modified: max, min, length, NumDelay 
  ;Variables passed: position, DivNum       
            
    find_maxmin:                      
                 ldaa   position      ;Finds max
                 adda   position 
                 cmpa   #$7
                 bgt    larger
                 staa   max
                 bra    minimum
      larger:    movb   #$7,max
      minimum:   suba   #$7           ;Finds min
                 bgt    larger_2
                 movb   #$0,min
                 bra    getLength
      larger_2:  staa   min
      getLength: ldaa   max           ;Finds length
                 suba   min
                 staa   length
                 adda   length
                 staa   length
                 
                 tst    length
                 bne    skip
                 movb   DivNum,NumDelay
                 bra    end1
        skip:    clra
                 ldab   length
                 tfr    d,x
                 clra            ;Finds number of times to call delay
                 ldab   DivNum    
                 idiv
                 clra
                 tfr    x,d
                 stab   NumDelay     
            
        end1:     RTS
                 
  
  
  
  ;update_LEDS
  ;Subroutine which updates LEDS depending on the direction
  ;Registers modified: A, B
  ;Variables modified: direction (conditional), LEDS, position
  ;Variables passed: direction (1-left, 0-right), position, max, min                
                 
    update_LEDS:                       
                  ldaa  direction      
                  bgt   left
                  lsr   LEDS            ;Shifts LEDS to the right
                  dec   position
                  ldab  position
                  cmpb  min
                  beq   change
                  bra   done
      left:       lsl   LEDS            ;Shifts LEDS to the left
                  inc   position
                  ldab  position
                  cmpb  max
                  beq   change
                  bra   done
      change:     eora  #$1             ;Changes direction if at max or min
                  staa  direction
      done:
                  
                  RTS
  
  
                   
  ;StopProgram
  ;Subroutine which pauses program and chaecks for resume or clear keys
  ;Registers modified: A
  ;Variables modified: Key_flag, Key_value, clear_flag
  ;Variables passed: Key_flag, Key_value, clear_flag   
   
   StopProgram:
                
                clr     clear_flag
      wait:
                tst     Key_flag
                beq     wait
                ldaa    Key_value
                clr     Key_flag
                cmpa    #$0C             ;Checks if resume has been pressed
                beq     done_here
                cmpa    #$0A             ;Checks if clear has been pressed
                beq     need_clear
                bra     wait
  need_clear:   movb    #1,clear_flag
  done_here:    movb    StartValue,Key_value
  
                RTS
   
   
   
   
   
   
   
   ;delay
   ;Subroutine which creates a software delay
   ;Registers modified: D
   ;Variables modified: TSCR1, TSCR2, TIOS, TFLG1, TCNT, TC1
   ;Variables passed: TSCR1, TSCR2, TIOS, TFLG1, TCNT, TC1, Bit1
   ;NumClk, Key_flag, Key_value, position 
    
    delay:   
                bset    TSCR1,Bit7
                bclr    TSCR2,Bit0
                bset    TSCR2,Bit1
                bset    TIOS,Bit1
                movb    #Bit1,TFLG1
                ldd     TCNT
                addd    #NumClk
                std     TC1
       spin:    
                tst     Key_flag
                beq     bypass4
                ldab    Key_value
                cmpb    position
                beq     bypass4
                cmpb    #7
                ble     end2
                cmpb    #$B
                beq     end2
                bra     bypass4
                
      bypass4:  
                brclr   TFLG1,Bit1,spin         
                  
       end2:           RTS
                  
                  


;Key_ISR
;Interrupt Service Routine (Key_ISR) identifies the key pressed on 
;IT_Keyboard and computes the value of the pressed key. It grounds 
;column(s) and reads from rows where columns and rows are connected
;to Port A and Port B, respectively. The key value is returned in
;Key_value and the status of identification is returned in Key_fag.
;Variables modified: Key_value, Key_flag
;Variables passed: Mask
                
     Key_ISR:
                clrb
                ldx   #Mask
        back1:  movb  1,x+,PORTE
                ldaa  PORTB
                cmpa  #$FF
                bne   pressed
                incb
                cmpb  #4
                bne   back1
                bra   no_key
                
                
     pressed:   ldx   #Mask
                ldy   #5
     next_row:  cmpa  1,x+
                beq   stop_add
                addb  #4
                dbne  y,next_row
                bra   no_key
                
      stop_add: stab  Key_value
                movb  #1,Key_flag
      no_key:   movb  #0,PORTE
                
                RTI                                
                         
      
                  

;**************************************************************
;*                 Interrupt Vectors                          *
;**************************************************************

            
            ORG  $FFF2
            DC.W  Key_ISR
            
            ORG   $FFFE
            DC.W  Entry           ; Reset Vector

