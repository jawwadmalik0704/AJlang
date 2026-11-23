INCLUDE ajlang.inc

.data
likhoWord BYTE "LIKHO",0
rukoWord BYTE "RUKO",0
setWord BYTE "SET",0
bataoWord BYTE "BATAO",0
keywordTable DWORD OFFSET likhoWord, OFFSET rukoWord, OFFSET setWord, OFFSET bataoWord, 0

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

IsDigitCharacter PROC, character:DWORD
    mov eax, character
    cmp eax, '0'
    jb No
    cmp eax, '9'
    ja No
    mov eax, 1
    ret

No:
    mov eax, 0
    ret
IsDigitCharacter ENDP

IsNameStart PROC, character:DWORD
    mov eax, character
    cmp eax, '_'
    je Yes
    cmp eax, 'A'
    jb No
    cmp eax, 'Z'
    jbe Yes
    cmp eax, 'a'
    jb No
    cmp eax, 'z'
    jbe Yes

No:
    mov eax, 0
    ret

Yes:
    mov eax, 1
    ret
IsNameStart ENDP

IsNameCharacter PROC, character:DWORD
    INVOKE IsNameStart, character
    cmp eax, 1
    je Finish
    INVOKE IsDigitCharacter, character

Finish:
    ret
IsNameCharacter ENDP

IsWordEnd PROC, character:DWORD
    mov eax, character
    cmp eax, 0
    je Yes
    cmp eax, ' '
    je Yes
    cmp eax, 9
    je Yes
    mov eax, 0
    ret

Yes:
    mov eax, 1
    ret
IsWordEnd ENDP

IsMathOperator PROC, character:DWORD
    mov eax, character
    cmp eax, '+'
    je Yes
    cmp eax, '-'
    je Yes
    cmp eax, '*'
    je Yes
    cmp eax, '/'
    je Yes
    mov eax, 0
    ret

Yes:
    mov eax, 1
    ret
IsMathOperator ENDP

ReadName PROC USES esi edi, textPointer:DWORD
    mov esi, textPointer
    mov edi, OFFSET nameBuffer

    movzx eax, BYTE PTR [esi]
    INVOKE IsNameStart, eax
    cmp eax, 0
    je Finish

CopyCharacter:
    mov al, [esi]
    mov [edi], al
    inc esi
    inc edi
    movzx eax, BYTE PTR [esi]
    INVOKE IsNameCharacter, eax
    cmp eax, 0
    jne CopyCharacter

Finish:
    mov BYTE PTR [edi], 0
    mov eax, esi
    ret
ReadName ENDP

IsNumberText PROC, textPointer:DWORD
    mov eax, textPointer
    movzx eax, BYTE PTR [eax]
    cmp eax, '-'
    je Yes
    INVOKE IsDigitCharacter, eax
    ret

Yes:
    mov eax, 1
    ret
IsNumberText ENDP

ParseNumber PROC USES ebx ecx esi, textPointer:DWORD, resultPointer:PTR DWORD
    LOCAL isNegative:DWORD

    mov esi, textPointer
    mov ebx, 0
    mov ecx, 0
    mov isNegative, 0

    cmp BYTE PTR [esi], '-'
    jne ReadDigit
    mov isNegative, 1
    inc esi

ReadDigit:
    movzx eax, BYTE PTR [esi]
    INVOKE IsDigitCharacter, eax
    cmp eax, 0
    je EndOfDigits
    movzx eax, BYTE PTR [esi]
    sub eax, '0'
    imul ebx, 10
    add ebx, eax
    inc ecx
    inc esi
    jmp ReadDigit

EndOfDigits:
    cmp ecx, 0
    je NotANumber
    cmp BYTE PTR [esi], 0
    jne NotANumber

    cmp isNegative, 0
    je StoreResult
    neg ebx

StoreResult:
    mov eax, resultPointer
    mov [eax], ebx
    mov eax, 1
    ret

NotANumber:
    mov eax, 0
    ret
ParseNumber ENDP

CopyRestOfLine PROC USES ecx esi edi, source:DWORD, destination:DWORD, maxLength:DWORD
    mov esi, source
    mov edi, destination
    mov ecx, maxLength

CopyCharacter:
    cmp ecx, 0
    je Finish
    mov al, [esi]
    cmp al, 0
    je Finish
    mov [edi], al
    inc esi
    inc edi
    dec ecx
    jmp CopyCharacter

Finish:
    mov BYTE PTR [edi], 0
    ret
CopyRestOfLine ENDP

IsMathLine PROC USES esi, textPointer:DWORD
    INVOKE ReadName, textPointer
    cmp nameBuffer, 0
    je No

    INVOKE SkipSpaces, eax
    mov esi, eax
    cmp BYTE PTR [esi + 1], '='
    jne No
    movzx eax, BYTE PTR [esi]
    INVOKE IsMathOperator, eax
    ret

No:
    mov eax, 0
    ret
IsMathLine ENDP

END
