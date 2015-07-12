ORIGIN 4x0000
SEGMENT CodeSegment:

BRANCH_PREDICTION:
   
   ; R0 contains zero
   ; R1 is a loop counter for each test
   ; R2 is updated after each test.  Check that the modelsim values in R2
   ;     match the expected ones
   ; R3 generally contains junk created by setting the condition codes
   ; R4 points the LardSegment data array
   
   ; T = Taken,               N = not taken
   ; C = correctly predicted, X = mispredicted
   
   AND   R0, R0, 0               ;  R0 <--   0x0000 | PC = 0x00DA
   ADD   R2, R0, 4x0003          ;  R2 <--   0x0003

   ; Test backward TC, TX, NC, and NX
   ADD   R1, R0, -5              ;  R1 <-- 0xFFFB
MAGIC:
   ADD   R2, R2, R1              ;  R2 <-- 0xFFFE|     |0x0003|  |0x0007|  |0x000A|  |0x000C|  |0x000D|
   ADD   R1, R1, -1              ;               |     |      |  |      |  |      |  |      |  |      |
   BRp   MAGIC                   ;               |NC|  |      |TX|      |TX|      |TC|      |TC|      |NX|
   NOT   R1, R1                  ;                  |  |                                                 |
   BRp   MAGIC                   ;                  |TX|                                                 |NX|
                                 ;                                                                         \|/
      ; Basically NOPS, just used to divide up the tests/opcodes in the simulator
   LEA   R3, Steel               ;  R3 <-- 0x007C for now
   LEA   R3, Iron                ;  R3 <-- 0x007A for now
   LEA   R3, Bronze              ;  R3 <-- 0x0078 for now
   
   ; Test forward TC, TX, NC, and NX
   ADD   R1, R0, 5               ;  R1 <-- 0x0005
   LEA   R4, LardSegment         ;  R4 <-- 0x0042 for now
ARCHERY:
   LDR   R5, R4, 0               ;  R5 <-- 0xCAFE|                  |0xAC1D|           |0xBEEF|           |0xDEAF|           |FACE|
   AND   R3, R5, 4x0001          ;               |&|                |      |&|         |      |&|         |      |&|         |    |&|
   BRp   Melee                   ;                 |NC|             |        |TX|      |        |TX|      |        |TC|      |      |NX|
   ADD   R2, R2, R5              ;  R2 <--            |0xCB0B|      |           |      |           |      |           |      |         |0xC5D9|
Melee:                           ;                           |      |           |      |           |      |           |      |                |
   ADD   R4, R4, 2               ;                           |+|    |           |+|    |           |+|    |           |+|    |                |+|
   ADD   R1, R1, -1              ;                             |+|  |             |+|  |             |+|  |             |+|  |                  |+|
   BRp   Archery                 ;                               |TX|               |TC|               |TC|               |TC|                    |NX|
                                 ;                                                                                                                  \|/
   ; Test branch predictions for other control flow instructions
   ADD   R1, R0, 3
   LEA   R6, Summoning
Summoning:
   TRAP  Hamsters                ;         TX|                              |TC|                              |TC|
   JSR   Puppies                 ;           |         |TX|                 |  |         |TC|                 |  |         |TC|
   ADD   R1, R1, -1              ;           |         |  |         |+|     |  |         |  |         |+|     |  |         |  |         |+|
   BRnz  X86_SUX                 ;           |         |  |         | |NC|  |  |         |  |         | |NC|  |  |         |  |         | |TX|
   JMP   R6                      ;           |         |  |         |    |TX|  |         |  |         |    |TC|  |         |  |         |    |
Bunnies:                         ;           |         |  |         |          |         |  |         |          |         |  |         |    |
   ADD   R2, R2, R1              ; R2 <--    |0xC5DC|  |  |         |          |0xC5E3|  |  |         |          |0xC5E9|  |  |         |    |
   RET                           ;                  |TX|  |         |                 |TC|  |         |                 |TC|  |         |    |
Puppies:                         ;                        |         |                       |         |                       |         |    |
   ADD   R2, R2, 5               ; R2 <--                 |0xC5E1|  |                       |0xC5E8|  |                       |0xC5EE|  |    |
   RET                           ;                               |TX|                              |TC|                              |TC|    |
X86_SUX:                         ;                                                                                                          \|/
   BRnzp X86_SUX

Hamsters:   DATA2    Bunnies

SEGMENT LardSegment:
Point:      DATA2    4xCAFE
Line:       DATA2    4xAC1D
Square:     DATA2    4xBEEF
Cube:       DATA2    4xDEAF
Tesseract:  DATA2    4xFACE

Quark:      DATA2    4x0EDD
Broton:     DATA2    4xACED
Atom:       DATA2    4xBEAD
Molecule:   DATA2    4xD1CE
Protien:    DATA2    4x0BEE
Organelle:  DATA2    4x1DEA
Cell:       DATA2    4x1CED
Tissue:     DATA2    4xB00B
Organ:      DATA2    4x0ECE
Organism:   DATA2    4xC0DE
Society:    DATA2    4xFEED

Happy:      DATA2    Quark
Grumpy:     DATA2    Broton
Sleepy:     DATA2    Atom
Dopey:      DATA2    Molecule
Bashful:    DATA2    Protien
Sneezy:     DATA2    Organelle
Doc:        DATA2    Cell
SnowWhite:  DATA2    Tissue
Prince:     DATA2    Organ
EvilQueen:  DATA2    Organism
Mirror:     DATA2    Society

SEGMENT DataSegment:
Bronze:     DATA2    4x1111
Iron:       DATA2    4xCC33
Steel:      DATA1    4x21
            DATA1    4x43