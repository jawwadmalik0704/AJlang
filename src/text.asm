INCLUDE ajlang.inc

.data
likhoWord BYTE "LIKHO",0
rukoWord BYTE "RUKO",0
setWord BYTE "SET",0
bataoWord BYTE "BATAO",0
agarWord BYTE "AGAR",0
warnaWord BYTE "WARNA",0
loopWord BYTE "LOOP",0
repeatWord BYTE "REPEAT",0
endWord BYTE "/",0
randoWord BYTE "RANDO",0
keywordTable DWORD OFFSET likhoWord, OFFSET rukoWord, OFFSET setWord, OFFSET bataoWord
             DWORD OFFSET agarWord, OFFSET warnaWord, OFFSET loopWord, OFFSET repeatWord
             DWORD OFFSET endWord, OFFSET randoWord, 0

.code
GetLineAddress PROC, lineNumber:DWORD
    mov eax, lineNumber
    imul eax, LINELEN
    add eax, OFFSET sourceLines
    ret
GetLineAddress ENDP

GetTextAfterWord PROC, lineNumber:DWORD
    INVOKE GetLineAddress, lineNumber
    INVOKE SkipSpaces, eax
    INVOKE ReadWord, eax
    ret
GetTextAfterWord ENDP

GetLineKeyword PROC, lineNumber:DWORD
    INVOKE GetTextAfterWord, lineNumber
    INVOKE MatchKeyword
    ret
GetLineKeyword ENDP

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

ReadToken PROC USES esi edi, source:DWORD, destination:DWORD
    INVOKE SkipSpaces, source
    mov esi, eax
    mov edi, destination

CopyCharacter:
    movzx eax, BYTE PTR [esi]
    INVOKE IsWordEnd, eax
    cmp eax, 0
    jne Finish
    mov al, [esi]
    mov [edi], al
    inc esi
    inc edi
    jmp CopyCharacter

Finish:
    mov BYTE PTR [edi], 0
    mov eax, esi
    ret
ReadToken ENDP

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

ElseConditionPointer PROC, textPointer:DWORD
    LOCAL afterWord:DWORD

    INVOKE SkipSpaces, textPointer
    cmp BYTE PTR [eax], 0
    je PlainElse

    INVOKE ReadWord, eax
    mov afterWord, eax
    INVOKE Str_compare, ADDR wordBuffer, ADDR agarWord
    jne BadElse
    mov eax, afterWord
    ret

PlainElse:
    mov eax, 0
    ret

BadElse:
    mov eax, -1
    ret
ElseConditionPointer ENDP

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

SkipIndex PROC, textPointer:DWORD
    mov eax, textPointer
    cmp BYTE PTR [eax], '['
    jne Finish

FindClosingBracket:
    inc eax
    cmp BYTE PTR [eax], 0
    je Unclosed
    cmp BYTE PTR [eax], ']'
    jne FindClosingBracket
    inc eax

Finish:
    ret

Unclosed:
    mov eax, 0
    ret
SkipIndex ENDP

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

ParseDigits PROC USES ebx ecx esi, textPointer:DWORD, resultPointer:PTR DWORD
    mov esi, textPointer
    mov ebx, 0
    mov ecx, 0

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
    je NoDigits
    mov eax, resultPointer
    mov [eax], ebx
    mov eax, esi
    ret

NoDigits:
    mov eax, 0
    ret
ParseDigits ENDP

ParseNumber PROC USES ebx, textPointer:DWORD, resultPointer:PTR DWORD
    LOCAL isNegative:DWORD, magnitude:DWORD

    mov ebx, textPointer
    mov isNegative, 0
    cmp BYTE PTR [ebx], '-'
    jne ReadMagnitude
    mov isNegative, 1
    inc ebx

ReadMagnitude:
    INVOKE ParseDigits, ebx, ADDR magnitude
    cmp eax, 0
    je NotANumber
    cmp BYTE PTR [eax], 0
    jne NotANumber

    mov eax, magnitude
    cmp isNegative, 0
    je StoreResult
    neg eax

StoreResult:
    mov ebx, resultPointer
    mov [ebx], eax
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
    INVOKE SkipIndex, eax
    cmp eax, 0
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
