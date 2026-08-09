$vaultDir = "C:\Users\phili\Desktop\EDX GCSE Chemistry"
$outDir   = "C:\Users\phili\Desktop\EDX GCSE Chemistry Tiered Practice\Web\notes"
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

# ── markdown helpers ───────────────────────────────────────────────────────────

function Esc-HTML([string]$s) {
    $s = $s -replace '&', '&amp;'
    $s = $s -replace '<', '&lt;'
    $s = $s -replace '>', '&gt;'
    return $s
}

function Inline-MD([string]$s) {
    $s = Esc-HTML $s
    $s = [regex]::Replace($s, '\[\[(?:[^\]|]+\|)?([^\]]+)\]\]', '$1')
    $s = [regex]::Replace($s, '\*\*(.+?)\*\*', '<strong>$1</strong>')
    $s = [regex]::Replace($s, '(?<!\*)\*(?!\*)(.+?)(?<!\*)\*(?!\*)', '<em>$1</em>')
    $s = [regex]::Replace($s, '`([^`]+)`', '<code>$1</code>')
    return $s
}

function Lines-To-HTML([string[]]$lines) {
    $html = [System.Text.StringBuilder]::new()
    $i = 0
    while ($i -lt $lines.Count) {
        $line = $lines[$i]
        # skip empty
        if (-not $line.Trim()) { $i++; continue }
        # h3/h4
        if ($line -match '^####\s+(.+)$') { $null=$html.Append("<h4>$(Inline-MD $matches[1])</h4>"); $i++; continue }
        if ($line -match '^###\s+(.+)$')  { $null=$html.Append("<h3>$(Inline-MD $matches[1])</h3>"); $i++; continue }
        # table
        if ($line -match '^\|') {
            $null=$html.Append('<table>')
            $isHeader = $true
            while ($i -lt $lines.Count -and $lines[$i] -match '^\|') {
                if ($lines[$i] -match '^[\|\s\-:]+$') { $isHeader=$false; $i++; continue }
                $tag = if ($isHeader) { 'th' } else { 'td' }
                $cells = $lines[$i] -split '\|' | Where-Object { $_ -ne '' }
                $null=$html.Append('<tr>')
                foreach ($cell in $cells) {
                    $null=$html.Append("<$tag>$(Inline-MD $cell.Trim())</$tag>")
                }
                $null=$html.Append('</tr>')
                if ($isHeader) { $isHeader=$false }
                $i++
            }
            $null=$html.Append('</table>')
            continue
        }
        # ordered list
        if ($line -match '^\d+\.\s+(.+)$') {
            $null=$html.Append('<ol>')
            while ($i -lt $lines.Count -and $lines[$i] -match '^\d+\.\s+(.+)$') {
                $null=$html.Append("<li>$(Inline-MD $matches[1])</li>"); $i++
            }
            $null=$html.Append('</ol>'); continue
        }
        # unordered list
        if ($line -match '^-\s+(.+)$') {
            $null=$html.Append('<ul>')
            while ($i -lt $lines.Count -and $lines[$i] -match '^-\s+(.+)$') {
                $null=$html.Append("<li>$(Inline-MD $matches[1])</li>"); $i++
            }
            $null=$html.Append('</ul>'); continue
        }
        # blockquote / italic intro line
        if ($line -match '^\*(.+)\*$') { $null=$html.Append("<p class='intro'><em>$(Esc-HTML ($matches[1]))</em></p>"); $i++; continue }
        # paragraph
        $para = $line.Trim()
        $i++
        while ($i -lt $lines.Count -and $lines[$i].Trim() -and
               $lines[$i] -notmatch '^#+\s' -and $lines[$i] -notmatch '^\|' -and
               $lines[$i] -notmatch '^\d+\.\s' -and $lines[$i] -notmatch '^-\s') {
            $para += ' ' + $lines[$i].Trim(); $i++
        }
        $null=$html.Append("<p>$(Inline-MD $para)</p>")
    }
    return $html.ToString()
}

