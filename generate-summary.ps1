$vaultDir = "C:\Users\phili\Desktop\EDX GCSE Chemistry"
$outDir   = "C:\Users\phili\Desktop\EDX GCSE Chemistry Tiered Practice\Web\summary"
New-Item -ItemType Directory -Force -Path $outDir | Out-Null

$topicMap = @(
    @{id="T1"; prefix=@("1.1","1.2"); titleH="Atomic Structure &amp; the Periodic Table"},
    @{id="B";  prefix=@("1.3","1.4","1.5"); titleH="Bonding &amp; Types of Substance"},
    @{id="C";  prefix=@("1.6"); titleH="Calculations"},
    @{id="T2"; prefix=@("2."); titleH="States of Matter &amp; Mixtures"},
    @{id="T3"; prefix=@("3."); titleH="Chemical Changes"},
    @{id="T4"; prefix=@("4."); titleH="Extracting Metals &amp; Equilibria"},
    @{id="T5"; prefix=@("5."); titleH="Separate Chemistry 1"},
    @{id="T6"; prefix=@("6."); titleH="Groups in the Periodic Table"},
    @{id="T7"; prefix=@("7."); titleH="Rates of Reaction &amp; Energy Changes"},
    @{id="T8"; prefix=@("8."); titleH="Fuels &amp; Earth Science"},
    @{id="T9"; prefix=@("9."); titleH="Separate Chemistry 2"}
)

function Esc-HTML([string]$s) { $s=$s -replace '&','&amp;'; $s=$s -replace '<','&lt;'; $s=$s -replace '>','&gt;'; return $s }
function Inline-MD([string]$s) {
    $s = Esc-HTML $s
    $s = [regex]::Replace($s,'\[\[(?:[^\]|]+\|)?([^\]]+)\]\]','$1')
    $s = [regex]::Replace($s,'\*\*(.+?)\*\*','<strong>$1</strong>')
    $s = [regex]::Replace($s,'(?<!\*)\*(?!\*)(.+?)(?<!\*)\*(?!\*)','<em>$1</em>')
    $s = [regex]::Replace($s,'`([^`]+)`','<code>$1</code>')
    return $s
}

function Table-To-HTML([string[]]$lines) {
    $html = '<table>'
    $isHeader = $true
    foreach ($line in $lines) {
        if ($line -match '^[\|\s\-:]+$') { $isHeader=$false; continue }
        if (-not ($line -match '^\|')) { continue }
        $tag = if ($isHeader) { 'th' } else { 'td' }
        $cells = $line -split '\|' | Where-Object { $_ -ne '' }
        $html += '<tr>'
        foreach ($c in $cells) { $html += "<$tag>$(Inline-MD $c.Trim())</$tag>" }
        $html += '</tr>'
        if ($isHeader) { $isHeader=$false }
    }
    return $html + '</table>'
}

function List-To-HTML([string[]]$lines, [bool]$ordered) {
    $tag = if ($ordered) { 'ol' } else { 'ul' }
    $html = "<$tag>"
    foreach ($line in $lines) {
        if ($line -match '^\d+\.\s+(.+)$') { $html += "<li>$(Inline-MD $matches[1])</li>" }
        elseif ($line -match '^-\s+(.+)$')  { $html += "<li>$(Inline-MD $matches[1])</li>" }
    }
    return $html + "</$tag>"
}

function Parse-VaultFile([string]$path) {
    $raw = @(Get-Content $path -Encoding UTF8)
    $specNum=''; $specName=''; $tier=''
    if ($raw[0] -eq '---') {
        $end=1; while ($end -lt $raw.Count -and $raw[$end] -ne '---') { $end++ }
        for ($i=1;$i -lt $end;$i++) {
            if ($raw[$i] -match '^sp_number:\s*"?([^"]+)"?') { $specNum=$matches[1].Trim() }
            if ($raw[$i] -match '^sp_name:\s*"?([^"]+)"?')   { $specName=$matches[1].Trim() }
            if ($raw[$i] -match '^tier:\s*"?([^"]+)"?')       { $tier=$matches[1].Trim() }
        }
        $raw = $raw[($end+1)..($raw.Count-1)]
    }
    $sections=[System.Collections.Generic.Dictionary[string,System.Collections.ArrayList]]::new()
    $secOrder=[System.Collections.ArrayList]::new()
    $curSec='_intro'; $null=$secOrder.Add($curSec); $sections[$curSec]=[System.Collections.ArrayList]::new()
    foreach ($line in $raw) {
        if ($line -match '^##\s+(.+)$' -and $line -notmatch '^###') {
            $curSec=$matches[1].Trim()
            if (-not $sections.ContainsKey($curSec)) { $null=$secOrder.Add($curSec); $sections[$curSec]=[System.Collections.ArrayList]::new() }
        } else { $null=$sections[$curSec].Add($line) }
    }
    return @{specNum=$specNum;specName=$specName;tier=$tier;sections=$sections;secOrder=$secOrder}
}

