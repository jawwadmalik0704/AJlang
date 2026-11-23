INCLUDE ajlang.inc

.data
askFileMessage BYTE "File ka naam batao: ",0
commandTail BYTE FILENAME_SIZE DUP(0)

.code
ReadFileName PROC USES eax ecx edx
    mov edx, OFFSET commandTail
    call GetCommandTail
    INVOKE SkipSpaces, ADDR commandTail
    INVOKE Str_copy, eax, ADDR fileName
    INVOKE Str_trim, ADDR fileName, ' '
    cmp fileName, 0
    jne Finish

    mov edx, OFFSET askFileMessage
    call WriteString
    mov edx, OFFSET fileName
    mov ecx, FILENAME_SIZE - 1
    call ReadString
    INVOKE Str_trim, ADDR fileName, ' '

Finish:
    ret
ReadFileName ENDP

SplitIntoLines PROC USES ebx ecx esi edi
    mov esi, OFFSET rawBuffer
    mov edi, OFFSET sourceLines
    mov ebx, 0
    mov ecx, 0

    cmp BYTE PTR [esi], 0EFh
    jne NextCharacter
    add esi, 3

NextCharacter:
    mov al, [esi]
    cmp al, 0
    je EndOfText
    inc esi
    cmp al, 10
    je EndOfLine
    cmp al, 13
    je NextCharacter
    cmp ecx, LINELEN - 1
    jae NextCharacter
    mov [edi + ecx], al
    inc ecx
    jmp NextCharacter

EndOfLine:
    INVOKE Str_trim, edi, ' '
    inc ebx
    add edi, LINELEN
    mov ecx, 0
    cmp ebx, MAXLINES
    jb NextCharacter
    cmp BYTE PTR [esi], 0
    jne TooLong
    jmp Finish

EndOfText:
    cmp ecx, 0
    je Finish
    INVOKE Str_trim, edi, ' '
    inc ebx

Finish:
    mov lineCount, ebx
    mov eax, 1
    ret

TooLong:
    INVOKE ShowMessage, ADDR programTooLongMessage
    mov eax, 0
    ret
SplitIntoLines ENDP

LoadProgram PROC USES ebx ecx edx
    LOCAL fileHandle:DWORD

    INVOKE ReadFileName

    mov edx, OFFSET fileName
    call OpenInputFile
    cmp eax, INVALID_HANDLE_VALUE
    je FileMissing

    mov fileHandle, eax
    mov edx, OFFSET rawBuffer
    mov ecx, RAWSIZE - 1
    call ReadFromFile
    jc ReadFailed

    mov ebx, eax
    mov BYTE PTR rawBuffer[ebx], 0
    mov eax, fileHandle
    call CloseFile

    cmp ebx, RAWSIZE - 1
    jae TooLong

    INVOKE SplitIntoLines
    ret

FileMissing:
    INVOKE ShowMessage, ADDR fileNotFoundMessage
    mov eax, 0
    ret

ReadFailed:
    INVOKE ShowMessage, ADDR fileReadMessage
    mov eax, 0
    ret

TooLong:
    INVOKE ShowMessage, ADDR programTooLongMessage
    mov eax, 0
    ret
LoadProgram ENDP

TopBlock PROC
    mov eax, stackDepth
    dec eax
    mov eax, blockStack[eax * 4]
    ret
TopBlock ENDP

OpenBlock PROC USES edx, lineNumber:DWORD
    cmp stackDepth, MAXDEPTH
    jae TooDeep
    mov eax, stackDepth
    mov edx, lineNumber
    mov blockStack[eax * 4], edx
    mov previousBranch[edx * 4], edx
    inc stackDepth
    mov eax, 1
    ret

TooDeep:
    INVOKE ReportError, ADDR tooDeepMessage
    mov eax, 0
    ret
OpenBlock ENDP

AddBranch PROC USES ebx esi, lineNumber:DWORD
    cmp stackDepth, 0
    je StrayWarna
    INVOKE TopBlock
    mov ebx, eax
    INVOKE GetLineKeyword, ebx
    cmp eax, KW_AGAR
    jne StrayWarna

    INVOKE GetTextAfterWord, lineNumber
    INVOKE ElseConditionPointer, eax
    cmp eax, -1
    je BadWarna

    mov esi, previousBranch[ebx * 4]
    cmp esi, ebx
    je LinkBranch
    INVOKE GetTextAfterWord, esi
    INVOKE ElseConditionPointer, eax
    cmp eax, 0
    je ElseAgain

LinkBranch:
    mov eax, lineNumber
    mov nextBranch[esi * 4], eax
    mov previousBranch[ebx * 4], eax
    mov eax, 1
    ret

StrayWarna:
    INVOKE ReportError, ADDR strayWarnaMessage
    mov eax, 0
    ret

BadWarna:
    INVOKE ReportError, ADDR unknownCommandMessage
    mov eax, 0
    ret

ElseAgain:
    INVOKE ReportError, ADDR elseAgainMessage
    mov eax, 0
    ret
AddBranch ENDP

CloseBlock PROC USES ebx edx esi, lineNumber:DWORD
    cmp stackDepth, 0
    je StrayEnd
    INVOKE TopBlock
    mov ebx, eax
    dec stackDepth

    mov edx, lineNumber
    mov blockStart[edx * 4], ebx
    mov esi, previousBranch[ebx * 4]
    mov nextBranch[esi * 4], edx
    mov esi, ebx

MarkBranch:
    mov blockEnd[esi * 4], edx
    mov esi, nextBranch[esi * 4]
    cmp esi, edx
    jne MarkBranch
    mov eax, 1
    ret

StrayEnd:
    INVOKE ReportError, ADDR strayEndMessage
    mov eax, 0
    ret
CloseBlock ENDP

PrescanBlocks PROC USES ebx
    mov stackDepth, 0
    mov ebx, 0

CheckLine:
    cmp ebx, lineCount
    jae CheckUnclosed
    mov currentLine, ebx
    INVOKE GetLineKeyword, ebx
    cmp eax, KW_AGAR
    je Open
    cmp eax, KW_LOOP
    je Open
    cmp eax, KW_REPEAT
    je Open
    cmp eax, KW_WARNA
    je Branch
    cmp eax, KW_END
    je Close
    jmp NextLine

Open:
    INVOKE OpenBlock, ebx
    jmp CheckResult

Branch:
    INVOKE AddBranch, ebx
    jmp CheckResult

Close:
    INVOKE CloseBlock, ebx

CheckResult:
    cmp eax, 0
    je Failed

NextLine:
    inc ebx
    jmp CheckLine

CheckUnclosed:
    cmp stackDepth, 0
    je Finish
    INVOKE TopBlock
    mov currentLine, eax
    INVOKE ReportError, ADDR missingEndMessage

Failed:
    mov eax, 0
    ret

Finish:
    mov eax, 1
    ret
PrescanBlocks ENDP

END
