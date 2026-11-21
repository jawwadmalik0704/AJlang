INCLUDE Irvine32.inc

MAXLINES = 200
LINELEN = 80
MAXVARS = 50
NAMELEN = 16
MAXCELLS = 200
TEXTLEN = 64
MAXDEPTH = 20
RAWSIZE = MAXLINES * LINELEN
FILENAME_SIZE = 129

CELL_EMPTY = 0
CELL_NUMBER = 1
CELL_TEXT = 2

KW_UNKNOWN = 0
KW_LIKHO = 1
KW_RUKO = 2

externdef sourceLines:BYTE
externdef rawBuffer:BYTE
externdef lineCount:DWORD
externdef lineIndex:DWORD
externdef currentLine:DWORD
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

externdef unknownCommandMessage:BYTE
externdef fileNotFoundMessage:BYTE
externdef fileReadMessage:BYTE
externdef programTooLongMessage:BYTE

LoadProgram PROTO
RunProgram PROTO
RunLine PROTO

GetLineAddress PROTO, lineNumber:DWORD
SkipSpaces PROTO, textPointer:DWORD
ReadWord PROTO, textPointer:DWORD
MatchKeyword PROTO

DoLikho PROTO, textPointer:DWORD
DoRuko PROTO

ReportError PROTO, messagePointer:DWORD
ShowMessage PROTO, messagePointer:DWORD
