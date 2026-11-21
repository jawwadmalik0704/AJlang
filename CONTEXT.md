# AJlang Context File

Temporary planning file for the COAL semester project. Delete `CONTEXT.md` and `CLAUDE.md` when the project is finished.

## 1. Project in one paragraph

AJlang is a tiny beginner scripting language with Hinglish keywords (`set`, `likho`, `batao`, `agar`, `warna`, `loop`, `repeat`). The interpreter is written in **x86 MASM assembly with the Irvine32 library** for the FAST-NUCES COAL course (EL-2003, Fall 2026). It reads a `.aj` source file and runs it line by line. Two students build it in 4 days: Jawwad (`jawwadmalik0704`) and Ahmed (`AhmedMustafa-0817`).

## 2. Hard rules for every piece of code

1. **No comments in code.** Use clear procedure, label and variable names instead. (This file and the README are the only places with explanations.)
2. **Easy to read.** One idea per procedure, short procedures, meaningful names, blank line between logical steps.
3. **Use only what the lab manuals teach** (Labs 02 to 11). Anything outside them needs a one-line justification in the Progress Log (section 10).
4. Same style as the manuals: `INCLUDE Irvine32.inc`, `.data`, `.code`, `main PROC`, `exit`, 4-space indent, upper-case instructions are not required but be consistent.
5. A procedure never silently fails. Errors go through `ReportError` (section 7).
6. Do not add features beyond this spec without asking.

### Lab manual coverage map (where each tool comes from)

| Lab | Topic | Used in AJlang for |
|---|---|---|
| 02, 03 | Data types, BYTE/WORD/DWORD, strings, MOV/ADD/SUB | Tables, buffers, string constants |
| 04 | MOVZX, MOVSX, XCHG, NEG, `=` and EQU constants, DUP | Limits (`MAXVARS`), buffer allocation, char math |
| 05 | OFFSET, PTR, TYPE, LENGTHOF, SIZEOF, indirect and indexed operands | Walking the source buffer, variable tables |
| 06 | Arrays, JMP, LOOP, nested loops, Irvine32 I/O (`ReadString`, `WriteString`, `WriteInt`, `WriteDec`, `Crlf`, `Randomize`, `RandomRange`) | Output, input, `rando`, loops |
| 07 | PUSH/POP, PUSHFD, procedures, CALL/RET | Block stack, small procedures |
| 08 | CMP, conditional jumps, IF/ELSE and WHILE translation | `agar`, `repeat`, dispatch |
| 09 | MUL/IMUL, DIV/IDIV, CDQ | `*=`, `/=`, number parsing (x10) |
| 10 | Stack frames, `PROC` with parameters and `USES`, `INVOKE`, `PROTO`, `LOCAL` | Every helper procedure |
| 11 | `MOVS/CMPS/SCAS/STOS/LODS`, `REP`, `Str_compare`, `Str_length`, `Str_copy`, `Str_trim`, `Str_ucase`, 2D arrays | Reading words, copying text, keyword matching |

**One thing outside the labs:** reading the `.aj` file uses Irvine32 `GetCommandTail`, `OpenInputFile`, `ReadFromFile`, `CloseFile`. Reason: a file makes the language real and lets tests run without typing. If the instructor objects, fallback is section 11.

## 3. Toolchain and build

- MASM `ml.exe` (x86) from Visual Studio 18, Irvine32 in `C:\Irvine\irvine`.
- Day 1 creates `build.bat` that sets up `vcvars32.bat`, assembles every `src\*.asm`, links with `Irvine32.lib`, `kernel32.lib`, `user32.lib` and produces `ajlang.exe`.
- Run: `ajlang.exe tests\day1.aj`. With no argument the program asks for the file name.
- Visual Studio: same sources, project settings from the lab setup (Irvine32 include and library paths). Do not commit `.vs`, `*.obj`, `*.exe`, `*.pdb`, `*.ilk` (see `.gitignore`).
- Day 1 risk to verify: Irvine `WriteString` may not appear when stdout is redirected. If so, tests are checked by running in a console and comparing with `tests\dayN.expected` by eye, and the Progress Log records it.