function Parse-VaultFile([string]$path) {
    $raw = @(Get-Content $path -Encoding UTF8)
    $specNum=''; $specName=''; $tier=''
    # parse YAML
    if ($raw[0] -eq '---') {
        $end=1; while ($end -lt $raw.Count -and $raw[$end] -ne '---') { $end++ }
        for ($i=1; $i -lt $end; $i++) {
            if ($raw[$i] -match '^sp_number:\s*"?([^"]+)"?') { $specNum=$matches[1].Trim() }
            if ($raw[$i] -match '^sp_name:\s*"?([^"]+)"?')   { $specName=$matches[1].Trim() }
            if ($raw[$i] -match '^tier:\s*"?([^"]+)"?')       { $tier=$matches[1].Trim() }
        }
        $raw = $raw[($end+1)..($raw.Count-1)]
    }
    # split into sections by ## header
    $sections = [System.Collections.Generic.Dictionary[string,System.Collections.ArrayList]]::new()
    $secOrder = [System.Collections.ArrayList]::new()
    $curSec = '_intro'; $null=$secOrder.Add($curSec); $sections[$curSec]=[System.Collections.ArrayList]::new()
    foreach ($line in $raw) {
        if ($line -match '^##\s+(.+)$' -and $line -notmatch '^###') {
            $curSec = $matches[1].Trim()
            if (-not $sections.ContainsKey($curSec)) { $null=$secOrder.Add($curSec); $sections[$curSec]=[System.Collections.ArrayList]::new() }
        } else {
            $null=$sections[$curSec].Add($line)
        }
    }
    return @{specNum=$specNum; specName=$specName; tier=$tier; sections=$sections; secOrder=$secOrder}
}

