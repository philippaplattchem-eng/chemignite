$srcDir = "C:\Users\phili\Desktop\EDX GCSE Chemistry Tiered Practice\Questions"
$outDir = "C:\Users\phili\Desktop\EDX GCSE Chemistry Tiered Practice\Web"
New-Item -ItemType Directory -Force -Path $outDir | Out-Null

$topicList = @(
    @{id="T1";fn="T1 — Atomic Structure & the Periodic Table.md";titleH="Atomic Structure &amp; the Periodic Table";titleR="Atomic Structure & the Periodic Table"},
    @{id="T2";fn="T2 — States of Matter & Mixtures.md";titleH="States of Matter &amp; Mixtures";titleR="States of Matter & Mixtures"},
    @{id="T3";fn="T3 — Chemical Changes.md";titleH="Chemical Changes";titleR="Chemical Changes"},
    @{id="T4";fn="T4 — Extracting Metals & Equilibria.md";titleH="Extracting Metals &amp; Equilibria";titleR="Extracting Metals & Equilibria"},
    @{id="T5";fn="T5 — Separate Chemistry 1.md";titleH="Separate Chemistry 1";titleR="Separate Chemistry 1"},
    @{id="T6";fn="T6 — Groups in the Periodic Table.md";titleH="Groups in the Periodic Table";titleR="Groups in the Periodic Table"},
    @{id="T7";fn="T7 — Rates of Reaction & Energy Changes.md";titleH="Rates of Reaction &amp; Energy Changes";titleR="Rates of Reaction & Energy Changes"},
    @{id="T8";fn="T8 — Fuels & Earth Science.md";titleH="Fuels &amp; Earth Science";titleR="Fuels & Earth Science"},
    @{id="T9";fn="T9 — Separate Chemistry 2.md";titleH="Separate Chemistry 2";titleR="Separate Chemistry 2"}
)

$tKeys  = @("spark","flame","inferno")
$tLabel = @{spark="Spark";flame="Flame";inferno="Inferno"}
$tDesc  = @{spark="Recall";flame="Apply";inferno="Analyse"}
$tEmoji = @{spark="&#x1F525;";flame="&#x1F525;&#x1F525;";inferno="&#x1F525;&#x1F525;&#x1F525;"}

