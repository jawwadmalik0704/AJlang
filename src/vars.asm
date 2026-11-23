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

CreateVariable PROC USES ebx, namePointer:DWORD, cellsNeeded:DWORD, arrayLength:DWORD
    INVOKE Str_length, namePointer
    cmp eax, NAMELEN - 1
    ja NameTooLong

    mov ebx, varCount
    cmp ebx, MAXVARS
    jae TooManyVariables
    mov eax, cellCount
    add eax, cellsNeeded
    cmp eax, MAXCELLS
    ja TooManyVariables

    mov eax, cellCount
    mov varFirstCell[ebx * 4], eax
    mov eax, arrayLength
    mov varLength[ebx * 4], eax
    mov eax, cellsNeeded
    add cellCount, eax
    INVOKE GetVariableName, ebx
    INVOKE Str_copy, namePointer, eax
    inc varCount
    mov eax, ebx
    ret

NameTooLong:
    INVOKE ReportError, ADDR nameTooLongMessage
    mov eax, -1
    ret

TooManyVariables:
    INVOKE ReportError, ADDR tooManyVariablesMessage
    mov eax, -1
    ret
CreateVariable ENDP

DeclareVariable PROC, namePointer:DWORD
    INVOKE FindVariable, namePointer
    cmp eax, -1
    jne Finish
    INVOKE CreateVariable, namePointer, 1, 0

Finish:
    ret
DeclareVariable ENDP

DeclareScalarCell PROC, namePointer:DWORD
    INVOKE DeclareVariable, namePointer
    cmp eax, -1
    je Finish
    cmp varLength[eax * 4], 0
    jne NeedsIndex
    mov eax, varFirstCell[eax * 4]

Finish:
    ret

NeedsIndex:
    INVOKE ReportNameError, namePointer, ADDR arrayNeedsIndexMessage
    mov eax, -1
    ret
DeclareScalarCell ENDP

DeclareArray PROC, namePointer:DWORD, arrayLength:DWORD
    INVOKE FindVariable, namePointer
    cmp eax, -1
    jne AlreadyDefined
    cmp arrayLength, 0
    je BadSize
    INVOKE CreateVariable, namePointer, arrayLength, arrayLength
    ret

AlreadyDefined:
    INVOKE ReportNameError, namePointer, ADDR alreadyDefinedMessage
    mov eax, -1
    ret

BadSize:
    INVOKE ReportError, ADDR badArraySizeMessage
    mov eax, -1
    ret
DeclareArray ENDP

ReferenceCell PROC USES ebx esi edi, textPointer:DWORD, resultPointer:PTR DWORD, mustBeSet:DWORD
    LOCAL variableIndex:DWORD, index:DWORD, savedName[NAMELEN]:BYTE, indexText[LINELEN]:BYTE

    INVOKE ReadName, textPointer
    mov esi, eax
    cmp nameBuffer, 0
    je BadReference
    INVOKE FindVariable, ADDR nameBuffer
    cmp eax, -1
    je NotDefined
    mov variableIndex, eax
    INVOKE Str_copy, ADDR nameBuffer, ADDR savedName

    mov ebx, variableIndex
    cmp BYTE PTR [esi], '['
    je ReadIndex
    cmp varLength[ebx * 4], 0
    jne NeedsIndex
    mov ebx, varFirstCell[ebx * 4]
    jmp CheckIsSet

ReadIndex:
    cmp varLength[ebx * 4], 0
    je NotAnArray
    inc esi
    lea edi, indexText

CopyIndexCharacter:
    mov al, [esi]
    cmp al, 0
    je BadReference
    cmp al, ']'
    je EndOfIndex
    mov [edi], al
    inc esi
    inc edi
    jmp CopyIndexCharacter

EndOfIndex:
    mov BYTE PTR [edi], 0
    inc esi
    INVOKE ReadNumberValue, ADDR indexText, ADDR index
    cmp eax, 0
    je Failed
    mov eax, index
    cmp eax, 0
    jl OutOfRange
    cmp eax, varLength[ebx * 4]
    jge OutOfRange
    add eax, varFirstCell[ebx * 4]
    mov ebx, eax

