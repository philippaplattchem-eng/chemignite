$srcDir = "C:\Users\phili\Desktop\EDX GCSE Chemistry Tiered Practice\Questions"
$outDir = "C:\Users\phili\Desktop\EDX GCSE Chemistry Tiered Practice\Web\flashcards"
New-Item -ItemType Directory -Force -Path $outDir | Out-Null

$topicList = @(
    @{id="T1";fn="T1 — Atomic Structure & the Periodic Table.md";titleH="Atomic Structure &amp; the Periodic Table"},
    @{id="T2";fn="T2 — States of Matter & Mixtures.md";titleH="States of Matter &amp; Mixtures"},
    @{id="T3";fn="T3 — Chemical Changes.md";titleH="Chemical Changes"},
    @{id="T4";fn="T4 — Extracting Metals & Equilibria.md";titleH="Extracting Metals &amp; Equilibria"},
    @{id="T5";fn="T5 — Separate Chemistry 1.md";titleH="Separate Chemistry 1"},
    @{id="T6";fn="T6 — Groups in the Periodic Table.md";titleH="Groups in the Periodic Table"},
    @{id="T7";fn="T7 — Rates of Reaction & Energy Changes.md";titleH="Rates of Reaction &amp; Energy Changes"},
    @{id="T8";fn="T8 — Fuels & Earth Science.md";titleH="Fuels &amp; Earth Science"},
    @{id="T9";fn="T9 — Separate Chemistry 2.md";titleH="Separate Chemistry 2"}
)
$tKeys  = @("spark","flame","inferno")
$tLabel = @{spark="Spark";flame="Flame";inferno="Inferno"}
$tDesc  = @{spark="Recall";flame="Apply";inferno="Analyse"}
$tEmoji = @{spark="&#x1F525;";flame="&#x1F525;&#x1F525;";inferno="&#x1F525;&#x1F525;&#x1F525;"}

function EscJs([string]$s) {
    $s = $s -replace '\\', '\\\\'
    $s = $s -replace '"', '\"'
    $s = $s -replace "`r`n", ' '
    $s = $s -replace "`n", ' '
    $s = $s -replace '\s*—\s*', ', '
    $s = [regex]::Replace($s, '\*\*(.+?)\*\*', '<strong>$1</strong>')
    return $s
}

function Get-TierLines([string[]]$lines, [int]$idx) {
    $pos = @()
    for ($j = 0; $j -lt $lines.Count; $j++) {
        if ($lines[$j] -match '^##\s+.*\b(Spark|Flame|Inferno)\b') { $pos += $j }
    }
    if ($idx -ge $pos.Count) { return @() }
    $s = $pos[$idx] + 1
    $e = if ($idx + 1 -lt $pos.Count) { $pos[$idx + 1] - 1 } else { $lines.Count - 1 }
    if ($s -gt $e) { return @() }
    return $lines[$s..$e]
}

function Parse-Qs([string[]]$lines) {
    $qs = [System.Collections.ArrayList]::new()
    $i = 0
    while ($i -lt $lines.Count) {
        if ($lines[$i] -match '^\*\*Q\d+\.\*\*\s*(.*)$') {
            $stem = $matches[1].Trim(); $opts = @{A='';B='';C='';D=''}; $cor = ''; $ex = ''
            $i++
            while ($i -lt $lines.Count -and $lines[$i] -notmatch '^-\s+[A-D]\)' -and
                   $lines[$i] -notmatch '^\*\*Q\d+\.\*\*' -and $lines[$i] -notmatch '^\*\*Explain:' -and $lines[$i] -ne '---') {
                if ($lines[$i].Trim()) { $stem += ' ' + $lines[$i].Trim() }; $i++
            }
            while ($i -lt $lines.Count -and $lines[$i] -match '^-\s+([A-D])\)\s+(.+)$') {
                $l = $matches[1]; $t = $matches[2].Trim()
                if ($t -match '✅') { $cor = $l; $t = ($t -replace '✅','').Trim() }
                $opts[$l] = $t; $i++
            }
            $inEx = $false
            while ($i -lt $lines.Count) {
                if ($lines[$i] -match '^\*\*Q\d+\.\*\*' -or ($lines[$i] -match '^##\s' -and $lines[$i] -notmatch '^###')) { break }
                if ($lines[$i] -match '^\*\*Explain:\*\*\s*(.*)$') { $inEx=$true; $ex=$matches[1].Trim() }
                elseif ($inEx -and $lines[$i] -ne '---' -and $lines[$i].Trim()) { $ex += ' ' + $lines[$i].Trim() }
                $i++
            }
            if ($stem -and $cor -and $opts.A -and $opts.B -and $opts.C -and $opts.D) {
                $null = $qs.Add(@{stem=$stem;A=$opts.A;B=$opts.B;C=$opts.C;D=$opts.D;correct=$cor;explain=$ex})
            }
        } else { $i++ }
    }
    return $qs
}

