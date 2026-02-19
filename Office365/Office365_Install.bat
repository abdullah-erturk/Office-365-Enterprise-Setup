
	:: Bu betik dosyas Abdullah ERTšRK tarafndan kodlanmŸtr. 
	:: This script file was coded by Abdullah ERTšRK.
	
	:: https://github.com/abdullah-erturk
	:: https://erturk.netlify.app/
	
@echo off
:: ==============================
::   D˜L ALGILAMA (TR / EN)
:: ==============================
for /f %%i in ('powershell -NoProfile -Command "(Get-UICulture).Name"') do set LANGID=%%i

if /I "%LANGID%"=="tr-TR" (
    set TITLE_TXT="Office 365 Enterprise Kurulum | made by Abdullah ERTšRK | www.TNCTR.com"
    set ADMIN_TXT=Y™NET˜C˜ HAKLARI ETK˜NLEžT˜R˜L˜YOR...
    set UI_TXT=		Arayz hazrlanyor, ltfen bekleyin...
    set PS_ERR=o365.ps1 ‡alŸtrlrken bir hata oluŸtu.
    set OSERR_POPUP="˜Ÿletim Sistemi Windows 10/11 de§il. Bu uygulama iŸletim sisteminiz tarafndan desteklenmiyor. 5 saniye i‡inde iŸlem sonlandrlacak."
    set POPUP_TITLE="made by Abdullah ERTšRK ^| www.TNCTR.com"
) else (
    set TITLE_TXT="Office 365 Enterprise Setup | made by Abdullah ERTšRK | www.TNCTR.com"
    set ADMIN_TXT=ELEVATING ADMINISTRATOR PRIVILEGES...
    set UI_TXT=		Preparing interface, please wait...
    set PS_ERR=An error occurred while running o365.ps1.
    set OSERR_POPUP="The Operating System is not Windows 10/11. This application is not supported. The process will terminate in 5 seconds."
    set POPUP_TITLE="made by Abdullah ERTšRK ^| www.TNCTR.com"
)

title %TITLE_TXT%
mode con cols=100 lines=4

>nul 2>&1 "%systemroot%\system32\cacls.exe" "%systemroot%\system32\config\system"
if '%errorlevel%' neq '0' (
    echo.
    echo.
    echo          %ADMIN_TXT%
    echo.
    powershell -Command "Start-Process '%~f0' -Verb RunAs"
    exit /b
)

for /f "tokens=6 delims=[]. " %%# in ('ver') do set winbuild=%%#
if %winbuild% LSS 10240 (
    goto :UnsupportedVersion
)

echo.
echo          %UI_TXT%
start /b timeout /t 3 >nul 2>&1

start "" powershell -WindowStyle Hidden -ExecutionPolicy Bypass -File "%~dp0Office\o365.ps1" >nul 2>&1
if %errorlevel% neq 0 (
    echo.
    echo %PS_ERR%
    pause
    exit /b
)
exit /b

:UnsupportedVersion
echo.
powershell -Command "$wshell = New-Object -ComObject wscript.shell; $wshell.Popup('%OSERR_POPUP%', 5, '%POPUP_TITLE%', 64+4096)"
cls
exit