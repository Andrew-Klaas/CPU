ORIGIN 4x0000
Segment CodeSegment:

; This is the final test program designed to agressivly test all possible
; paths associated with the forwarding unit.
; The program is designed in such a way that it will branch to the
; "Hell" label and set all registers to 0x0BAD when any error occurrs.  If the
; entire program runs correctly, it will end at the "HEAVEN" label with all
; the register values set to 0x600D.

;  The following is a summary of what the test cases are designed to verify:
;  The CPU has a number of paths which are summarized below:
;  
;  All possible data sources:
;  1) REG  (The register file unforwarded)
;  2) EXE1 (the most recently forwarded value from the execute stage)
;  3) EXE2 (the second most recently forwarded value from the execute stage)
;  4) MEM  (a value forwarded from the memory unit)
;
;  All possible data destinations:
;  A) SR1 of the ALU
;  B) SR2 of the ALU
;  C) Address for an LDR/LDB/STR/STB instruction
;  D) Address for an LDI/STI instruction
;  E) Data for an STR/STB instruction
;  F) Data for an STI instruction
;  G) Value used to calculate the condition codes of a dependant BR
;  H) Jump address for a dependent JMP/JSRR 
;
;  The first set of test cases uses each of the source options {1, 2, 3, 4}
;  for each of the destinations {A, B, C, D, E, F, G, H, I} for a total of
;  at least 36 tests.  Note that each test may actually test more than it is
;  required to (i.e. for a test of 2A the ALU must recieve SR2 from EXE1 but
;  the other operand can come from anywhere (REG, EXE1, EXE2, or MEM)
;
;  The second set of tests checks instructions which consume data from two
;  different parts of the forwarding unit (2, 3, 4} for all possible
;  destinations {AB, DF, EG}.
   
;  R0 is a pointer to an array of random input data
;  R1 is a checksum to determine if the program is executing correctly
;  < indicates a self-checking instruction (dest is R1)
;  ^ indicates the checksum for the most recent test
   
   LEA   R0, DataSetOne    ;           |        R0 <-- 0x0110
   AND   R1, R1, 4x0000    ;           |        R1 <-- 0x0000
   LDR   R2, R0, L1        ;           |        R2 <-- 0x0154
   NOP
   NOP
   NOP
   ADD   R1, R1, 4x0002    ;  A1 <     |  CheckSum <-- 0x0002
   ADD   R3, R1, 4x0005    ;  A2       |        R3 <-- 0x0007
   ADD   R1, R1, R3        ;  ^        |  CheckSum <-- 0x0009
   ADD   R4, R3, R2        ;  A3       |        R4 <-- 0x015B
   ADD   R1, R1, R4        ;  ^        |  CheckSum <-- 0x0164
   LDR   R5, R0, L1        ;           |        R5 <-- 0x0154
   ADD   R1, R5, R1        ;  A4 <     |  CheckSum <-- 0x02B8
   ADD   R1, R1, R3        ;  B1 <     |  CheckSum <-- 0x02BF
   ADD   R6, R4, R1        ;  B2 <     |        R6 <-- 0x041A
   ADD   R1, R6, R1        ;  B3 <     |  CheckSum <-- 0x06D9
   LDR   R7, R0, L2        ;           |        R7 <-- 0x011E
   ADD   R1, R1, R7        ;  B4 <     |  CheckSum <-- 0x07F7
   LDR   R2, R5, 0         ;  C1       |        R2 <-- 0x63B2
   ADD   R1, R1, R2        ;  ^        |  CheckSum <-- 0x6BA9
   ADD   R3, R7, 2         ;           |        R3 <-- 0x0120
   ADD   R4, R3, -2        ;           |        R4 <-- 0x011E
   LDB   R5, R4, 0         ;  C2       |        R5 <-- 0x0020
   LDR   R6, R0, L5        ;           |        R6 <-- 0x0120
   ADD   R7, R6, 4         ;           |        R7 <-- 0x0124
   ADD   R2, R7, -4        ;           |        R2 <-- 0x0120
   ADD   R1, R1, R5        ;  ^        |  CheckSum <-- 0x6BC9
   STR   R2, R2, 0         ;  C3
   LDR   R3, R2, 0         ;           |        R3 <-- 0x0120
   ADD   R1, R1, R3        ;  ^        |  CheckSum <-- 0x6CE9
   LDR   R5, R0, L7        ;           |        R5 <-- 0x0124
   STB   R4, R3, 0         ;  C4
   LDR   R6, R3, 0         ;           |        R6 <-- 0x011E
   ADD   R1, R1, R6        ;  ^        |  CheckSum <-- 0x6E07
   LDI   R2, R5, 0         ;  D1       |        R2 <-- 0x6D2B
   ADD   R1, R1, R2        ;  ^        |  CheckSum <-- 0xDB32
   LDR   R7, R0, L9        ;           |        R7 <-- 0x0128
   ADD   R2, R7, 6         ;           |        R2 <-- 0x012E
   ADD   R3, R2, -6        ;           |        R3 <-- 0x0128
   LDR   R4, R3, 0         ;  D2       |        R4 <-- 0xD78B
   LDR   R5, R0, L11       ;           |        R5 <-- 0x012C
   ADD   R6, R5, 8         ;           |        R6 <-- 0x0134
   ADD   R7, R6, -8        ;           |        R7 <-- 0x012C
   ADD   R1, R1, R4        ;  ^        |  CheckSum <-- 0xB2BD
   LDI   R2, R7, 0         ;  D3       |        R2 <-- 0x0150
   STI   R3, R2, 0         ;  D4
   LDR   R4, R0, L14       ;           |        R4 <-- 0x7D26
   ADD   R1, R1, R3        ;  > for D3 |  CheckSum <-- 0xB3E5
   LDR   R5, R0, L13       ;           |        R5 <-- 0x0150
   ADD   R1, R1, R5        ;  ^        |  CheckSum <-- 0xB535
   STR   R4, R0, L16       ;  E1
   LDR   R6, R0, L16       ;           |        R6 <-- 0x7D26
   ADD   R1, R1, R6        ;  ^        |  Checksum <-- 0x325B
   STR   R1, R0, L17       ;  E2
   LDR   R7, R0, L17
   ADD   R2, R7, 4x0005    ;           |        R2 <-- 0x3260
   ADD   R1, R1, R7        ;  ^        |  Checksum <-- 0x64B6
   STB   R2, R0, L18       ;  E3
   LDR   R3, R0, L18       ;           |        R3 <-- 0x0B60
   LDR   R4, R0, L20       ;           |        R4 <-- 0x010A
   ADD   R1, R1, R3        ;  ^        |  Checksum <-- 0x7016
   LDR   R5, R0, L15       ;           |        R5 <-- 0xA381
   STB   R5, R0, L19       ;  E4
   LDR   R6, R0, L19       ;           |        R6 <-- 0x0B81
   ADD   R1, R1, R6        ;  ^        |  Checksum <-- 0x7B97
   STI   R4, R0, L22       ;  F1
   LDR   R7, R0, L23       ;           |        R7 <-- 0x010A
   ADD   R1, R1, R7        ;  ^        |  Checksum <-- 0x7CA1
   STI   R1, R0, L24       ;  F2
   LDR   R2, R0, L25       ;           |        R2 <-- 0x7CA1
   ADD   R3, R2, -8        ;           |        R3 <-- 0x7C99
   ADD   R1, R1, R2        ;  ^        |  Checksum <-- 0xF942
   STI   R3, R0, L26       ;  F3
   LDR   R4, R0, L27       ;           |        R4 <-- 0x7C99
   LDR   R5, R0, L30       ;           |        R5 <-- 0x6D2B
   ADD   R1, R1, R4        ;  ^        |  Checksum <-- 0x75DB
   LDR   R6, R0, L21       ;           |        R6 <-- 0x4E98
   STI   R6, R0, L28       ;  F4
   LDR   R7, R0, L29       ;           |        R7 <-- 0x4E98
   ADD   R1, R1, R7        ;  ^        |  Checksum <-- 0xC473
   ADD   R2, R5, -3        ;           |        R2 <-- 0x6D28
   NOP
   NOP
   NOP
   BRnz  Hell              ;  G1
   BRp   PassedG1          ;  G1
   BRnzp Hell              ;  G1
   NOP
   NOP
PassedG1:
   ADD   R1, R1, R2        ; ^         |  Checksum <-- 0x319B
   AND   R3, R3, 0         ;           |        R3 <-- 0x0000
   BRnp  Hell              ;  G2
   BRz   PassedG2          ;  G2
   BRnzp Hell              ;  G2
   NOP
   NOP
PassedG2:
   ADD   R1, R1, 4x0005    ;  ^        |  Checksum <-- 0x31A0
   ADD   R4, R3, -1        ;           |        R4 <-- 0xFFFF
   NOP
   BRzp  Hell              ;  G3
   BRn   PassedG3          ;  G3
   BRnzp Hell              ;  G3
   NOP
   NOP
PassedG3:
   ADD   R1, R1, -4        ;  ^        |  Checksum <-- 0x319C
   LDR   R5, R0, L31       ;           |        R5 <-- 0x144B
   BRnz  Hell              ;  G4
   BRp   PassedG4          ;  G4
   BRnzp Hell              ;  G4
   NOP
   NOP
PassedG4:
   ADD   R1, R1, R5        ;  ^        |  Checksum <-- 0x45E7
   LEA   R6, PassedF1      ;           |        R6 <-- 0x00E6
   JMP   R6                ;  F1
   BRnzp Hell
PassedF1:
   ADD   R1, R1, R6        ;  ^        |  Checksum <-- 0x46CD
   LEA   R7, PassedF2      ;           |        R7 <-- 0x00F0
   JMP   R7                ;  F2
   NOP
   BRnzp Hell
PassedF2:
   LEA   R2, PassedF3      ;           |        R2 <-- 0x0106
   ADD   R1, R1, R7        ;  ^        |  Checksum <-- 0x47BD
   JSRR  R2                ;  F3
   NOP
   NOP
   LDR   R3, R0, L20       ;           |        R3 <-- 0x010A
   JSRR  R3                ;  F4
   LDR   R4, R0, L34       ;  Final CS |        R4 <-- 0x0000
   ADD   R5, R4, R1        ;           |        R5 <-- 0x0000
   BRz   Heaven
   BRnzp Hell
PassedF3:
   ADD   R1, R1, R2        ;  > For F3 |  Checksum <-- 0x48C3
   RET
PassedF4:
   ADD   R1, R1, R3        ;  > For F4 |  Checksum <-- 0x49CD
   RET
   BRnzp Hell

SEGMENT  DataSetOne:
   L18:  DATA2    4x0BAD
   L19:  DATA2    4x0BAD
   L0:   DATA2    4x3967
   L1:   DATA2    L4
   L2:   DATA2    L5
   L3:   DATA2    4xBEAB
   L34:  DATA2    4xB633
   L5:   DATA2    L6
   L6:   DATA2    4x0BAD
   L7:   DATA2    L8
   L8:   DATA2    L30
   L9:   DATA2    L10
   L10:  DATA2    4xD78B
   L11:  DATA2    L12
   L12:  DATA2    L13
   L13:  DATA2    L32
   L14:  DATA2    4x7D26
   L15:  DATA2    4xA381
   L16:  DATA2    4x0BAD
   L17:  DATA2    4x0BAD
   L20:  DATA2    PassedF4
   L21:  DATA2    4x4E98
   L22:  DATA2    L23
   L23:  DATA2    4x0BAD
   L24:  DATA2    L25
   L25:  DATA2    4x0BAD
   L26:  DATA2    L27
   L27:  DATA2    4x0BAD
   L28:  DATA2    L29
   L29:  DATA2    4x0BAD
   L30:  DATA2    4x6D2B
   L31:  DATA2    4x144B
   L32:  DATA2    L33
   L33:  DATA2    4x0BAD
   L4:   DATA2    4x63B2
   
Heaven:
   LEA   R7, Good
   LDR   R0, R7, 0
   LDR   R1, R7, 0
   LDR   R2, R7, 0
   LDR   R3, R7, 0
   LDR   R4, R7, 0
   LDR   R5, R7, 0
   LDR   R6, R7, 0
   LDR   R7, R7, 0
HeavenLoop:
   BRnzp HeavenLoop

Hell:
   LEA   R7, Bad
   LDR   R0, R7, 0
   LDR   R1, R7, 0
   LDR   R2, R7, 0
   LDR   R3, R7, 0
   LDR   R4, R7, 0
   LDR   R5, R7, 0
   LDR   R6, R7, 0
   LDR   R7, R7, 0
HellLoop:
   BRnzp HellLoop

Good:    DATA2    4x600D
Bad:     DATA2    4x0BAD

