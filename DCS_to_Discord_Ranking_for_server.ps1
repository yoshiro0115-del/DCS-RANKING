# --- 設定項目 ---
# 1. 個別成績（速報）の送り先
$webhookPersonal = "https://discord.com/api/webhooks/1470703166935924911/bZ4ehtZzWgT2acQlG2BTwIv2SZmHJdMaeY0wjgE2doNokJ09miAYzdu7qflvAo-ikH80"
# 2. ランキング（上位5件）の送り先
$webhookRanking  = "https://discord.com/api/webhooks/1470700112656338984/cf7GI1hNI8OhF6Lay0bsyIRZ4Up3HumjsEUfFK48KwjJC58Fr5ZzsIeyI3BC_7SJEVKn"

$logFile = "D:\DCS_RANKING_SYS\Ranking_Live.txt"
$dbFile = "D:\DCS_RANKING_SYS\ranking_db.json"

# もし特定のファイル(Ranking_Live.txt)を監視するならそのパスを指定してください 
# --- --- --- ---
Write-Host "--------------------------------------------------" -ForegroundColor Cyan
Write-Host " DCS to Discord Log Monitor Started" -ForegroundColor Cyan
Write-Host " Monitoring: $logFile (Embed Only Mode)" -ForegroundColor Cyan
Write-Host "--------------------------------------------------" -ForegroundColor Cyan

# --- ミッション名変換リスト（ここに数字と名前を登録してください） ---
$missionMap = @{
    "120" = "Short Flight"
    "121" = "Formation Flight 1"
    "122" = "Formation Flight 2"
    "123" = "Formation Flight 3"
    "124" = "Refueling"
    "125" = "Low-alt Flight Time Attack 1"
    "126" = "Low-alt Flight Time Attack 2"
    "127" = "Low-alt Flight Time Attack 3"
    "128" = "Low-alt Flight Time Attack 4"

    "130" = "Baloon Shooting 1"
    "131" = "Baloon Shooting 2"
    "132" = "Baloon Shooting 3"
    "133" = "Baloon Shooting 4"
    "134" = "Baloon Shooting 5"
    "135" = "Ground Shooting 1"
    "136" = "Ground Shooting 2"
    "137" = "Ground Shooting 3"
    "138" = "Ground Shooting 4"

    "140" = "AREA Shooting 1"
    "141" = "AREA Shooting 2"
    "142" = "AREA Shooting 3"
    "143" = "AREA Shooting 4"
    "144" = "AREA Shooting 5"
    "145" = "AREA Shooting 6"
    "146" = "AREA Shooting 7"
    "147" = "AREA Shooting 8"
    "148" = "AREA Shooting 9"

    "150" = "ACM vs F-86F"
    "151" = "ACM vs F-4E"
    "152" = "ACM vs F-5E"
    "153" = "ACM vs F-16C"
    "154" = "ACM vs F/A-18C"
    "155" = "ACM vs F-14B"
    "156" = "ACM vs F-15C"
    "157" = "ACM vs Mig-29S"

    "160" = "C-BFM vs F-4E"
    "161" = "C-BFM vs F-5E"
    "162" = "C-BFM vs F-16C"
    "163" = "C-BFM vs F-14B"
    "164" = "C-BFM vs F-15C"
    "165" = "C-BFM vs Su-27"

}
# --- --- --- ---



function Get-DB {
    if (Test-Path $script:dbFile) { 
        $content = Get-Content $script:dbFile -Raw -Encoding UTF8
        if (![string]::IsNullOrWhiteSpace($content)) { 
            $json = $content | ConvertFrom-Json
            # 1件でも複数件でも、確実に「配列」として返すための魔法の書き方
            return ,$json | % { if ($_ -is [array]) { $_ } else { @($_) } }
        }
    }
    return @()
}

function Save-DB ($dbData) {
    $dbData | ConvertTo-Json -Depth 10 | Set-Content -Path $script:dbFile -Encoding UTF8
}

$buffer = ""
Write-Host "--- DCS Ranking System (Ultimate Repair) Start ---" -ForegroundColor Cyan

