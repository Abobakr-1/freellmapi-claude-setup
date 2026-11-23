@echo off
REM ===========================================================================
REM  setup.cmd - one-time installer for the Claude Code free-LLM gateway
REM
REM  1. Checks Node.js
REM  2. Clones FreeLLMAPI next to this folder
REM  3. Installs dependencies and builds
REM  4. Prompts for your free Google + Groq keys
REM  5. Writes the gateway config
REM  6. Configures Claude Code
REM
REM  Run this once. After that, use OPEN-CLAUDE.cmd.
REM ===========================================================================
setlocal EnableExtensions EnableDelayedExpansion
cd /d "%~dp0"

set "ROUTER_DIR=%CD%\..\freellmapi"
set "PORT=3001"

echo.
echo   ==========================================================
echo     Claude Code on 10 Free LLM Providers - setup
echo   ==========================================================
echo.

REM --- 1. Node -------------------------------------------------------------
where node >nul 2>nul
if errorlevel 1 (
  echo   [X] Node.js is required but not installed.
  echo       Download the LTS build from https://nodejs.org and re-run this.
  echo.
  pause
  exit /b 1
)
for /f "tokens=*" %%v in ('node --version') do set "NODEV=%%v"
echo   [OK] Node.js %NODEV%

REM --- 2. Get FreeLLMAPI ---------------------------------------------------
if exist "%ROUTER_DIR%\server\package.json" (
  echo   [OK] FreeLLMAPI already present at %ROUTER_DIR%
  goto :INSTALL
)

echo   [..] Cloning FreeLLMAPI (the router this kit configures)...
git --version >nul 2>nul
if errorlevel 1 (
  echo   [X] git is required. Install it from https://git-scm.com and re-run.
  pause
  exit /b 1
)
git clone https://github.com/tashfeenahmed/freellmapi.git "%ROUTER_DIR%"
if errorlevel 1 (
  echo   [X] Clone failed. Check your internet connection and try again.
  pause
  exit /b 1
)
echo   [OK] Cloned.

:INSTALL
echo.
echo   [..] Installing dependencies (this takes a few minutes the first time)...
pushd "%ROUTER_DIR%"
call npm install
if errorlevel 1 (
  echo   [X] npm install failed. See the output above.
  popd
  pause
  exit /b 1
)

echo.
echo   [..] Building the server...
call npm run build -w server
if errorlevel 1 (
  echo   [X] Build failed. See the output above.
  popd
  pause
  exit /b 1
)
popd
echo   [OK] Router built.

REM --- 3. Keys -------------------------------------------------------------
echo.
echo   ----------------------------------------------------------
echo    Free provider keys (both are email-only, no credit card)
echo.
echo      Google Gemini : https://aistudio.google.com/apikey
echo      Groq          : https://console.groq.com/keys
echo.
echo    Press Enter to skip a key and add it later.
echo   ----------------------------------------------------------
echo.
set "GKEY="
set "QKEY="
set /p "GKEY=  Google Gemini key: "
set /p "QKEY=  Groq key: "

if "!GKEY!"=="" set "GKEY=YOUR_GOOGLE_GEMINI_KEY_HERE"
if "!QKEY!"=="" set "QKEY=YOUR_GROQ_KEY_HERE"

REM --- 4. Write config ----------------------------------------------------
set /p "ADMINPW=  Choose a dashboard password (min 8 chars, Enter = random): "
if "!ADMINPW!"=="" (
  for /f "usebackq tokens=*" %%p in (`powershell -NoProfile -Command "-join ((48..57)+(97..122) | Get-Random -Count 20 | ForEach-Object {[char]$_})"`) do set "ADMINPW=%%p"
  echo   [OK] Generated a random password for you.
)

if not exist "%ROUTER_DIR%\server\data" mkdir "%ROUTER_DIR%\server\data"

REM --- 4a. Write .env so the server reads our config, and give it a real
REM         encryption key. Without .env a fresh clone ignores the config
REM         entirely (FREEAPI_CONFIG_PATH would be unset).
for /f "usebackq tokens=*" %%k in (`node -e "console.log(require('crypto').randomBytes(32).toString('hex'))"`) do set "ENCKEY=%%k"
if "!ENCKEY!"=="" (
  echo   [X] Could not generate an encryption key.
  popd
  pause
  exit /b 1
)
> "%ROUTER_DIR%\.env" echo ENCRYPTION_KEY=!ENCKEY!
>> "%ROUTER_DIR%\.env" echo PORT=%PORT%
>> "%ROUTER_DIR%\.env" echo FREEAPI_CONFIG_PATH=%ROUTER_DIR%/server/data/freellmapi.config.json
>> "%ROUTER_DIR%\.env" echo FREELLMAPI_CONTEXT_HANDOFF=on_model_switch
>> "%ROUTER_DIR%\.env" echo FREELLMAPI_UPDATE_CHECK=off
echo   [OK] .env written (encryption key generated).

powershell -NoProfile -Command ^
  "$t = Get-Content -Raw '%CD%\config\freellmapi.config.example.json' | ConvertFrom-Json; " ^
  "$t.admin.password = '%ADMINPW%'; " ^
  "foreach ($k in $t.keys) { if ($k.platform -eq 'google') { $k.key = '%GKEY%' } elseif ($k.platform -eq 'groq') { $k.key = '%QKEY%' } }; " ^
  "$t | ConvertTo-Json -Depth 10 | Set-Content -Encoding UTF8 '%ROUTER_DIR%\server\data\freellmapi.config.json'"
if errorlevel 1 (
  echo   [X] Could not write the config file.
  pause
  exit /b 1
)
echo   [OK] Config written to %ROUTER_DIR%\server\data\freellmapi.config.json

REM --- 5. Claude Code -----------------------------------------------------
echo.
where claude >nul 2>nul
if errorlevel 1 (
  echo   [..] Installing Claude Code...
  call npm install -g @anthropic-ai/claude-code
  if errorlevel 1 (
    echo   [!] Could not install Claude Code automatically.
    echo       Run:  npm install -g @anthropic-ai/claude-code
  )
) else (
  echo   [OK] Claude Code already installed.
)

echo.
echo   ----------------------------------------------------------
echo    Almost done.
echo.
echo    1. A gateway key is generated on first start.
echo    2. Open the dashboard to copy it:
echo         http://127.0.0.1:%PORT%
echo       (log in as local@freellmapi.dev / !ADMINPW!)
echo    3. Point Claude Code at that key, one line:
echo         OPEN-CLAUDE.cmd does this for you automatically.
echo   ----------------------------------------------------------
echo.
echo   [OK] Setup complete. Double-click OPEN-CLAUDE.cmd to start coding.
echo.
pause
endlocal