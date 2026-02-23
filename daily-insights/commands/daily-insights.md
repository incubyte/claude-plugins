---
description: Generate a daily AI usage insights report from Claude Code session data. Shows tokens, cost, sessions, projects and patterns. Args: today|yesterday|YYYY-MM-DD|7d
---

Generate a daily AI usage insights report. The argument passed is: `$ARGUMENTS`

## Step 1 — Detect platform

```bash
uname -s 2>/dev/null || echo Windows
```

## Step 2 — Collect data

**If Step 1 output contains `Darwin` or `Linux` (macOS / Linux / WSL):**

Requirements: `jq` (`brew install jq` / `apt install jq`). Works on bash 3.2+.

```bash
bash << 'EOF'
# ── Argument resolution ───────────────────────────────────
arg=$(printf '%s' "$ARGUMENTS" | tr '[:upper:]' '[:lower:]' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
today=$(date +%Y-%m-%d)

_ago() {  # macOS: date -v, Linux/WSL: date -d
  date -v"-${1}d" +%Y-%m-%d 2>/dev/null || date -d "${1} days ago" +%Y-%m-%d
}

target_dates=""; label=""
if [[ -z "$arg" || "$arg" == "today" ]]; then
  target_dates="$today"; label="Today ($today)"
elif [[ "$arg" == "yesterday" ]]; then
  d=$(_ago 1); target_dates="$d"; label="$d"
elif [[ "$arg" =~ ^([0-9]+)d$ ]]; then
  n="${BASH_REMATCH[1]}"
  for ((i=0; i<n; i++)); do target_dates="$target_dates $(_ago "$i")"; done
  target_dates="${target_dates# }"
  label="Last $n days (${target_dates##* } to ${target_dates%% *})"
elif [[ "$arg" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]]; then
  target_dates="$arg"; label="$arg"
else
  target_dates="$today"; label="Today ($today)"
fi

DATES_JSON=$(printf '%s\n' $target_dates | jq -Rsc '[split("\n")[] | select(length>0)]')

CLAUDE="$HOME/.claude"
CACHE="$CLAUDE/stats-cache.json"
PROJECTS="$CLAUDE/projects"

# ── Stats cache — single jq call, awk for aggregation ─────
cache_out=""
if [[ -f "$CACHE" ]]; then
  cache_out=$(jq -r --argjson d "$DATES_JSON" '
    (.dailyActivity // []    | [.[] | select(.date as $x | $d | index($x) != null)]) as $acts |
    (.dailyModelTokens // [] | [.[] | select(.date as $x | $d | index($x) != null)]) as $dtok |
    (.hourCounts // {} | to_entries | sort_by(-.value) | .[:3] | map(.key+":00") | join(", ")) as $peak |
    "META\tSESSIONS\t"+($acts | map(.sessionCount//0)  | add // 0 | tostring),
    "META\tMESSAGES\t"+($acts | map(.messageCount//0)  | add // 0 | tostring),
    "META\tTOOLS\t"+   ($acts | map(.toolCallCount//0) | add // 0 | tostring),
    "META\tPEAK\t"+$peak,
    ($dtok[] | .tokensByModel | to_entries[] | "MODEL\t"+.key+"\t"+(.value|tostring)),
    ($acts[]  | "DAY\t"+.date+"\t"+(.sessionCount//0|tostring)+"\t"+(.messageCount//0|tostring)+"\t"+(.toolCallCount//0|tostring))
  ' "$CACHE" 2>/dev/null)
fi

TOT_SESS=$(printf '%s\n'  "$cache_out" | awk -F'\t' '$2=="SESSIONS"{print $3}')
TOT_MSGS=$(printf '%s\n'  "$cache_out" | awk -F'\t' '$2=="MESSAGES"{print $3}')
TOT_TOOLS=$(printf '%s\n' "$cache_out" | awk -F'\t' '$2=="TOOLS"{print $3}')
PEAK=$(printf '%s\n'      "$cache_out" | awk -F'\t' '$2=="PEAK"{print $3}')
TOT_SESS="${TOT_SESS:-0}"; TOT_MSGS="${TOT_MSGS:-0}"; TOT_TOOLS="${TOT_TOOLS:-0}"

model_agg=$(printf '%s\n' "$cache_out" | awk -F'\t' '
  $1=="MODEL" { tok[$2]+=$3; total+=$3 }
  END {
    pi["claude-opus-4-6"]=5;    pi["claude-opus-4-5-20251101"]=5
    pi["claude-sonnet-4-6"]=3;  pi["claude-sonnet-4-5-20250929"]=3; pi["claude-haiku-4-5"]=1
    po["claude-opus-4-6"]=25;   po["claude-opus-4-5-20251101"]=25
    po["claude-sonnet-4-6"]=15; po["claude-sonnet-4-5-20250929"]=15; po["claude-haiku-4-5"]=5
    names["claude-opus-4-6"]="Opus 4.6"; names["claude-opus-4-5-20251101"]="Opus 4.5"
    names["claude-sonnet-4-6"]="Sonnet 4.6"; names["claude-sonnet-4-5-20250929"]="Sonnet 4.5"
    names["claude-haiku-4-5"]="Haiku 4.5"
    cost=0; mstr=""
    for (m in tok) {
      p=(m in pi)?pi[m]:3; q=(m in po)?po[m]:15
      cost+=(tok[m]*0.8/1e6)*p+(tok[m]*0.2/1e6)*q
      n=(m in names)?names[m]:m
      mstr=mstr (mstr?"; ":"") n": "tok[m]" tokens"
    }
    printf "TOT_CTOK\t%d\nTOTAL_COST\t%.6f\nMODELS_STR\t%s\n", total, cost, mstr
  }')

TOT_CTOK=$(printf '%s\n'   "$model_agg" | awk -F'\t' '$1=="TOT_CTOK"{print $2}')
TOTAL_COST=$(printf '%s\n' "$model_agg" | awk -F'\t' '$1=="TOTAL_COST"{print $2}')
MODELS_STR=$(printf '%s\n' "$model_agg" | awk -F'\t' '$1=="MODELS_STR"{print $2}')
TOT_CTOK="${TOT_CTOK:-0}"; TOTAL_COST="${TOTAL_COST:-0.000000}"

# ── JSONL sessions ────────────────────────────────────────
session_rows=""
# Compute once outside the loop
home_prefix=$(printf '%s' "$HOME" | sed 's|^/||; s|/|-|g')
for proj_dir in "$PROJECTS"/*/; do
  [[ -d "$proj_dir" ]] || continue
  dname=$(basename "$proj_dir"); dname="${dname#-}"
  # Strip home dir prefix (e.g. "Users-alice-" or "home-alice-") to get relative path
  pname="${dname#${home_prefix}-}"
  # Fallback: if stripping produced nothing or had no effect, use last 2 dash-parts
  if [[ -z "$pname" || "$pname" == "$dname" ]]; then
    pname=$(echo "$dname" | awk -F'-' '{if(NF>=2) print $(NF-1)"-"$NF; else print $0}')
  fi
  for jf in "$proj_dir"*.jsonl; do
    [[ -f "$jf" ]] || continue
    row=$(jq -rs --argjson dates "$DATES_JSON" '
      [.[] | select(.timestamp?) |
        (.timestamp | split("T")[0]) as $ds |
        select($dates | index($ds) != null) |
        select(.type == "assistant")
      ] |
      if length == 0 then empty else . as $rows |
      ($rows | map(.message.usage.input_tokens            // 0) | add // 0) as $i  |
      ($rows | map(.message.usage.output_tokens           // 0) | add // 0) as $o  |
      ($rows | map(.message.usage.cache_read_input_tokens // 0) | add // 0) as $cr |
      ($rows | map([.message.content[]? | select(.type=="tool_use")] | length) | add // 0) as $t |
      ($rows | length) as $msgs |
      (
        $rows | map(
          .timestamp | split("T")[1] | split(":") |
          ((.[0]|tonumber)*3600) + ((.[1]|tonumber)*60) +
          (.[2] | gsub("[^0-9.]";"") | if length>0 then tonumber|floor else 0 end)
        ) |
        if length > 1 then ((max - min) / 60 | if .<1 then 1 else . | round end) else 1 end
      ) as $dur |
      [$i,$o,$cr,$t,$msgs,$dur] | @tsv
      end
    ' "$jf" 2>/dev/null) || continue
    [[ -z "$row" ]] && continue
    session_rows="$session_rows
$pname	$row"
  done
done

agg=$(printf '%s\n' "$session_rows" | awk -F'\t' '
  NF==7 {
    p=$1; i=$2; o=$3; cr=$4; t=$5; m=$6; d=$7
    psess[p]++; pin[p]+=i; pout[p]+=o; ptools[p]+=t; pdur[p]+=d
    tot_in+=i; tot_out+=o; tot_cr+=cr; tot_tools+=t; tot_msgs+=m; tot_sess++
    skey[NR]=p; sdur[NR]=d; smsgs[NR]=m; stools[NR]=t; sinp[NR]=i; sout[NR]=o
  }
  END {
    printf "JSONL_IN\t%d\nJSONL_OUT\t%d\nCACHE_READS\t%d\n", tot_in, tot_out, tot_cr
    printf "JSONL_TOOLS\t%d\nJSONL_MSGS\t%d\nJSONL_SESS\t%d\n", tot_tools, tot_msgs, tot_sess
    for (p in psess)
      printf "PROJ\t%s\t%d\t%d\t%d\t%d\t%d\n", p, psess[p], pin[p], pout[p], ptools[p], pdur[p]
    for (r in skey)
      printf "SESS\t%s\t%d\t%d\t%d\t%d\t%d\n", skey[r], sdur[r], smsgs[r], stools[r], sinp[r], sout[r]
  }')

JSONL_IN=$(printf '%s\n' "$agg"    | awk -F'\t' '$1=="JSONL_IN"{print $2}')
JSONL_OUT=$(printf '%s\n' "$agg"   | awk -F'\t' '$1=="JSONL_OUT"{print $2}')
CACHE_READS=$(printf '%s\n' "$agg" | awk -F'\t' '$1=="CACHE_READS"{print $2}')
JSONL_TOOLS=$(printf '%s\n' "$agg" | awk -F'\t' '$1=="JSONL_TOOLS"{print $2}')
JSONL_MSGS=$(printf '%s\n' "$agg"  | awk -F'\t' '$1=="JSONL_MSGS"{print $2}')
JSONL_SESS=$(printf '%s\n' "$agg"  | awk -F'\t' '$1=="JSONL_SESS"{print $2}')
JSONL_IN="${JSONL_IN:-0}"; JSONL_OUT="${JSONL_OUT:-0}"; CACHE_READS="${CACHE_READS:-0}"
JSONL_TOOLS="${JSONL_TOOLS:-0}"; JSONL_MSGS="${JSONL_MSGS:-0}"; JSONL_SESS="${JSONL_SESS:-0}"

if [[ "${TOT_CTOK:-0}" -eq 0 && "${JSONL_SESS:-0}" -gt 0 ]]; then
  TOTAL_COST=$(awk -v i="$JSONL_IN" -v o="$JSONL_OUT" 'BEGIN{printf "%.6f",(i/1e6)*3+(o/1e6)*15}')
fi
[[ "${TOT_SESS:-0}"  -eq 0 ]] && TOT_SESS="$JSONL_SESS"
[[ "${TOT_MSGS:-0}"  -eq 0 ]] && TOT_MSGS="$JSONL_MSGS"
[[ "${TOT_TOOLS:-0}" -eq 0 ]] && TOT_TOOLS="$JSONL_TOOLS"

printf 'LABEL: %s\n'        "$label"
printf 'SESSIONS: %s\n'     "$TOT_SESS"
printf 'MESSAGES: %s\n'     "$TOT_MSGS"
printf 'TOOL_CALLS: %s\n'   "$TOT_TOOLS"
printf 'CACHE_TOKENS: %s\n' "${TOT_CTOK:-0}"
printf 'JSONL_INPUT: %s  JSONL_OUTPUT: %s\n' "$JSONL_IN" "$JSONL_OUT"
printf 'CACHE_READS: %s (saves ~90%% on those tokens)\n' "$CACHE_READS"
printf 'EST_COST: $%s\n'    "$TOTAL_COST"
printf 'PEAK_HOURS: %s\n'   "${PEAK:-N/A}"
printf 'MODELS: %s\n'       "${MODELS_STR:-N/A}"
echo ""
echo "DAILY BREAKDOWN:"
printf '%s\n' "$cache_out" | awk -F'\t' \
  '$1=="DAY"{printf "  %s: %s sessions | %s messages | %s tools\n",$2,$3,$4,$5}'
echo ""
echo "PROJECTS:"
printf '%s\n' "$agg" | awk -F'\t' \
  '$1=="PROJ"{printf "  %s: %s sessions | %s in / %s out | %s tools | ~%sm active\n",$2,$3,$4,$5,$6,$7}'
echo ""
echo "SESSIONS:"
printf '%s\n' "$agg" | awk -F'\t' \
  '$1=="SESS"{printf "  [%s] %sm | %s responses | %s tools | %s in / %s out\n",$2,$3,$4,$5,$6,$7}'
EOF
```

