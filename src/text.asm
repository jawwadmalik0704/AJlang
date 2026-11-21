INCLUDE ajlang.inc

.data
likhoWord BYTE "LIKHO",0
rukoWord BYTE "RUKO",0
keywordTable DWORD OFFSET likhoWord, OFFSET rukoWord, 0

.code
GetLineAddress PROC, lineNumber:DWORD
    mov eax, lineNumber
    imul eax, LINELEN
    add eax, OFFSET sourceLines
    ret
GetLineAddress ENDP

SkipSpaces PROC, textPointer:DWORD
    mov eax, textPointer

CheckCharacter:
    cmp BYTE PTR [eax], ' '
    je SkipCharacter
    cmp BYTE PTR [eax], 9
    jne Finish

SkipCharacter:
    inc eax
    jmp CheckCharacter

Finish:
    ret
SkipSpaces ENDP

ReadWord PROC USES esi edi, textPointer:DWORD
    mov esi, textPointer
    mov edi, OFFSET wordBuffer

CopyCharacter:
    mov al, [esi]
    cmp al, 0
    je Finish
    cmp al, ' '
    je Finish
    cmp al, 9
    je Finish
    mov [edi], al
    inc esi
    inc edi
    jmp CopyCharacter

Finish:
    mov BYTE PTR [edi], 0
    INVOKE Str_ucase, ADDR wordBuffer
    mov eax, esi
    ret
ReadWord ENDP

MatchKeyword PROC USES ebx edx
    mov ebx, 0

CheckKeyword:
    mov edx, keywordTable[ebx * 4]
    cmp edx, 0
    je NotFound
    INVOKE Str_compare, ADDR wordBuffer, edx
    je Found
    inc ebx
    jmp CheckKeyword

Found:
    lea eax, [ebx + 1]
    ret

NotFound:
    mov eax, KW_UNKNOWN
    ret
MatchKeyword ENDP

END