CheckIsSet:
    cmp mustBeSet, 0
    je StoreCell
    cmp cellType[ebx * 4], CELL_EMPTY
    jne StoreCell
    mov eax, variableIndex
    cmp varLength[eax * 4], 0
    jne SlotNotSet
    INVOKE ReportNameError, ADDR savedName, ADDR undefinedVariableMessage
    jmp Failed

SlotNotSet:
    INVOKE ReportIndexError, ADDR savedName, index, ADDR undefinedVariableMessage
    jmp Failed

StoreCell:
    mov eax, resultPointer
    mov [eax], ebx
    mov eax, esi
    ret

NotDefined:
    INVOKE ReportNameError, ADDR nameBuffer, ADDR undefinedVariableMessage
    jmp Failed

NeedsIndex:
    INVOKE ReportNameError, ADDR savedName, ADDR arrayNeedsIndexMessage
    jmp Failed

NotAnArray:
    INVOKE ReportNameError, ADDR savedName, ADDR notAnArrayMessage
    jmp Failed

OutOfRange:
    INVOKE ReportIndexError, ADDR savedName, index, ADDR outOfRangeMessage
    jmp Failed

BadReference:
    INVOKE ReportError, ADDR unknownCommandMessage

Failed:
    mov eax, 0
    ret
ReferenceCell ENDP

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
    LOCAL cell:DWORD

    INVOKE IsNumberText, textPointer
    cmp eax, 0
    je ReadReference

    INVOKE ParseNumber, textPointer, resultPointer
    cmp eax, 0
    je NotANumber
    ret

ReadReference:
    INVOKE ReadName, textPointer
    cmp nameBuffer, 0
    je NotANumber
    INVOKE ReferenceCell, textPointer, ADDR cell, 1
    cmp eax, 0
    je Failed
    cmp BYTE PTR [eax], 0
    jne NotANumber
    INVOKE GetCellNumber, cell, resultPointer
    ret

NotANumber:
    INVOKE ReportError, ADDR numberNeededMessage

Failed:
    mov eax, 0
    ret
ReadNumberValue ENDP

DoSet PROC USES esi, textPointer:DWORD
    LOCAL referencePointer:DWORD, valuePointer:DWORD, cell:DWORD, arrayLength:DWORD

    INVOKE SkipSpaces, textPointer
    mov referencePointer, eax
    INVOKE ReadName, eax
    mov esi, eax
    cmp nameBuffer, 0
    je BadCommand
    cmp BYTE PTR [esi], '['
    je SetWithIndex

    movzx eax, BYTE PTR [esi]
    INVOKE IsWordEnd, eax
    cmp eax, 0
    je BadCommand
    INVOKE SkipSpaces, esi
    mov valuePointer, eax
    cmp BYTE PTR [eax], 0
    je ValueNeeded

    INVOKE DeclareScalarCell, ADDR nameBuffer
    cmp eax, -1
    je Failed
    mov cell, eax
    INVOKE StoreValue, cell, valuePointer
    ret

SetWithIndex:
    INVOKE SkipIndex, esi
    cmp eax, 0
    je BadCommand
    INVOKE SkipSpaces, eax
    mov valuePointer, eax
    cmp BYTE PTR [eax], 0
    je DeclareNewArray

    INVOKE ReferenceCell, referencePointer, ADDR cell, 0
    cmp eax, 0
    je Failed
    INVOKE StoreValue, cell, valuePointer
    ret

DeclareNewArray:
    inc esi
    INVOKE ParseDigits, esi, ADDR arrayLength
    cmp eax, 0
    je BadSize
    cmp BYTE PTR [eax], ']'
    jne BadSize
    INVOKE DeclareArray, ADDR nameBuffer, arrayLength
    cmp eax, -1
    je Failed
    mov eax, 1
    ret

BadSize:
    INVOKE ReportError, ADDR badArraySizeMessage
    jmp Failed

ValueNeeded:
    INVOKE ReportError, ADDR valueNeededMessage
    jmp Failed

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

    INVOKE ReferenceCell, textPointer, ADDR leftCell, 1
    cmp eax, 0
    je Failed
    INVOKE SkipSpaces, eax
    mov esi, eax
    movzx eax, BYTE PTR [esi]
    mov operator, eax

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