---

**If Step 1 output is `Windows` (native Windows, no WSL):**

No extra dependencies — uses built-in PowerShell 5.1+.

```powershell
$arg = "$ARGUMENTS".Trim().ToLower()
$today = Get-Date -Format "yyyy-MM-dd"

# ── Date resolution ───────────────────────────────────────
$targetDates = @(); $label = ""
if ($arg -eq "" -or $arg -eq "today") {
    $targetDates = @($today); $label = "Today ($today)"
} elseif ($arg -eq "yesterday") {
    $d = (Get-Date).AddDays(-1).ToString("yyyy-MM-dd")
    $targetDates = @($d); $label = $d
} elseif ($arg -match "^(\d+)d$") {
    $n = [int]$Matches[1]
    $targetDates = 0..($n-1) | ForEach-Object { (Get-Date).AddDays(-$_).ToString("yyyy-MM-dd") }
    $label = "Last $n days ($($targetDates[-1]) to $($targetDates[0]))"
} elseif ($arg -match "^\d{4}-\d{2}-\d{2}$") {
    $targetDates = @($arg); $label = $arg
} else {
    $targetDates = @($today); $label = "Today ($today)"
}

$claudeDir   = "$env:USERPROFILE\.claude"
$cacheFile   = "$claudeDir\stats-cache.json"
$projectsDir = "$claudeDir\projects"

$MODEL_PI    = @{ "claude-opus-4-6"=5; "claude-opus-4-5-20251101"=5; "claude-sonnet-4-6"=3; "claude-sonnet-4-5-20250929"=3; "claude-haiku-4-5"=1 }
$MODEL_PO    = @{ "claude-opus-4-6"=25;"claude-opus-4-5-20251101"=25;"claude-sonnet-4-6"=15;"claude-sonnet-4-5-20250929"=15;"claude-haiku-4-5"=5 }
$MODEL_NAMES = @{ "claude-opus-4-6"="Opus 4.6";"claude-opus-4-5-20251101"="Opus 4.5";"claude-sonnet-4-6"="Sonnet 4.6";"claude-sonnet-4-5-20250929"="Sonnet 4.5";"claude-haiku-4-5"="Haiku 4.5" }

# ── Stats cache ───────────────────────────────────────────
$totSess=0; $totMsgs=0; $totTools=0; $totCTok=0; $totalCost=0.0
$modelTokens = @{}; $peak = "N/A"

if (Test-Path $cacheFile) {
    $cache = Get-Content $cacheFile -Raw | ConvertFrom-Json

    foreach ($act in $cache.dailyActivity) {
        if ($targetDates -contains $act.date) {
            $totSess  += [int]($act.sessionCount)
            $totMsgs  += [int]($act.messageCount)
            $totTools += [int]($act.toolCallCount)
        }
    }
    foreach ($entry in $cache.dailyModelTokens) {
        if ($targetDates -contains $entry.date) {
            $entry.tokensByModel.PSObject.Properties | ForEach-Object {
                $m = $_.Name; $t = [int]$_.Value
                if (-not $modelTokens.ContainsKey($m)) { $modelTokens[$m] = 0 }
                $modelTokens[$m] += $t; $totCTok += $t
            }
        }
    }
    if ($cache.hourCounts) {
        $peakList = $cache.hourCounts.PSObject.Properties |
            Sort-Object { [int]$_.Value } -Descending | Select-Object -First 3 |
            ForEach-Object { "$($_.Name):00" }
        $peak = $peakList -join ", "
    }
}

foreach ($m in $modelTokens.Keys) {
    $t  = $modelTokens[$m]
    $pi = if ($MODEL_PI.ContainsKey($m))  { $MODEL_PI[$m]  } else { 3  }
    $po = if ($MODEL_PO.ContainsKey($m))  { $MODEL_PO[$m]  } else { 15 }
    $totalCost += ($t * 0.8 / 1e6) * $pi + ($t * 0.2 / 1e6) * $po
}
$modelsStr = ($modelTokens.Keys | ForEach-Object {
    $n = if ($MODEL_NAMES.ContainsKey($_)) { $MODEL_NAMES[$_] } else { $_ }
    "$n`: $($modelTokens[$_]) tokens"
}) -join "; "