## 4. Language spec (final, v0.1)

### Rules
- One statement per line. No terminators.
- Keywords are case-insensitive (`Agar` = `agar`). Variable names are case-sensitive.
- Leading spaces and tabs are ignored.
- Every block (`agar`, `loop`, `repeat`) ends with a line containing only `/`.
- `# comment` lines are skipped. Empty lines are skipped.
- Max 15 characters per variable name, max 50 variables. Max 200 source lines, max 80 characters per line.

### Types
- Every value has a type flag: **number** (32-bit signed) or **text**.
- Text means the first character is not a digit and not `-`. `set x 500` is a number, `set x riej` is text, `set x -5` is a number.
- Text needs no quotes and runs to the end of the line (max 63 characters).

### Commands

| Command | Meaning |
|---|---|
| `set x 5` / `set x Ahmed` | declare or assign (text is always a literal, never another variable) |
| `set arr[26]` | declare an array of 26 slots |
| `set arr[0] Inception` | assign one slot (index is a number or a variable) |
| `likho big boy` | print the rest of the line and a newline |
| `likho Hi :name, age :age` | `:var` and `:arr[i]` insert a value |
| `likho cost :: 5` | `::` prints a single `:` |
| `batao x` | read a line; number if it starts with digit or `-`, else text |
| `x+=1` `x-=1` `x*=2` `x/=2` | math, right side is a number or a number variable, integer division |
| `rando x 10` | x = random number from 0 to 9 (end excluded, like `loop`) |
| `ruko` | stop the program immediately |

### Conditions
Operators: `>  <  ==  !=  >=  <=`. Each side is a variable or a number. `==` and `!=` also compare two text values.
```
agar x > 18
    likho big boy
warna agar x > 12
    likho teen
warna
    likho kid
/
```
`warna agar` and `warna` are optional. The whole chain closes with one `/`.

### Loops
```
loop i 0-5
    likho :i
/
repeat age < 25
    age+=1
/
```
`loop i 0-5` runs i = 0,1,2,3,4 (end excluded). `i` is created automatically. Start and end are plain non-negative numbers in v0.1. `repeat` takes the same condition as `agar`. Nesting works to any depth up to 20.

### Arrays
Indices start at 0. Slots hold numbers or text. Bad index prints `Line 7: movies[5] bahar hai bhai` and stops.

### Sample program (must work at the end)
```
set name Ahmed
set age 19
likho Salam :name, umar :age
batao age
agar age > 18
    likho big boy
warna
    likho kid
/
repeat age < 25
    age+=1
/
likho Ab umar :age hai
```

## 5. Architecture

Interpreter, not compiler. Three phases:

1. **Load**: read the file into `sourceLines` (fixed 80-byte rows), strip the end-of-line characters, count lines.
2. **Prescan**: one pass over the lines with a block stack to fill the jump tables, so runtime never searches for matching `/`. Missing `/` or stray `/` is reported before anything runs.
3. **Run**: `lineIndex` walks the table. Each line is trimmed, its first word is upper-cased into `wordBuffer`, matched against the keyword table, and the matching handler procedure is called. Handlers may change `lineIndex` (jump).

### Source files (split so two people rarely touch the same file)

| File | Owner (suggested) | Contents |
|---|---|---|
| `src\ajlang.inc` | both | `INCLUDE Irvine32.inc`, constants, `PROTO`s, `externdef`s |
| `src\main.asm` | Jawwad | `main`, program flow, data shared by all |
| `src\loader.asm` | Ahmed | file reading, `LoadProgram`, `PrescanBlocks` |
| `src\text.asm` | Ahmed | trimming, word reading, keyword matching, `ParseNumber`, `IsNumberText` |
| `src\vars.asm` | Jawwad | cell table, `FindVariable`, `DeclareVariable`, get/set value |
| `src\print.asm` | Jawwad | `likho`, `:var` insertion, `batao` |
| `src\logic.asm` | Ahmed | conditions, `agar`/`warna`, `loop`, `repeat` |
| `src\errors.asm` | both | `ReportError` and message strings |

