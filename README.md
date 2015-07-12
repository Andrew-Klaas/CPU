mp3
UPDATE:
- found a bug 
	LDI R1, R0, BLAH
	ADD R1, R1, 1

	// R1 is getting set to 1 instead of adding the loaded value plus 1
