$vaultDir = "C:\Users\phili\Desktop\EDX GCSE Chemistry"
$outFile  = "C:\Users\phili\Desktop\EDX GCSE Chemistry Tiered Practice\Web\speclist.html"

$topicMap = @(
    @{id="T1"; prefix=@("1.1","1.2"); titleH="Atomic Structure &amp; the Periodic Table";    paper=1},
    @{id="B";  prefix=@("1.3","1.4","1.5"); titleH="Bonding &amp; Types of Substance";       paper=1},
    @{id="C";  prefix=@("1.6"); titleH="Calculations";                                        paper="1+2"},
    @{id="T2"; prefix=@("2."); titleH="States of Matter &amp; Mixtures";                      paper=1},
    @{id="T3"; prefix=@("3."); titleH="Chemical Changes";                                     paper=1},
    @{id="T4"; prefix=@("4."); titleH="Extracting Metals &amp; Equilibria";                   paper=1},
    @{id="T5"; prefix=@("5."); titleH="Separate Chemistry 1";                                 paper="1+2"},
    @{id="T6"; prefix=@("6."); titleH="Groups in the Periodic Table";                         paper=2},
    @{id="T7"; prefix=@("7."); titleH="Rates of Reaction &amp; Energy Changes";               paper=2},
    @{id="T8"; prefix=@("8."); titleH="Fuels &amp; Earth Science";                            paper=2},
    @{id="T9"; prefix=@("9."); titleH="Separate Chemistry 2";                                 paper=2}
)

$allFiles = @(Get-ChildItem $vaultDir -Filter "*.md" | Where-Object { $_.Name -match '^\d+\.\d' } | Sort-Object Name)

function Parse-YamlFront([string]$path) {
    $raw = @(Get-Content $path -Encoding UTF8)
    $specNum=''; $specName=''; $tier=''; $papers=@()
    if ($raw[0] -ne '---') { return $null }
    $end=1; while ($end -lt $raw.Count -and $raw[$end] -ne '---') { $end++ }
    $inPapers = $false; $inSpec = $false; $specText = ""; $qual = ""
    for ($i=1;$i -lt $end;$i++) {
        if ($raw[$i] -match '^sp_number:\s*"?([^"]+)"?')      { $specNum=$matches[1].Trim(); $inSpec=$false; $inPapers=$false }
        elseif ($raw[$i] -match '^sp_name:\s*"?([^"]+)"?')    { $specName=$matches[1].Trim(); $inSpec=$false; $inPapers=$false }
        elseif ($raw[$i] -match '^tier:\s*"?([^"]+)"?')        { $tier=$matches[1].Trim(); $inSpec=$false; $inPapers=$false }
        elseif ($raw[$i] -match '^qualification:\s*"?([^"#]+)"?') { $qual=$matches[1].Trim(); $inSpec=$false; $inPapers=$false }
        elseif ($raw[$i] -match '^papers:')                     { $inPapers=$true; $inSpec=$false; continue }
        elseif ($raw[$i] -match '^spec_text:\s*\|')             { $inSpec=$true; $inPapers=$false; continue }
        elseif ($inPapers -and $raw[$i] -match '^\s+-\s+"?([^"]+)"?') { $papers += $matches[1].Trim() }
        elseif ($inPapers -and $raw[$i] -notmatch '^\s+-')  { $inPapers=$false }
        elseif ($inSpec -and $raw[$i] -match '^\s+(.+)$')   { $specText += " " + $matches[1].Trim() }
        elseif ($inSpec -and $raw[$i] -notmatch '^\s')       { $inSpec=$false }
    }
    if (-not $specNum) { return $null }
    $p1 = $papers | Where-Object { $_ -match '/1[FH]' }
    $p2 = $papers | Where-Object { $_ -match '/2[FH]' }
    $paperNum = if ($p1 -and $p2) { "1+2" } elseif ($p2) { "2" } else { "1" }
    $qualCode = if ($qual -match 'only') { "sep" } else { "both" }
    return @{specNum=$specNum; specName=$specName; tier=$tier; paper=$paperNum; specText=$specText.Trim(); qual=$qualCode}
}

