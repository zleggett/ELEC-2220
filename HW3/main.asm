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
va     DS.B 3
vb     DS.B 5
vc     DS.W 4
vd     DC.B $A,$10,$B,"B"
ve     DC.W $03,$210,$800,$810,"1"


; code section
            ORG   ROMStart


Entry:
_Startup:

        ldaa   #$12
        staa   va
        ldx    $814
        ldx    #$814
        ldaa   -3,x
        staa   -$10,x
        ldab   2,+x
        ldy    b,x
        stab   b,y
        staa   [4,x]
        ldd    #2
        staa   [d,x]
        ldx    #vd
        ldaa   5,+x
        ldaa   3,-x
        staa   1,-x
            RTS                   

;**************************************************************
;*                 Interrupt Vectors                          *
;**************************************************************
            ORG   $FFFE
            DC.W  Entry           ; Reset Vector
