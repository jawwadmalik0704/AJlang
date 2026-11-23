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
KW_SET = 3
KW_BATAO = 4

externdef sourceLines:BYTE
externdef rawBuffer:BYTE
externdef lineCount:DWORD
externdef lineIndex:DWORD
externdef currentLine:DWORD
externdef fileName:BYTE
externdef wordBuffer:BYTE
externdef nameBuffer:BYTE

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
externdef undefinedVariableMessage:BYTE
externdef nameTooLongMessage:BYTE
externdef tooManyVariablesMessage:BYTE
externdef numberNeededMessage:BYTE
externdef divideByZeroMessage:BYTE

LoadProgram PROTO
RunProgram PROTO
RunLine PROTO

GetLineAddress PROTO, lineNumber:DWORD
SkipSpaces PROTO, textPointer:DWORD
ReadWord PROTO, textPointer:DWORD
MatchKeyword PROTO
IsDigitCharacter PROTO, character:DWORD
IsNameStart PROTO, character:DWORD
IsNameCharacter PROTO, character:DWORD
IsWordEnd PROTO, character:DWORD
IsMathOperator PROTO, character:DWORD
ReadName PROTO, textPointer:DWORD
IsNumberText PROTO, textPointer:DWORD
ParseNumber PROTO, textPointer:DWORD, resultPointer:PTR DWORD
CopyRestOfLine PROTO, source:DWORD, destination:DWORD, maxLength:DWORD
IsMathLine PROTO, textPointer:DWORD

FindVariable PROTO, namePointer:DWORD
DeclareVariable PROTO, namePointer:DWORD
CellForReference PROTO, namePointer:DWORD
GetCellTextAddress PROTO, cell:DWORD
SetCellNumber PROTO, cell:DWORD, value:DWORD
SetCellText PROTO, cell:DWORD, textPointer:DWORD
GetCellNumber PROTO, cell:DWORD, resultPointer:PTR DWORD
StoreValue PROTO, cell:DWORD, textPointer:DWORD
ReadNumberValue PROTO, textPointer:DWORD, resultPointer:PTR DWORD

DoLikho PROTO, textPointer:DWORD
DoBatao PROTO, textPointer:DWORD
DoSet PROTO, textPointer:DWORD
DoMath PROTO, textPointer:DWORD
DoRuko PROTO

ReportError PROTO, messagePointer:DWORD
ReportNameError PROTO, namePointer:DWORD, messagePointer:DWORD
ShowMessage PROTO, messagePointer:DWORD