# ── JSONL sessions ────────────────────────────────────────
$jsonlIn=0; $jsonlOut=0; $cacheReads=0; $jsonlTools=0; $jsonlMsgs=0
$projData = @{}; $sessionLines = @()

foreach ($projDir in Get-ChildItem $projectsDir -Directory -ErrorAction SilentlyContinue) {
    $dname = $projDir.Name.TrimStart('-')
    # Strip home dir prefix (e.g. "Users-alice-" or "C:-Users-alice-") to get relative path
    $homePrefix = ($env:USERPROFILE -replace '[/\\:]', '-').TrimStart('-')
    $pname = $dname -replace "^$([regex]::Escape($homePrefix))-?", ""
    # Fallback: if nothing was stripped, use last 2 dash-parts
    if (-not $pname -or $pname -eq $dname) {
        $parts = $dname.Split('-')
        $pname = if ($parts.Count -ge 2) { "$($parts[-2])-$($parts[-1])" } else { $dname }
    }

    foreach ($jf in Get-ChildItem $projDir.FullName -Filter "*.jsonl" -ErrorAction SilentlyContinue) {
        $msgs = Get-Content $jf.FullName -ErrorAction SilentlyContinue | ForEach-Object {
            try { $_ | ConvertFrom-Json -ErrorAction Stop } catch { $null }
        } | Where-Object {
            $_ -and $_.timestamp -and $_.type -eq "assistant" -and
            ($targetDates -contains $_.timestamp.Substring(0, 10))
        }
        if (-not $msgs -or @($msgs).Count -eq 0) { continue }

        $sIn=0; $sOut=0; $sCr=0; $sTools=0; $sMsgs=0; $times=@()
        foreach ($msg in @($msgs)) {
            $u = $msg.message.usage
            $sIn    += [int]($u.input_tokens)
            $sOut   += [int]($u.output_tokens)
            $sCr    += [int]($u.cache_read_input_tokens)
            $sMsgs++
            $tp = ($msg.timestamp.Split('T')[1] -replace '\.\d+.*$','').Split(':')
            $times += [int]$tp[0]*3600 + [int]$tp[1]*60 + $(if ($tp.Count -ge 3) { [int]$tp[2] } else { 0 })
            foreach ($b in @($msg.message.content)) {
                if ($b -and $b.type -eq "tool_use") { $sTools++ }
            }
        }
        $maxT = ($times | Measure-Object -Maximum).Maximum
        $minT = ($times | Measure-Object -Minimum).Minimum
        $dur  = if ($times.Count -gt 1) { [Math]::Max(1, [Math]::Round(($maxT - $minT) / 60)) } else { 1 }

        $jsonlIn += $sIn; $jsonlOut += $sOut; $cacheReads += $sCr
        $jsonlTools += $sTools; $jsonlMsgs += $sMsgs

        if (-not $projData.ContainsKey($pname)) { $projData[$pname] = @{sess=0;inp=0;out=0;tools=0;dur=0} }
        $projData[$pname].sess++; $projData[$pname].inp+=$sIn
        $projData[$pname].out+=$sOut; $projData[$pname].tools+=$sTools; $projData[$pname].dur+=$dur
        $sessionLines += [PSCustomObject]@{p=$pname;dur=$dur;msgs=$sMsgs;tools=$sTools;inp=$sIn;out=$sOut}
    }
}

