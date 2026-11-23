INCLUDE ajlang.inc

.data
leftToken BYTE LINELEN DUP(0)
operatorToken BYTE LINELEN DUP(0)
rightToken BYTE LINELEN DUP(0)
equalWord BYTE "==",0
notEqualWord BYTE "!=",0
greaterEqualWord BYTE ">=",0
lessEqualWord BYTE "<=",0
greaterWord BYTE ">",0
lessWord BYTE "<",0
operatorTable DWORD OFFSET equalWord, OFFSET notEqualWord, OFFSET greaterEqualWord
              DWORD OFFSET lessEqualWord, OFFSET greaterWord, OFFSET lessWord, 0

.code
MatchOperator PROC USES ebx edx
    mov ebx, 0

CheckOperator:
    mov edx, operatorTable[ebx * 4]
    cmp edx, 0
    je NotFound
    INVOKE Str_compare, ADDR operatorToken, edx
    je Found
    inc ebx
    jmp CheckOperator

Found:
    lea eax, [ebx + 1]
    ret

NotFound:
    mov eax, 0
    ret
MatchOperator ENDP

LoadOperand PROC USES ebx edx, tokenPointer:DWORD, numberPointer:PTR DWORD, textAddressPointer:PTR DWORD
    LOCAL cell:DWORD

    INVOKE IsNumberText, tokenPointer
    cmp eax, 0
    je ReadReference
    INVOKE ParseNumber, tokenPointer, numberPointer
    cmp eax, 0
    je NotANumber
    mov eax, CELL_NUMBER
    ret

ReadReference:
    INVOKE ReadName, tokenPointer
    cmp nameBuffer, 0
    je BadOperand
    INVOKE ReferenceCell, tokenPointer, ADDR cell, 1
    cmp eax, 0
    je Failed
    cmp BYTE PTR [eax], 0
    jne BadOperand

    mov ebx, cell
    cmp cellType[ebx * 4], CELL_TEXT
    je TextOperand
    mov eax, cellNumber[ebx * 4]
    mov edx, numberPointer
    mov [edx], eax
    mov eax, CELL_NUMBER
    ret

TextOperand:
    INVOKE GetCellTextAddress, ebx
    mov edx, textAddressPointer
    mov [edx], eax
    mov eax, CELL_TEXT
    ret

NotANumber:
    INVOKE ReportError, ADDR numberNeededMessage
    jmp Failed

BadOperand:
    INVOKE ReportError, ADDR unknownCommandMessage

Failed:
    mov eax, -1
    ret
LoadOperand ENDP

CompareNumbers PROC USES edx, leftValue:DWORD, rightValue:DWORD, operatorCode:DWORD
    mov eax, leftValue
    mov edx, rightValue
    cmp operatorCode, OP_EQUAL
    je CheckEqual
    cmp operatorCode, OP_NOT_EQUAL
    je CheckNotEqual
    cmp operatorCode, OP_GREATER_EQUAL
    je CheckGreaterEqual
    cmp operatorCode, OP_LESS_EQUAL
    je CheckLessEqual
    cmp operatorCode, OP_GREATER
    je CheckGreater

    cmp eax, edx
    jl IsTrue
    jmp IsFalse

CheckEqual:
    cmp eax, edx
    je IsTrue
    jmp IsFalse

CheckNotEqual:
    cmp eax, edx
    jne IsTrue
    jmp IsFalse

CheckGreaterEqual:
    cmp eax, edx
    jge IsTrue
    jmp IsFalse

CheckLessEqual:
    cmp eax, edx
    jle IsTrue
    jmp IsFalse

CheckGreater:
    cmp eax, edx
    jg IsTrue

IsFalse:
    mov eax, 0
    ret

IsTrue:
    mov eax, 1
    ret
CompareNumbers ENDP

CompareEquality PROC, isEqual:DWORD, operatorCode:DWORD
    mov eax, isEqual
    cmp operatorCode, OP_EQUAL
    je Finish
    cmp operatorCode, OP_NOT_EQUAL
    jne NumberNeeded
    xor eax, 1

