# --- 設定項目 ---
$webhookPersonal = "https://discord.com/api/webhooks/1470703166935924911/bZ4ehtZzWgT2acQlG2BTwIv2SZmHJdMaeY0wjgE2doNokJ09miAYzdu7qflvAo-ikH80"
$webhookRanking  = "https://discord.com/api/webhooks/1470700112656338984/cf7GI1hNI8OhF6Lay0bsyIRZ4Up3HumjsEUfFK48KwjJC58Fr5ZzsIeyI3BC_7SJEVKn"

$logFile = "D:\DCS_RANKING_SYS\Ranking_Live.txt"
$dbFile = "D:\DCS_RANKING_SYS\ranking_db.json"

Write-Host "--------------------------------------------------" -ForegroundColor Cyan
Write-Host " DCS to Discord Log Monitor Started" -ForegroundColor Cyan
Write-Host " Monitoring: $logFile (Embed Only Mode)" -ForegroundColor Cyan
Write-Host "--------------------------------------------------" -ForegroundColor Cyan

# --- ミッション名変換リスト（添付ファイルを100%維持） ---
$missionMap = @{
    "120" = "Short Flight"; "121" = "Formation Flight 1"; "122" = "Formation Flight 2"; "123" = "Formation Flight 3"; "124" = "Refueling";
    "125" = "Low-alt Flight Time Attack 1"; "126" = "Low-alt Flight Time Attack 2"; "127" = "Low-alt Flight Time Attack 3"; "128" = "Low-alt Flight Time Attack 4"; 
    "130" = "Baloon Shooting 1"; "131" = "Baloon Shooting 2"; "132" = "Baloon Shooting 3"; "133" = "Baloon Shooting 4"; "134" = "Baloon Shooting 5";
    "135" = "Ground Shooting 1"; "136" = "Ground Shooting 2"; "137" = "Ground Shooting 3"; "138" = "Ground Shooting 4";
    "140" = "Acro Loop"; "141" = "Acro Skewed loop"; "142" = "Acro Aileron roll"; "143" = "Acro Barrel roll"; "144" = "Acro Knife edge";
    "145" = "Acro Tail slide"; "146" = "Acro Hammerhead"; "147" = "Acro Rolling combo"; "148" = "Acro Continuous Demo";
    "150" = "ACM vs F-86F"; "151" = "ACM vs F-4E"; "152" = "ACM vs F-5E"; "153" = "ACM vs F-16C"; "154" = "ACM vs F/A-18C"
    "155" = "ACM vs F-14B"; "156" = "ACM vs F-15C"; "157" = "ACM vs Mig-29S";
    "160" = "C-BFM vs F-4E"; "161" = "C-BFM vs F-5E"; "162" = "C-BFM vs F-16C"; "163" = "C-BFM vs F-14B"; "164" = "C-BFM vs F-15C";
    "165" = "C-BFM vs Su-27"; "168" = "C-BFM vs HAWK";
    "200" = "DACT 800-10-3"; "201" = "DACT 800-9-5"; "202" = "SCRAMBLE"
    

}