### Data layout (all in `.data`, sizes are `=` constants)

- `MAXLINES = 200`, `LINELEN = 80`, `MAXVARS = 50`, `NAMELEN = 16`, `MAXCELLS = 200`, `TEXTLEN = 64`, `MAXDEPTH = 20`.
- `sourceLines BYTE MAXLINES * LINELEN DUP(0)`, `lineCount DWORD`, `lineIndex DWORD`.
- Jump tables, one DWORD per line: `blockEnd` (line of the closing `/`), `blockStart` (opener of a `/`), `nextBranch` (next `warna` or `warna agar` in the chain), `previousBranch` (used only by prescan).
- **Cells** hold every value. A scalar variable is one cell, an array is N consecutive cells:
  `cellType DWORD MAXCELLS DUP(0)` (0 empty, 1 number, 2 text), `cellNumber DWORD MAXCELLS DUP(0)`, `cellText BYTE MAXCELLS * TEXTLEN DUP(0)`.
- **Variable table**: `varName BYTE MAXVARS * NAMELEN DUP(0)`, `varFirstCell DWORD MAXVARS DUP(0)`, `varLength DWORD MAXVARS DUP(0)` (0 = scalar, N = array), `varCount DWORD`.
- Block stack for prescan: `blockStack DWORD MAXDEPTH DUP(0)`, `stackDepth DWORD`.

### Procedure list (all use `PROC` with parameters and `USES`, called with `INVOKE`, result in EAX)

Loader/prescan: `LoadProgram`, `PrescanBlocks`.
Text: `SkipSpaces`, `ReadWord`, `UpperCaseWord`, `MatchKeyword`, `IsNumberText`, `ParseNumber`, `CopyRestOfLine`.
Variables: `FindVariable`, `DeclareVariable`, `DeclareArray`, `GetCellNumber`, `SetCellNumber`, `SetCellText`, `CellForReference` (handles `name` and `name[i]` and the bounds error).
Commands: `DoSet`, `DoLikho`, `DoBatao`, `DoMath`, `DoRando`, `DoRuko`, `DoAgar`, `DoWarna`, `DoLoop`, `DoRepeat`, `DoEnd`.
Shared: `EvaluateCondition`, `ReportError`, `RunProgram`.

## 6. Runtime rules for blocks

- `agar` false: jump to `nextBranch`. If it is a `warna agar`, evaluate its condition. If it is `warna`, run it. If it is `/`, continue after it.
- Reaching a `warna` or `warna agar` line by normal flow means a taken branch just finished: jump to `blockEnd` of that line.
- `loop i a-b`: on entry set i = a. If i >= b, jump past the `/`. At the closing `/`, add 1 to i and jump back to the line after the opener (re-check the bound). The loop variable is stored in a cell so `likho :i` works.
- `repeat cond`: at entry and at every closing `/` evaluate the condition. False means jump past the `/`.
- `/` with `blockStart` pointing to a `loop` or `repeat` jumps back. A `/` that closes an `agar` is a no-op.

## 7. Errors

Format: `Line N: message`, then stop. Hinglish tone like the spec.

| Situation | Message |
|---|---|
| unknown command | `ye command samajh nahi aya` |
| variable not set | `<name> define nahi hai` |
| index out of range | `<name>[<i>] bahar hai bhai` |
| name longer than 15 | `naam bohot lamba hai` |
| more than 50 variables | `bohot zyada variables` |
| number needed, got text | `yahan number chahiye` |
| divide by zero | `zero se divide nahi hota` |
| block not closed / stray `/` | `/ missing hai` / `ye / ka koi jor nahi` |
| file cannot be opened | `file nahi mili` |

## 7b. Decisions already made (do not re-ask)

- `loop` is end-exclusive. Arrays start at 0.
- `::` is the escape for a literal colon in `likho` (the friend asked for "escape :").
- `warna agar` chains are included.
- `ruko` and `rando` are included (built on Day 4).
- Source comes from a file given on the command line.

## 8. Four-day plan