$CSS = @'
:root{--pr:#3f51b5;--pr-dk:#283593;--bg:#f4f6fb;--card:#fff;--tx:#1c1f3a;--txm:#6b7280;--bdr:#dde1f0;--r:12px;--sh:0 2px 10px rgba(63,81,181,.09);--sh2:0 6px 24px rgba(63,81,181,.16);--acc:#eef1ff}
*{box-sizing:border-box;margin:0;padding:0}
body{font-family:'Segoe UI',system-ui,sans-serif;background:var(--bg);color:var(--tx);line-height:1.7;min-height:100vh}
.site-header{background:linear-gradient(135deg,var(--pr-dk),var(--pr));color:#fff;padding:1rem 1.5rem;display:flex;align-items:center;gap:.9rem;box-shadow:0 2px 8px rgba(0,0,0,.18)}
.site-header h1{font-size:1rem;font-weight:600;flex:1}
.back-link{color:rgba(255,255,255,.82);text-decoration:none;font-size:.84rem;white-space:nowrap;border:1px solid rgba(255,255,255,.35);padding:.25rem .7rem;border-radius:20px;transition:background .15s}
.back-link:hover{background:rgba(255,255,255,.15)}
.hero{background:linear-gradient(135deg,var(--pr-dk),var(--pr) 60%,#5c6bc0);color:#fff;padding:2.5rem 1.5rem 2rem;text-align:center}
.hero-icon{font-size:2.5rem;display:block;margin-bottom:.5rem}
.hero h1{font-size:1.8rem;font-weight:800;margin-bottom:.35rem}
.hero p{opacity:.88;font-size:.97rem;max-width:460px;margin:0 auto}
.topics-section{max-width:900px;margin:2rem auto 4rem;padding:0 1.2rem}
.topics-heading{font-size:.78rem;font-weight:700;text-transform:uppercase;letter-spacing:.08em;color:var(--txm);margin-bottom:1rem}
.topic-grid{display:grid;grid-template-columns:repeat(3,1fr);gap:.9rem}
.topic-card{background:var(--card);border-radius:var(--r);box-shadow:var(--sh);overflow:hidden;text-decoration:none;color:var(--tx);display:flex;flex-direction:column;transition:transform .18s,box-shadow .18s}
.topic-card:hover{transform:translateY(-3px);box-shadow:var(--sh2)}
.tc-top{padding:1.1rem 1.2rem;flex:1}
.tc-num{display:inline-block;background:var(--pr);color:#fff;font-size:.7rem;font-weight:800;padding:.18rem .55rem;border-radius:6px;margin-bottom:.5rem}
.tc-name{font-weight:700;font-size:.92rem;line-height:1.4;color:var(--tx)}
.tc-count{font-size:.76rem;color:var(--txm);margin-top:.3rem}
.tc-footer{background:var(--pr);color:#fff;padding:.5rem 1.2rem;font-size:.8rem;font-weight:600}
main{max-width:860px;margin:0 auto;padding:1.5rem 1rem 5rem}
.spec-card{background:var(--card);border-radius:var(--r);box-shadow:var(--sh);margin-bottom:1.2rem;overflow:hidden}
.spec-header{display:flex;align-items:center;gap:.8rem;padding:.9rem 1.2rem;cursor:pointer;user-select:none;border-bottom:2px solid transparent;transition:border-color .15s}
.spec-header:hover{border-bottom-color:var(--bdr)}
.spec-header.open{border-bottom:2px solid var(--bdr)}
.spec-num{background:var(--pr);color:#fff;font-size:.7rem;font-weight:800;padding:.2rem .55rem;border-radius:6px;white-space:nowrap}
.spec-name{font-weight:700;font-size:.97rem;flex:1}
.spec-tier{font-size:.72rem;color:var(--txm);white-space:nowrap}
.spec-arrow{font-size:.8rem;color:var(--txm);transition:transform .25s}
.spec-header.open .spec-arrow{transform:rotate(180deg)}
.spec-body{display:none;padding:1.2rem 1.4rem 1.4rem}
.spec-body.open{display:block}
.spec-body p{margin-bottom:.75rem;font-size:.92rem}
.spec-body p.intro{color:var(--txm);font-style:italic}
.spec-body h3{font-size:.95rem;color:var(--pr);margin:1.1rem 0 .5rem;font-weight:700}
.spec-body h4{font-size:.88rem;color:var(--tx);margin:.9rem 0 .4rem;font-weight:700}
.spec-body ul,.spec-body ol{margin:.3rem 0 .75rem 1.5rem;font-size:.91rem}
.spec-body li{margin-bottom:.25rem}
.spec-body table{width:100%;border-collapse:collapse;font-size:.88rem;margin:.5rem 0 .9rem}
.spec-body th{background:var(--pr);color:#fff;padding:.45rem .7rem;text-align:left;font-weight:700}
.spec-body td{padding:.4rem .7rem;border-bottom:1px solid var(--bdr)}
.spec-body tr:nth-child(even) td{background:var(--acc)}
.spec-body code{background:#f0f2ff;padding:.1rem .35rem;border-radius:4px;font-size:.85rem;font-family:monospace}
.pitfall-box{background:#fff8e1;border-left:4px solid #f9a825;border-radius:0 8px 8px 0;padding:.7rem 1rem;margin:.5rem 0 .75rem;font-size:.88rem}
.takeaway-box{background:var(--acc);border-left:4px solid var(--pr);border-radius:0 8px 8px 0;padding:.7rem 1rem;margin:.5rem 0}
.takeaway-box ol{margin-left:1.2rem}
.takeaway-box li{font-size:.88rem;margin-bottom:.2rem}
@media(max-width:700px){.topic-grid{grid-template-columns:repeat(2,1fr)}}
@media(max-width:480px){.topic-grid{grid-template-columns:1fr}.hero h1{font-size:1.4rem}}
'@

$TOGGLE_JS = @'
document.querySelectorAll('.spec-header').forEach(function(h){
  h.addEventListener('click',function(){
    var body=this.nextElementSibling;
    var open=body.classList.toggle('open');
    this.classList.toggle('open',open);
  });
});
'@

# ── topic landing page ─────────────────────────────────────────────────────────
$cards = ""
$allFiles = @(Get-ChildItem $vaultDir -Filter "*.md" | Where-Object { $_.Name -match '^\d' } | Sort-Object Name)

foreach ($t in $topicMap) {
    $count = ($allFiles | Where-Object {
        $name = $_.Name
        $t.prefix | Where-Object { $name -like "$_*" }
    }).Count
    $cards += @"
    <a href="$($t.id).html" class="topic-card">
      <div class="tc-top">
        <span class="tc-num">$($t.id)</span>
        <div class="tc-name">$($t.titleH)</div>
        <div class="tc-count">$count spec points</div>
      </div>
      <div class="tc-footer">View notes &rarr;</div>
    </a>
"@
}

$landingHtml = @"
<!DOCTYPE html><html lang="en"><head><meta charset="UTF-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>Revision Notes &mdash; GCSE Chemistry</title><style>$CSS</style></head><body>
<div class="hero"><span class="hero-icon">&#x1F4D6;</span><h1>Revision Notes</h1><p>Edexcel GCSE Chemistry &mdash; full spec point notes with key definitions, explanations and exam tips</p></div>
<div class="topics-section"><div class="topics-heading">Choose a topic</div>
<div class="topic-grid">$cards</div></div></body></html>
"@
$landingHtml | Out-File (Join-Path $outDir "index.html") -Encoding UTF8
Write-Host "Generated notes/index.html"

# ── topic note pages ───────────────────────────────────────────────────────────
$skipSecs = @('Related Subtopics','How .+ Appears in Exams','Command Words','Mathematical Skills','_intro')

foreach ($t in $topicMap) {
    $files = $allFiles | Where-Object {
        $name = $_.Name
        $t.prefix | Where-Object { $name -like "$_*" }
    }

    $specCards = ""
    foreach ($f in $files) {
        $vf = Parse-VaultFile $f.FullName
        if (-not $vf.specNum) { continue }

        $bodyHtml = [System.Text.StringBuilder]::new()
        foreach ($sec in $vf.secOrder) {
            $skip = $false
            foreach ($pat in $skipSecs) { if ($sec -match $pat) { $skip=$true; break } }
            if ($skip) { continue }

            $secLines = @($vf.sections[$sec])
            if (-not $secLines -or $secLines.Count -eq 0) { continue }

            if ($sec -match 'Key Takeaway') {
                $null=$bodyHtml.Append('<div class="takeaway-box"><strong>Key Takeaways</strong>')
                $null=$bodyHtml.Append($(Lines-To-HTML $secLines))
                $null=$bodyHtml.Append('</div>')
            } elseif ($sec -match 'Common pitfall|pitfall') {
                $null=$bodyHtml.Append('<div class="pitfall-box"><strong>&#x26A0; Common Pitfalls</strong>')
                $null=$bodyHtml.Append($(Lines-To-HTML $secLines))
                $null=$bodyHtml.Append('</div>')
            } elseif ($sec -match 'Examiner') {
                # skip examiner reports for now - too long
            } else {
                $inner = Lines-To-HTML $secLines
                if ($inner.Trim()) {
                    if ($sec -notmatch '^_') {
                        $null=$bodyHtml.Append("<h3>$(Esc-HTML ($sec))</h3>")
                    }
                    $null=$bodyHtml.Append($inner)
                }
            }
        }

        $specCards += @"
<div class="spec-card">
  <div class="spec-header">
    <span class="spec-num">$($vf.specNum)</span>
    <span class="spec-name">$(Esc-HTML ($vf.specName))</span>
    <span class="spec-tier">$($vf.tier)</span>
    <span class="spec-arrow">&#x25BC;</span>
  </div>
  <div class="spec-body">$($bodyHtml.ToString())</div>
</div>
"@
    }

    $pageHtml = @"
<!DOCTYPE html><html lang="en"><head><meta charset="UTF-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>$($t.titleH -replace '&amp;','&') &mdash; Notes</title><style>$CSS</style></head><body>
<header class="site-header">
  <a href="index.html" class="back-link">&larr; All Topics</a>
  <h1>$($t.titleH)</h1>
</header>
<main>$specCards</main>
<script>$TOGGLE_JS</script></body></html>
"@
    $pageHtml | Out-File (Join-Path $outDir "$($t.id).html") -Encoding UTF8
    Write-Host "  Generated notes/$($t.id).html ($($files.Count) spec points)"
}
Write-Host "Notes done."
