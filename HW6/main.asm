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





ROMStart    EQU  $4000  ; absolute address to place my code/constant data
RAMStart    EQU  $0800

; variable/data section

            ORG RAMStart
 ; Insert here your data definition.
LEDS        DS.B 1
Initial     DC.B 5,2
direction   DS.B 1
length      DS.B 1
position    DS.B 1
max         DS.B 1
min         DS.B 1
loop_count  DC.B 2
LED_initial DS.B 1


; code section
            ORG   ROMStart


Entry:
_Startup:

                lds     #$2000
                ldx     #Initial
                movb    #$1,direction      ;Makes sure intial doirection is always left
  loop:         clr     LEDS               ;Clears LEDS inbetween Intial values
                movb    1,x+,position      ;Loads in Intial value
                ldaa    position
                movb    #$1,LED_initial
  initial_pos:  lsl     LED_initial           ;Finds the starting postion
                dbne    a,initial_pos
                movb    LED_initial,LEDS      ;Copies starting postion into LEDS
                ldaa    LEDS
                cmpa    #$80                   ;Checks if already at max position
                bne     bypass
                movb    #$0,direction
  bypass:       jsr     find_maxmin           ;Finds max. min, and length
                dec     length                ;Decrement length since we already have starting position in LEDS
  more:         jsr     update_LEDS           ;Changes LEDS to follow cycle
                dec     length
                bgt     more
                dec     loop_count
                bgt     loop                  ;Executes main twice
  
            RTS
            
            
            
            
    find_maxmin: ldaa   position      ;Finds max
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
                 
                 
                 
    update_LEDS:  ldaa  direction
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
                   
    
                             

;**************************************************************
;*                 Interrupt Vectors                          *
;**************************************************************
            ORG   $FFFE
            DC.W  Entry           ; Reset Vector
