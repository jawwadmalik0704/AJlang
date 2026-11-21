INCLUDE ajlang.inc

.data
bannerMessage BYTE "AJlang environment is ready.",0

.code
main PROC
    mov edx, OFFSET bannerMessage
    call WriteString
    call Crlf
    exit
main ENDP

END main