# ── helpers ──────────────────────────────────────────────────────────────────

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
            $stem = $matches[1].Trim()
            $opts = @{A='';B='';C='';D=''}
            $cor = ''; $ex = ''
            $i++
            while ($i -lt $lines.Count -and
                   $lines[$i] -notmatch '^-\s+[A-D]\)' -and
                   $lines[$i] -notmatch '^\*\*Q\d+\.\*\*' -and
                   $lines[$i] -notmatch '^\*\*Explain:' -and
                   $lines[$i] -ne '---') {
                if ($lines[$i].Trim()) { $stem += ' ' + $lines[$i].Trim() }
                $i++
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

# ── shared CSS ────────────────────────────────────────────────────────────────

$CSS = @'
:root{--pr:#3f51b5;--pr-dk:#283593;--sp:#5b9bd5;--fl:#1e5fb4;--inf:#0d3575;--bg:#f4f6fb;--card:#fff;--tx:#1c1f3a;--txm:#6b7280;--bdr:#dde1f0;--cok:#e8f5e9;--cob:#2e7d32;--wng:#ffebee;--wnb:#c62828;--r:14px;--sh:0 2px 10px rgba(63,81,181,.10);--sh2:0 6px 24px rgba(63,81,181,.18)}
*{box-sizing:border-box;margin:0;padding:0}
body{font-family:'Segoe UI',system-ui,sans-serif;background:var(--bg);color:var(--tx);line-height:1.65;min-height:100vh}

/* ── quiz-page header ── */
.site-header{background:linear-gradient(135deg,var(--pr-dk),var(--pr));color:#fff;padding:1rem 1.5rem;display:flex;align-items:center;gap:.9rem;box-shadow:0 2px 8px rgba(0,0,0,.18)}
.site-header h1{font-size:1rem;font-weight:600;flex:1}
.back-link{color:rgba(255,255,255,.82);text-decoration:none;font-size:.84rem;white-space:nowrap;border:1px solid rgba(255,255,255,.35);padding:.25rem .7rem;border-radius:20px;transition:background .15s}
.back-link:hover{background:rgba(255,255,255,.15);color:#fff}
.tier-badge{font-size:.78rem;font-weight:700;padding:.25rem .7rem;border-radius:20px;white-space:nowrap;color:#fff;letter-spacing:.03em}
.tier-badge.spark{background:var(--sp)}.tier-badge.flame{background:var(--fl)}.tier-badge.inferno{background:var(--inf)}

/* ── landing hero ── */
.hero{background:linear-gradient(135deg,var(--pr-dk) 0%,var(--pr) 60%,#5c6bc0 100%);color:#fff;padding:3rem 1.5rem 2.5rem;text-align:center}
.hero-icon{font-size:2.8rem;margin-bottom:.6rem;display:block}
.hero h1{font-size:1.9rem;font-weight:800;letter-spacing:-.01em;margin-bottom:.4rem}
.hero p{font-size:1rem;opacity:.88;max-width:480px;margin:0 auto .5rem}
.hero-pills{display:flex;justify-content:center;gap:.5rem;flex-wrap:wrap;margin-top:1.1rem}
.hero-pill{background:rgba(255,255,255,.18);border:1px solid rgba(255,255,255,.3);border-radius:20px;padding:.3rem .85rem;font-size:.82rem;font-weight:600}

/* ── tier legend ── */
.tier-legend{display:flex;gap:0;max-width:700px;margin:1.8rem auto 0;background:var(--card);border-radius:var(--r);box-shadow:var(--sh);overflow:hidden}
.tier-leg-item{flex:1;padding:.85rem 1rem;text-align:center;border-right:1px solid var(--bdr)}
.tier-leg-item:last-child{border-right:none}
.tl-name{font-weight:700;font-size:.9rem;margin-bottom:.15rem}
.tl-desc{font-size:.78rem;color:var(--txm)}
.tl-dot{display:inline-block;width:10px;height:10px;border-radius:50%;margin-right:.35rem;vertical-align:middle}
.tl-dot.spark{background:var(--sp)}.tl-dot.flame{background:var(--fl)}.tl-dot.inferno{background:var(--inf)}

/* ── topic grid ── */
.topics-section{max-width:960px;margin:2rem auto 4rem;padding:0 1.2rem}
.topics-heading{font-size:.78rem;font-weight:700;text-transform:uppercase;letter-spacing:.08em;color:var(--txm);margin-bottom:1rem;padding-left:.2rem}
.topic-grid{display:grid;grid-template-columns:repeat(3,1fr);gap:1rem}
.topic-card{background:var(--card);border-radius:var(--r);box-shadow:var(--sh);overflow:hidden;display:flex;flex-direction:column;transition:transform .18s,box-shadow .18s}
.topic-card:hover{transform:translateY(-3px);box-shadow:var(--sh2)}
.tc-top{padding:1.1rem 1.2rem .9rem;flex:1}
.tc-num{display:inline-block;background:var(--pr);color:#fff;font-size:.7rem;font-weight:800;padding:.18rem .55rem;border-radius:6px;letter-spacing:.05em;margin-bottom:.55rem}
.tc-name{font-weight:700;font-size:.95rem;line-height:1.4;color:var(--tx)}
.tc-btns{display:flex;flex-direction:column;gap:.5rem;padding:.9rem 1.1rem 1.1rem}
.tc-btn{display:flex;align-items:center;justify-content:flex-start;gap:.45rem;padding:.55rem .9rem;border-radius:8px;text-decoration:none;font-weight:700;font-size:.85rem;color:#fff;transition:filter .15s,transform .1s}
.tc-btn:hover{filter:brightness(1.1);transform:translateX(2px)}
.tc-btn.spark{background:var(--sp)}.tc-btn.flame{background:var(--fl)}.tc-btn.inferno{background:var(--inf)}

/* ── quiz page ── */
main{max-width:820px;margin:0 auto;padding:1.5rem 1rem 4rem}
.quiz-meta{display:flex;justify-content:space-between;align-items:center;padding:.7rem 0;margin-bottom:1.2rem;border-bottom:2px solid var(--bdr);color:var(--txm);font-size:.87rem}
.score-banner{background:linear-gradient(135deg,var(--pr-dk),var(--pr));color:#fff;border-radius:var(--r);padding:1.4rem 1.5rem;margin-bottom:1.5rem;text-align:center;display:none;box-shadow:var(--sh2)}
.score-banner h2{font-size:2rem;font-weight:800}.score-banner p{opacity:.88;margin-top:.3rem;font-size:.97rem}
.question-card{background:var(--card);border:2px solid var(--bdr);border-radius:var(--r);padding:1.2rem 1.3rem;margin-bottom:1rem;box-shadow:var(--sh);transition:border-color .2s,box-shadow .2s}
.question-card.correct{border-color:var(--cob);background:var(--cok);box-shadow:none}
.question-card.wrong{border-color:var(--wnb);background:var(--wng);box-shadow:none}
.q-header{display:flex;align-items:flex-start;gap:.75rem;margin-bottom:.8rem}
.q-num{background:var(--pr);color:#fff;font-weight:700;font-size:.72rem;padding:.2rem .5rem;border-radius:6px;white-space:nowrap;flex-shrink:0;margin-top:.12rem}
.q-stem{font-size:.97rem;line-height:1.6}
.options{display:flex;flex-direction:column;gap:.35rem;margin-left:2.6rem}
.opt-lbl{display:flex;align-items:flex-start;gap:.6rem;cursor:pointer;padding:.4rem .6rem;border-radius:8px;transition:background .12s;font-size:.91rem;border:1px solid transparent}
.opt-lbl:hover{background:#f0f2ff;border-color:var(--bdr)}
.opt-lbl input{margin-top:.22rem;flex-shrink:0;accent-color:var(--pr)}
.opt-lbl.hl-ok{background:var(--cok);border-color:var(--cob);font-weight:600;color:var(--cob)}
.opt-lbl.hl-bad{background:var(--wng);border-color:var(--wnb);color:var(--wnb)}
.res-icon{display:none;font-size:.93rem;font-weight:700;margin:.5rem 0 0 2.6rem;padding:.25rem .6rem;border-radius:6px;display:none}
.res-ok{color:var(--cob);background:#d4edda}.res-bad{color:var(--wnb);background:#fde8e8}
.explain-box{display:none;margin:.7rem 0 0 2.6rem;padding:.7rem 1rem;background:#f0f2ff;border-left:4px solid var(--pr);border-radius:0 8px 8px 0;font-size:.87rem;line-height:1.65;color:#374151}
.explain-lbl{font-weight:700;color:var(--pr);margin-bottom:.2rem;font-size:.78rem;text-transform:uppercase;letter-spacing:.06em}
.submit-area{margin-top:2rem;text-align:center}
.submit-btn{background:linear-gradient(135deg,var(--pr-dk),var(--pr));color:#fff;border:none;padding:.85rem 2.8rem;border-radius:10px;font-size:1.05rem;font-weight:700;cursor:pointer;box-shadow:0 4px 14px rgba(63,81,181,.35);transition:transform .15s,box-shadow .15s}
.submit-btn:hover{transform:translateY(-2px);box-shadow:0 6px 20px rgba(63,81,181,.45)}
.submit-btn:disabled{opacity:.5;cursor:default;transform:none;box-shadow:none}
@media(max-width:700px){.topic-grid{grid-template-columns:repeat(2,1fr)}}
@media(max-width:480px){.topic-grid{grid-template-columns:1fr}.hero h1{font-size:1.5rem}.site-header h1{font-size:.88rem}.options{margin-left:1.5rem}.explain-box{margin-left:1.5rem}.tier-legend{flex-direction:column}.tier-leg-item{border-right:none;border-bottom:1px solid var(--bdr)}.tier-leg-item:last-child{border-bottom:none}}
'@

# ── shared quiz JS ────────────────────────────────────────────────────────────

$QUIZ_JS = @'
function renderQuiz(){
  var c=document.getElementById('questions');
  QUESTIONS.forEach(function(q,idx){
    var n=idx+1;
    var div=document.createElement('div');
    div.className='question-card';div.id='qcard-'+n;
    var opts=['A','B','C','D'].map(function(l){
      return '<label class="opt-lbl" id="opt-'+n+'-'+l+'"><input type="radio" name="q'+n+'" value="'+l+'"> <span><strong>'+l+'.</strong> '+q[l]+'</span></label>';
    }).join('');
    div.innerHTML='<div class="q-header"><span class="q-num">Q'+n+'</span><span class="q-stem">'+q.stem+'</span></div>'
      +'<div class="options">'+opts+'</div>'
      +'<div class="res-icon" id="res-'+n+'"></div>'
      +'<div class="explain-box" id="ex-'+n+'"><div class="explain-lbl">Explanation</div>'+q.explain+'</div>';
    c.appendChild(div);
  });
}
function submitQuiz(){
  var unanswered=[];
  QUESTIONS.forEach(function(q,idx){
    var n=idx+1;
    if(!document.querySelector('input[name="q'+n+'"]:checked'))unanswered.push(n);
  });
  if(unanswered.length>0&&!confirm(unanswered.length+' question(s) not answered. Submit anyway?'))return;
  var score=0,total=QUESTIONS.length;
  QUESTIONS.forEach(function(q,idx){
    var n=idx+1;
    var sel=document.querySelector('input[name="q'+n+'"]:checked');
    var card=document.getElementById('qcard-'+n);
    var res=document.getElementById('res-'+n);
    var ex=document.getElementById('ex-'+n);
    document.querySelectorAll('input[name="q'+n+'"]').forEach(function(r){r.disabled=true;});
    document.getElementById('opt-'+n+'-'+q.correct).classList.add('hl-ok');
    if(sel&&sel.value===q.correct){
      score++;card.classList.add('correct');
      res.innerHTML='&#10003; Correct';res.className='res-icon res-ok';
    }else{
      card.classList.add('wrong');
      if(sel)document.getElementById('opt-'+n+'-'+sel.value).classList.add('hl-bad');
      var ans=sel?'Incorrect — correct answer: <strong>'+q.correct+'</strong>':'Not answered — correct answer: <strong>'+q.correct+'</strong>';
      res.innerHTML='&#10007; '+ans;res.className='res-icon res-bad';
    }
    res.style.display='block';ex.style.display='block';
  });
  var pct=Math.round(score/total*100);
  var msg=score===total?'Full marks — excellent work!':score>=Math.round(total*0.7)?'Good work — check the explanations for any you missed.':'Keep practising — work through all the explanations below.';
  var banner=document.getElementById('score-banner');
  banner.innerHTML='<h2>'+score+' / '+total+'</h2><p>'+pct+'% — '+msg+'</p>';
  banner.style.display='block';
  banner.scrollIntoView({behavior:'smooth'});
  document.getElementById('submit-btn').disabled=true;
  document.getElementById('submit-btn').textContent='Submitted';
}
renderQuiz();
document.getElementById('submit-btn').addEventListener('click',submitQuiz);
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
      <div class="tc-top">
        <span class="tc-num">$($t.id)</span>
        <div class="tc-name">$($t.titleH)</div>
      </div>
      <div class="tc-btns">$btns</div>
    </div>
"@
}

$landingHtml = @"
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>GCSE Chemistry &mdash; Tiered Practice</title>
<style>$CSS</style>
</head>
<body>

<div class="hero">
  <span class="hero-icon">&#x1F9EA;</span>
  <h1>GCSE Chemistry Practice</h1>
  <p>Edexcel (1CH0) &mdash; Tiered multiple-choice questions with instant feedback</p>
  <div class="hero-pills">
    <span class="hero-pill">9 Topics</span>
    <span class="hero-pill">3 Tiers</span>
    <span class="hero-pill">Up to 20 questions each</span>
    <span class="hero-pill">Score &amp; explanations</span>
  </div>
</div>

<div class="topics-section">
  <div class="tier-legend">
    <div class="tier-leg-item">
      <div class="tl-name"><span class="tl-dot spark"></span>&#x1F525; Spark</div>
      <div class="tl-desc">Recall &amp; definitions</div>
    </div>
    <div class="tier-leg-item">
      <div class="tl-name"><span class="tl-dot flame"></span>&#x1F525;&#x1F525; Flame</div>
      <div class="tl-desc">Apply in context</div>
    </div>
    <div class="tier-leg-item">
      <div class="tl-name"><span class="tl-dot inferno"></span>&#x1F525;&#x1F525;&#x1F525; Inferno</div>
      <div class="tl-desc">Multi-step &amp; analyse</div>
    </div>
  </div>

  <div class="topics-heading" style="margin-top:2rem">Choose a topic</div>
  <div class="topic-grid">
$cards  </div>
</div>

</body>
</html>
"@

$landingHtml | Out-File (Join-Path $outDir "index.html") -Encoding UTF8
Write-Host "Generated index.html"

# ── question pages ────────────────────────────────────────────────────────────

foreach ($t in $topicList) {
    $mdPath = Join-Path $srcDir $t.fn
    $lines = @(Get-Content $mdPath -Encoding UTF8)

    for ($ti = 0; $ti -lt 3; $ti++) {
        $tk = $tKeys[$ti]
        $tierLines = @(Get-TierLines $lines $ti)
        $qs = @(Parse-Qs $tierLines)

        if ($qs.Count -eq 0) { Write-Warning "  !! No questions: $($t.id) $tk"; continue }

        # Build JS data array
        $jsArr = "["
        for ($qi = 0; $qi -lt $qs.Count; $qi++) {
            $q = $qs[$qi]
            if ($qi -gt 0) { $jsArr += "," }
            $jsArr += "{`"stem`":`"$(EscJs $q.stem)`",`"A`":`"$(EscJs $q.A)`",`"B`":`"$(EscJs $q.B)`",`"C`":`"$(EscJs $q.C)`",`"D`":`"$(EscJs $q.D)`",`"correct`":`"$($q.correct)`",`"explain`":`"$(EscJs $q.explain)`"}"
        }
        $jsArr += "]"

        $badge = "$($tEmoji[$tk]) $($tLabel[$tk])"
        $qCount = $qs.Count

        $pageHtml = @"
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>$($t.id) $($tLabel[$tk]) &mdash; $($t.titleR)</title>
<style>$CSS</style>
</head>
<body>
<header class="site-header">
  <a href="index.html" class="back-link">&larr; All Topics</a>
  <h1>$($t.id) &mdash; $($t.titleH)</h1>
  <span class="tier-badge $($tk)">$badge</span>
</header>
<main>
  <div class="quiz-meta">
    <span>$qCount questions</span>
    <span>$($tLabel[$tk]) &mdash; $($tDesc[$tk])</span>
  </div>
  <div id="score-banner" class="score-banner"></div>
  <div id="questions"></div>
  <div class="submit-area">
    <button id="submit-btn" class="submit-btn">Submit All Answers</button>
  </div>
</main>
<script>
const QUESTIONS=$jsArr;
$QUIZ_JS
</script>
</body>
</html>
"@
        $outFile = Join-Path $outDir "$($t.id)-$($tk).html"
        $pageHtml | Out-File $outFile -Encoding UTF8
        Write-Host "  Generated $($t.id)-$($tk).html ($qCount questions)"
    }
}

Write-Host "`nDone. Files in: $outDir"
