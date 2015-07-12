; this tests the L2 cache for clean evictions and PLRU policy


; RUN TIME 
;    -> VICTIM AND L2   -> 
;    -> L2 NO VICTIM    ->
;    -> NO L2 NO VICITM ->
;


ORIGIN 4x0000
SEGMENT  CodeSegment:
	;LEA R0,  INDIRECT
	LDI R1, R0, way_one_line1     ;1111, to see these values scroll down and look at Segment Indirect
	LDI R2, R0, way_two_line1     ;4444
	LDI R3, R0, way_three_line1   ;AAAA
	LDI R4, R0, way_four_line1    ;dddd
	LDI R5, R0, way_five_line1    ;7777

	LDI R6, R0, way_nine_line1
	LDI R7, R0, way_one_line1     ;1111, to see these values scroll down and look at Segment Indirect
	LDI R1, R0, way_two_line1     ;4444
	LDI R2, R0, way_three_line1   ;AAAA
	LDI R3, R0, way_four_line1    ;dddd
	LDI R4, R0, way_five_line1    ;7777

	
	
	
   HALT:                   ; Infinite loop to keep the processor
       BRnzp HALT          ; from trying to execute the data below.
 ;SEGMENT INDIRECT:
   way_one_line1: DATA2 way1_line1 ;1111
   ;way_one_line2: DATA2 way1_line2  ;2222
   ;way_one_line3: DATA2 way1_line3 ;3333

   way_two_line1: DATA2 way2_line1  ;4444
   ;way_two_line2: DATA2 way2_line2   ;5555
   ;way_two_line3: DATA2 way2_line3  ;6666

   way_three_line1: DATA2 way3_line1  ;AAAA
   ;way_three_line2: DATA2 way3_line2   ;BBBB
   ;way_three_line3: DATA2 way3_line3  ;CCCC

   way_four_line1: DATA2 way4_line1   ;DDDD
   ;way_four_line2: DATA2 way4_line2    ;EEEE
   ;way_four_line3: DATA2 way4_line3   ;FFFF

   way_five_line1: DATA2 way5_line1   ;7777
   ;way_five_line2: DATA2 way5_line2    ;8888
   ;way_five_line3: DATA2 way5_line3   ;9999
   
   way_six_line1: DATA2 way6_line1    ;1234
   ;way_six_line2: DATA2 way6_line2     ;5678
   ;way_six_line3: DATA2 way6_line3    ;ABCD
	
   way_seven_line1: DATA2 way7_line1    ;7777
   ;way_seven_line2: DATA2 way7_line2     ;7777
   ;way_seven_line3: DATA2 way7_line3    ;7777

   way_eight_line1: DATA2 way8_line1    ;8888
   ;way_eight_line2: DATA2 way8_line2     ;8888
   ;way_eight_line3: DATA2 way8_line3    ;8888
	
   way_nine_line1: DATA2 way9_line1    ;9999
   ;way_nine_line2: DATA2 way9_line2     ;9999
   ;way_nine_line3: DATA2 way9_line3    ;9999

   BLAH : DATA2 4xFFFF



SEGMENT 512 Way1:
	way1_line1: DATA2 4x1111
	DATA2 4x0000
    DATA2 4x0000
	DATA2 4x0000
	DATA2 4x0000
	DATA2 4x0000
	DATA2 4x0000
	DATA2 4x0000

	way1_line2: DATA2 4x2222
	DATA2 4x0000
    DATA2 4x0000
	DATA2 4x0000
	DATA2 4x0000
	DATA2 4x0000
	DATA2 4x0000
	DATA2 4x0000

	way1_line3: DATA2 4x3333
	DATA2 4x0000
    DATA2 4x0000
	DATA2 4x0000
	DATA2 4x0000
	DATA2 4x0000
	DATA2 4x0000
	DATA2 4x0000

SEGMENT  512 Way2:
	way2_line1: DATA2 4x4444
	DATA2 4x0000
    DATA2 4x0000
	DATA2 4x0000
	DATA2 4x0000
	DATA2 4x0000
	DATA2 4x0000
	DATA2 4x0000

	way2_line2: DATA2 4x5555
	DATA2 4x0000
    DATA2 4x0000
	DATA2 4x0000
	DATA2 4x0000
	DATA2 4x0000
	DATA2 4x0000
	DATA2 4x0000

	way2_line3: DATA2 4x6666
	DATA2 4x0000
    DATA2 4x0000
	DATA2 4x0000
	DATA2 4x0000
	DATA2 4x0000
	DATA2 4x0000
	DATA2 4x0000

