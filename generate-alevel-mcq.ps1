# generate-alevel-mcq.ps1
# Generates OCR A Level Chemistry MCQ quiz pages for ChemIgnite
# Run from within the gcse-repo folder

$VaultRoot = "C:\Users\phili\Desktop\OCR A level Chemistry"
$OutputDir  = Split-Path -Parent $MyInvocation.MyCommand.Path

# ── CSS ──────────────────────────────────────────────────────────────────────
$ALC_CSS = @'
:root{--pr:#2d6a4f;--pr-dk:#1b4332;--sp:#40916c;--fl:#2d6a4f;--inf:#1b4332;--bg:#f4f6fb;--card:#fff;--tx:#1c1f3a;--txm:#6b7280;--bdr:#dde1f0;--cok:#e8f5e9;--cob:#2e7d32;--wng:#ffebee;--wnb:#c62828;--r:14px;--sh:0 2px 10px rgba(45,106,79,.10);--sh2:0 6px 24px rgba(45,106,79,.18)}
*{box-sizing:border-box;margin:0;padding:0}
body{font-family:'Nunito','Segoe UI',system-ui,sans-serif;background:var(--bg);color:var(--tx);line-height:1.65;min-height:100vh}
.site-header{background:linear-gradient(135deg,#0d2e1e,#1b4332 50%,var(--pr));color:#fff;padding:1rem 1.5rem;display:flex;align-items:center;gap:.9rem;box-shadow:0 2px 8px rgba(0,0,0,.18)}
.site-header h1{font-size:1rem;font-weight:600;flex:1}
.back-link{color:rgba(255,255,255,.82);text-decoration:none;font-size:.84rem;white-space:nowrap;border:1px solid rgba(255,255,255,.35);padding:.25rem .7rem;border-radius:20px;transition:background .15s}
.back-link:hover{background:rgba(255,255,255,.15);color:#fff}
.tier-badge{font-size:.78rem;font-weight:700;padding:.25rem .7rem;border-radius:20px;white-space:nowrap;color:#fff;letter-spacing:.03em}
.tier-badge.spark{background:var(--sp)}.tier-badge.flame{background:var(--fl)}.tier-badge.inferno{background:var(--inf)}.tier-badge.mcq{background:#52b788}
main{max-width:820px;margin:0 auto;padding:1.5rem 1rem 4rem}
.quiz-meta{display:flex;justify-content:space-between;align-items:center;padding:.7rem 0;margin-bottom:1.2rem;border-bottom:2px solid var(--bdr);color:var(--txm);font-size:.87rem}
.score-banner{background:linear-gradient(135deg,#0d2e1e,#1b4332 50%,var(--pr));color:#fff;border-radius:var(--r);padding:1.4rem 1.5rem;margin-bottom:1.5rem;text-align:center;display:none;box-shadow:var(--sh2)}
.score-banner h2{font-size:2rem;font-weight:800}.score-banner p{opacity:.88;margin-top:.3rem;font-size:.97rem}
.question-card{background:var(--card);border:2px solid var(--bdr);border-radius:var(--r);padding:1.2rem 1.3rem;margin-bottom:1rem;box-shadow:var(--sh);transition:border-color .2s,box-shadow .2s}
.question-card.correct{border-color:var(--cob);background:var(--cok);box-shadow:none}
.question-card.wrong{border-color:var(--wnb);background:var(--wng);box-shadow:none}
.q-header{display:flex;align-items:flex-start;gap:.75rem;margin-bottom:.8rem}
.q-num{background:var(--pr);color:#fff;font-weight:700;font-size:.72rem;padding:.2rem .5rem;border-radius:6px;white-space:nowrap;flex-shrink:0;margin-top:.12rem}
.q-stem{font-size:.97rem;line-height:1.6}
.options{display:flex;flex-direction:column;gap:.35rem;margin-left:2.6rem}
.opt-lbl{display:flex;align-items:flex-start;gap:.6rem;cursor:pointer;padding:.4rem .6rem;border-radius:8px;transition:background .12s;font-size:.91rem;border:1px solid transparent}
.opt-lbl:hover{background:#f0fff4;border-color:var(--bdr)}
.opt-lbl input{margin-top:.22rem;flex-shrink:0;accent-color:var(--pr)}
.opt-lbl.hl-ok{background:var(--cok);border-color:var(--cob);font-weight:600;color:var(--cob)}
.opt-lbl.hl-bad{background:var(--wng);border-color:var(--wnb);color:var(--wnb)}
.res-icon{font-size:.93rem;font-weight:700;margin:.5rem 0 0 2.6rem;padding:.25rem .6rem;border-radius:6px;display:none}
.res-ok{color:var(--cob);background:#d4edda}.res-bad{color:var(--wnb);background:#fde8e8}
.explain-box{display:none;margin:.7rem 0 0 2.6rem;padding:.7rem 1rem;background:#f0fff4;border-left:4px solid var(--pr);border-radius:0 8px 8px 0;font-size:.87rem;line-height:1.65;color:#374151}
.explain-lbl{font-weight:700;color:var(--pr);margin-bottom:.2rem;font-size:.78rem;text-transform:uppercase;letter-spacing:.06em}
.submit-area{margin-top:2rem;text-align:center}
.submit-btn{background:linear-gradient(135deg,#0d2e1e,#1b4332 50%,var(--pr));color:#fff;border:none;padding:.85rem 2.8rem;border-radius:10px;font-size:1.05rem;font-weight:700;cursor:pointer;box-shadow:0 4px 14px rgba(45,106,79,.35);transition:transform .15s,box-shadow .15s}
.submit-btn:hover{transform:translateY(-2px);box-shadow:0 6px 20px rgba(45,106,79,.45)}
.submit-btn:disabled{opacity:.5;cursor:default;transform:none;box-shadow:none}
@media(max-width:480px){.site-header h1{font-size:.88rem}.options{margin-left:1.5rem}.explain-box{margin-left:1.5rem}}
'@

# ── Quiz JS (same logic as GCSE) ─────────────────────────────────────────────
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
  banner.innerHTML='<h2><span id="score-num">0</span> / '+total+'</h2><p>'+pct+'% — '+msg+'</p>';
  (function(){if(score===0)return;var el=document.getElementById('score-num'),cur=0,t=setInterval(function(){el.textContent=++cur;if(cur>=score)clearInterval(t);},Math.min(120,Math.round(700/score)));})();
  banner.style.display='block';
  banner.scrollIntoView({behavior:'smooth'});
  document.getElementById('submit-btn').disabled=true;
  document.getElementById('submit-btn').textContent='Submitted';
}
renderQuiz();
document.getElementById('submit-btn').addEventListener('click',submitQuiz);
'@

# ── Helpers ───────────────────────────────────────────────────────────────────

function EscJ([string]$s) {
    $s = $s.Trim()
    $s = $s.Replace('\', '\\')
    $s = $s.Replace('"', '\"')
    $s = $s -replace "`r`n|`r|`n", ' '
    $s = $s -replace ' {2,}', ' '
    return $s.Trim()
}

function MdHtml([string]$s) {
    # Strip ✅ marker
    $s = $s.Replace([string][char]0x2705, '').Trim()
    # **bold** → <b>bold</b>
    $s = [regex]::Replace($s, '\*\*(.+?)\*\*', '<b>$1</b>')
    return $s.Trim()
}

function Get-SectionLines([string[]]$allLines, [string]$tier) {
    # Returns the sub-array of lines for the given tier section.
    # $tier: 'all' | 'spark' | 'flame' | 'inferno'
    if ($tier -eq 'all') { return $allLines }

    $headerPat = switch ($tier) {
        'spark'   { '##.*Spark' }
        'flame'   { '##.*Flame' }
        'inferno' { '##.*Inferno' }
    }
    $anyTierPat = '##.*(?:Spark|Flame|Inferno)'

    $start = -1
    for ($k = 0; $k -lt $allLines.Count; $k++) {
        if ($allLines[$k] -match $headerPat) { $start = $k; break }
    }

    if ($start -lt 0) {
        # No section headers — fall back to absolute Q-number ranges
        $ranges = @{ spark=@(1,10); flame=@(11,20); inferno=@(21,30) }
        $r = $ranges[$tier]
        return Get-QRangeLines $allLines $r[0] $r[1]
    }

    $end = $allLines.Count
    for ($k = $start + 1; $k -lt $allLines.Count; $k++) {
        if ($allLines[$k] -match $anyTierPat) { $end = $k; break }
    }

    return $allLines[$start..($end - 1)]
}

function Get-QRangeLines([string[]]$allLines, [int]$startQ, [int]$endQ) {
    # Returns only lines belonging to questions in the startQ..endQ range
    # Used as fallback when no section headers exist
    $result = [System.Collections.Generic.List[string]]::new()
    $inRange = $false
    foreach ($l in $allLines) {
        if ($l -match '^\*\*Q(\d+)\.\*\*') {
            $inRange = ([int]$Matches[1] -ge $startQ -and [int]$Matches[1] -le $endQ)
        }
        if ($inRange) { $result.Add($l) }
    }
    return $result.ToArray()
}

function Parse-Questions([string]$filePath, [string]$tier) {
    $raw   = [System.IO.File]::ReadAllText($filePath, [System.Text.Encoding]::UTF8)
    $allLines = ($raw -replace "`r`n","`n" -replace "`r","`n") -split "`n"
    $lines = Get-SectionLines $allLines $tier

    $results = [System.Collections.Generic.List[hashtable]]::new()
    $i = 0

    while ($i -lt $lines.Count) {
        $line = $lines[$i]

        $ck = [string][char]0x2705   # ✅

        # Matches: **Q1.** stem  |  **Q1. stem**  |  ### Q1. stem
        $qm = $null
        if ($line -match '^\*\*Q(\d+)\.(.*)') {
            $qm = @{ stem = ($Matches[2] -replace '^\*+','').TrimEnd('*').Trim() }
        } elseif ($line -match '^###\s*Q(\d+)\.\s*(.*)') {
            $qm = @{ stem = $Matches[2].Trim() }
        }
        if ($qm) {
            # Strip leading/trailing ** from captured text to get clean stem head
            $stemHead     = $qm.stem
            $stemParts    = [System.Collections.Generic.List[string]]::new()
            $explainParts = [System.Collections.Generic.List[string]]::new()
            $opts    = @{ A=''; B=''; C=''; D='' }
            $correct = ''
            $state   = 'stem'
            if ($stemHead) { $stemParts.Add($stemHead) }

            $i++
            while ($i -lt $lines.Count) {
                $l = $lines[$i]

                # Stop at next question header (all three formats)
                if ($l -match '^\*\*Q\d+\.' -or $l -match '^###\s*Q\d+\.') { break }

                # Section / tier separators — stop if inside explain, otherwise skip
                if ($l -match '^-{3,}$') {
                    if ($state -eq 'explain') { break }
                    $i++; continue
                }
                # H2 section headings (tier headers) — always break; skip H3+ in stem
                if ($l -match '^#{1,2}\s') {
                    if ($state -eq 'stem' -or $state -eq 'explain') { break }
                    $i++; continue
                }
                if ($l -match '^#{3,6}\s' -and $state -ne 'stem') {
                    $i++; continue
                }

                # Option line — handles:  - A) text ✅  |  - A: text  |  - ✅ A: text
                if ($l -match ('^-\s*(?:' + $ck + '\s*)?([A-D])[):]\s?(.*)')) {
                    $state     = 'opts'
                    $lt        = $Matches[1]
                    $otext     = $Matches[2]
                    $isCorrect = $l -match $ck
                    $i++
                    while ($i -lt $lines.Count) {
                        $nl = $lines[$i]
                        if ($nl -match ('^-\s*(?:' + $ck + '\s*)?[A-D][):]') -or
                            $nl -match '^>?\s*\*\*Explain:' -or
                            $nl -match '^\*\*Q\d+\.' -or $nl -match '^###\s*Q\d+\.' -or
                            $nl -match '^#{1,2}\s' -or $nl -match '^-{3,}$') { break }
                        if ($nl.Trim() -eq '') { break }
                        $otext += ' ' + $nl.Trim()
                        $i++
                    }
                    if ($isCorrect) { $correct = $lt }
                    $opts[$lt] = ($otext -replace $ck, '').Trim()
                    continue
                }

                # Explain line — handles both **Explain:** and > **Explain:**
                if ($l -match '^>?\s*\*\*Explain:\*\*\s?(.*)') {
                    $state = 'explain'
                    $ep = $Matches[1].Trim()
                    if ($ep) { $explainParts.Add($ep) }
                    $i++; continue
                }

                # Stem continuation
                if ($state -eq 'stem' -and $l.Trim() -ne '') { $stemParts.Add($l.Trim()) }

                # Explain continuation — strip blockquote markers
                if ($state -eq 'explain' -and $l.Trim() -ne '') {
                    $cleanL = ($l -replace '^>\s*','').Trim()
                    if ($cleanL -notmatch '^\*\[' -and $cleanL -notmatch '^tags:') { $explainParts.Add($cleanL) }
                }

                $i++
            }

            $results.Add(@{
                stem    = MdHtml (($stemParts    -join ' ').Trim())
                A       = MdHtml $opts['A']
                B       = MdHtml $opts['B']
                C       = MdHtml $opts['C']
                D       = MdHtml $opts['D']
                correct = $correct
                explain = MdHtml (($explainParts -join ' ').Trim())
            })
            continue   # $i already advanced by inner loop
        }   # end if ($qm)
        $i++
    }

    return ,$results   # comma forces array return
}

function Build-Json($questions) {
    $items = foreach ($q in $questions) {
        '{"stem":"'    + (EscJ $q.stem)    + '",' +
        '"A":"'        + (EscJ $q.A)       + '",' +
        '"B":"'        + (EscJ $q.B)       + '",' +
        '"C":"'        + (EscJ $q.C)       + '",' +
        '"D":"'        + (EscJ $q.D)       + '",' +
        '"correct":"'  + $q.correct        + '",' +
        '"explain":"'  + (EscJ $q.explain) + '"}'
    }
    return '[' + ($items -join ',') + ']'
}

function Get-Html([string]$topicId, [string]$topicName, [string]$tier, [string]$jsonData) {
    $tierBadgeClass = $tier
    $tierBadgeLabel = switch ($tier) {
        'spark'   { '&#x1F525; Spark' }
        'flame'   { '&#x1F525;&#x1F525; Flame' }
        'inferno' { '&#x1F525;&#x1F525;&#x1F525; Inferno' }
        default   { 'MCQ Practice' }
    }
    $tierMeta = switch ($tier) {
        'spark'   { 'Spark &mdash; Recall &amp; definitions' }
        'flame'   { 'Flame &mdash; Apply in context' }
        'inferno' { 'Inferno &mdash; Multi-step &amp; analyse' }
        default   { 'Practical skills MCQ practice' }
    }
    $qCount = ([regex]::Matches($jsonData, '"stem":')).Count
    $tierLabel = if ($tier -eq 'mcq') { '' } else { " &mdash; $tierBadgeLabel" }
    $pageTitle = "$topicId $topicName"
    if ($tier -ne 'mcq') { $pageTitle += " - $tier" }

    $badge = if ($tier -eq 'mcq') {
        '<span class="tier-badge mcq">MCQ Practice</span>'
    } else {
        "<span class=`"tier-badge $tier`">$tierBadgeLabel</span>"
    }

    return @"
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>$pageTitle &mdash; ChemIgnite</title>
<style>$ALC_CSS</style>
<link href="https://fonts.googleapis.com/css2?family=Nunito:wght@400;600;700;800;900&display=swap" rel="stylesheet">
</head>
<body>
<header class="site-header">
  <a href="alevel-practice.html" class="back-link">&larr; All Topics</a>
  <h1>$topicId &mdash; $topicName</h1>
  $badge
</header>
<main>
  <div class="quiz-meta">
    <span>$qCount questions</span>
    <span>$tierMeta</span>
  </div>
  <div id="score-banner" class="score-banner"></div>
  <div id="questions"></div>
  <div class="submit-area">
    <button id="submit-btn" class="submit-btn">Submit All Answers</button>
  </div>
</main>
<script>
const QUESTIONS=$jsonData;
$QUIZ_JS
</script>
</body>
</html>
"@
}

# ── Topic list ────────────────────────────────────────────────────────────────
$topics = @(
    # Module 1 — flat (15 questions, no tiers)
    [pscustomobject]@{ id='1.1'; name='Physical Chemistry Practicals';           flat=$true;  folder='Module 1 - Development of Practical Skills\1.1 Physical Chemistry Practicals' }
    [pscustomobject]@{ id='1.2'; name='Organic and Inorganic Practicals';        flat=$true;  folder='Module 1 - Development of Practical Skills\1.2 Organic and Inorganic Practicals' }
    [pscustomobject]@{ id='1.3'; name='Further Organic and Inorganic Practicals';flat=$true;  folder='Module 1 - Development of Practical Skills\1.3 Further Organic and Inorganic Practicals' }
    [pscustomobject]@{ id='1.4'; name='Further Physical Chemistry Practicals';   flat=$true;  folder='Module 1 - Development of Practical Skills\1.4 Further Physical Chemistry Practicals' }
    # Module 2 — tiered (30 questions)
    [pscustomobject]@{ id='2.1'; name='Atoms and Reactions';              flat=$false; folder='Module 2 - Foundations in Chemistry\2.1 Atoms and Reactions' }
    [pscustomobject]@{ id='2.2'; name='Amount of Substance';              flat=$false; folder='Module 2 - Foundations in Chemistry\2.2 Amount of Substance' }
    [pscustomobject]@{ id='2.3'; name='Acid-base and Redox Reactions';    flat=$false; folder='Module 2 - Foundations in Chemistry\2.3 Acid-base and Redox Reactions' }
    [pscustomobject]@{ id='2.4'; name='Electrons, Bonding and Structure'; flat=$false; folder='Module 2 - Foundations in Chemistry\2.4 Electrons, Bonding and Structure' }
    [pscustomobject]@{ id='2.5'; name='Shapes of Molecules and Ions';     flat=$false; folder='Module 2 - Foundations in Chemistry\2.5 Shapes of Simple Molecules and Ions' }
    # Module 3
    [pscustomobject]@{ id='3.1'; name='Periodicity';          flat=$false; folder='Module 3 - Periodic Table and Energy\3.1 Periodicity' }
    [pscustomobject]@{ id='3.2'; name='Group 2';              flat=$false; folder='Module 3 - Periodic Table and Energy\3.2 Group 2' }
    [pscustomobject]@{ id='3.3'; name='The Halogens';         flat=$false; folder='Module 3 - Periodic Table and Energy\3.3 The Halogens' }
    [pscustomobject]@{ id='3.4'; name='Enthalpy Changes';     flat=$false; folder='Module 3 - Periodic Table and Energy\3.4 Enthalpy Changes' }
    [pscustomobject]@{ id='3.5'; name='Reaction Rates';       flat=$false; folder='Module 3 - Periodic Table and Energy\3.5 Reaction Rates' }
    [pscustomobject]@{ id='3.6'; name='Chemical Equilibrium'; flat=$false; folder='Module 3 - Periodic Table and Energy\3.6 Chemical Equilibrium' }
    # Module 4
    [pscustomobject]@{ id='4.1'; name='Basic Concepts';                flat=$false; folder='Module 4 - Core Organic Chemistry\4.1 Basic Concepts' }
    [pscustomobject]@{ id='4.2'; name='Alkanes';                       flat=$false; folder='Module 4 - Core Organic Chemistry\4.2 Alkanes' }
    [pscustomobject]@{ id='4.3'; name='Alkenes';                       flat=$false; folder='Module 4 - Core Organic Chemistry\4.3 Alkenes' }
    [pscustomobject]@{ id='4.4'; name='Alcohols';                      flat=$false; folder='Module 4 - Core Organic Chemistry\4.4 Alcohols' }
    [pscustomobject]@{ id='4.5'; name='Haloalkanes';                   flat=$false; folder='Module 4 - Core Organic Chemistry\4.5 Haloalkanes' }
    [pscustomobject]@{ id='4.6'; name='Organic Synthesis (AS)';        flat=$false; folder='Module 4 - Core Organic Chemistry\4.6 Organic Synthesis (AS)' }
    [pscustomobject]@{ id='4.7'; name='Analytical Techniques (AS)';    flat=$false; folder='Module 4 - Core Organic Chemistry\4.7 Analytical Techniques (AS)' }
    # Module 5
    [pscustomobject]@{ id='5.1'; name='Rates of Reaction';         flat=$false; folder='Module 5 - Physical Chemistry and Transition Elements\5.1 Rates of Reaction' }
    [pscustomobject]@{ id='5.2'; name='Chemical Equilibria';        flat=$false; folder='Module 5 - Physical Chemistry and Transition Elements\5.2 Chemical Equilibria' }
    [pscustomobject]@{ id='5.3'; name='Acids, Bases and Buffers';   flat=$false; folder='Module 5 - Physical Chemistry and Transition Elements\5.3 Acids, Bases and Buffers' }
    [pscustomobject]@{ id='5.4'; name='Thermodynamics';             flat=$false; folder='Module 5 - Physical Chemistry and Transition Elements\5.4 Thermodynamics' }
    [pscustomobject]@{ id='5.5'; name='Electrochemistry';           flat=$false; folder='Module 5 - Physical Chemistry and Transition Elements\5.5 Electrochemistry' }
    [pscustomobject]@{ id='5.6'; name='Transition Elements';        flat=$false; folder='Module 5 - Physical Chemistry and Transition Elements\5.6 Transition Elements' }
    # Module 6
    [pscustomobject]@{ id='6.1'; name='Aromatic Chemistry';               flat=$false; folder='Module 6 - Organic Chemistry and Analysis\6.1 Aromatic Chemistry' }
    [pscustomobject]@{ id='6.2'; name='Carbonyl Chemistry';               flat=$false; folder='Module 6 - Organic Chemistry and Analysis\6.2 Carbonyl Chemistry' }
    [pscustomobject]@{ id='6.3'; name='Carboxylic Acids and Derivatives'; flat=$false; folder='Module 6 - Organic Chemistry and Analysis\6.3 Carboxylic Acids and Derivatives' }
    [pscustomobject]@{ id='6.4'; name='Nitrogen Compounds';               flat=$false; folder='Module 6 - Organic Chemistry and Analysis\6.4 Nitrogen Compounds' }
    [pscustomobject]@{ id='6.5'; name='Stereoisomerism';                  flat=$false; folder='Module 6 - Organic Chemistry and Analysis\6.5 Stereoisomerism' }
    [pscustomobject]@{ id='6.6'; name='Polymers';                         flat=$false; folder='Module 6 - Organic Chemistry and Analysis\6.6 Polymers' }
    [pscustomobject]@{ id='6.7'; name='Carbon-Carbon Bond Formation';     flat=$false; folder='Module 6 - Organic Chemistry and Analysis\6.7 Carbon-Carbon Bond Formation' }
    [pscustomobject]@{ id='6.8'; name='Organic Synthesis (A2)';           flat=$false; folder='Module 6 - Organic Chemistry and Analysis\6.8 Organic Synthesis (A2)' }
    [pscustomobject]@{ id='6.9'; name='Analytical Chemistry (A2)';        flat=$false; folder='Module 6 - Organic Chemistry and Analysis\6.9 Analytical Chemistry (A2)' }
)

# ── Generate pages ────────────────────────────────────────────────────────────
$generated = 0
$errors    = 0

foreach ($t in $topics) {
    # Use wildcard to find the MCQ Practice file (avoids em-dash encoding issues)
    $topicFolder = Join-Path $VaultRoot $t.folder
    $mcqFile = Get-ChildItem $topicFolder -Filter "*MCQ Practice*" -ErrorAction SilentlyContinue | Select-Object -First 1
    if (-not $mcqFile) {
        Write-Warning "NOT FOUND: $($t.folder)"
        $errors++
        continue
    }
    $fullPath = $mcqFile.FullName

    if ($t.flat) {
        # Module 1: one flat page, all questions
        $qs = Parse-Questions $fullPath 'all'
        if ($qs.Count -eq 0) {
            Write-Warning "No questions parsed for $($t.id)"
            $errors++
        } else {
            $outFile = Join-Path $OutputDir "ocr-$($t.id)-mcq.html"
            $html = Get-Html $t.id $t.name 'mcq' (Build-Json $qs)
            [System.IO.File]::WriteAllText($outFile, $html, [System.Text.Encoding]::UTF8)
            Write-Host "  $($t.id) MCQ ($($qs.Count)Q) -> $(Split-Path -Leaf $outFile)"
            $generated++
        }
    } else {
        # Modules 2–6: three tiered pages
        foreach ($tierName in @('spark','flame','inferno')) {
            $qs = Parse-Questions $fullPath $tierName
            if ($qs.Count -eq 0) {
                Write-Warning "No questions parsed for $($t.id) $tierName"
                $errors++
            } else {
                $outFile = Join-Path $OutputDir "ocr-$($t.id)-$tierName.html"
                $html = Get-Html $t.id $t.name $tierName (Build-Json $qs)
                [System.IO.File]::WriteAllText($outFile, $html, [System.Text.Encoding]::UTF8)
                Write-Host "  $($t.id) $tierName ($($qs.Count)Q) -> $(Split-Path -Leaf $outFile)"
                $generated++
            }
        }
    }
}

Write-Host ""
Write-Host "Done: $generated files generated, $errors errors." -ForegroundColor $(if ($errors -gt 0) { 'Yellow' } else { 'Green' })
