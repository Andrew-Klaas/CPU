ORIGIN   4x0000
SEGMENT  CodeSegment:

; this tests BOTH the L2 and Victim cache for Dirty evictions for read hits and dirty evictions
;
; The Overall testing strategy was to just hammer a cache line as much as possible with load's and stores
; The values in memory that our pointers point to are detailed at "SEGMENT INDIRECT"
;
; To see these values scroll down and look at Segment Indirect
;
; *****************Also note -> approximate timeings may be off********************
; 
;  L2
;  Shows all ways in a single set being used -> refer to "easy" clean test
;  shows evictions based on plru -> "easy" test
;  
;  shows multiple sets being accessed -> highlight any way
;  shows dirty/clean evictions L2 -> show any victim writes "8952"
;  shows multiple consecutive cache misses, initial LDI's "beginning of program"
;  shows LRU policy on L2 -> eviction. take a look at "9672" -> LRU = 4, so replacement set should equal way 1
;
;  VICTIM
;  shows  evictions VICTIM    "13888"
;  shows LRU policy on victim cache "13888"
;  shows Multiple Dirty evictions -> expand victim table tab


	LEA R0,  INDIRECT
	LDI R1, R0, way_one_line1     ;1111, to see these values scroll down and look at Segment Indirect
	LDI R2, R0, way_two_line1     ;4444
	LDI R3, R0, way_three_line1   ;AAAA
	LDI R4, R0, way_four_line1    ;dddd
	LDI R5, R0, way_five_line1    ;7777
	LDI R6, R0, way_six_line1     ;1234
	LDI R7, R0, way_seven_line1   ;7777

	AND R1, R1, 0
	AND R2, R2, 0
	AND R3, R3, 0
	AND R4, R4, 0
	AND R5, R5, 0
	AND R6, R6, 0
	AND R7, R7, 0
      
        ;Change register values so we can easily see results later on	
	ADD R1, R1, 1
	ADD R2, R2, 2
	ADD R3, R3, 3
	ADD R4, R4, 4
	ADD R5, R5, 5
	ADD R6, R6, 6
	ADD R7, R7, 7

	
	STI R1, R0, way_one_line1    	; Store "1" ->  "6825ns"
	AND R1, R1, 0
	ADD R1, r1, 8
	LDI R1, R0, way_eight_line1  	;8888
	STI R1, R0, way_eight_line1  	; Store "8" -> "7485ns"	
	STI R2, R0, way_two_line1    	; Store "2"
	STI R3, R0, way_three_line1  	; Store "3"
	
	; ******NOTE ****** This is where our first Dirty evicts start to begin. The first is on way 0, where before it held the value of "1" stored from R1
	
	; Now it is getting replaced by R4's "4", also note that the evicted value "1" is written to the victim cache.
	; Victim wrote to at "8245ns", way 0 replaced at "8505"
	STI R4, R0, way_four_line1   ; Store "4"  
	
	;"8" is dirty evicted from way 2, written to victim at "8925ns", to make room for storing "5"
	STI R5, R0, way_five_line1   ; Store "5"
	
	;"2" is dirty evicted from way 1, written to victim at "9318ns", to make room for storing "6"
	STI R6, R0, way_six_line1    ; Store "6"
	
	;"3" is dirty evicted from way 3, written to victim at "9710ns", to make room for storing "7"
	STI R7, R0, way_seven_line1  ; Store "7"
	
	
	LDI R1, R0, way_nine_line1
	AND R1, R1, 0
	ADD R1, R1, 9
	;"4" is dirty evicted from way 0, written to victim at "10065ns", to make room for storing "9"
	STI R1, R0, way_nine_line1   ; store "9" -> "10385.415ns"

	LDR R1, R0, BLAH	     ; FILL with "FFFF", makes it easy to see changes
	LDR R2, R0, BLAH
	LDR R3, R0, BLAh
	LDR R4, R0, BLAH
	LDR R5, R0, BLAH
	LDR R6, r0, BLAH
	LDR R7, R0, BLAH

	;******NOTE***** This is where hits in the victim cache hits begin to occur -> L2 -> L1 -> CPU
	;victim cache hit at "12107ns", 
	LDI R1, R0, way_one_line1 ;1  "11485ns"
	AND R1, R1, 0
	STI R1, R0, way_one_line1
	
	;victim cache hit at "12845ns", 
	LDI R2, R0, way_two_line1 ;2
	AND r2, r2, 0  
	sti r2, r0, way_two_line1	
	
	;victim cache hit at "13277.578ns"
	LDI R3, R0, way_three_line1 ;3
	and r3, r3, 0
	STI R3, R0, way_three_line1
	
	;******NOTE***** This is where evictions of the VICTIM begin "14022ns"
   
	;victim cache hit at "14228.432ns"
	LDI R4, R0, way_four_line1 ;4  
	AND R4, R4, 0
	STI R4, R0, way_four_line1

	
	;*****NOTE****** there is no Victim cache hit here, The time taken to load is much longer
	LDI R5, R0, way_five_line1 ;5 
	AND R5, R5, 0
	STI R5, R0, way_five_line1

	;victim cache hit
	LDI R6, R0, way_six_line1 ;6
	AND R6, R6, 0
	STI R6, R0, way_six_line1

	;victim cache hit
	LDI R7, R0, way_seven_line1 ; 7
	AnD R7, R7, 0
	STI R7, R0, way_seven_line1

	;victim cache hit
	LDI R1, R0, way_eight_line1 ;8  
	AND R1, R1, 0
	STI R1, R0, way_eight_line1 

	LDI R2, R0, way_nine_line1  ; 9 
	AND R2, R2, 0		    ; 0
	STI R2, R0, way_nine_line1

	;Fill all the registers with "FFFF"
	LDR R1, R0, BLAH
	LDR R2, R0, BLAH
	LDR R3, R0, BLAh
	LDR R4, R0, BLAH
	LDR R5, R0, BLAH
	LDR R6, r0, BLAH
	LDR R7, R0, BLAH
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; This block causes a lot of bugs
	LDI R1, R0, way_one_line1 ; 1  PC = 0x0058 | R1 <-- 0x0000 | t = 11,215    ; This succeeds
	ADD R1, R1, 1             ;    PC = 0x005A | R1 <-- 0x0001 | t = 12,225    ; This fails
	STI R1, R0, way_one_line1 ;    PC = 0x005C
	
	LDI R2, R0, way_two_line1 ;2
	ADD r2, r2, 2  
	STI r2, r0, way_two_line1	
	
	LDI R3, R0, way_three_line1 ;3
	add r3, r3, 3
	STI R3, R0, way_three_line1

	LDI R4, R0, way_four_line1 ;4  "13824ns"
	ADD R4, R4, 4
	STI R4, R0, way_four_line1

	LDI R5, R0, way_five_line1 ;5 
	ADD R5, R5, 5
	STI R5, R0, way_five_line1

	LDI R6, R0, way_six_line1 ;6
	ADD R6, R6, 6
	STI R6, R0, way_six_line1

	LDI R7, R0, way_seven_line1 ; 7
	ADD R7, R7, 7
	STI R7, R0, way_seven_line1

	LDI R1, R0, way_eight_line1 ;8 "16876ns" -> where bug shows up should be 8 but is 3 the bug happens at "8888"
	ADD R1, R1, 8
	STI R1, R0, way_eight_line1 

	LDI R2, R0, way_nine_line1  ; 9 
	ADD R2, R2, 9		    ; change to 1, easy to read when finished
	STI R2, R0, way_nine_line1

	;Fill all the registers with "FFFF"
	LDR R1, R0, BLAH
	LDR R2, R0, BLAH
	LDR R3, R0, BLAH
	LDR R4, R0, BLAH
	LDR R5, R0, BLAH
	LDR R6, R0, BLAH
	LDR R7, R0, BLAH
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	LDI R1, R0, way_one_line1	
	LDI R2, R0, way_two_line1 ;
	LDI R3, R0, way_three_line1 
	LDI R4, R0, way_four_line1 ;
	LDI R5, R0, way_five_line1
	LDI R6, R0, way_six_line1  ; 
	LDI R7, R0, way_seven_line1
	
	STI R1, R0, way_one_line1	
	STI R2, R0, way_two_line1 ;
	STI R3, R0, way_three_line1 
	STI R4, R0, way_four_line1 ;
	STI R5, R0, way_five_line1
	STI R6, R0, way_six_line1  ; 
	STI R7, R0, way_seven_line1
	
		;Fill all the registers with "FFFF"
	LDR R1, R0, BLAH
	LDR R2, R0, BLAH
	LDR R3, R0, BLAH
	LDR R4, R0, BLAH
	LDR R5, R0, BLAH
	LDR R6, R0, BLAH
	LDR R7, R0, BLAH
	
	LDI R1, R0, way_one_line1	
	LDI R2, R0, way_two_line1 ;
	LDI R3, R0, way_three_line1 
	LDI R4, R0, way_four_line1 ;
	LDI R5, R0, way_five_line1
	LDI R6, R0, way_six_line1  ; 
	LDI R7, R0, way_seven_line1
	LDI R1, R0, way_eight_line1
	LDI R2, R0, way_nine_line1 ; 
	
	
	
   HALT:                   ; Infinite loop to keep the processor
       BRnzp HALT          ; from trying to execute the data below.
 SEGMENT INDIRECT:
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

