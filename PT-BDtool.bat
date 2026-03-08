@echo off
setlocal
set SCRIPT_DIR=%~dp0
if exist "%SCRIPT_DIR%ptbd-gui.py" (
  py -3 "%SCRIPT_DIR%ptbd-gui.py"
  if %errorlevel%==0 exit /b 0
  python "%SCRIPT_DIR%ptbd-gui.py"
  exit /b %errorlevel%
)
echo [ERROR] Cannot find ptbd-gui.py
exit /b 1
