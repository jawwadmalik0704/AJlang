INCLUDE ajlang.inc

.code
GetVariableName PROC, variableIndex:DWORD
    mov eax, variableIndex
    imul eax, NAMELEN
    add eax, OFFSET varName
    ret
GetVariableName ENDP

FindVariable PROC USES ebx, namePointer:DWORD
    mov ebx, 0

CheckVariable:
    cmp ebx, varCount
    jae NotFound
    INVOKE GetVariableName, ebx
    INVOKE Str_compare, namePointer, eax
    je Found
    inc ebx
    jmp CheckVariable

Found:
    mov eax, ebx
    ret

NotFound:
    mov eax, -1
    ret
FindVariable ENDP

DeclareVariable PROC USES ebx, namePointer:DWORD
    INVOKE FindVariable, namePointer
    cmp eax, -1
    jne Finish

    INVOKE Str_length, namePointer
    cmp eax, NAMELEN - 1
    ja NameTooLong

    mov ebx, varCount
    cmp ebx, MAXVARS
    jae TooManyVariables
    mov eax, cellCount
    cmp eax, MAXCELLS
    jae TooManyVariables

    mov varFirstCell[ebx * 4], eax
    mov varLength[ebx * 4], 0
    inc cellCount
    INVOKE GetVariableName, ebx
    INVOKE Str_copy, namePointer, eax
    inc varCount
    mov eax, ebx

Finish:
    ret

NameTooLong:
    INVOKE ReportError, ADDR nameTooLongMessage
    mov eax, -1
    ret

TooManyVariables:
    INVOKE ReportError, ADDR tooManyVariablesMessage
    mov eax, -1
    ret
DeclareVariable ENDP

CellForReference PROC, namePointer:DWORD
    INVOKE FindVariable, namePointer
    cmp eax, -1
    je NotDefined
    mov eax, varFirstCell[eax * 4]
    ret

NotDefined:
    INVOKE ReportNameError, namePointer, ADDR undefinedVariableMessage
    mov eax, -1
    ret
CellForReference ENDP

GetCellTextAddress PROC, cell:DWORD
    mov eax, cell
    imul eax, TEXTLEN
    add eax, OFFSET cellText
    ret
GetCellTextAddress ENDP

SetCellNumber PROC USES eax ebx, cell:DWORD, value:DWORD
    mov ebx, cell
    mov cellType[ebx * 4], CELL_NUMBER
    mov eax, value
    mov cellNumber[ebx * 4], eax
    ret
SetCellNumber ENDP

SetCellText PROC USES eax ebx, cell:DWORD, textPointer:DWORD
    mov ebx, cell
    mov cellType[ebx * 4], CELL_TEXT
    INVOKE GetCellTextAddress, ebx
    INVOKE CopyRestOfLine, textPointer, eax, TEXTLEN - 1
    ret
SetCellText ENDP

GetCellNumber PROC USES ebx, cell:DWORD, resultPointer:PTR DWORD
    mov ebx, cell
    cmp cellType[ebx * 4], CELL_NUMBER
    jne NotANumber

    mov eax, cellNumber[ebx * 4]
    mov ebx, resultPointer
    mov [ebx], eax
    mov eax, 1
    ret

NotANumber:
    INVOKE ReportError, ADDR numberNeededMessage
    mov eax, 0
    ret
GetCellNumber ENDP

StoreValue PROC, cell:DWORD, textPointer:DWORD
    LOCAL number:DWORD

    INVOKE IsNumberText, textPointer
    cmp eax, 0
    je StoreText

    INVOKE ParseNumber, textPointer, ADDR number
    cmp eax, 0
    je NotANumber
    INVOKE SetCellNumber, cell, number
    mov eax, 1
    ret

StoreText:
    INVOKE SetCellText, cell, textPointer
    mov eax, 1
    ret

NotANumber:
    INVOKE ReportError, ADDR numberNeededMessage
    mov eax, 0
    ret
