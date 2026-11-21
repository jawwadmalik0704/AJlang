INCLUDE ajlang.inc

.code
DoLikho PROC USES edx, textPointer:DWORD
    INVOKE SkipSpaces, textPointer
    mov edx, eax
    call WriteString
    call Crlf
    mov eax, 1
    ret
DoLikho ENDP

END
