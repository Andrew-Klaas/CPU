ORIGIN 4x0000
SEGMENT CodeSegment:

   ;  DISCLAIMER:  Most of these tests also depend on other tests in order to work
   ;     (something in the MEMORY test may require part of FORWARDING)
   ;  
   ;  Skip to a particular test by changing the label
   ;  ALL_TESTS
   ;  MEMORY
   ;  BASIC_ARITHMETIC
   ;  EXTENDED_ARITHMETIC
   ;  CONTROL_FLOW
   ;  FORWARDING
   
   AND      R0, R0, R0     ;     Just initializes the condition codes
   BRnzp    CONTROL_FLOW
   
ALL_TESTS:

MEMORY:
   LEA   R0, DataSegment   ;     R0 <-- <ptr> - 0x00B2 at the moment
   LDR   R1, R0, Bronze    ;     R1 <-- 0x1111
   LDR   R2, R0, Iron      ;     R2 <-- 0xCC33
   LDR   R3, R0, -1        ;     R3 <-- 0xAAAA
   LDB   R1, R0, Steel     ;     R1 <-- 0x0021
   LDB   R2, R0, Mithril   ;     R2 <-- 0x0043
   STR   R3, R0, Addy
   LDR   R4, R0, Addy      ;     R4 <-- 0xAAAA
   STB   R2, R0, Addy
   STB   R1, R0, Dragon
   LDR   R5, R0, Addy      ;     R5 <-- 0xAA43
   LDR   R6, R0, Runite    ;     R6 <-- 0x2177
   STI   R6, R0, Gold
   LDI   R7, R0, Gold      ;     R7 <-- 0x2177
   LDR   R1, R0, Steel     ;     R1 <-- 0x4321
   STR   R1, R0, Addy      ;     
   LDR   R2, R0, Addy      ;     R2 <-- 0x4321
   
BASIC_ARITHMETIC:
   AND   R0, R0, 0         ;     R0 <-- 0x0000
   ADD   R1, R0, 8         ;     R1 <-- 0x0008
   ADD   R2, R1, 4         ;     R2 <-- 0x000C
   ADD   R3, R2, -16       ;     R3 <-- 0xFFFC
   AND   R4, R3, -5        ;     R4 <-- 0xFFF8
   ADD   R5, R4, R2        ;     R5 <-- 0x0004
   AND   R6, R4, R2        ;     R6 <-- 0x0008
   LSHF  R7, R1, 1         ;     R7 <-- 0x0010
   RSHFA R0, R4, 2         ;     R0 <-- 0xFFFE
   RSHFL R1, R4, 2         ;     R1 <-- 0x3FFE
   RSHFA R2, R1, 12        ;     R2 <-- 0x0003
   NOT   R3, R1            ;     R3 <-- 0xC001

EXTENDED_ARITHMETIC:
   ; This is where things like SUB and MULT will go

CONTROL_FLOW:              ;     0x003E for now
   AND   R0, R0, 0         ;     1     R0 <-- 0x0000
   BRnp  Hell              ;     2
   BRz   Air               ;     3
   BRnzp Hell
Water:                     ;     0x0046 for now
   ADD   R1, R0, 2         ;     7     R1 <-- 0x0002
   ADD   R5, R0, -1        ;     9
   BRzp  Hell              ;     0
   BRn   Earth             ;     10
   BRnzp Hell
Air:                       ;     0x0050 for now
   ADD   R1, R0, 1         ;     4     R1 <-- 0x0001
   BRnz  Hell              ;     5
   BRp   Water             ;     6
   BRnzp Hell
Earth:                     ;     0x0058 for now
   ADD   R1, R0, 3         ;     11    R1 <-- 0x0003
   LEA   R6, Fire          ;     12    R6 <-- <ptr>
   JMP   R6                ;     13
   BRnzp Hell
   BRnzp Hell
   BRnzp Hell
