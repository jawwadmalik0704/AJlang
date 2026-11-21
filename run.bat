@echo off
cd /d "%~dp0"
if not exist build\ajlang.exe call build.bat
if errorlevel 1 exit /b 1
build\ajlang.exe %*
