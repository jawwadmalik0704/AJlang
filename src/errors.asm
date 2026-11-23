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
valueNeededMessage BYTE "set ke saath value chahiye",0
missingEndMessage BYTE "/ missing hai",0
strayEndMessage BYTE "ye / ka koi jor nahi",0
strayWarnaMessage BYTE "ye warna ka koi agar nahi hai",0
elseAgainMessage BYTE "warna ke baad aur warna nahi aa sakta",0
tooDeepMessage BYTE "blocks bohot gehre hain",0
outOfRangeMessage BYTE " bahar hai bhai",0
arrayNeedsIndexMessage BYTE " array hai, index chahiye",0
notAnArrayMessage BYTE " array nahi hai",0
alreadyDefinedMessage BYTE " pehle se define hai",0
badArraySizeMessage BYTE "array ka size galat hai",0

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

ReportIndexError PROC USES eax edx, namePointer:DWORD, index:DWORD, messagePointer:DWORD
    INVOKE WriteLinePrefix
    mov edx, namePointer
    call WriteString
    mov al, '['
    call WriteChar
    INVOKE WriteNumber, index
    mov al, ']'
    call WriteChar
    INVOKE ShowMessage, messagePointer
    ret
ReportIndexError ENDP

END
