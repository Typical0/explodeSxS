if exist X:\image\sources rmdir /s /q X:\image\sources
if exist X:\image\perflogs\admin rmdir /s /q X:\image\perflogs\admin
rem \windows\winsxs\migration.xml
if not exist X:\image\windows\winsxs\fusion\ md X:\image\windows\winsxs\fusion\
if exist X:\image\windows\csc rmdir /s /q X:\image\windows\csc
if exist X:\image\windows\prefetch rmdir /s /q X:\image\windows\prefetch
if not exist "X:\image\Windows\Setup\State" mkdir "X:\image\Windows\Setup\State"

echo:[State]>X:\image\Windows\Setup\State\State.ini
echo:ImageState=IMAGE_STATE_GENERALIZE_RESEAL_TO_OOBE>X:\image\Windows\Setup\State\State.ini>>X:\image\Windows\Setup\State\State.ini

REG.EXE LOAD HKLM\CBSS_SOFTWARE X:\image\Windows\System32\config\SOFTWARE || exit /b 1
REG.EXE LOAD HKLM\CBSS_SYSTEM X:\image\Windows\System32\config\SYSTEM || exit /b 1

reg add "HKLM\CBSS_SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\ApplicabilityEvaluationCache\Microsoft-Windows-FodMetadata-Package~31bf3856ad364e35~amd64~~%1" /f /v "ApplicabilityState" /t REG_DWORD /d 112
reg add "HKLM\CBSS_SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\ApplicabilityEvaluationCache\Microsoft-Windows-FodMetadata-Package~31bf3856ad364e35~amd64~~%1" /f /v "CurrentState" /t REG_DWORD /d 112

REG.EXE IMPORT "%~dp0files\imagestate.reg" || exit /b 1

REG.EXE UNLOAD HKLM\CBSS_SOFTWARE || exit /b 1
REG.EXE UNLOAD HKLM\CBSS_SYSTEM || exit /b 1