StoreValue ENDP

ReadNumberValue PROC, textPointer:DWORD, resultPointer:PTR DWORD
    INVOKE IsNumberText, textPointer
    cmp eax, 0
    je ReadVariable

    INVOKE ParseNumber, textPointer, resultPointer
    cmp eax, 0
    je NotANumber
    ret

ReadVariable:
    INVOKE ReadName, textPointer
    cmp nameBuffer, 0
    je NotANumber
    cmp BYTE PTR [eax], 0
    jne NotANumber

    INVOKE CellForReference, ADDR nameBuffer
    cmp eax, -1
    je Failed
    INVOKE GetCellNumber, eax, resultPointer
    ret

NotANumber:
    INVOKE ReportError, ADDR numberNeededMessage

Failed:
    mov eax, 0
    ret
ReadNumberValue ENDP

DoSet PROC, textPointer:DWORD
    LOCAL valuePointer:DWORD, cell:DWORD

    INVOKE SkipSpaces, textPointer
    INVOKE ReadName, eax
    mov valuePointer, eax
    cmp nameBuffer, 0
    je BadCommand
    movzx eax, BYTE PTR [eax]
    INVOKE IsWordEnd, eax
    cmp eax, 0
    je BadCommand

    INVOKE DeclareVariable, ADDR nameBuffer
    cmp eax, -1
    je Failed
    mov eax, varFirstCell[eax * 4]
    mov cell, eax

    INVOKE SkipSpaces, valuePointer
    mov valuePointer, eax
    cmp BYTE PTR [eax], 0
    je SetToZero
    INVOKE StoreValue, cell, valuePointer
    ret

SetToZero:
    INVOKE SetCellNumber, cell, 0
    mov eax, 1
    ret

BadCommand:
    INVOKE ReportError, ADDR unknownCommandMessage

Failed:
    mov eax, 0
    ret
DoSet ENDP

ApplyOperator PROC USES ebx edx, operator:DWORD, leftValue:DWORD, rightValue:DWORD, resultPointer:PTR DWORD
    mov eax, leftValue
    cmp operator, '+'
    je AddValue
    cmp operator, '-'
    je SubtractValue
    cmp operator, '*'
    je MultiplyValue

    cmp rightValue, 0
    je DivideByZero
    cdq
    idiv rightValue
    jmp StoreResult

AddValue:
    add eax, rightValue
    jmp StoreResult

SubtractValue:
    sub eax, rightValue
    jmp StoreResult

MultiplyValue:
    imul eax, rightValue

StoreResult:
    mov ebx, resultPointer
    mov [ebx], eax
    mov eax, 1
    ret

DivideByZero:
    INVOKE ReportError, ADDR divideByZeroMessage
    mov eax, 0
    ret
ApplyOperator ENDP

DoMath PROC USES esi, textPointer:DWORD
    LOCAL operator:DWORD, leftCell:DWORD, leftValue:DWORD, rightValue:DWORD

    INVOKE ReadName, textPointer
    INVOKE SkipSpaces, eax
    mov esi, eax
    movzx eax, BYTE PTR [esi]
    mov operator, eax

    INVOKE CellForReference, ADDR nameBuffer
    cmp eax, -1
    je Failed
    mov leftCell, eax
    INVOKE GetCellNumber, leftCell, ADDR leftValue
    cmp eax, 0
    je Failed

    add esi, 2
    INVOKE SkipSpaces, esi
    mov esi, eax
    INVOKE ReadNumberValue, esi, ADDR rightValue
    cmp eax, 0
    je Failed

    INVOKE ApplyOperator, operator, leftValue, rightValue, ADDR leftValue
    cmp eax, 0
    je Failed
    INVOKE SetCellNumber, leftCell, leftValue
    mov eax, 1
    ret

Failed:
    mov eax, 0
    ret
DoMath ENDP

END
