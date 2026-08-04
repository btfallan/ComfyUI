@echo off
chcp 65001 >nul
title JakeUpgrade Nodes Installer

echo.
echo ========================================
echo    JakeUpgrade Nodes Installer
echo ========================================
echo.

:: 检查是否在 ComfyUI 目录中 / Check if in ComfyUI directory
if not exist "..\..\comfyui" (
	if not exist "..\..\..\comfyui" (
		if not exist "..\..\..\..\comfyui" (
			echo ⚠️  Warning: ComfyUI not detected
			echo.
		)
	)
)

:: 设置 Python 执行路径 / Set Python executable path
set "PYTHON_EMBEDDED=..\..\..\python_embeded\python.exe"
set "PYTHON_EMBEDDED1=..\..\..\python_embeded\python.exe"
set "PYTHON_EMBEDDED2=..\..\..\..\python_embeded\python.exe"
set "PYTHON_SYSTEM=python"
set "PYTHON_EXEC="

:: 优先使用嵌入式 Python / Prefer embedded Python
if exist "%PYTHON_EMBEDDED%" (
    set "PYTHON_EXEC=%PYTHON_EMBEDDED%"
    echo ✅ Using embedded Python: %PYTHON_EMBEDDED%
) else if exist "%PYTHON_EMBEDDED1%" (
    set "PYTHON_EXEC=%PYTHON_EMBEDDED1%"
    echo ✅ Using embedded Python: %PYTHON_EMBEDDED1%
) else if exist "%PYTHON_EMBEDDED2%" (
    set "PYTHON_EXEC=%PYTHON_EMBEDDED2%"
    echo ✅ Using embedded Python: %PYTHON_EMBEDDED2%
) else (
    :: 检查系统 Python / Check system Python
    %PYTHON_SYSTEM% --version >nul 2>&1
    if %errorlevel% equ 0 (
        set "PYTHON_EXEC=%PYTHON_SYSTEM%"
        echo ✅ Using system Python
    ) else (
        echo ❌ Python not found, please ensure Python 3.8+ is installed
        pause
        exit /b 1
    )
)

echo.
echo 📦 Starting smart dependency check...
echo.

:: 运行 Python 安装脚本 - 使用手动安装版本
%PYTHON_EXEC% install_manual.py

if %errorlevel% neq 0 (
    echo.
    echo ❌ Error during installation
    echo 💡 Please try the following solutions:
    echo    1. Check network connection
    echo    2. Run this script as administrator
    echo    3. Manual run: %PYTHON_EXEC% -m pip install -r requirements.txt
    echo.
    pause
    exit /b 1
)

echo.
echo ========================================
echo   Installation Complete!
echo ========================================
echo.
echo 📝 Next steps:
echo   • Start ComfyUI
echo   • Find JakeUpgrade nodes in node menu
echo   • If issues occur, check console error messages
echo.

pause