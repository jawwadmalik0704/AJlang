@echo off
setlocal enabledelayedexpansion
cd /d "%~dp0"

if "%IRVINE_DIR%"=="" set "IRVINE_DIR=C:\Irvine\irvine"

if not exist "%IRVINE_DIR%\Irvine32.lib" (
    echo Irvine32.lib not found in %IRVINE_DIR%
    echo Set IRVINE_DIR to the folder that contains Irvine32.lib and Irvine32.inc
    exit /b 1
)

set "VSPATH="
set "VSWHERE=%ProgramFiles(x86)%\Microsoft Visual Studio\Installer\vswhere.exe"
"%VSWHERE%" -latest -products * -property installationPath > "%TEMP%\ajlang_vspath.txt"
set /p VSPATH=<"%TEMP%\ajlang_vspath.txt"
del "%TEMP%\ajlang_vspath.txt"

if "%VSPATH%"=="" (
    echo Visual Studio with the C++ tools was not found
    exit /b 1
)

call "%VSPATH%\VC\Auxiliary\Build\vcvars32.bat" >nul

if not exist build mkdir build
del /q build\*.obj build\ajlang.exe 2>nul

set "OBJECTS="
for %%F in (src\*.asm) do (
    ml /nologo /c /coff /Zi /I"%IRVINE_DIR%" /Isrc /Fo"build\%%~nF.obj" "%%F"
    if errorlevel 1 exit /b 1
    set "OBJECTS=!OBJECTS! build\%%~nF.obj"
)

link /nologo /SUBSYSTEM:CONSOLE /DEBUG /SAFESEH:NO /LIBPATH:"%IRVINE_DIR%" /OUT:build\ajlang.exe !OBJECTS! Irvine32.lib kernel32.lib user32.lib
if errorlevel 1 exit /b 1

echo Build succeeded: build\ajlang.exe
