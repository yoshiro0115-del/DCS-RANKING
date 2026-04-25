@echo off
title TSUMUGI_LIVE_LOGGER_V2.5
chcp 65001 >nul

:: --- 設定 ---
set "SLOG=C:\Users\yoshi\Saved Games\DCS TRAINING SERVER\Logs\dcs.log"
set "TFILE=D:\DCS_RANKING_SYS\Ranking_Live.txt"
set "AFILE=D:\DCS_RANKING_SYS\Ranking_Archive.txt"
set "PS_SCRIPT=%TEMP%\dcs_monitor.ps1"

echo [初期化] フォルダを確認中...
if not exist "D:\DCS_RANKING_SYS" mkdir "D:\DCS_RANKING_SYS"
type nul > "%TFILE%"

:: 一時的なPowerShellスクリプトを作成（ここでBOMなしUTF-8の処理を定義）
echo $enc = New-Object System.Text.UTF8Encoding($false) > "%PS_SCRIPT%"
echo Get-Content -Path '%SLOG%' -Wait -Tail 0 ^| Where-Object { $_ -match 'RANKING^|BVR_RESULT^|SD_RESULT^|DACT^|SCRAMBLE_RESULT' } ^| ForEach-Object { >> "%PS_SCRIPT%"
echo     $line = $_ + [Environment]::NewLine >> "%PS_SCRIPT%"
echo     [System.IO.File]::AppendAllText('%TFILE%', $line, $enc) >> "%PS_SCRIPT%"
echo     [System.IO.File]::AppendAllText('%AFILE%', $line, $enc) >> "%PS_SCRIPT%"
echo     Write-Host $_ >> "%PS_SCRIPT%"
echo } >> "%PS_SCRIPT%"

echo --------------------------------------------------
echo [監視開始] ログを監視中... (BOMなしUTF-8)
echo --------------------------------------------------

:LOOP
:: 作成したスクリプトを実行
powershell -NoProfile -ExecutionPolicy Bypass -File "%PS_SCRIPT%"

echo [再試行] 5秒後に監視を再開します...
timeout /t 5 >nul
goto LOOP