Rules for the plan: each day ends with a working `ajlang.exe`, passing test programs in `tests\`, a Progress Log entry, and a git push. Never leave the build broken at day end.

### Day 1: Foundation
- Create `src\`, `tests\`, `build.bat`, `src\ajlang.inc`, all `.asm` files as small compiling stubs.
- `LoadProgram` (file or asked file name), line splitting and trimming.
- `ReadWord`, `UpperCaseWord`, keyword table, `RunProgram` dispatch loop.
- `likho` with plain text only, `#` comments, blank lines, `ruko`, case-insensitive keywords.
- `ReportError` with line numbers, unknown command error, file-not-found error.
- Done when `tests\day1.aj` (several `likho`, mixed-case keywords, comments, a `ruko` before a last `likho`, one bad line at the end) prints the expected lines and the bad line reports `Line N: ye command samajh nahi aya`.

### Day 2: Variables, input, math
- Variable table and cells, `set` number/text, number-vs-text detection, `ParseNumber`.
- `likho` with `:var` and `::`.
- `batao` with auto type detection.
- `+=`, `-=`, `*=`, `/=` with number-only checks and divide-by-zero error.
- Errors: undefined variable, name too long, too many variables.
- Done when `tests\day2.aj` shows `set`, text and number mix, `likho Hi :name, age :age`, `batao`, all four operators, and each error.

### Day 3: Decisions and loops
- `PrescanBlocks` with stack, jump tables, missing/stray `/` errors.
- `EvaluateCondition` (six operators, text `==`/`!=`).
- `agar`, `warna agar`, `warna`.
- `loop i a-b`, `repeat cond`, nesting.
- Done when `tests\day3.aj` covers an if/else-if/else chain, nested `agar`, a nested `loop` (the `:i x :j` table), a `repeat`, and the full sample program in section 4.

### Day 4: Arrays, extras, polish
- `set arr[N]`, `set arr[i] value`, `:arr[i]` in `likho`, bounds error, array reads in conditions and math.
- `rando x N`, final `ruko` checks.
- Error pass: every message in section 7 reachable and tested.
- Sample programs in `examples\` (calculator, guess the number, movie list), `README.md` with usage and the language reference.
- Final cleanup: re-read all code for stray comments and unclear names, rebuild from clean, run every test, delete `CONTEXT.md` and `CLAUDE.md`.
- Done when all `tests\day1..day4.aj` pass, examples run, and the repo has a clean README.

## 9. How to run a day (instructions for the assistant)

Command from the user: `Do Day N`.
1. Read this file fully, including the Progress Log.
2. `git pull`. If the previous day is not marked done, stop and say so.
3. Implement only that day's scope, following section 2.
4. Build with `build.bat`, run the day's test file(s), compare with `tests\dayN.expected`.
5. Fix until the tests pass. Never claim a pass without running it.
6. Append to the Progress Log: what was done, test result, anything left over, what the next day needs to know.
7. Commit with a clear message (`Day N: ...`) and push. No `Co-Authored-By` trailer and no other collaborator: the repo has only the two students.
8. Reply with a short summary and what to check manually in Visual Studio.

## 10. Progress Log

| Day | Status | Notes |
|---|---|---|
| 0 | done | Spec finalised, context file, repo created |
| 1 | not started | |
| 2 | not started | |
| 3 | not started | |
| 4 | not started | |

Outside-lab constructs used: `GetCommandTail`, `OpenInputFile`, `ReadFromFile`, `CloseFile` (file loading).

## 11. Fallbacks and open items

- If file I/O is not allowed by the instructor: paste the program in the console, one line per `ReadString`, finish with a line `chalao`, then run. Only `LoadProgram` changes.
- If stdout redirect does not work for tests: see section 3.
- Stretch (only if all four days finish early): `loop i 0-n` with a variable end, `set x :y` copy, `//` escape for `/` text lines.

## 12. Repo

- GitHub: `jawwadmalik0704/AJlang` (public). Collaborator: `AhmedMustafa-0817`.
- Branch `main`. Pull before starting, push at the end of each day. Daily work is one commit (or a few) per day to keep history readable.
- Lab manuals are not in the repo (they live in `D:\lab manuals`).