function Extract-KeyDefs([System.Collections.ArrayList]$lines) {
    $tableLines = @($lines | Where-Object { $_ -match '^\|' })
    if ($tableLines.Count -eq 0) { return "" }
    return Table-To-HTML $tableLines
}

function Extract-Takeaways([System.Collections.ArrayList]$lines) {
    $listLines = @($lines | Where-Object { $_ -match '^\d+\.\s' -or $_ -match '^-\s' })
    if ($listLines.Count -eq 0) { return "" }
    $ordered = $listLines[0] -match '^\d+\.'
    return List-To-HTML $listLines $ordered
}

$CSS = @'
:root{--pr:#3f51b5;--pr-dk:#283593;--bg:#f4f6fb;--card:#fff;--tx:#1c1f3a;--txm:#6b7280;--bdr:#dde1f0;--r:10px;--sh:0 2px 8px rgba(63,81,181,.09);--acc:#eef1ff}
*{box-sizing:border-box;margin:0;padding:0}
body{font-family:'Segoe UI',system-ui,sans-serif;background:var(--bg);color:var(--tx);line-height:1.6;min-height:100vh}
.site-header{background:linear-gradient(135deg,var(--pr-dk),var(--pr));color:#fff;padding:1rem 1.5rem;display:flex;align-items:center;gap:.9rem;box-shadow:0 2px 8px rgba(0,0,0,.18)}
.site-header h1{font-size:1rem;font-weight:600;flex:1}
.back-link{color:rgba(255,255,255,.82);text-decoration:none;font-size:.84rem;white-space:nowrap;border:1px solid rgba(255,255,255,.35);padding:.25rem .7rem;border-radius:20px}
.back-link:hover{background:rgba(255,255,255,.15)}
.hero{background:linear-gradient(135deg,var(--pr-dk),var(--pr) 60%,#5c6bc0);color:#fff;padding:2.5rem 1.5rem 2rem;text-align:center}
.hero-icon{font-size:2.5rem;display:block;margin-bottom:.5rem}
.hero h1{font-size:1.8rem;font-weight:800;margin-bottom:.35rem}
.hero p{opacity:.88;font-size:.97rem;max-width:480px;margin:0 auto}
.topics-section{max-width:900px;margin:2rem auto 4rem;padding:0 1.2rem}
.topics-heading{font-size:.78rem;font-weight:700;text-transform:uppercase;letter-spacing:.08em;color:var(--txm);margin-bottom:1rem}
.topic-grid{display:grid;grid-template-columns:repeat(3,1fr);gap:.9rem}
.topic-card{background:var(--card);border-radius:var(--r);box-shadow:var(--sh);overflow:hidden;text-decoration:none;color:var(--tx);display:flex;flex-direction:column;transition:transform .18s,box-shadow .18s}
.topic-card:hover{transform:translateY(-3px);box-shadow:0 6px 24px rgba(63,81,181,.18)}
.tc-top{padding:1rem 1.2rem;flex:1}
.tc-num{display:inline-block;background:var(--pr);color:#fff;font-size:.7rem;font-weight:800;padding:.18rem .55rem;border-radius:6px;margin-bottom:.5rem}
.tc-name{font-weight:700;font-size:.92rem;line-height:1.4}
.tc-footer{background:var(--pr);color:#fff;padding:.5rem 1.2rem;font-size:.8rem;font-weight:600;display:flex;justify-content:space-between}
main{max-width:900px;margin:0 auto;padding:1.5rem 1rem 5rem}
.print-bar{display:flex;justify-content:flex-end;margin-bottom:1.2rem}
.print-btn{background:var(--pr);color:#fff;border:none;padding:.55rem 1.4rem;border-radius:8px;font-size:.9rem;font-weight:600;cursor:pointer}
.print-btn:hover{background:var(--pr-dk)}
.spec-block{background:var(--card);border-radius:var(--r);box-shadow:var(--sh);margin-bottom:1rem;padding:1.1rem 1.3rem}
.spec-tag{display:inline-flex;align-items:center;gap:.5rem;margin-bottom:.6rem}
.spec-num{background:var(--pr);color:#fff;font-size:.68rem;font-weight:800;padding:.15rem .5rem;border-radius:5px}
.spec-name{font-weight:700;font-size:.93rem}
.spec-tier{font-size:.72rem;color:var(--txm);margin-left:.3rem}
.defs-label,.kt-label{font-size:.72rem;font-weight:700;text-transform:uppercase;letter-spacing:.06em;color:var(--pr);margin:.7rem 0 .35rem}
table{width:100%;border-collapse:collapse;font-size:.84rem;margin-bottom:.6rem}
th{background:var(--pr);color:#fff;padding:.4rem .6rem;text-align:left;font-size:.8rem}
td{padding:.35rem .6rem;border-bottom:1px solid var(--bdr)}
tr:nth-child(even) td{background:var(--acc)}
ol,ul{margin:.2rem 0 .5rem 1.4rem;font-size:.84rem}
li{margin-bottom:.18rem}
strong{font-weight:700}em{font-style:italic}code{background:#f0f2ff;padding:.1rem .3rem;border-radius:3px;font-size:.8rem}
@media print{
  body{background:#fff;font-size:10pt}
  .site-header,.print-bar{display:none}
  .spec-block{box-shadow:none;border:1px solid #ccc;break-inside:avoid;margin-bottom:.6rem;padding:.7rem}
  th{background:#3f51b5!important;-webkit-print-color-adjust:exact;print-color-adjust:exact}
}
@media(max-width:700px){.topic-grid{grid-template-columns:repeat(2,1fr)}}
@media(max-width:480px){.topic-grid{grid-template-columns:1fr}}
'@

# ── landing page ───────────────────────────────────────────────────────────────
$allFiles = @(Get-ChildItem $vaultDir -Filter "*.md" | Where-Object { $_.Name -match '^\d' } | Sort-Object Name)
$cards = ""
foreach ($t in $topicMap) {
    $count = ($allFiles | Where-Object { $name=$_.Name; $t.prefix | Where-Object { $name -like "$_*" } }).Count
    $cards += @"
    <a href="$($t.id).html" class="topic-card">
      <div class="tc-top"><span class="tc-num">$($t.id)</span><div class="tc-name">$($t.titleH)</div></div>
      <div class="tc-footer"><span>$count spec points</span><span>Print &amp; revise &rarr;</span></div>
    </a>
"@
}

$landingHtml = @"
<!DOCTYPE html><html lang="en"><head><meta charset="UTF-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>Summary Sheets &mdash; GCSE Chemistry</title><style>$CSS</style></head><body>
<div class="hero"><span class="hero-icon">&#x1F4CB;</span><h1>Summary Sheets</h1><p>Key definitions and takeaways for every spec point &mdash; printable A4 revision sheets</p></div>
<div class="topics-section"><div class="topics-heading">Choose a topic</div>
<div class="topic-grid">$cards</div></div></body></html>
"@
$landingHtml | Out-File (Join-Path $outDir "index.html") -Encoding UTF8
Write-Host "Generated summary/index.html"

# ── summary pages ──────────────────────────────────────────────────────────────
foreach ($t in $topicMap) {
    $files = $allFiles | Where-Object { $name=$_.Name; $t.prefix | Where-Object { $name -like "$_*" } }
    $blocks = ""
    foreach ($f in $files) {
        $vf = Parse-VaultFile $f.FullName
        if (-not $vf.specNum) { continue }

        $defsHTML = ""; $ktHTML = ""
        foreach ($sec in $vf.secOrder) {
            $secLines = $vf.sections[$sec]
            if ($sec -match 'Key Def') { $defsHTML = Extract-KeyDefs $secLines }
            if ($sec -match 'Key Takeaway') { $ktHTML = Extract-Takeaways $secLines }
        }

        $inner = ""
        if ($defsHTML) { $inner += "<div class='defs-label'>Key Definitions</div>$defsHTML" }
        if ($ktHTML)   { $inner += "<div class='kt-label'>Key Takeaways</div>$ktHTML" }
        if (-not $inner) { continue }

        $blocks += @"
<div class="spec-block">
  <div class="spec-tag">
    <span class="spec-num">$($vf.specNum)</span>
    <span class="spec-name">$(Esc-HTML ($vf.specName))</span>
    <span class="spec-tier">$($vf.tier)</span>
  </div>
  $inner
</div>
"@
    }

    $pageHtml = @"
<!DOCTYPE html><html lang="en"><head><meta charset="UTF-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>$($t.titleH -replace '&amp;','&') &mdash; Summary</title><style>$CSS</style></head><body>
<header class="site-header">
  <a href="index.html" class="back-link">&larr; All Topics</a>
  <h1>$($t.titleH) &mdash; Summary Sheet</h1>
</header>
<main>
<div class="print-bar"><button class="print-btn" onclick="window.print()">&#x1F5A8; Print this sheet</button></div>
$blocks
</main></body></html>
"@
    $pageHtml | Out-File (Join-Path $outDir "$($t.id).html") -Encoding UTF8
    Write-Host "  Generated summary/$($t.id).html ($($files.Count) spec points)"
}
Write-Host "Summary sheets done."