$CSS = @'
:root{--pr:#3f51b5;--pr-dk:#283593;--bg:#f4f6fb;--card:#fff;--tx:#1c1f3a;--txm:#6b7280;--bdr:#dde1f0;--r:12px;--sh:0 2px 10px rgba(63,81,181,.09);--p1:#1565c0;--p2:#6a1b9a;--fh:#2e7d32;--fo:#e65100;--ho:#7b1fa2}
*{box-sizing:border-box;margin:0;padding:0}
body{font-family:'Segoe UI',system-ui,sans-serif;background:var(--bg);color:var(--tx);line-height:1.6;min-height:100vh}
.site-header{background:linear-gradient(135deg,var(--pr-dk),var(--pr));color:#fff;padding:1rem 1.5rem;display:flex;align-items:center;gap:.9rem;box-shadow:0 2px 8px rgba(0,0,0,.18)}
.site-header h1{font-size:1rem;font-weight:600;flex:1}
.back-link{color:rgba(255,255,255,.82);text-decoration:none;font-size:.84rem;white-space:nowrap;border:1px solid rgba(255,255,255,.35);padding:.25rem .7rem;border-radius:20px;transition:background .15s}
.back-link:hover{background:rgba(255,255,255,.15)}
.hero{background:linear-gradient(135deg,var(--pr-dk),var(--pr) 60%,#5c6bc0);color:#fff;padding:2.5rem 1.5rem 2rem;text-align:center}
.hero-icon{font-size:2.5rem;display:block;margin-bottom:.5rem}
.hero h1{font-size:1.8rem;font-weight:800;margin-bottom:.35rem}
.hero p{opacity:.88;font-size:.97rem;max-width:520px;margin:0 auto}
.controls{max-width:960px;margin:1.5rem auto .5rem;padding:0 1.2rem;display:flex;flex-wrap:wrap;gap:.6rem;align-items:center}
.filter-label{font-size:.8rem;font-weight:700;color:var(--txm);text-transform:uppercase;letter-spacing:.05em;margin-right:.3rem}
.filter-btn{padding:.38rem .9rem;border-radius:20px;border:2px solid var(--bdr);background:var(--card);font-size:.83rem;font-weight:600;cursor:pointer;color:var(--txm);transition:all .15s}
.filter-btn.active{border-color:var(--pr);background:var(--pr);color:#fff}
.filter-btn.p1.active{background:var(--p1);border-color:var(--p1)}
.filter-btn.p2.active{background:var(--p2);border-color:var(--p2)}
.count-badge{font-size:.75rem;background:rgba(255,255,255,.25);border-radius:10px;padding:.05rem .4rem;margin-left:.25rem}
main{max-width:960px;margin:0 auto;padding:.5rem 1.2rem 5rem}
.topic-section{margin-bottom:1.5rem}
.topic-heading{display:flex;align-items:center;gap:.7rem;padding:.7rem 1rem;background:var(--card);border-radius:var(--r) var(--r) 0 0;border-bottom:2px solid var(--bdr);box-shadow:var(--sh)}
.topic-id{background:var(--pr);color:#fff;font-size:.7rem;font-weight:800;padding:.2rem .55rem;border-radius:6px}
.topic-title{font-weight:700;font-size:1rem;flex:1}
.paper-tag{font-size:.72rem;font-weight:700;padding:.2rem .55rem;border-radius:12px;color:#fff}
.paper-tag.p1{background:var(--p1)}.paper-tag.p2{background:var(--p2)}.paper-tag.p12{background:linear-gradient(90deg,var(--p1),var(--p2))}
.spec-table{width:100%;background:var(--card);border-radius:0 0 var(--r) var(--r);box-shadow:var(--sh);border-collapse:collapse;overflow:hidden}
.spec-table tr{border-bottom:1px solid var(--bdr);transition:background .1s}
.spec-table tr:last-child{border-bottom:none}
.spec-table tr:hover{background:#f0f2ff}
.spec-table tr.hidden{display:none}
.col-num{padding:.65rem 1rem .5rem;font-size:.78rem;font-weight:700;color:var(--txm);white-space:nowrap;width:80px;vertical-align:top}
.col-name{padding:.65rem .5rem .2rem;font-size:.9rem;font-weight:600;vertical-align:top}
.col-desc{padding:0 .5rem .6rem;font-size:.8rem;color:var(--txm);line-height:1.5}
.col-tier{padding:.65rem .5rem;width:80px;text-align:center;vertical-align:top}
.col-paper{padding:.65rem 1rem;width:90px;text-align:center;vertical-align:top}
.tier-pill{display:inline-block;font-size:.7rem;font-weight:700;padding:.18rem .5rem;border-radius:10px;white-space:nowrap}
.tier-fh{background:#e8f5e9;color:var(--fh)}
.tier-f{background:#fff3e0;color:var(--fo)}
.tier-h{background:#f3e5f5;color:var(--ho)}
.paper-pill{display:inline-block;font-size:.7rem;font-weight:700;padding:.18rem .5rem;border-radius:10px;color:#fff;white-space:nowrap}
.pp1{background:var(--p1)}.pp2{background:var(--p2)}.pp12{background:linear-gradient(90deg,var(--p1) 40%,var(--p2))}
.qual-pill{display:inline-block;font-size:.68rem;font-weight:700;padding:.12rem .45rem;border-radius:8px;white-space:nowrap;margin-left:.3rem}
.qsep{background:#fce4ec;color:#880e4f}.qboth{background:#e8eaf6;color:#283593}
.legend{display:flex;flex-wrap:wrap;gap:.6rem;max-width:960px;margin:0 auto 1.2rem;padding:0 1.2rem;font-size:.78rem}
.leg-item{display:flex;align-items:center;gap:.35rem;color:var(--txm)}
.controls-row{display:flex;flex-wrap:wrap;gap:.6rem;align-items:center}
@media print{.controls,.back-link{display:none}.topic-section{break-inside:avoid}}
@media(max-width:600px){.col-tier,.col-paper{width:60px}.col-num{width:60px}}
'@

$FILTER_JS = @'
var rows=document.querySelectorAll('.spec-row');
var sections=document.querySelectorAll('.topic-section');
var curPaper='all', curQual='all';
function applyFilters(){
  rows.forEach(function(r){
    var paperOk=curPaper==='all'||r.dataset.paper===curPaper;
    var qualOk=curQual==='all'||curQual==='sep-all'||r.dataset.qual===curQual;
    r.classList.toggle('hidden',!(paperOk&&qualOk));
  });
  sections.forEach(function(s){
    s.style.display=s.querySelectorAll('.spec-row:not(.hidden)').length===0?'none':'';
  });
}
document.querySelectorAll('[data-type="paper"]').forEach(function(b){
  b.addEventListener('click',function(){
    document.querySelectorAll('[data-type="paper"]').forEach(function(x){x.classList.remove('active');});
    this.classList.add('active'); curPaper=this.dataset.filter; applyFilters();
  });
});
document.querySelectorAll('[data-type="qual"]').forEach(function(b){
  b.addEventListener('click',function(){
    document.querySelectorAll('[data-type="qual"]').forEach(function(x){x.classList.remove('active');});
    this.classList.add('active'); curQual=this.dataset.filter; applyFilters();
  });
});
'@

# ── build page ────────────────────────────────────────────────────────────────
$sectionsHtml = ""
$totalRows = 0

foreach ($t in $topicMap) {
    $files = $allFiles | Where-Object { $name=$_.Name; $t.prefix | Where-Object { $name -like "$_*" } }
    $rows = ""
    $count = 0
    foreach ($f in $files) {
        $sp = Parse-YamlFront $f.FullName
        if (-not $sp) { continue }
        $tierClass = switch ($sp.tier) { "F+H"{"tier-fh"} "F"{"tier-f"} default{"tier-h"} }
        $tierLabel = switch ($sp.tier) { "F+H"{"F + H"} "F"{"Foundation"} default{"Higher"} }
        $ppClass = switch ($sp.paper) { "1"{"pp1"} "2"{"pp2"} default{"pp12"} }
        $ppLabel = switch ($sp.paper) { "1"{"Paper 1"} "2"{"Paper 2"} default{"P1 &amp; P2"} }
        $safeName = $sp.specName -replace '&','&amp;' -replace '<','&lt;' -replace '>','&gt;'
        $safeDesc = $sp.specText -replace '&','&amp;' -replace '<','&lt;' -replace '>','&gt;'
        $qualBadge = if ($sp.qual -eq 'sep') { "<span class='qual-pill qsep'>Separate only</span>" } else { "<span class='qual-pill qboth'>Combined &amp; Separate</span>" }
        $rows += "<tr class='spec-row' data-paper='$($sp.paper)' data-qual='$($sp.qual)'>"
        $rows += "<td class='col-num' rowspan='2'>$($sp.specNum)</td>"
        $rows += "<td class='col-name'>$safeName $qualBadge</td>"
        $rows += "<td class='col-tier' rowspan='2'><span class='tier-pill $tierClass'>$tierLabel</span></td>"
        $rows += "<td class='col-paper' rowspan='2'><span class='paper-pill $ppClass'>$ppLabel</span></td></tr>"
        if ($safeDesc) {
            $rows += "<tr class='spec-row' data-paper='$($sp.paper)' data-qual='$($sp.qual)'><td class='col-desc'>$safeDesc</td></tr>"
        }
        $count++; $totalRows++
    }
    if (-not $rows) { continue }

    $paperTagClass = switch ($t.paper.ToString()) { "1"{"p1"} "2"{"p2"} default{"p12"} }
    $paperTagLabel = switch ($t.paper.ToString()) { "1"{"Paper 1"} "2"{"Paper 2"} default{"Paper 1 &amp; 2"} }

    $sectionsHtml += @"
<div class="topic-section" id="topic-$($t.id)">
  <div class="topic-heading">
    <span class="topic-id">$($t.id)</span>
    <span class="topic-title">$($t.titleH)</span>
    <span class="paper-tag $paperTagClass">$paperTagLabel</span>
  </div>
  <table class="spec-table"><tbody>$rows</tbody></table>
</div>
"@
}

$pageHtml = @"
<!DOCTYPE html><html lang="en"><head><meta charset="UTF-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>Spec Point List &mdash; GCSE Chemistry</title><style>$CSS</style></head><body>
<header class="site-header">
  <a href="home.html" class="back-link">&larr; Home</a>
  <h1>Specification Point List</h1>
</header>
<div class="hero">
  <span class="hero-icon">&#x1F4DC;</span>
  <h1>What's on Each Paper?</h1>
  <p>All $totalRows specification points &mdash; grouped by topic, filtered by paper, with tier information</p>
</div>
<div class="controls">
  <div class="controls-row">
    <span class="filter-label">Paper:</span>
    <button class="filter-btn active" data-type="paper" data-filter="all">All</button>
    <button class="filter-btn p1" data-type="paper" data-filter="1">Paper 1</button>
    <button class="filter-btn p2" data-type="paper" data-filter="2">Paper 2</button>
  </div>
  <div class="controls-row">
    <span class="filter-label">Course:</span>
    <button class="filter-btn active" data-type="qual" data-filter="all">All</button>
    <button class="filter-btn" data-type="qual" data-filter="both" style="border-color:#1565c0;color:#1565c0">Combined Science</button>
    <button class="filter-btn" data-type="qual" data-filter="sep-all" style="border-color:#880e4f;color:#880e4f">Separate Science</button>
  </div>
</div>
<div class="legend">
  <span class="leg-item"><span class="tier-pill tier-fh">F + H</span> Foundation &amp; Higher</span>
  <span class="leg-item"><span class="tier-pill tier-f">Foundation</span> Foundation only</span>
  <span class="leg-item"><span class="tier-pill tier-h">Higher</span> Higher only</span>
  <span class="leg-item"><span class="paper-pill pp1">Paper 1</span> Paper 1 (Topics 1&ndash;5)</span>
  <span class="leg-item"><span class="paper-pill pp2">Paper 2</span> Paper 2 (Topics 6&ndash;9)</span>
</div>
<main>$sectionsHtml</main>
<script>$FILTER_JS</script>
</body></html>
"@

$pageHtml | Out-File $outFile -Encoding UTF8
Write-Host "Generated speclist.html ($totalRows spec points)"
