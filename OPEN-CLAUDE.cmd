@echo off
REM ===========================================================================
REM  OPEN-CLAUDE.cmd - start the gateway (if needed) and open Claude Code
REM
REM  Reads the gateway key from the router's own .unified-key file, so no
REM  secret is ever stored in this repo.
REM
REM  Just double-click this file.
REM ===========================================================================
setlocal EnableExtensions EnableDelayedExpansion
cd /d "%~dp0"

set "ROUTER_DIR=%CD%\..\freellmapi"
set "GATEWAY=http://127.0.0.1:3001"
set "KEYFILE=%ROUTER_DIR%\.unified-key"

echo.
echo   ============================================
echo     Claude Code  ^|  free-LLM gateway
echo   ============================================
echo.

REM --- Sanity --------------------------------------------------------------
if not exist "%ROUTER_DIR%\server\dist\index.js" (
  echo   [X] The router is not built yet.
  echo       Run setup.cmd first.
  echo.
  pause
  exit /b 1
)
where claude >nul 2>nul
if errorlevel 1 (
  echo   [X] Claude Code is not installed.
  echo       Run:  npm install -g @anthropic-ai/claude-code
  pause
  exit /b 1
)

REM --- Is the gateway already up? -----------------------------------------
call :IS_UP
if "!UP!"=="1" (
  echo   [OK] Gateway already running on %GATEWAY%
  goto :READKEY
)

echo   [..] Starting the gateway in a minimised window...
start "free-LLM gateway" /min cmd /c "cd /d "%ROUTER_DIR%" && node server\dist\index.js"

echo   [..] Waiting for it to answer...
set /a N=0
:WAIT
call :IS_UP
if "!UP!"=="1" goto :READKEY
set /a N+=1
if !N! GEQ 40 (
  echo.
  echo   [X] The gateway did not answer after 40 seconds.
  echo       Open the minimised "free-LLM gateway" window to see why.
  pause
  exit /b 1
)
ping -n 2 127.0.0.1 >nul
goto :WAIT

:READKEY
REM --- Resolve the gateway key ---------------------------------------------
REM The router stores it in its SQLite 'settings' table. Older/hand-made
REM installs may also keep a .unified-key file, so try that first, then the DB.
REM Nothing here is a secret of ours: we read the key the router already made.
set "GATEWAYKEY="

if exist "%KEYFILE%" (
  for /f "usebackq tokens=1,* delims==" %%a in ("%KEYFILE%") do (
    if /i "%%a"=="KEY" set "GATEWAYKEY=%%b"
  )
  if "!GATEWAYKEY!"=="" (
    for /f "usebackq tokens=*" %%a in ("%KEYFILE%") do if "!GATEWAYKEY!"=="" set "GATEWAYKEY=%%a"
  )
)

if "!GATEWAYKEY!"=="" (
  for /f "usebackq tokens=*" %%k in (`node "%ROUTER_DIR%\scripts\read-gateway-key.mjs" "%ROUTER_DIR%"`) do set "GATEWAYKEY=%%k"
)

if "!GATEWAYKEY!"=="" (
  echo   [X] Could not read the gateway key.
  echo.
  echo       Open the dashboard and copy it from the Keys page:
  echo         %GATEWAY%
  echo.
  pause
  exit /b 1
)
echo   [OK] Gateway healthy.

REM --- Persist the Claude Code settings (idempotent) ----------------------
REM Written via .NET UTF8Encoding($false) to avoid a BOM: PowerShell's
REM -Encoding UTF8 emits one, and a BOM makes the file invalid JSON.
set "CLAUDE_DIR=%USERPROFILE%\.claude"
if not exist "%CLAUDE_DIR%" mkdir "%CLAUDE_DIR%"
powershell -NoProfile -Command ^
  "$p = '%CLAUDE_DIR%\settings.json'; " ^
  "if (Test-Path $p) { $j = Get-Content -Raw $p | ConvertFrom-Json } else { $j = New-Object psobject }; " ^
  "if (-not $j.env) { $j | Add-Member -NotePropertyName env -NotePropertyValue (New-Object psobject) -Force }; " ^
  "$j.env | Add-Member -NotePropertyName ANTHROPIC_BASE_URL -NotePropertyValue 'http://127.0.0.1:3001' -Force; " ^
  "$j.env | Add-Member -NotePropertyName ANTHROPIC_AUTH_TOKEN -NotePropertyValue '!GATEWAYKEY!' -Force; " ^
  "$j.env | Add-Member -NotePropertyName ANTHROPIC_MODEL -NotePropertyValue 'auto' -Force; " ^
  "$j.env | Add-Member -NotePropertyName ANTHROPIC_DEFAULT_OPUS_MODEL -NotePropertyValue 'auto' -Force; " ^
  "$j.env | Add-Member -NotePropertyName ANTHROPIC_DEFAULT_SONNET_MODEL -NotePropertyValue 'auto' -Force; " ^
  "$j.env | Add-Member -NotePropertyName ANTHROPIC_DEFAULT_HAIKU_MODEL -NotePropertyValue 'auto' -Force; " ^
  "$json = $j | ConvertTo-Json -Depth 10; " ^
  "[System.IO.File]::WriteAllText($p, $json, (New-Object System.Text.UTF8Encoding($false)))"
if errorlevel 1 (
  echo   [X] Could not write %CLAUDE_DIR%\settings.json
  pause
  exit /b 1
)
echo   [OK] Claude Code configured.

REM --- Pick a folder ------------------------------------------------------
echo.
echo   Where do you want to work?
echo     [1] This folder   - %CD%        (default)
echo     [2] Another folder
echo.
set "TARGET="
set /p "PICK=  Choice: "
if "!PICK!"=="2" (
  set /p "TARGET=  Full path: "
) else (
  set "TARGET=%CD%"
)
if "!TARGET!"=="" set "TARGET=%CD%"
if not exist "!TARGET!" (
  echo   [X] That folder does not exist: !TARGET!
  pause
  exit /b 1
)

echo.
echo   ------------------------------------------------------------
echo    Claude Code is starting in: !TARGET!
echo.
echo      /help    all commands        /exit   quit
echo      /model   switch models       /clear  reset context
echo.
echo    Failover across all providers is automatic. If a model is
echo    busy or rate limited, the router moves on without telling
echo    you.
echo   ------------------------------------------------------------
echo.

pushd "!TARGET!"
call claude
popd

echo.
echo   Claude Code closed. The gateway is still running minimised.
ping -n 5 127.0.0.1 >nul
exit /b 0

REM ===========================================================================
:IS_UP
REM /health is unauthenticated and answers 200 when the gateway is ready.
REM (/v1/models needs a bearer token, so it cannot be used before we know the key.)
set "UP=0"
powershell -NoProfile -Command "try { $r = Invoke-WebRequest -UseBasicParsing -Uri '%GATEWAY%/health' -TimeoutSec 4; if ($r.StatusCode -eq 200) { exit 0 } else { exit 1 } } catch { exit 1 }" >nul 2>nul
if not errorlevel 1 set "UP=1"
exit /b 0