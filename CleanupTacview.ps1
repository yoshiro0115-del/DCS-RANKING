# --- 設定項目 ---
$TargetDir = "D:\tacview_log"  # 消去したいフォルダのパスに変更してください
$FilePattern = "Tacview*"          # 消去するファイル名のパターン
$DaysOld = 10                       # 0なら即時削除。3なら3日以上前のものを削除


# --- 実行処理 ---
Write-Host "Cleanup Start: $TargetDir"

# ファイルを検索して削除
Get-ChildItem -Path $TargetDir -Filter $FilePattern -Recurse | Where-Object {
    $_.LastWriteTime -lt (Get-Date).AddDays(-$DaysOld)
} | Remove-Item -Force -Verbose

Write-Host "Done."