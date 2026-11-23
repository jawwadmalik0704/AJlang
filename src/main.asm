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
    INVOKE RunProgram

Finish:
    exit
main ENDP

END main
