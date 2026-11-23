INCLUDE ajlang.inc

.code
RunLine PROC
    LOCAL lineStart:DWORD, textPointer:DWORD

    INVOKE GetLineAddress, currentLine
    INVOKE SkipSpaces, eax
    mov lineStart, eax

    cmp BYTE PTR [eax], 0
    je ContinueProgram
    cmp BYTE PTR [eax], '#'
    je ContinueProgram

    INVOKE ReadWord, lineStart
    mov textPointer, eax
    INVOKE MatchKeyword

    cmp eax, KW_LIKHO
    je RunLikho
    cmp eax, KW_RUKO
    je RunRuko
    cmp eax, KW_SET
    je RunSet
    cmp eax, KW_BATAO
    je RunBatao
    cmp eax, KW_AGAR
    je RunAgar
    cmp eax, KW_WARNA
    je RunWarna
    cmp eax, KW_LOOP
    je RunLoop
    cmp eax, KW_REPEAT
    je RunRepeat
    cmp eax, KW_END
    je RunEnd
    cmp eax, KW_RANDO
    je RunRando

    INVOKE IsMathLine, lineStart
    cmp eax, 0
    jne RunMath

    INVOKE ReportError, ADDR unknownCommandMessage
    mov eax, 0
    ret

RunLikho:
    INVOKE DoLikho, textPointer
    ret

RunRuko:
    INVOKE DoRuko
    ret

RunSet:
    INVOKE DoSet, textPointer
    ret

RunBatao:
    INVOKE DoBatao, textPointer
    ret

RunAgar:
    INVOKE DoAgar, textPointer
    ret

RunWarna:
    INVOKE DoWarna
    ret

RunLoop:
    INVOKE DoLoop
    ret

RunRepeat:
    INVOKE DoRepeat, textPointer
    ret

RunEnd:
    INVOKE DoEnd
    ret

RunRando:
    INVOKE DoRando, textPointer
    ret

RunMath:
    INVOKE DoMath, lineStart
    ret

ContinueProgram:
    mov eax, 1
    ret
RunLine ENDP

RunProgram PROC
    mov lineIndex, 0

NextLine:
    mov eax, lineIndex
    cmp eax, lineCount
    jae Finish
    mov currentLine, eax
    inc lineIndex
    INVOKE RunLine
    cmp eax, 0
    jne NextLine

Finish:
    ret
RunProgram ENDP

main PROC
    INVOKE LoadProgram
    cmp eax, 0
    je Finish
    INVOKE PrescanBlocks
    cmp eax, 0
    je Finish
    call Randomize
    INVOKE RunProgram

Finish:
    exit
main ENDP

END main
