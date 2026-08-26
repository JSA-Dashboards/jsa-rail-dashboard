@echo off
title JSA Rail Shipments — Streamlit Dashboard
cd /d "%~dp0"

set PYTHON=C:\Python314\python.exe

echo.
echo  Starting JSA Rail Shipments Dashboard...
echo.

:: Kill any old instance on this port first
for /f "tokens=5" %%a in ('netstat -ano 2^>nul ^| findstr :8505 2^>nul') do (
    taskkill /PID %%a /F >nul 2>&1
)

:: Wait 2 seconds then open browser
start /b cmd /c "timeout /t 4 /nobreak >nul && start http://localhost:8505"

"%PYTHON%" -m streamlit run "%~dp0streamlit_app.py" ^
    --server.port 8505 ^
    --server.address localhost ^
    --server.headless true ^
    --browser.gatherUsageStats false

pause
