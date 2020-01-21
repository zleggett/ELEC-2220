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



; Include derivative-specific definitions 
;		INCLUDE 'derivative.inc' 

RAMStart    EQU  $0800
ROMStart    EQU  $4000  ; absolute address to place my code/constant data

; variable/data section

            ORG RAMStart
 ; Insert here your data definition.
samples     DC.B $20,$30,$40,$A0,$B0,$90
sum         DS.B 1


; code section
            ORG   ROMStart


Entry:
_Startup:
  ldaa  $800
  staa  sum
  adda  $801
  staa  sum
  ldx   #$802
  adda  $1,x+
  staa  sum
  adda  $1,x+
  staa  sum
  adda  0,x
  staa  sum
  ldab  #$1
  adda  b,x
  staa  sum  
            RTS                   ; result in D

;**************************************************************
;*                 Interrupt Vectors                          *
;**************************************************************
            ORG   $FFFE
            DC.W  Entry           ; Reset Vector