function Get-DB {
    if (Test-Path $script:dbFile) { 
        $content = Get-Content $script:dbFile -Raw -Encoding UTF8
        if (![string]::IsNullOrWhiteSpace($content)) { 
            $json = $content | ConvertFrom-Json
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

    # --- DACT_RESULT の処理 (追記部分) ---
    if ($line -match "\[DACT\]") {
        if ($line -match "ID:(?<id>.*?) \| Winner:(?<winner>.*?) \| Loser:(?<loser>.*?) \| Time:(?<time>.*?) \[END\]") {
            $mIdStr = $Matches['id'].Trim()
            $winner = $Matches['winner'].Trim()
            $loser  = $Matches['loser'].Trim()
            $pTime  = $Matches['time'].Trim()
            
            $mName = if ($missionMap.ContainsKey($mIdStr)) { $missionMap[$mIdStr] } else { "DACT Mission $mIdStr" }

            $dactPayload = @{ 
                embeds = @(@{ 
                    title = "DACT TRAINING COMPLETED"
                    color = 65280  # 緑色
                    fields = @(
                        @{ name = "Mission"; value = "``$mName``"; inline = $true },
                        @{ name = "Clear Time"; value = "``$pTime sec``"; inline = $true },
                        @{ name = "Winner"; value = "``$winner``"; inline = $false },
                        @{ name = "Loser"; value = "``$loser``"; inline = $false }
                    )
                    footer = @{ text = "Training Record - Results sent to Discord" } 
                }) 
            } | ConvertTo-Json -Depth 10 -Compress

            Invoke-RestMethod -Uri $webhookPersonal -Method Post -Body ([System.Text.Encoding]::UTF8.GetBytes($dactPayload)) -ContentType "application/json; charset=utf-8"
        }
        return
    }

    if ($line -match "\[BVR_RESULT\]") {
        if ($line -match "ID:(?<id>.*?) \| Time:(?<time>.*?) \| Pilots:(?<pilots>.*?) \[END\]") {
            $mIdStr = $Matches['id'].Trim(); $pTime = $Matches['time'].Trim(); $pNames = $Matches['pilots'].Trim()
            $bvrPayload = @{ embeds = @(@{ title = "BVR TRAINING COMPLETED"; color = 3447003; fields = @(@{ name = "Target Setup"; value = "``$mIdStr``"; inline = $true }, @{ name = "Clear Time"; value = "``$pTime sec``"; inline = $true }, @{ name = "Pilots"; value = "``$pNames``" }); footer = @{ text = "Training Record - Not reflected in rankings" } }) } | ConvertTo-Json -Depth 10 -Compress
            Invoke-RestMethod -Uri $webhookPersonal -Method Post -Body ([System.Text.Encoding]::UTF8.GetBytes($bvrPayload)) -ContentType "application/json; charset=utf-8"
        }
        return
    }


    if ($line -match "\[SCRAMBLE_RESULT\]") {
        if ($line -match "ID:(?<id>.*?) \| Time:(?<time>.*?) \| Pilots:(?<pilots>.*?) \[END\]") {
            $mIdStr = $Matches['id'].Trim(); $pTime = $Matches['time'].Trim(); $pNames = $Matches['pilots'].Trim()
            # "202(Su-27)" などを "SCRAMBLE(Su-27)" に置換
            $mName = if ($mIdStr -like "202*") { $mIdStr -replace "202", "SCRAMBLE" } else { "SCRAMBLE $mIdStr" }
            $scramblePayload = @{ embeds = @(@{ title = "SCRAMBLE MISSION COMPLETED"; color = 255; fields = @(@{ name = "Mission"; value = "``$mName``"; inline = $true }, @{ name = "Intercept Time"; value = "``$pTime sec``"; inline = $true }, @{ name = "Intercepting Pilots"; value = "``$pNames``" }); footer = @{ text = "JASDF Hamamatsu Alert - Training Record" } }) } | ConvertTo-Json -Depth 10 -Compress
            Invoke-RestMethod -Uri $webhookPersonal -Method Post -Body ([System.Text.Encoding]::UTF8.GetBytes($scramblePayload)) -ContentType "application/json; charset=utf-8"
        }
        return
    }




    if ($line -match "\[SD_RESULT\]") {
        if ($line -match "ID:(?<id>.*?) \| Kills:(?<kills>.*?) \[END\]") {
            $mIdStr = $Matches['id'].Trim(); $pKills = $Matches['kills'].Trim() -replace ":", " - "
            $sdPayload = @{ embeds = @(@{ title = "SEARCH & DESTROY COMPLETED"; color = 15105570; fields = @(@{ name = "Mission ID"; value = "``$mIdStr``"; inline = $true }, @{ name = "Final Kill Counts"; value = "``$pKills``" }); footer = @{ text = "Training Record - Results sent to Discord" } }) } | ConvertTo-Json -Depth 10 -Compress
            Invoke-RestMethod -Uri $webhookPersonal -Method Post -Body ([System.Text.Encoding]::UTF8.GetBytes($sdPayload)) -ContentType "application/json; charset=utf-8"
        }
        return 
    }

    if ($line -match "\[RANKING\]") { $buffer = $line }
    elseif ($buffer -ne "") { $buffer += $line }

    if ($buffer -match "\[END\]") {
        $data = ($buffer -replace ".*\[RANKING\]", "" -replace "\[END\].*", "" -replace "`n", "" -replace "`r", "")
        $parts = $data.Split("|")
        
        if ($parts.Count -ge 6) {
            $mId = ($parts[0] -replace "Mi:", "").Trim(); $pName = ($parts[1] -replace "Pi:", "").Trim()
            $acType = ($parts[2] -replace "AF:", "").Trim(); $score = [int]($parts[3] -replace "SC:", "").Trim()
            $time = [double]($parts[4] -replace "Ti:", "").Trim(); $rank = ($parts[5] -replace "Ra:", "").Trim()
            $mName = if ($missionMap.ContainsKey($mId)) { $missionMap[$mId] } else { "Mission $mId" }

            $pColor = if ($rank -like "*S*") { 16766720 } elseif ($rank -like "*A*") { 15548997 } else { 3447003 }
            $personalPayload = @{ embeds = @(@{ title = "NEW FLIGHT RECORD"; color = $pColor; fields = @(@{ name = "Mission"; value = $mName; inline = $true }, @{ name = "Pilot"; value = $pName; inline = $true }, @{ name = "Aircraft"; value = $acType; inline = $true }, @{ name = "Rank"; value = "**$rank**"; inline = $true }, @{ name = "Score"; value = "$score pts"; inline = $true }, @{ name = "Total Time"; value = "$time sec"; inline = $true }) }) } | ConvertTo-Json -Depth 10 -Compress
            Invoke-RestMethod -Uri $webhookPersonal -Method Post -Body ([System.Text.Encoding]::UTF8.GetBytes($personalPayload)) -ContentType "application/json; charset=utf-8"

            [array]$db = Get-DB
            $found = $false; $shouldUpdate = $false
            foreach ($item in $db) {
                if ($item.mId -eq $mId -and $item.pName -eq $pName -and $item.acType -eq $acType) {
                    $found = $true
                    $isBetter = if ($mId -eq "124") { ($score -gt $item.score -or ($score -eq $item.score -and $time -gt $item.time)) }
                                else { ($score -gt $item.score -or ($score -eq $item.score -and $time -lt $item.time)) }
                    if ($isBetter) { $item.score = $score; $item.time = $time; $item.rank = $rank; $shouldUpdate = $true }
                    break
                }
            }
            if (-not $found) { $db += [PSCustomObject]@{ mId=$mId; pName=$pName; acType=$acType; score=$score; time=$time; rank=$rank }; $shouldUpdate = $true }

            if ($shouldUpdate) {
                Save-DB $db
                $sort = if ($mId -eq "124") { @{Expression="score";Descending=$true}, @{Expression="time";Descending=$true} }
                        else { @{Expression="score";Descending=$true}, @{Expression="time";Ascending=$true} }
                $top5 = $db | Where-Object { $_.mId -eq $mId } | Sort-Object $sort | Select-Object -First 5
                $scoreBoard = ""; $idx = 1
                foreach ($entry in $top5) { $scoreBoard += "$idx. **$($entry.pName)** ($($entry.acType))`n   > Score: **$($entry.score)** | Time: **$($entry.time)**s | Rank: **$($entry.rank)**`n"; $idx++ }
                
                $rankingPayload = @{ embeds = @(@{ title = "$mName TOP 5 RANKING"; color = 16766720; description = $scoreBoard; footer = @{ text = "Ranking Updated!" } }) } | ConvertTo-Json -Depth 10 -Compress
                Invoke-RestMethod -Uri $webhookRanking -Method Post -Body ([System.Text.Encoding]::UTF8.GetBytes($rankingPayload)) -ContentType "application/json; charset=utf-8"
                
                # --- GitHub Update ---
                try {
                    $oldDir = Get-Location; Set-Location -Path 'D:\DCS_RANKING_SYS'
                    & git add index.html ranking_db.json logo.png bg.png
                    & git commit -m "Auto Update: $(Get-Date -Format 'yyyy/MM/dd HH:mm:ss')" --allow-empty
                    & git push origin main
                    Set-Location $oldDir
                } catch { Write-Host "Git Push Failed" -ForegroundColor Red }
            }
        }
        $buffer = ""
    }
}