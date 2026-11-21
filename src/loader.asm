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

END