Fire:                      ;     0x0064 for now
   ADD   R1, R0, 4         ;     14    R1 <-- 0x0004
   JSR   Mind              ;     15
   ADD   R1, R0, 6         ;     18
   LEA   R5, Chaos         ;     19    R5 <-- <ptr>
   JSRR  R5                ;     23
   ADD   R1, R0, 8         ;     24    R1 <-- 0x0008
   TRAP  Death             ;     25
   ADD   R1, R0, 10        ;     28    R1 <-- 0x000A
   BRnzp FORWARDING        ;     29
   
Mind:                      ;     0x0076 for now
   ADD   R1, R0, 5         ;     16    R1 <-- 0x0005
   RET                     ;     17 (RET really tests JSRR R7)
Chaos:                     ;     0x007A for now
   ADD   R1, R0, 7         ;     21    R1 <-- 0x0006
   RET                     ;     22
Death:                     ;     0x007E for now
   DATA2 Blood
Blood:                     ;     0x0080 for now
   ADD   R1, R0, 9         ;     26    R1 <-- 0x0009
   RET                     ;     27
   
FORWARDING:
   ; A = newest value forwarded from the execute stage
   ; B = oldest value forwarded from the execute stage
   ; C = value forwarded from the memory stage

   ; Just initialize some registers.  No forwarding yet
   AND   R0, R0, 0
   ADD   R1, R0, 1
   ADD   R2, R0, 2
   LEA   R3, DataSegment
   NOP
   NOP
   NOP
   NOP
   NOP
   ; Now for the real forwarding testing (execute only)
   ADD   R4, R1, 3         ;     R4 <-- 0x0004 <-- (R1 + imm5)
   ADD   R5, R4, 1         ;     R5 <-- 0x0005 <-- (A  + imm5)
   ADD   R6, R4, -5        ;     R6 <-- 0xFFFF <-- (B  + imm5)
   ADD   R6, R2, 4         ;     R6 <-- 0x0006 <-- (R2 + imm5)
   ADD   R7, R6, 1         ;     R7 <-- 0x0007 <-- (A  + imm5)
   ADD   R4, R6, R7        ;     R4 <-- 0x000D <-- (B  + A)
   ADD   R5, R4, R7        ;     R5 <-- 0x0014 <-- (A  + B)
   ADD   R6, R5, R1        ;     R6 <-- 0x0015 <-- (A  + R1)
   ADD   R7, R5, R2        ;     R7 <-- 0x0016 <-- (B  + R2)
   ADD   R4, R1, R7        ;     R4 <-- 0x0017 <-- (R1 + A)
   ADD   R5, R2, R7        ;     R5 <-- 0x0018 <-- (R2 + B)
   ADD   R6, R1, R2        ;     R6 <-- 0x0003 <-- (R1 + R2)
   ; Test forwarding that interacts with the memory stage
   LDR   R7, R3, Silver    ;     R7 <-- <ptr>  <-- (*R3)
   LDR   R4, R7, 0         ;     R4 <-- 0x1111 <-- (*C)
   ADD   R7, R7, -2        ;     R7 <-- <ptr>  <-- (R7) 
   ADD   R5, R4, -3        ;     R5 <-- 0x110E <-- (C)
   LDR   R6, R7, 0         ;     R6 <-- 0xAAAA <-- (*B)
   ADD   R7, R7, 6         ;     R7 <-- <ptr>  <-- (R7)
   LDR   R7, R7, 0         ;     R7 <-- 0x4321 <-- (*A)   

Heaven:
   BRnzp Heaven

Hell:
   BRnzp Hell

Coal:    DATA2    4xAAAA
SEGMENT DataSegment:
Bronze:  DATA2    4x1111
Iron:    DATA2    4xCC33
Steel:   DATA1    4x21
Mithril: DATA1    4x43
Addy:    DATA1    4x55
         DATA1    4x55
Runite:  DATA1    4x77
Dragon:  DATA1    4x77
Silver:  DATA2    Bronze
Gold:    DATA2    Iron

