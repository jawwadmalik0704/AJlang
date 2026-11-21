INCLUDE ajlang.inc

.code
RunLine PROC
    LOCAL textPointer:DWORD

    INVOKE GetLineAddress, currentLine
    INVOKE SkipSpaces, eax
    mov textPointer, eax

    cmp BYTE PTR [eax], 0
    je ContinueProgram
    cmp BYTE PTR [eax], '#'
    je ContinueProgram

    INVOKE ReadWord, textPointer
    mov textPointer, eax
    INVOKE MatchKeyword

    cmp eax, KW_LIKHO
    je RunLikho
    cmp eax, KW_RUKO
    je RunRuko

    INVOKE ReportError, ADDR unknownCommandMessage
    mov eax, 0
    ret

RunLikho:
    INVOKE DoLikho, textPointer
    ret

RunRuko:
    INVOKE DoRuko
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