SEGMENT  512 Way3:
	way3_line1: DATA2 4xAAAA
	DATA2 4x0000
    DATA2 4x0000
	DATA2 4x0000
	DATA2 4x0000
	DATA2 4x0000
	DATA2 4x0000
	DATA2 4x0000

	way3_line2: DATA2 4xBBBB
	DATA2 4x0000
    DATA2 4x0000
	DATA2 4x0000
	DATA2 4x0000
	DATA2 4x0000
	DATA2 4x0000
	DATA2 4x0000

	way3_line3: DATA2 4xCCCC
	DATA2 4x0000
    DATA2 4x0000
	DATA2 4x0000
	DATA2 4x0000
	DATA2 4x0000
	DATA2 4x0000
	DATA2 4x0000

SEGMENT  512 Way_4:
	way4_line1: DATA2 4xDDDD
	DATA2 4x0000
    DATA2 4x0000
	DATA2 4x0000
	DATA2 4x0000
	DATA2 4x0000
	DATA2 4x0000
	DATA2 4x0000

	way4_line2: DATA2 4xEEEE
	DATA2 4x0000
    DATA2 4x0000
	DATA2 4x0000
	DATA2 4x0000
	DATA2 4x0000
	DATA2 4x0000
	DATA2 4x0000

	way4_line3: DATA2 4xFFFF
	DATA2 4x0000
    DATA2 4x0000
	DATA2 4x0000
	DATA2 4x0000
	DATA2 4x0000
	DATA2 4x0000
	DATA2 4x0000

SEGMENT  512 Way_5:
	way5_line1: DATA2 4x7777
	DATA2 4x0000
    DATA2 4x0000
	DATA2 4x0000
	DATA2 4x0000
	DATA2 4x0000
	DATA2 4x0000
	DATA2 4x0000

	way5_line2: DATA2 4x8888
	DATA2 4x0000
    DATA2 4x0000
	DATA2 4x0000
	DATA2 4x0000
	DATA2 4x0000
	DATA2 4x0000
	DATA2 4x0000

	way5_line3: DATA2 4x9999
	DATA2 4x0000
    DATA2 4x0000
	DATA2 4x0000
	DATA2 4x0000
	DATA2 4x0000
	DATA2 4x0000
	DATA2 4x0000

SEGMENT  512 Way_6:
	way6_line1: DATA2 4x1234
	DATA2 4x0000
    DATA2 4x0000
	DATA2 4x0000
	DATA2 4x0000
	DATA2 4x0000
	DATA2 4x0000
	DATA2 4x0000

	way6_line2: DATA2 4x5678
	DATA2 4x0000
    DATA2 4x0000
	DATA2 4x0000
	DATA2 4x0000
	DATA2 4x0000
	DATA2 4x0000
	DATA2 4x0000

	way6_line3: DATA2 4xABCD
	DATA2 4x0000
    DATA2 4x0000
	DATA2 4x0000
	DATA2 4x0000
	DATA2 4x0000
	DATA2 4x0000
	DATA2 4x0000

SEGMENT  512 Way_7:
	way7_line1: DATA2 4x7777
	DATA2 4x0000
    DATA2 4x0000
	DATA2 4x0000
	DATA2 4x0000
	DATA2 4x0000
	DATA2 4x0000
	DATA2 4x0000

	way7_line2: DATA2 4x7777
	DATA2 4x0000
    DATA2 4x0000
	DATA2 4x0000
	DATA2 4x0000
	DATA2 4x0000
	DATA2 4x0000
	DATA2 4x0000

	way7_line3: DATA2 4x7777
	DATA2 4x0000
    DATA2 4x0000
	DATA2 4x0000
	DATA2 4x0000
	DATA2 4x0000
	DATA2 4x0000
	DATA2 4x0000

SEGMENT  512 Way_8:
	way8_line1: DATA2 4x8888
	DATA2 4x0000
    DATA2 4x0000
	DATA2 4x0000
	DATA2 4x0000
	DATA2 4x0000
	DATA2 4x0000
	DATA2 4x0000

	way8_line2: DATA2 4x8888
	DATA2 4x0000
    DATA2 4x0000
	DATA2 4x0000
	DATA2 4x0000
	DATA2 4x0000
	DATA2 4x0000
	DATA2 4x0000

	way8_line3: DATA2 4x8888
	DATA2 4x0000
    DATA2 4x0000
	DATA2 4x0000
	DATA2 4x0000
	DATA2 4x0000
	DATA2 4x0000
	DATA2 4x0000

SEGMENT  512 Way_9:
	way9_line1: DATA2 4x9999
	DATA2 4x0000
    DATA2 4x0000
	DATA2 4x0000
	DATA2 4x0000
	DATA2 4x0000
	DATA2 4x0000
	DATA2 4x0000

	way9_line2: DATA2 4x9999
	DATA2 4x0000
    DATA2 4x0000
	DATA2 4x0000
	DATA2 4x0000
	DATA2 4x0000
	DATA2 4x0000
	DATA2 4x0000

	way9_line3: DATA2 4x9999
	DATA2 4x0000
    DATA2 4x0000
	DATA2 4x0000
	DATA2 4x0000
	DATA2 4x0000
	DATA2 4x0000
	DATA2 4x0000

