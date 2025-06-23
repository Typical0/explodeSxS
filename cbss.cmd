@echo off
setlocal EnableDelayedExpansion

pushd "%~dp0"
cd /d "%~dp0"

for %%k in (sxs\Microsoft-Windows-ProfessionalEdition~31bf3856ad364e35~*.mum) do (
    set "name_tmp=%%~nk"
for /f "tokens=3,4,5,6,7 delims=~." %%a in ("!name_tmp!") do (
    set "_arch=%%a"
    set "V1=%%b"
    set "V2=%%c"
    set "V3=%%d"
    set "V4=%%e"
    set "LVER=!V1!.!V2!.!V3!.!V4!"
)
)

for %%m in (sxs\%_arch%_microsoft-windows-servicingstack_31bf3856ad364e35_%LVER%_none_*) do (
   set "ssu_tmp=%%~nm"
for /f "tokens=9 delims=_." %%o in ("!ssu_tmp!") do (
set "_ss=sxs\%_arch%_microsoft-windows-servicingstack_31bf3856ad364e35_%LVER%_none_%%o"
)
)
:MainMenu
cls
echo __________________________________________________________________
echo.
echo                     stageSxS-principalis                            
echo __________________________________________________________________
echo.
echo SxSFounder, CbsExploder - made by WitherOrNot (https://github.com/WitherOrNot), 
echo licensed under GNU GPL 3.0
echo.
echo This tool constructs Microsoft Windows image out of base UUP components.
echo.
echo For the tool to work, you need to have X: drive letter assigned. 
echo RAM disk (8 gigabytes at least) is recommended, you can also assign an
echo actual drive or use subst to assign the drive letter to a folder.
echo ===============================================================================
if not defined selectedEdition (
  if not defined selectedLang (
    echo Constructed build: !LVER! !_arch!
  ) else (
    echo Constructed build: !LVER! !selectedLang! !_arch!
  )
) else (
  if not defined selectedLang (
    echo Constructed build: !LVER! !selectedEdition! !_arch!
  ) else (
    echo Constructed build: !LVER! !selectedEdition! !selectedLang! !_arch!
  )
)        
echo ===============================================================================
echo         0: Start Construction
echo ===============================================================================
echo.
echo         1: Select edition
echo         2: Select language
echo         E: Exit
echo. 
echo ==============================================================================
set /p Choice="Select your option: "
if "%Choice%"=="0" goto Continue
if "%Choice%"=="1" goto EditionSelect 
if "%Choice%"=="2" goto LangSelect 
if "%Choice%"=="E" goto End

goto :MainMenu

:EditionSelect
cls
set "editionCount=0"
for %%f in (sxs\Microsoft-Windows-*Edition~31bf3856ad364e35~*.mum) do (
    set "filename=%%~nxf"
    for /f "tokens=3 delims=-" %%a in ("!filename!") do (
        for /f "delims=~" %%b in ("%%a") do (
            set "rawEdition=%%b"
            set "edition=!rawEdition:Edition=!"
            if not defined editionFound_!edition! (
                call :AddUniqueEdition "!edition!"
                set "editionFound_!edition!=1"
            )
        )
    )
)

echo.
echo Available Windows Editions:
for /l %%i in (1,1,!editionCount!) do (
    echo %%i. !edition%%i!
)
set /p "editionChoice=Select an edition number: "
if not defined edition%editionChoice% (
    echo Invalid selection.
    exit /b
)
set "selectedEdition=!edition%editionChoice%!"
set "_edition=!selectedEdition!"
echo Selected Edition: !selectedEdition!
goto :MainMenu

:LangSelect
cls
set "langCount=0"

for %%f in (sxs\Microsoft-Windows-Client-LanguagePack-Package~31bf3856ad364e35~*.mum) do (
    set "filename=%%~nxf"
    for /f "tokens=4 delims=~" %%a in ("!filename!") do (
        echo %%a >> nul
        if !errorlevel! == 0 (
            if not defined langFound_%%a (
                call :AddUniqueLang "%%a"
                set "langFound_%%a=1"
            )
        )
    )
)

echo.
echo Available Languages:
for /l %%i in (1,1,!langCount!) do (
    echo %%i. !lang%%i!
)
set /p "langChoice=Select a language number: "
if not defined lang%langChoice% (
    echo Invalid selection.
    exit /b
)
set "selectedLang=!lang%langChoice%!"
set "_lang=!lang%langChoice%!"
set "_lp=sxs\Microsoft-Windows-Client-LanguagePack-Package~31bf3856ad364e35~%_arch%~%_lang%~%LVER%.mum"
goto :MainMenu
:: === Language Menu (End)

:AddUniqueEdition
for /l %%i in (1,1,!editionCount!) do (
    if /i "!edition%%i!"=="%~1" goto :eof
)
set /a editionCount+=1
set "edition!editionCount!=%~1"
goto :eof

:AddUniqueLang
for /l %%i in (1,1,!langCount!) do (
    if /i "!lang%%i!"=="%~1" goto :eof
)
set /a langCount+=1
set "lang!langCount!=%~1"
goto :eof

:Continue
if not defined _edition (
   call :Error Edition
)
  
if not defined _lang (
   call :Error Language
)

::Prepare disk
echo Preparing...
call "%~dp0prepare.cmd" "%_arch%" "%_ss%" || exit /b 1

::Install SKUs
echo Installing SKUs...
set WINDOWS_WCP_INSKUASSEMBLY=1
X:\desktopimaging\cbsx.exe /o:X:\image\Windows /log:X:\logs\1-skuassembly.log /ip /m:sxs/Microsoft-Windows-!selectedEdition!Edition~31bf3856ad364e35~%_arch%~~!LVER!.mum /s:X:\temp || exit /b 1
set WINDOWS_WCP_INSKUASSEMBLY=

::Install Language pack
echo.
echo Installing language pack...
dism /logpath:X:\logs\2-langpack.log /scratchdir:"X:\temp" /image:X:\image /add-package /packagepath:"%_lp%" || exit /b 1

::Edition specific
echo.
echo Applying edition specific settings...
copy X:\image\Windows\servicing\Editions\%_edition%Edition.xml X:\image\Windows\%_edition%.xml || exit /b 1
dism /logpath:X:\logs\3-skuspecific.log /scratchdir:"X:\temp" /image:X:\image /apply-unattend:X:\image\Windows\%_edition%.xml || exit /b 1

::Check edition
echo.
echo Verifying current edition and target editions...
dism /logpath:X:\logs\4-currentedition.log /scratchdir:"X:\temp" /image:X:\image /get-currentedition /english || exit /b 1
dism /logpath:X:\logs\4-targetedition.log /scratchdir:"X:\temp" /image:X:\image /get-targeteditions /english || exit /b 1

::Language
echo.
echo Setting language configuration...
dism /logpath:X:\logs\5-intl.log /scratchdir:"X:\temp" /image:X:\image /set-allintl:%_lang% /english || exit /b 1

::Cleanup
echo.
echo Cleaning up the image...
dism /logpath:X:\logs\6-analyze.log /scratchdir:"X:\temp" /image:X:\image /cleanup-image /analyzecomponentstore /english || exit /b 1
dism /logpath:X:\logs\6-cleanup.log /scratchdir:"X:\temp" /image:X:\image /cleanup-image /startcomponentcleanup /english || exit /b 1

::Finish image
echo.
echo Finishing the image...
call "%~dp0finishimg.cmd" %LVER% || exit /b 1


:Error
echo %1 not selected. Going back to the main menu...
timeout /t 5
goto :MainMenu

:END
echo.
pause
exit

