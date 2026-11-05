@echo off
chcp 65001 >nul
echo ============================================================
echo   OMS C++ Engine - Build Script
echo   Compiler: MinGW-W64 GCC (CodeBlocks)
echo ============================================================

set COMPILER="C:\Program Files\CodeBlocks\MinGW\bin\g++.exe"
set SRC="src\main.cpp"
set OUT="oms_engine.exe"
set FLAGS=-std=c++17 -Wall -static -static-libgcc -static-libstdc++

echo [1/2] Compiling...
%COMPILER% %FLAGS% -o %OUT% %SRC%

if %ERRORLEVEL% == 0 (
    echo [2/2] Build SUCCESS! -^> %OUT%
    echo.
    echo Running demo...
    echo ============================================================
    %OUT%
) else (
    echo [2/2] Build FAILED! Check errors above.
    pause
)
