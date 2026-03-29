# 設定
$sourceFile = "D:\DCS_RANKING_SYS\ranking_db.json"
$backupFolder = "D:\DCS_RANKING_SYS\Backup"
$date = Get-Date -Format "yyyyMMdd_HHmm"

# バックアップフォルダがなければ作成
if (!(Test-Path $backupFolder)) {
    New-Item -ItemType Directory -Path $backupFolder
}

# コピー実行（例: ranking_db_20260329_0100.json）
$destFile = Join-Path $backupFolder "ranking_db_$date.json"
Copy-Item -Path $sourceFile -Destination $destFile

Write-Host "Backup completed: $destFile" -ForegroundColor Green

# 30日以上前の古いバックアップを自動削除（不要なら削除してください）
Get-ChildItem $backupFolder -Filter "ranking_db_*.json" | Where-Object { $_.LastWriteTime -lt (Get-Date).AddDays(-30) } | Remove-Item