Finish:
    ret

NumberNeeded:
    INVOKE ReportError, ADDR numberNeededMessage
    mov eax, -1
    ret
CompareEquality ENDP

EvaluateCondition PROC USES ebx, textPointer:DWORD
    LOCAL operatorCode:DWORD, leftType:DWORD, rightType:DWORD
    LOCAL leftNumber:DWORD, rightNumber:DWORD, leftText:DWORD, rightText:DWORD

    INVOKE ReadToken, textPointer, ADDR leftToken
    INVOKE ReadToken, eax, ADDR operatorToken
    INVOKE ReadToken, eax, ADDR rightToken
    INVOKE SkipSpaces, eax
    cmp BYTE PTR [eax], 0
    jne BadCondition
    cmp rightToken, 0
    je BadCondition
    INVOKE MatchOperator
    cmp eax, 0
    je BadCondition
    mov operatorCode, eax

    INVOKE LoadOperand, ADDR leftToken, ADDR leftNumber, ADDR leftText
    cmp eax, -1
    je Failed
    mov leftType, eax
    INVOKE LoadOperand, ADDR rightToken, ADDR rightNumber, ADDR rightText
    cmp eax, -1
    je Failed
    mov rightType, eax

    mov eax, leftType
    cmp eax, rightType
    jne DifferentTypes
    cmp eax, CELL_NUMBER
    je BothNumbers

    mov ebx, 1
    INVOKE Str_compare, leftText, rightText
    je CheckEquality

DifferentTypes:
    mov ebx, 0

CheckEquality:
    INVOKE CompareEquality, ebx, operatorCode
    ret

BothNumbers:
    INVOKE CompareNumbers, leftNumber, rightNumber, operatorCode
    ret

BadCondition:
    INVOKE ReportError, ADDR unknownCommandMessage

Failed:
    mov eax, -1
    ret
EvaluateCondition ENDP

SkipBlock PROC
    mov eax, currentLine
    mov eax, blockEnd[eax * 4]
    inc eax
    mov lineIndex, eax
    mov eax, 1
    ret
SkipBlock ENDP

JumpToNextBranch PROC USES ebx, branchLine:DWORD
    mov ebx, branchLine

CheckBranch:
    mov ebx, nextBranch[ebx * 4]
    INVOKE GetLineKeyword, ebx
    cmp eax, KW_WARNA
    jne EnterBranch

    INVOKE GetTextAfterWord, ebx
    INVOKE ElseConditionPointer, eax
    cmp eax, 0
    je EnterBranch
    mov currentLine, ebx
    INVOKE EvaluateCondition, eax
    cmp eax, -1
    je Stop
    cmp eax, 0
    je CheckBranch

EnterBranch:
    lea eax, [ebx + 1]
    mov lineIndex, eax
    mov eax, 1
    ret

Stop:
    mov eax, 0
    ret
JumpToNextBranch ENDP

DoAgar PROC, textPointer:DWORD
    INVOKE EvaluateCondition, textPointer
    cmp eax, -1
    je Stop
    cmp eax, 1
    je Finish
    INVOKE JumpToNextBranch, currentLine

Finish:
    ret

Stop:
    mov eax, 0
    ret
DoAgar ENDP

DoWarna PROC
    mov eax, currentLine
    mov eax, blockEnd[eax * 4]
    mov lineIndex, eax
    mov eax, 1
    ret
DoWarna ENDP

ParseLoopHeader PROC USES esi, lineNumber:DWORD, startPointer:PTR DWORD, endPointer:PTR DWORD
    INVOKE GetTextAfterWord, lineNumber
    INVOKE SkipSpaces, eax
    INVOKE ReadName, eax
    mov esi, eax
    cmp nameBuffer, 0
    je BadHeader

    INVOKE SkipSpaces, esi
    INVOKE ParseDigits, eax, startPointer
    cmp eax, 0
    je BadHeader
    cmp BYTE PTR [eax], '-'
    jne BadHeader
    inc eax
    INVOKE ParseDigits, eax, endPointer
    cmp eax, 0
    je BadHeader
    cmp BYTE PTR [eax], 0
    jne BadHeader

    INVOKE DeclareScalarCell, ADDR nameBuffer
    ret

