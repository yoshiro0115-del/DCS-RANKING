@echo off
setlocal
cd /d "D:\DCS_RANKING_SYS"

echo ==================================================
echo   GitHub Manual Update (Mods and Ranking)
echo ==================================================

:: 1. 変更があったファイルをすべて登録
git add .

:: 2. メッセージの作成（スペース対策済み）
set "CURRENT_TIME=%date% %time%"
set /p "msg=Update message (Enter for default): "
if "%msg%"=="" set "msg=Manual Update: %CURRENT_TIME%"

:: 3. コミットとプッシュ（ダブルクォーテーションで囲んでエラー回避）
git commit -m "%msg%" --allow-empty
git push origin main

echo ==================================================
echo   Update Completed!
echo ==================================================
pause