$CSS = @'
:root{--pr:#3f51b5;--pr-dk:#283593;--sp:#5b9bd5;--fl:#1e5fb4;--inf:#0d3575;--bg:#f4f6fb;--card:#fff;--tx:#1c1f3a;--txm:#6b7280;--bdr:#dde1f0;--r:14px;--sh:0 2px 10px rgba(63,81,181,.10);--sh2:0 8px 30px rgba(63,81,181,.20)}
*{box-sizing:border-box;margin:0;padding:0}
body{font-family:'Segoe UI',system-ui,sans-serif;background:var(--bg);color:var(--tx);line-height:1.65;min-height:100vh}
.site-header{background:linear-gradient(135deg,var(--pr-dk),var(--pr));color:#fff;padding:1rem 1.5rem;display:flex;align-items:center;gap:.9rem;box-shadow:0 2px 8px rgba(0,0,0,.18)}
.site-header h1{font-size:1rem;font-weight:600;flex:1}
.back-link{color:rgba(255,255,255,.82);text-decoration:none;font-size:.84rem;white-space:nowrap;border:1px solid rgba(255,255,255,.35);padding:.25rem .7rem;border-radius:20px;transition:background .15s}
.back-link:hover{background:rgba(255,255,255,.15);color:#fff}
.tier-badge{font-size:.78rem;font-weight:700;padding:.25rem .7rem;border-radius:20px;white-space:nowrap;color:#fff}
.tier-badge.spark{background:var(--sp)}.tier-badge.flame{background:var(--fl)}.tier-badge.inferno{background:var(--inf)}
.hero{background:linear-gradient(135deg,var(--pr-dk),var(--pr) 60%,#5c6bc0);color:#fff;padding:3rem 1.5rem 2.5rem;text-align:center}
.hero-icon{font-size:2.8rem;margin-bottom:.6rem;display:block}
.hero h1{font-size:1.9rem;font-weight:800;margin-bottom:.4rem}
.hero p{font-size:1rem;opacity:.88;max-width:480px;margin:0 auto}
.tier-legend{display:flex;max-width:700px;margin:1.8rem auto 0;background:var(--card);border-radius:var(--r);box-shadow:var(--sh);overflow:hidden}
.tier-leg-item{flex:1;padding:.85rem 1rem;text-align:center;border-right:1px solid var(--bdr)}
.tier-leg-item:last-child{border-right:none}
.tl-name{font-weight:700;font-size:.9rem;margin-bottom:.15rem}
.tl-desc{font-size:.78rem;color:var(--txm)}
.tl-dot{display:inline-block;width:10px;height:10px;border-radius:50%;margin-right:.35rem;vertical-align:middle}
.tl-dot.spark{background:var(--sp)}.tl-dot.flame{background:var(--fl)}.tl-dot.inferno{background:var(--inf)}
.topics-section{max-width:960px;margin:2rem auto 4rem;padding:0 1.2rem}
.topics-heading{font-size:.78rem;font-weight:700;text-transform:uppercase;letter-spacing:.08em;color:var(--txm);margin-bottom:1rem}
.topic-grid{display:grid;grid-template-columns:repeat(3,1fr);gap:1rem}
.topic-card{background:var(--card);border-radius:var(--r);box-shadow:var(--sh);overflow:hidden;display:flex;flex-direction:column;transition:transform .18s,box-shadow .18s}
.topic-card:hover{transform:translateY(-3px);box-shadow:var(--sh2)}
.tc-top{padding:1.1rem 1.2rem .9rem;flex:1}
.tc-num{display:inline-block;background:var(--pr);color:#fff;font-size:.7rem;font-weight:800;padding:.18rem .55rem;border-radius:6px;letter-spacing:.05em;margin-bottom:.55rem}
.tc-name{font-weight:700;font-size:.95rem;line-height:1.4}
.tc-btns{display:flex;flex-direction:column;gap:.5rem;padding:.9rem 1.1rem 1.1rem}
.tc-btn{display:flex;align-items:center;gap:.45rem;padding:.55rem .9rem;border-radius:8px;text-decoration:none;font-weight:700;font-size:.85rem;color:#fff;transition:filter .15s,transform .1s}
.tc-btn:hover{filter:brightness(1.1);transform:translateX(2px)}
.tc-btn.spark{background:var(--sp)}.tc-btn.flame{background:var(--fl)}.tc-btn.inferno{background:var(--inf)}
main{max-width:720px;margin:0 auto;padding:2rem 1rem 4rem}
.deck-meta{display:flex;justify-content:space-between;align-items:center;margin-bottom:1.5rem;font-size:.88rem;color:var(--txm)}
.counter{font-weight:700;font-size:1rem;color:var(--pr)}
.card-scene{perspective:1000px;width:100%;height:300px;cursor:pointer;margin-bottom:1.5rem}
.card{width:100%;height:100%;position:relative;transform-style:preserve-3d;transition:transform .45s ease}
.card.flipped{transform:rotateY(180deg)}
.card-face{position:absolute;width:100%;height:100%;border-radius:var(--r);padding:1.8rem 2rem;display:flex;flex-direction:column;justify-content:center;backface-visibility:hidden;-webkit-backface-visibility:hidden;overflow:hidden}
.card-front{background:var(--card);border:2px solid var(--bdr);box-shadow:var(--sh2)}
.card-back{background:#eef1ff;border:2px solid var(--pr);transform:rotateY(180deg);justify-content:flex-start;overflow-y:auto}
.card-hint{font-size:.73rem;color:var(--txm);margin-bottom:.6rem;text-transform:uppercase;letter-spacing:.06em}
.card-q{font-size:1.05rem;line-height:1.6;color:var(--tx)}
.card-ans{font-size:.97rem;font-weight:700;color:var(--pr);margin-bottom:.6rem}
.card-ex{font-size:.86rem;line-height:1.6;color:#374151}
.nav-row{display:flex;align-items:center;justify-content:center;gap:1rem;margin-bottom:1rem}
.nav-btn{background:var(--card);border:2px solid var(--bdr);color:var(--tx);padding:.55rem 1.3rem;border-radius:8px;font-size:.9rem;font-weight:600;cursor:pointer;transition:border-color .15s,background .15s}
.nav-btn:hover:not(:disabled){border-color:var(--pr);background:#eef1ff}
.nav-btn:disabled{opacity:.35;cursor:default}
.btn-shuffle{background:var(--pr);color:#fff;border-color:var(--pr)}
.btn-shuffle:hover{background:var(--pr-dk);border-color:var(--pr-dk)}
.flip-hint{text-align:center;font-size:.8rem;color:var(--txm);margin-top:.5rem}
@media(max-width:700px){.topic-grid{grid-template-columns:repeat(2,1fr)}.card-scene{height:260px}}
@media(max-width:480px){.topic-grid{grid-template-columns:1fr}.hero h1{font-size:1.5rem}.card-face{padding:1.2rem 1.3rem}.tier-legend{flex-direction:column}.tier-leg-item{border-right:none;border-bottom:1px solid var(--bdr)}.tier-leg-item:last-child{border-bottom:none}}
'@

$FC_JS = @'
var cur=0,flipped=false;
var order=QUESTIONS.map(function(_,i){return i;});
function showCard(idx){
  cur=idx;
  var q=QUESTIONS[order[idx]];
  document.getElementById('card-q').innerHTML=q.stem;
  document.getElementById('card-ans').innerHTML='<strong>'+q.correct+'.</strong> '+q[q.correct];
  document.getElementById('card-ex').textContent=q.explain;
  document.getElementById('counter').textContent=(idx+1)+' / '+QUESTIONS.length;
  document.getElementById('card').classList.remove('flipped');
  flipped=false;
  document.getElementById('btn-prev').disabled=(cur===0);
  document.getElementById('btn-next').disabled=(cur===order.length-1);
}
function flip(){flipped=!flipped;document.getElementById('card').classList.toggle('flipped');}
document.getElementById('card').addEventListener('click',flip);
document.getElementById('btn-prev').addEventListener('click',function(){if(cur>0)showCard(cur-1);});
document.getElementById('btn-next').addEventListener('click',function(){if(cur<order.length-1)showCard(cur+1);});
document.getElementById('btn-shuffle').addEventListener('click',function(){
  for(var i=order.length-1;i>0;i--){var j=Math.floor(Math.random()*(i+1));var t=order[i];order[i]=order[j];order[j]=t;}
  showCard(0);
});
document.addEventListener('keydown',function(e){
  if(e.key==='ArrowRight'){if(cur<order.length-1)showCard(cur+1);}
  else if(e.key==='ArrowLeft'){if(cur>0)showCard(cur-1);}
  else if(e.key===' '){e.preventDefault();flip();}
});
showCard(0);
'@

# ── landing page ──────────────────────────────────────────────────────────────
$cards = ""
foreach ($t in $topicList) {
    $btns = ""
    foreach ($tk in $tKeys) {
        $btns += "<a href=`"$($t.id)-$($tk).html`" class=`"tc-btn $($tk)`">$($tEmoji[$tk]) $($tLabel[$tk])</a>"
    }
    $cards += @"
    <div class="topic-card">
      <div class="tc-top"><span class="tc-num">$($t.id)</span><div class="tc-name">$($t.titleH)</div></div>
      <div class="tc-btns">$btns</div>
    </div>
"@
}

$landingHtml = @"
<!DOCTYPE html><html lang="en"><head><meta charset="UTF-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>Flashcards &mdash; GCSE Chemistry</title><style>$CSS</style></head><body>
<div class="hero"><span class="hero-icon">&#x1F0CF;</span><h1>Chemistry Flashcards</h1><p>Click a card to flip &mdash; use arrows or keyboard to navigate &mdash; shuffle anytime</p>
<div class="tier-legend">
<div class="tier-leg-item"><div class="tl-name"><span class="tl-dot spark"></span>&#x1F525; Spark</div><div class="tl-desc">Recall &amp; definitions</div></div>
<div class="tier-leg-item"><div class="tl-name"><span class="tl-dot flame"></span>&#x1F525;&#x1F525; Flame</div><div class="tl-desc">Apply in context</div></div>
<div class="tier-leg-item"><div class="tl-name"><span class="tl-dot inferno"></span>&#x1F525;&#x1F525;&#x1F525; Inferno</div><div class="tl-desc">Multi-step &amp; analyse</div></div>
</div></div>
<div class="topics-section"><div class="topics-heading">Choose a topic</div>
<div class="topic-grid">$cards</div></div></body></html>
"@
$landingHtml | Out-File (Join-Path $outDir "index.html") -Encoding UTF8
Write-Host "Generated flashcards/index.html"

# ── flashcard pages ───────────────────────────────────────────────────────────
foreach ($t in $topicList) {
    $mdPath = Join-Path $srcDir $t.fn
    $lines = @(Get-Content $mdPath -Encoding UTF8)
    for ($ti = 0; $ti -lt 3; $ti++) {
        $tk = $tKeys[$ti]
        $tierLines = @()
        $pos = @()
        for ($j = 0; $j -lt $lines.Count; $j++) {
            if ($lines[$j] -match '^##\s+.*\b(Spark|Flame|Inferno)\b') { $pos += $j }
        }
        if ($ti -lt $pos.Count) {
            $s = $pos[$ti] + 1
            $e = if ($ti + 1 -lt $pos.Count) { $pos[$ti + 1] - 1 } else { $lines.Count - 1 }
            if ($s -le $e) { $tierLines = $lines[$s..$e] }
        }
        $qs = @(Parse-Qs $tierLines)
        if ($qs.Count -eq 0) { continue }

        $jsArr = "[" + (($qs | ForEach-Object {
            "{`"stem`":`"$(EscJs $_.stem)`",`"A`":`"$(EscJs $_.A)`",`"B`":`"$(EscJs $_.B)`",`"C`":`"$(EscJs $_.C)`",`"D`":`"$(EscJs $_.D)`",`"correct`":`"$($_.correct)`",`"explain`":`"$(EscJs $_.explain)`"}"
        }) -join ",") + "]"

        $pageHtml = @"
<!DOCTYPE html><html lang="en"><head><meta charset="UTF-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>$($t.id) $($tLabel[$tk]) Flashcards</title><style>$CSS</style></head><body>
<header class="site-header">
  <a href="index.html" class="back-link">&larr; All Topics</a>
  <h1>$($t.id) &mdash; $($t.titleH)</h1>
  <span class="tier-badge $($tk)">$($tEmoji[$tk]) $($tLabel[$tk])</span>
</header>
<main>
<div class="deck-meta"><span>$($qs.Count) cards &mdash; $($tLabel[$tk]) ($($tDesc[$tk]))</span><span class="counter" id="counter">1 / $($qs.Count)</span></div>
<div class="card-scene"><div class="card" id="card">
  <div class="card-face card-front"><div class="card-hint">Question &mdash; tap to reveal answer</div><div class="card-q" id="card-q"></div></div>
  <div class="card-face card-back"><div class="card-hint">Answer</div><div class="card-ans" id="card-ans"></div><div class="card-ex" id="card-ex"></div></div>
</div></div>
<div class="nav-row">
  <button class="nav-btn" id="btn-prev">&larr; Prev</button>
  <button class="nav-btn btn-shuffle" id="btn-shuffle">&#x1F500; Shuffle</button>
  <button class="nav-btn" id="btn-next">Next &rarr;</button>
</div>
<div class="flip-hint">Tap card or press Space to flip &nbsp;&bull;&nbsp; &larr; &rarr; arrow keys to navigate</div>
</main>
<script>const QUESTIONS=$jsArr;$FC_JS</script></body></html>
"@
        $pageHtml | Out-File (Join-Path $outDir "$($t.id)-$($tk).html") -Encoding UTF8
        Write-Host "  Generated flashcards/$($t.id)-$($tk).html ($($qs.Count) cards)"
    }
}
Write-Host "Flashcards done."