BadHeader:
    INVOKE ReportError, ADDR unknownCommandMessage
    mov eax, -1
    ret
ParseLoopHeader ENDP

DoLoop PROC
    LOCAL startValue:DWORD, endValue:DWORD

    INVOKE ParseLoopHeader, currentLine, ADDR startValue, ADDR endValue
    cmp eax, -1
    je Stop
    INVOKE SetCellNumber, eax, startValue
    mov eax, startValue
    cmp eax, endValue
    jl Continue
    INVOKE SkipBlock
    ret

Continue:
    mov eax, 1
    ret

Stop:
    mov eax, 0
    ret
DoLoop ENDP

DoRepeat PROC, textPointer:DWORD
    INVOKE EvaluateCondition, textPointer
    cmp eax, -1
    je Stop
    cmp eax, 1
    je Finish
    INVOKE SkipBlock

Finish:
    ret

Stop:
    mov eax, 0
    ret
DoRepeat ENDP

DoEnd PROC USES ebx esi
    LOCAL startValue:DWORD, endValue:DWORD, loopValue:DWORD

    mov ebx, currentLine
    mov ebx, blockStart[ebx * 4]
    INVOKE GetLineKeyword, ebx
    cmp eax, KW_LOOP
    je EndOfLoop
    cmp eax, KW_REPEAT
    je EndOfRepeat
    jmp Continue

EndOfLoop:
    INVOKE ParseLoopHeader, ebx, ADDR startValue, ADDR endValue
    cmp eax, -1
    je Stop
    mov esi, eax
    INVOKE GetCellNumber, esi, ADDR loopValue
    cmp eax, 0
    je Stop
    inc loopValue
    INVOKE SetCellNumber, esi, loopValue
    mov eax, loopValue
    cmp eax, endValue
    jge Continue
    jmp JumpBack

EndOfRepeat:
    mov currentLine, ebx
    INVOKE GetTextAfterWord, ebx
    INVOKE EvaluateCondition, eax
    cmp eax, -1
    je Stop
    cmp eax, 0
    je Continue

JumpBack:
    lea eax, [ebx + 1]
    mov lineIndex, eax

Continue:
    mov eax, 1
    ret

Stop:
    mov eax, 0
    ret
DoEnd ENDP

DoRando PROC USES esi, textPointer:DWORD
    LOCAL cell:DWORD, limit:DWORD

    INVOKE SkipSpaces, textPointer
    INVOKE ReadName, eax
    mov esi, eax
    cmp nameBuffer, 0
    je BadCommand
    movzx eax, BYTE PTR [esi]
    INVOKE IsWordEnd, eax
    cmp eax, 0
    je BadCommand

    INVOKE SkipSpaces, esi
    mov esi, eax
    cmp BYTE PTR [esi], 0
    je BadCommand
    INVOKE DeclareScalarCell, ADDR nameBuffer
    cmp eax, -1
    je Failed
    mov cell, eax

    INVOKE ReadNumberValue, esi, ADDR limit
    cmp eax, 0
    je Failed
    cmp limit, 0
    jle NumberNeeded
    mov eax, limit
    call RandomRange
    INVOKE SetCellNumber, cell, eax
    mov eax, 1
    ret

NumberNeeded:
    INVOKE ReportError, ADDR numberNeededMessage
    jmp Failed

BadCommand:
    INVOKE ReportError, ADDR unknownCommandMessage

Failed:
    mov eax, 0
    ret
DoRando ENDP

DoRuko PROC
    mov eax, 0
    ret
DoRuko ENDP

END
