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
            XDEF Entry, _Startup            ; export 'Entry' symbol
            ABSENTRY Entry        ; for absolute assembly: mark this as application entry point





PORTA       EQU  $0000
DDRA        EQU  $0002
ROMStart    EQU  $4000  ; absolute address to place my code/constant data
RAMStart    EQU  $0800

; variable/data section

            ORG RAMStart
 ; Insert here your data definition.
LEDS        DS.B 1            ;LED output
Initial     DC.B 3,5          ;intial sequence values
direction   DS.B 1            ;shift direction (1-left, 0-right)
length      DS.B 1            ;sequence length
position    DS.B 1            ;index within LEDS
max         DS.B 1            ;maximum index
min         DS.B 1            ;minimum index
loop_count  DC.B 2            ;number of initial sequence values
delay1      DC.B $20          ;delay first loop value
delay2      DC.W $FFFF        ;delay second loop value
delay3      DC.W $3000        ;delay third loop value

; code section
            ORG   ROMStart


Entry:
_Startup:

                lds     #$2000
                movb    #$FF,DDRA
                jsr     delay
                ldx     #Initial
                movb    #$1,direction      ;Makes sure intial doirection is always left
  loop:         jsr     delay
                clr     LEDS               ;Clears LEDS in-between Initial values
                movb    1,x+,position      ;Loads in Intial value
                movb    #$1,LEDS
                ldaa    position
                beq     bypass             ;Checks if intial position is 0
  initial_pos:  lsl     LEDS               ;Sets LEDS to starting position
                dbne    a,initial_pos
                movb    LEDS,PORTA         ;Outputs to IO_LEDS
                jsr     delay
                jsr     find_maxmin        ;Finds max. min, and length
                ldaa    position
                cmpa    #7                 ;Checks if intial position is 7
                beq     bypass
                dec     length             ;Decrement length since we already have starting position in LEDS
  more:         jsr     update_LEDS        ;Changes LEDS to follow cycle
                movb    LEDS,PORTA         ;Outputs to IO_LEDS
                jsr     delay
                dec     length
                bgt     more
                bra     next               ;Skips bypass if not 0 or 7
  bypass:       movb    LEDS,PORTA
  next:         dec     loop_count
                bgt     loop               ;Executes main twice
  
            RTS
            
      
            
  ;find_maxmin:
  ;Subroutine to determine sequence length, maximum and minimum
  ;levels based on initial level.
  ;Registers modified: A
  ;Variables modified: max, min, length
  ;Variables passed: position       
            
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
            
                 RTS
                 
  
  
  
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
                   
   
   
   ;delay
   ;Subroutine which creates a software delay
   ;Registers modified: NONE
   ;Variables modified: delay1, delay2, delay3
   ;Variables passed: delay1, delay2, delay3
    
    delay:                                 
       loop1:     movw #$FFFF,delay2
       more1:     movw #$3000,delay3
       more2:     dec   delay3
                  bne   more2
                  dec   delay2
                  bne   more1
                  dec   delay1
                  bne   loop1
                  
                  RTS
                  

;**************************************************************
;*                 Interrupt Vectors                          *
;**************************************************************
            ORG   $FFFE
            DC.W  Entry           ; Reset Vector
