INCLUDE Irvine32.inc

MAXLINES = 200
LINELEN = 80
MAXVARS = 50
NAMELEN = 16
MAXCELLS = 200
TEXTLEN = 64
MAXDEPTH = 20

CELL_EMPTY = 0
CELL_NUMBER = 1
CELL_TEXT = 2

externdef sourceLines:BYTE
externdef lineCount:DWORD
externdef lineIndex:DWORD
externdef fileName:BYTE
externdef wordBuffer:BYTE

externdef blockEnd:DWORD
externdef blockStart:DWORD
externdef nextBranch:DWORD
externdef previousBranch:DWORD
externdef blockStack:DWORD
externdef stackDepth:DWORD

externdef varName:BYTE
externdef varFirstCell:DWORD
externdef varLength:DWORD
externdef varCount:DWORD

externdef cellType:DWORD
externdef cellNumber:DWORD
externdef cellText:BYTE
externdef cellCount:DWORD
