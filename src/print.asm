INCLUDE ajlang.inc

.data
inputBuffer BYTE LINELEN DUP(0)

.code
WriteNumber PROC USES eax, value:DWORD
    mov eax, value
    cmp eax, 0
    jge WriteDigits
    push eax
    mov al, '-'
    call WriteChar
    pop eax
    neg eax

WriteDigits:
    call WriteDec
    ret
WriteNumber ENDP

PrintCell PROC USES eax ebx edx, cell:DWORD
    mov ebx, cell
    cmp cellType[ebx * 4], CELL_NUMBER
    je PrintNumber
    cmp cellType[ebx * 4], CELL_TEXT
    jne Finish

    INVOKE GetCellTextAddress, ebx
    mov edx, eax
    call WriteString
    jmp Finish

PrintNumber:
    INVOKE WriteNumber, cellNumber[ebx * 4]

Finish:
    ret
PrintCell ENDP

WriteInsert PROC USES esi, colonPointer:DWORD, shouldPrint:DWORD
    mov esi, colonPointer
    inc esi
    cmp BYTE PTR [esi], ':'
    je DoubleColon

    INVOKE ReadName, esi
    cmp nameBuffer, 0
    je WriteColon
    mov esi, eax

    INVOKE CellForReference, ADDR nameBuffer
    cmp eax, -1
    je Failed
    cmp shouldPrint, 0
    je Finish
    INVOKE PrintCell, eax
    jmp Finish

DoubleColon:
    inc esi

WriteColon:
    cmp shouldPrint, 0
    je Finish
    mov al, ':'
    call WriteChar

Finish:
    mov eax, esi
    ret

Failed:
    mov eax, 0
    ret
WriteInsert ENDP

WriteLikhoText PROC USES esi, textPointer:DWORD, shouldPrint:DWORD
    mov esi, textPointer

NextCharacter:
    mov al, [esi]
    cmp al, 0
    je Finish
    cmp al, ':'
    je InsertValue

    cmp shouldPrint, 0
    je SkipCharacter
    call WriteChar

SkipCharacter:
    inc esi
    jmp NextCharacter

InsertValue:
    INVOKE WriteInsert, esi, shouldPrint
    cmp eax, 0
    je Failed
    mov esi, eax
    jmp NextCharacter

Finish:
    mov eax, 1
    ret

Failed:
    mov eax, 0
    ret
WriteLikhoText ENDP

DoLikho PROC, textPointer:DWORD
    LOCAL messagePointer:DWORD

    INVOKE SkipSpaces, textPointer
    mov messagePointer, eax

    INVOKE WriteLikhoText, messagePointer, 0
    cmp eax, 0
    je Failed

    INVOKE WriteLikhoText, messagePointer, 1
    call Crlf
    mov eax, 1
    ret

Failed:
    mov eax, 0
    ret
DoLikho ENDP

DoBatao PROC USES ecx edx, textPointer:DWORD
    LOCAL cell:DWORD

    INVOKE SkipSpaces, textPointer
    INVOKE ReadName, eax
    cmp nameBuffer, 0
    je BadCommand
    INVOKE SkipSpaces, eax
    cmp BYTE PTR [eax], 0
    jne BadCommand

    INVOKE DeclareVariable, ADDR nameBuffer
    cmp eax, -1
    je Failed
    mov eax, varFirstCell[eax * 4]
    mov cell, eax

    mov edx, OFFSET inputBuffer
    mov ecx, LINELEN - 1
    call ReadString
    INVOKE Str_trim, ADDR inputBuffer, ' '
    INVOKE SkipSpaces, ADDR inputBuffer
    INVOKE StoreValue, cell, eax
    ret

BadCommand:
    INVOKE ReportError, ADDR unknownCommandMessage

Failed:
    mov eax, 0
    ret
DoBatao ENDP

END
