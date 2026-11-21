# AJlang

A small Hinglish scripting language with its interpreter written in x86 MASM assembly (Irvine32) for the FAST-NUCES COAL course.

```
set name Ahmed
set age 19
likho Salam :name, umar :age
agar age > 18
    likho big boy
warna
    likho kid
/
```

## Build and run

Requirements: Visual Studio with the C++ tools (MASM is included) and the Irvine32 library in `C:\Irvine\irvine`. If it lives elsewhere, set the `IRVINE_DIR` environment variable to that folder.

- Command line: `build.bat`, then `run.bat tests\day1.aj`
- Visual Studio: open `AJlang.slnx` and press F5

## Layout

- `src\` MASM source split by job (`main`, `data`, `loader`, `text`, `vars`, `print`, `logic`, `errors`) plus the shared `ajlang.inc`

Status: in development. The full language reference will be added on the final day.
