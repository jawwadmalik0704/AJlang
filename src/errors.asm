INCLUDE ajlang.inc

.data
lineLabel BYTE "Line ",0
separator BYTE ": ",0
unknownCommandMessage BYTE "ye command samajh nahi aya",0
fileNotFoundMessage BYTE "file nahi mili",0
fileReadMessage BYTE "file padhne me masla hai",0
programTooLongMessage BYTE "program bohot lamba hai",0

.code
ShowMessage PROC USES edx, messagePointer:DWORD
    mov edx, messagePointer
    call WriteString
    call Crlf
    ret
ShowMessage ENDP

ReportError PROC USES eax edx, messagePointer:DWORD
    mov edx, OFFSET lineLabel
    call WriteString
    mov eax, currentLine
    inc eax
    call WriteDec
    mov edx, OFFSET separator
    call WriteString
    INVOKE ShowMessage, messagePointer
    ret
ReportError ENDP

END
