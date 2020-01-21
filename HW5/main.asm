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
	;	INCLUDE 'derivative.inc' 

ROMStart    EQU  $4000  ; absolute address to place my code/constant data
RAMStart    EQU  $0800

; variable/data section

            ORG RAMStart
 ; Insert here your data definition.
samples     DC.B $90,$55,$A0,$00,$20,$CC,$88,$77
pelements   DS.B 8
nsum        DS.B 1
pnumber     DS.B 1


; code section
            ORG   ROMStart


Entry:
_Startup:

            ldx   #samples
            ldy   #pelements
            ldab  #8
  
  loop:     ldaa  1,x+
            bgt   positive
            beq   done
            adda  nsum
            staa  nsum
            bra   done
  positive: staa  1,y+
            inc   pnumber
  done:     dbne  b,loop
            RTS                   ; result in D

;**************************************************************
;*                 Interrupt Vectors                          *
;**************************************************************
            ORG   $FFFE
            DC.W  Entry           ; Reset Vector
