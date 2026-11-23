INCLUDE ajlang.inc

.data
lineLabel BYTE "Line ",0
separator BYTE ": ",0
unknownCommandMessage BYTE "ye command samajh nahi aya",0
fileNotFoundMessage BYTE "file nahi mili",0
fileReadMessage BYTE "file padhne me masla hai",0
programTooLongMessage BYTE "program bohot lamba hai",0
undefinedVariableMessage BYTE " define nahi hai",0
nameTooLongMessage BYTE "naam bohot lamba hai",0
tooManyVariablesMessage BYTE "bohot zyada variables",0
numberNeededMessage BYTE "yahan number chahiye",0
divideByZeroMessage BYTE "zero se divide nahi hota",0

.code
ShowMessage PROC USES edx, messagePointer:DWORD
    mov edx, messagePointer
    call WriteString
    call Crlf
    ret
ShowMessage ENDP

WriteLinePrefix PROC USES eax edx
    mov edx, OFFSET lineLabel
    call WriteString
    mov eax, currentLine
    inc eax
    call WriteDec
    mov edx, OFFSET separator
    call WriteString
    ret
WriteLinePrefix ENDP

ReportError PROC, messagePointer:DWORD
    INVOKE WriteLinePrefix
    INVOKE ShowMessage, messagePointer
    ret
ReportError ENDP

ReportNameError PROC USES edx, namePointer:DWORD, messagePointer:DWORD
    INVOKE WriteLinePrefix
    mov edx, namePointer
    call WriteString
    INVOKE ShowMessage, messagePointer
    ret
ReportNameError ENDP

END