if ($totCTok -eq 0 -and $sessionLines.Count -gt 0) {
    $totalCost = ($jsonlIn / 1e6) * 3 + ($jsonlOut / 1e6) * 15
}
if ($totSess  -eq 0) { $totSess  = $sessionLines.Count }
if ($totMsgs  -eq 0) { $totMsgs  = $jsonlMsgs }
if ($totTools -eq 0) { $totTools = $jsonlTools }

# ── Output ────────────────────────────────────────────────
Write-Output "LABEL: $label"
Write-Output "SESSIONS: $totSess"
Write-Output "MESSAGES: $totMsgs"
Write-Output "TOOL_CALLS: $totTools"
Write-Output "CACHE_TOKENS: $totCTok"
Write-Output "JSONL_INPUT: $jsonlIn  JSONL_OUTPUT: $jsonlOut"
Write-Output "CACHE_READS: $cacheReads (saves ~90% on those tokens)"
Write-Output ("EST_COST: `${0:F6}" -f $totalCost)
Write-Output "PEAK_HOURS: $peak"
Write-Output "MODELS: $modelsStr"
Write-Output ""
Write-Output "DAILY BREAKDOWN:"
if (Test-Path $cacheFile) {
    $cache2 = Get-Content $cacheFile -Raw | ConvertFrom-Json
    foreach ($ds in $targetDates) {
        $act = $cache2.dailyActivity | Where-Object { $_.date -eq $ds }
        $tok = [int]($cache2.dailyModelTokens | Where-Object { $_.date -eq $ds } | ForEach-Object {
            $_.tokensByModel.PSObject.Properties | ForEach-Object { [int]$_.Value }
        } | Measure-Object -Sum).Sum
        if ($act) { Write-Output "  $ds`: $($act.sessionCount) sessions | $tok tokens | $($act.messageCount) messages | $($act.toolCallCount) tools" }
    }
}
Write-Output ""
Write-Output "PROJECTS:"
foreach ($p in $projData.Keys) {
    $d = $projData[$p]
    Write-Output "  $p`: $($d.sess) sessions | $($d.inp) in / $($d.out) out | $($d.tools) tools | ~$($d.dur)m active"
}
Write-Output ""
Write-Output "SESSIONS:"
foreach ($s in $sessionLines) {
    Write-Output "  [$($s.p)] $($s.dur)m | $($s.msgs) responses | $($s.tools) tools | $($s.inp) in / $($s.out) out"
}
```

## Step 3 — Write the insights report

Using the data collected above, write a clean insights report in this exact format:

---
## AI Usage Insights — {label from LABEL line}

### Summary
2-3 sentences covering total activity, standout stats, and overall AI usage intensity.

### Metrics
| Metric | Value |
|--------|-------|
| Sessions | |
| Messages (AI responses) | |
| Tool Calls | |
| Tokens | |
| Input / Output | |
| Cache Reads | (mention % saved) |
| Estimated Cost | $ |
| Peak Hours | |

### Projects
For each project listed: one line on what was done, token spend, tool call intensity.

### Patterns & Observations
- 2-4 bullet points with specific observations:
  - Cache efficiency (cache reads vs fresh input)
  - Tool-to-message ratio (high = complex tasks)
  - Session length patterns
  - Cost trends (if multi-day)

### Cost Breakdown
- Cost per model
- Cache savings estimate: cache reads × 90% × input price
- Daily rate if continued for a month

---

Use the exact numbers from the data. Be concise and analytical. Under 450 words.