Get-Content $logFile -Wait -Tail 0 | ForEach-Object {
    $line = $_

# ==========================================================
    # 1. BVRミッション結果の処理 (ランキング除外・Discord速報のみ)
    # ==========================================================
    if ($line -match "\[BVR_RESULT\]") {
        # ログ形式: [BVR_RESULT] ID:Su-27x2_MiG-29Sx2 | Time:120.50 | Pilots:Name1, Name2 [END]
        if ($line -match "ID:(?<id>.*?) \| Time:(?<time>.*?) \| Pilots:(?<pilots>.*?) \[END\]") {
            $mIdStr = $Matches['id'].Trim()
            $pTime  = $Matches['time'].Trim()
            $pNames = $Matches['pilots'].Trim()

            Write-Host "BVR Training Result Detected: $mIdStr" -ForegroundColor Cyan

            # Discord用ペイロード作成
            $bvrPayload = @{
                embeds = @(@{
                    title = "BVR TRAINING COMPLETED"
                    color = 3447003 # 青色
                    fields = @(
                        @{ name = "Target Setup"; value = "``$mIdStr``"; inline = $true }
                        @{ name = "Clear Time"; value = "``$pTime sec``"; inline = $true }
                        @{ name = "Pilots"; value = "``$pNames``" }
                    )
                    footer = @{ text = "Training Record - Not reflected in rankings" }
                })
            } | ConvertTo-Json -Depth 10 -Compress

            # Discordへ送信 (Personal用Webhookを使用)
            Invoke-RestMethod -Uri $webhookPersonal -Method Post -Body ([System.Text.Encoding]::UTF8.GetBytes($bvrPayload)) -ContentType "application/json; charset=utf-8"
            Write-Host "BVR Result sent to Discord. Skipping Ranking DB." -ForegroundColor Green
        }
        return # ForEach-Object内でのcontinueに相当し、次の行の処理へ移る
    }
# ==========================================================
    # S&Dミッション結果の処理 (速報のみ)
    # ==========================================================
    if ($line -match "\[SD_RESULT\]") {
        # ログ形式: [SD_RESULT] ID:Balloon_Hunting_field-8 | Kills:Name1:5, Name2:3 [END]
        if ($line -match "ID:(?<id>.*?) \| Kills:(?<kills>.*?) \[END\]") {
            $mIdStr = $Matches['id'].Trim()
            $pKills = $Matches['kills'].Trim() -replace ":", " - " # 表示を見やすく加工

            Write-Host "S&D Mission Result Detected: $mIdStr" -ForegroundColor Cyan

            $sdPayload = @{
                embeds = @(@{
                    title = "SEARCH & DESTROY COMPLETED"
                    color = 15105570 # オレンジ色
                    fields = @(
                        @{ name = "Mission ID"; value = "``$mIdStr``"; inline = $true }
                        @{ name = "Final Kill Counts"; value = "``$pKills``" }
                    )
                    footer = @{ text = "Training Record - Results sent to Discord" }
                })
            } | ConvertTo-Json -Depth 10 -Compress

            # 速報用(webhookPersonal)へ送信
            Invoke-RestMethod -Uri $webhookPersonal -Method Post -Body ([System.Text.Encoding]::UTF8.GetBytes($sdPayload)) -ContentType "application/json; charset=utf-8"
            Write-Host "S&D Result sent to Discord." -ForegroundColor Green
        }
        return 
    }

    if ($line -match "\[RANKING\]") { $buffer = $line }
    elseif ($buffer -ne "") { $buffer += $line }

    if ($buffer -match "\[END\]") {
        $data = $buffer -replace ".*\[RANKING\]", "" -replace "\[END\].*", ""
        $data = $data -replace "`n", "" -replace "`r", ""
        $parts = $data.Split("|")
        
        if ($parts.Count -ge 6) {
            $mId    = ($parts[0] -replace "Mi:", "").Trim()
            $pName  = ($parts[1] -replace "Pi:", "").Trim()
            $acType = ($parts[2] -replace "AF:", "").Trim()
            $score  = [int]($parts[3] -replace "SC:", "").Trim()
            $time   = [double]($parts[4] -replace "Ti:", "").Trim()
            $rank   = ($parts[5] -replace "Ra:", "").Trim()
            $mName  = if ($missionMap.ContainsKey($mId)) { $missionMap[$mId] } else { "Mission $mId" }

            Write-Host "Record: $pName ($acType) in $mName" -ForegroundColor Yellow

            # --- A. 個別速報の送信 ---
            $pColor = if ($rank -like "*S*") { 16766720 } elseif ($rank -like "*A*") { 15548997 } else { 3447003 }
            $personalPayload = @{
                embeds = @(@{
                    title = "NEW FLIGHT RECORD"
                    color = $pColor
                    fields = @(
                        @{ name = "Mission"; value = $mName; inline = $true }
                        @{ name = "Pilot"; value = $pName; inline = $true }
                        @{ name = "Aircraft"; value = $acType; inline = $true }
                        @{ name = "Rank"; value = "**$rank**"; inline = $true }
                        @{ name = "Score"; value = "$score pts"; inline = $true }
                        @{ name = "Total Time"; value = "$time sec"; inline = $true }
                    )
                })
            } | ConvertTo-Json -Depth 10 -Compress
            Invoke-RestMethod -Uri $webhookPersonal -Method Post -Body ([System.Text.Encoding]::UTF8.GetBytes($personalPayload)) -ContentType "application/json; charset=utf-8"

            # --- B. ランキング処理 (ここがエラーの箇所) ---
            # 読み込み時に強制配列化
            [array]$db = Get-DB
            
            # 既存記録の検索
            $found = $false
            # 既存記録の検索ループの中
            foreach ($item in $db) {
                if ($item.mId -eq $mId -and $item.pName -eq $pName -and $item.acType -eq $acType) {
                    $found = $true

                    # --- ここから修正 ---
                    # 124(給油)は時間が長い方が「良い記録」とみなす判定
                    $isBetter = if ($mId -eq "124") {
                        ($score -gt $item.score -or ($score -eq $item.score -and $time -gt $item.time))
                    } else {
                        ($score -gt $item.score -or ($score -eq $item.score -and $time -lt $item.time))
                    }

                    if ($isBetter) {
                        $item.score = $score
                        $item.time = $time
                        $item.rank = $rank
                        $shouldUpdate = $true
                    } else {
                        $shouldUpdate = $false
                    }
                    # --- ここまで修正 ---
                    break
                }
            }

            if (-not $found) {
                # 新規追加
                $newItem = [PSCustomObject]@{ mId=$mId; pName=$pName; acType=$acType; score=$score; time=$time; rank=$rank }
                $db = $db + $newItem
                $shouldUpdate = $true
                Write-Host "New Pilot/Aircraft registered." -ForegroundColor White
            }

            Save-DB $db

            # --- C. ランキング送信 ---
            if ($shouldUpdate) {
               if ($mId -eq "124") {
        $top5 = $db | Where-Object { $_.mId -eq $mId } | Sort-Object @{Expression="score";Descending=$true}, @{Expression="time";Descending=$true} | Select-Object -First 5
    } else {
        $top5 = $db | Where-Object { $_.mId -eq $mId } | Sort-Object @{Expression="score";Descending=$true}, @{Expression="time";Ascending=$true} | Select-Object -First 5
    }
                $scoreBoard = ""
                $idx = 1
                foreach ($entry in $top5) {
                    $scoreBoard += "$idx. **$($entry.pName)** ($($entry.acType))`n   > Score: **$($entry.score)** | Time: **$($entry.time)**s | Rank: **$($entry.rank)**`n"
                    $idx++
                }
                $rankingPayload = @{
                    embeds = @(@{
                        title = "$mName TOP 5 RANKING"
                        color = 16766720
                        description = $scoreBoard
                        footer = @{ text = "Ranking Updated!" }
                    })
                } | ConvertTo-Json -Depth 10 -Compress
                Invoke-RestMethod -Uri $webhookRanking -Method Post -Body ([System.Text.Encoding]::UTF8.GetBytes($rankingPayload)) -ContentType "application/json; charset=utf-8"
                Write-Host "Ranking updated!" -ForegroundColor Green
            }
        }
        $buffer = ""
    }
}