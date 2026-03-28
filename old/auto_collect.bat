@echo off
title TSUMUGI_LIVE_LOGGER_FINAL
chcp 65001 >nul

set "SOURCE_LOG=C:\Users\yoshi\Saved Games\DCS TRAINING SERVER\Logs\dcs.log"
set "TARGET_FILE=D:\DCS_RANKING_SYS\Ranking_Live.txt"
set "ARCHIVE_FILE="D:\DCS_RANKING_SYS\Ranking_Archive.txt"

echo [初期化] ファイルを確認中...
if not exist "D:\DCS_RANKING_SYS" mkdir "D:\DCS_RANKING_SYS"
type nul > "%TARGET_FILE%"

echo --------------------------------------------------
echo [監視開始] ログの生成と更新を永久ループで監視します...
echo ※DCSがログを再作成しても自動で再接続します。
echo --------------------------------------------------




:: PowerShellを実行。エラー（ファイル消失）が起きたら終了してバッチのループに戻る
powershell -Command "Get-Content '%SOURCE_LOG%' -Wait -Tail 0 | Where-Object { $_ -match 'RANKING|BVR_RESULT|SD_RESULT' } | ForEach-Object { $_ | Out-File -FilePath '%TARGET_FILE%' -Append -Encoding utf8; $_ | Out-File -FilePath '%ARCHIVE_FILE%' -Append -Encoding utf8; Write-Host $_ }"


:: PowerShellを実行（ファイルの共有モードを完全に開放して読み取る方式）
powershell -Command "[Console]::OutputEncoding = [System.Text.Encoding]::UTF8; $stream = $null; while($null -eq $stream){ try { $stream = New-Object System.IO.FileStream('%SOURCE_LOG%', 'Open', 'Read', 'ReadWrite') } catch { Start-Sleep -Milliseconds 500 } } $reader = New-Object System.IO.StreamReader($stream); try { $reader.BaseStream.Seek(0, 'End') | Out-Null; while($true) { $line = $reader.ReadLine(); if($line -match 'RANKING|BVR_RESULT|SD_RESULT') { $line | Out-File -FilePath '%TARGET_FILE%' -Append -Encoding utf8; $line | Out-File -FilePath '%ARCHIVE_FILE%' -Append -Encoding utf8; Write-Host $line } elseif($line -eq $null) { Start-Sleep -Milliseconds 100 } } } finally { if ($null -ne $reader) { $reader.Close() }; if ($null -ne $stream) { $stream.Close() } }"


:: PowerShellが終了（ファイル消失など）したら、ここに来る
echo [警告] ログが一時的に中断されました。3秒後に再接続を試みます...
timeout /t 3 /nobreak >nul
goto MAIN_LOOP