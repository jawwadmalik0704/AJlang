# AJlang

A small Hinglish scripting language with its interpreter written in x86 MASM assembly (Irvine32) for the FAST-NUCES COAL course.

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

## Build and run

Requirements: Visual Studio with the C++ tools (MASM is included) and the Irvine32 library in `C:\Irvine\irvine`. If it lives elsewhere, set the `IRVINE_DIR` environment variable to that folder (and restart Visual Studio).

- Command line: `build.bat`, then `run.bat yourprogram.aj` (or `build\ajlang.exe yourprogram.aj`)
- Visual Studio: open `AJlang.slnx`, set the program file under Project Properties > Debugging > Command Arguments, and press F5
- Without a file name the program asks for one

## Language reference

### Rules

- One statement per line. Leading spaces and tabs are ignored.
- Keywords are case-insensitive (`Agar` = `agar`). Variable names are case-sensitive.
- `# comment` lines and empty lines are skipped.
- Every block (`agar`, `loop`, `repeat`) ends with a line containing only `/`. Blocks nest up to 20 deep.
- Names start with a letter or `_`, then letters, digits or `_`, at most 15 characters.
- Limits: 200 lines, 80 characters per line, 50 variables, 200 value slots in total, text up to 63 characters.

### Values

Every value is a **number** (32-bit signed) or **text**. A value that starts with a digit or `-` is a number, anything else is text. Text needs no quotes and runs to the end of the line.

### Commands

| Command | Meaning |
|---|---|
| `set x 5` / `set x Ahmed` | create or change a variable (a value is required) |
| `set arr[26]` | create an array of 26 slots (index 0 to 25) |
| `set arr[0] Inception` | set one slot; the index is a number or a variable |
| `likho text` | print the rest of the line and a newline |
| `likho Hi :name, age :age` | `:var` and `:arr[i]` insert a value |
| `likho cost :: 5` | `::` prints a single `:` |
| `batao x` | read a line from the keyboard; number if it starts with a digit or `-`, else text |
| `x+=1` `x-=1` `x*=2` `x/=2` | math; the right side is a number or a number variable; integer division |
| `rando x 10` | x = random number from 0 to 9 |
| `ruko` | stop the program |

### Conditions

`agar` and `repeat` take a condition: `left operator right`, separated by spaces. Each side is a number, a variable or an array slot. Operators: `>  <  ==  !=  >=  <=`. Two text values can be compared with `==` and `!=`.

```
agar x > 18
    likho big boy
warna agar x > 12
    likho teen
warna
    likho kid
/
```

`warna agar` and `warna` are optional; the whole chain closes with one `/`.

### Loops

```
loop i 0-5
    likho :i
/
repeat age < 25
    age+=1
/
```

`loop i 0-5` runs i = 0, 1, 2, 3, 4 (end excluded) and creates `i` automatically. `repeat` runs while its condition is true.

### Arrays

```
set movies[3]
set movies[0] Inception
set movies[1] Interstellar
set movies[2] Tenet
loop i 0-3
    likho :i: :movies[i]
/
```

### Errors

Errors print `Line N: message` and stop the program. Block errors are found before the program starts.

| Situation | Message |
|---|---|
| unknown command or bad line | `ye command samajh nahi aya` |
| variable or slot not set | `x define nahi hai` / `arr[2] define nahi hai` |
| index out of range | `movies[5] bahar hai bhai` |
| name longer than 15 | `naam bohot lamba hai` |
| more than 50 variables or 200 slots | `bohot zyada variables` |
| number needed, got text | `yahan number chahiye` |
| divide by zero | `zero se divide nahi hota` |
| `set x` without a value | `set ke saath value chahiye` |
| block not closed / stray `/` | `/ missing hai` / `ye / ka koi jor nahi` |
| `warna` outside `agar` / two plain `warna` | `ye warna ka koi agar nahi hai` / `warna ke baad aur warna nahi aa sakta` |
| more than 20 nested blocks | `blocks bohot gehre hain` |
| array name without index / index on a non-array | `arr array hai, index chahiye` / `x array nahi hai` |
| array created twice / size 0 | `arr pehle se define hai` / `array ka size galat hai` |
| file cannot be opened | `file nahi mili` |

## How it works

The interpreter runs in three steps:

1. **Load** (`loader.asm`): read the file into fixed 80-byte rows, one per line.
2. **Prescan** (`loader.asm`): match every `agar`/`warna`/`loop`/`repeat` with its `/` and store the jumps in tables, so missing or stray `/` is reported before anything runs.
3. **Run** (`main.asm`): read the first word of each line, look it up in the keyword table and call its handler. Jumps only change the next line number.

## Layout

| File | Job |
|---|---|
| `src\ajlang.inc` | constants, shared names and every `PROTO` |
| `src\data.asm` | shared tables (lines, jump tables, variables, value cells) |
| `src\main.asm` | `main`, run loop, command dispatch |
| `src\loader.asm` | file loading and block prescan |
| `src\text.asm` | words, names, numbers, keyword matching |
| `src\vars.asm` | variables, arrays, `set`, math |
| `src\print.asm` | `likho`, `batao` |
| `src\logic.asm` | conditions, `agar`/`warna`, `loop`, `repeat`, `/`, `rando`, `ruko` |
| `src\errors.asm` | error messages and reporting |
