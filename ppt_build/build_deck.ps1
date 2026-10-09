$ErrorActionPreference='Stop'
$build='D:\Pothole\ppt_build'
$out='D:\Pothole\Road_Damage_Detection_Guide_Presentation.pptx'
$data=Get-Content -Raw -Encoding UTF8 "$build\content.json" | ConvertFrom-Json
function Color($hex) { $h=$hex.TrimStart('#'); return [Convert]::ToInt32($h.Substring(0,2),16)+256*[Convert]::ToInt32($h.Substring(2,2),16)+65536*[Convert]::ToInt32($h.Substring(4,2),16) }
$ink=Color '171C22'; $muted=Color '59616B'; $blue=Color '176CA4'; $rule=Color 'D4D9DD'; $pale=Color 'F0F3F5'; $white=Color 'FFFFFF'
$app=New-Object -ComObject PowerPoint.Application
$deck=$app.Presentations.Add(0)
$deck.PageSetup.SlideWidth=960
$deck.PageSetup.SlideHeight=540
$script:shapes=@()
function Text($s,$str,$x,$y,$w,$h,$size=18,$bold=$false,$color=$ink) {
  $sh=$s.Shapes.AddTextbox(1,$x,$y,$w,$h)
  $sh.TextFrame.MarginLeft=0; $sh.TextFrame.MarginRight=0; $sh.TextFrame.MarginTop=0; $sh.TextFrame.MarginBottom=0
  $sh.TextFrame.WordWrap=-1; $sh.TextFrame.AutoSize=0
  $tr=$sh.TextFrame.TextRange; $tr.Text=$str; $tr.Font.Name='Arial'; $tr.Font.Size=$size; $tr.Font.Color.RGB=$color; $tr.Font.Bold=([int]$bold * -1)
  $tr.ParagraphFormat.SpaceAfter=0; $tr.ParagraphFormat.SpaceBefore=0
  $sh.TextFrame2.AutoSize=0; $sh.Left=[single]$x; $sh.Top=[single]$y; $sh.Width=[single]$w; $sh.Height=[single]$h; $sh.TextFrame.MarginRight=6
  $script:shapes+=@{slide=$s.SlideIndex;name=$sh.Name;text=$str;x=$x;y=$y;w=$w;h=$h;size=$size}
  return $sh
}
function T($s,$str,$x,$y,$w,$h,$size=18,$bold=$false,$color=$ink) { $null=Text $s $str $x $y $w $h $size $bold $color }
function Line($s,$x1,$y1,$x2,$y2,$color=$rule,$width=1,$arrow=$false) {
  $l=$s.Shapes.AddLine($x1,$y1,$x2,$y2); $l.Line.ForeColor.RGB=$color; $l.Line.Weight=[single]$width
  if($arrow){$l.Line.EndArrowheadStyle=3}
}
function Rect($s,$x,$y,$w,$h,$fill=$pale) { $q=$s.Shapes.AddShape(1,$x,$y,$w,$h); $q.Fill.ForeColor.RGB=$fill; $q.Line.Visible=0 }
function Base($i,$title=$null) {
  $s=$deck.Slides.Add($i,12); $s.FollowMasterBackground=0; $s.Background.Fill.ForeColor.RGB=$white
  T $s $data[$i-1].section 48 26 820 22 12 $true $blue
  if($title){T $s $title 48 69 864 89 35 $true}
  Line $s 48 501 912 501
  T $s 'ROAD DAMAGE DETECTION  /  GECB' 48 510 700 18 10 $false $muted
  $pn=Text $s ('{0:D2} / 12' -f $i) 836 510 76 18 10 $false $muted; $pn.TextFrame.TextRange.ParagraphFormat.Alignment=3
  $s.NotesPage.Shapes.Placeholders.Item(2).TextFrame.TextRange.Text=$data[$i-1].notes
  return $s
}
function Bottom($s,$str) { Line $s 48 446 912 446; T $s $str 48 460 864 38 16 $false $blue }
function Columns($s,$items,$y=210,$bodyY=260,$bodyH=144) {
  $w=264; for($j=0;$j -lt 3;$j++){ $x=48+$j*300; T $s $items[$j][0] $x $y $w 60 24 $true; T $s $items[$j][1] $x $bodyY $w $bodyH 18 $false $muted }
}

# 1 — restrained academic cover; source logos are the only reused branding assets.
$s=Base 1
$null=$s.Shapes.AddPicture("$build\image2.png",0,-1,837,25,71,66)
T $s 'Government Engineering College, Bidar' 48 60 770 28 19 $true
T $s 'Computer Science & Engineering  ·  VTU Belagavi' 48 91 750 25 16 $false $muted
T $s $data[0].title 48 144 864 122 50 $true
T $s $data[0].subtitle 48 282 864 42 25 $false $blue
Line $s 48 349 912 349
T $s 'Presented by' 48 369 470 24 16 $true
T $s "Bhagyashree  ·  3DG23CS007`nPallavi  ·  3DG23CS028" 48 403 360 57 16
T $s "Pratiksha  ·  3DG23CS031`nVakilata  ·  3DG23CS059" 353 403 325 57 16
T $s 'Under the guidance of' 690 369 222 24 16 $true
T $s "Asst. Prof.`nPooja Hebbale" 690 403 222 62 18 $false $muted

# 2 — problem: headline, context and three open columns.
$s=Base 2 'A photo alone does not resolve a complaint'
T $s $data[1].lead 48 160 864 50 22 $false $muted
Columns $s $data[1].items 238 304 122
Bottom $s $data[1].bottom

# 3 — objectives: editorial numbered list, no boxed cards.
$s=Base 3 $data[2].title
for($j=0;$j -lt 4;$j++){
  $y=166+$j*67; T $s ('0'+($j+1)) 48 $y 48 36 24 $true $blue
  T $s $data[2].items[$j][0] 111 $y 296 35 24 $true
  T $s $data[2].items[$j][1] 425 ($y+1) 487 56 18 $false $muted
  if($j -lt 3){Line $s 111 ($y+57) 912 ($y+57)}
}
Bottom $s $data[2].bottom

# 4 — literature table.
$s=Base 4 'Existing research supports the design'
T $s 'Research / resource' 48 170 270 31 18 $true $blue
T $s 'What it contributes' 353 170 269 31 18 $true $blue
T $s 'Design implication' 659 170 253 31 18 $true $blue
Line $s 48 210 912 210 $ink
for($j=0;$j -lt 3;$j++){
  $y=228+$j*65
  T $s $data[3].rows[$j][0] 48 $y 270 53 20 $true
  T $s $data[3].rows[$j][1] 353 $y 267 53 18 $false $muted
  T $s $data[3].rows[$j][2] 659 $y 253 53 18 $false $muted
  Line $s 48 ($y+54) 912 ($y+54)
}
Bottom $s $data[3].bottom

# 5 — the exact nine-step user workflow, grouped chronologically.
$s=Base 5 $data[4].title
Line $s 48 223 902 223 $blue 2 $true
for($j=0;$j -lt 3;$j++){
  $x=48+$j*300
  T $s $data[4].groups[$j].title $x 173 264 42 24 $true
  for($k=0;$k -lt 3;$k++){T $s $data[4].groups[$j].steps[$k] $x (249+$k*63) 270 59 18 $false $muted}
}
Bottom $s $data[4].bottom

# 6 — method left, supported classes right.
$s=Base 6 'The AI creates an evidence-backed report'
for($j=0;$j -lt 3;$j++){
  $y=171+$j*88
  T $s $data[5].items[$j][0] 48 $y 508 34 24 $true
  T $s $data[5].items[$j][1] 48 ($y+36) 508 53 18 $false $muted
}
Line $s 596 173 596 415
T $s 'Target damage classes' 635 173 277 60 24 $true $blue
T $s "Potholes`nLongitudinal cracks`nTransverse cracks`nAlligator cracks" 635 255 277 139 20
T $s 'Subject to checkpoint support.' 635 402 277 32 16 $false $muted
Bottom $s $data[5].bottom

# 7 — assessment concepts, with separate questions and definitions.
$s=Base 7 'Severity and priority are different'
for($j=0;$j -lt 3;$j++){
  $x=48+$j*300
  T $s $data[6].items[$j][0] $x 182 264 40 24 $true $blue
  T $s $data[6].items[$j][1] $x 240 264 79 22 $true
  T $s $data[6].items[$j][2] $x 338 264 100 18 $false $muted
}
Bottom $s $data[6].bottom

# 8 — simple native architecture. Edges precede nodes.
$s=Base 8 'Proposed system architecture'
Line $s 309 220 352 220 $blue 1.5 $true
Line $s 608 220 653 220 $blue 1.5 $true
Line $s 479 262 479 322 $blue 1.5 $true
Line $s 407 262 256 321 $blue 1.5 $true
Line $s 308 367 351 367 $blue 1.5 $true
Line $s 608 367 653 367 $blue 1.5 $true
function Node($s,$x,$y,$title,$body){Rect $s $x $y 258 86; T $s $title ($x+15) ($y+13) 228 30 24 $true; T $s $body ($x+15) ($y+49) 228 27 16 $false $muted}
Node $s 48 177 'Web application' 'React · uploads & dashboard'
Node $s 352 177 'Application API' 'FastAPI · access & workflow'
Node $s 654 177 'Notifications' 'Configured municipal alerts'
T $s 'Queued jobs' 169 279 150 27 16 $false $blue
Node $s 48 323 'AI worker' 'OpenCV / PyTorch · inference'
Node $s 352 323 'Data & media' 'PostgreSQL / PostGIS'
Node $s 654 323 'Road history' 'Surveys & repair trends'
Bottom $s $data[7].bottom

# 9 — responsibilities, human verification highlighted.
$s=Base 9 $data[8].title
for($j=0;$j -lt 3;$j++){
  $y=172+$j*86
  T $s ('0'+($j+1)) 48 $y 49 34 24 $true $blue
  T $s $data[8].items[$j][0] 111 $y 285 65 24 $true
  T $s $data[8].items[$j][1] 425 ($y+1) 487 65 19 $false $muted
  if($j -lt 2){Line $s 111 ($y+70) 912 ($y+70)}
}
Bottom $s $data[8].bottom

# 10 — staged implementation, native timeline.
$s=Base 10 'Build the prototype in four stages'
Line $s 48 242 903 242 $blue 2 $true
for($j=0;$j -lt 4;$j++){
  $x=48+$j*224
  T $s $data[9].items[$j][0] $x 174 193 67 24 $true
  T $s $data[9].items[$j][1] $x 270 193 149 18 $false $muted
}
Bottom $s $data[9].bottom

# 11 — reviewable validation matrix, no fabricated performance charts.
$s=Base 11 'Test the AI and the complete workflow'
T $s 'Evaluation area' 48 166 292 30 18 $true $blue
T $s 'Evidence to collect' 370 166 542 30 18 $true $blue
Line $s 48 204 912 204 $ink
for($j=0;$j -lt 4;$j++){
  $y=217+$j*55
  T $s $data[10].rows[$j][0] 48 $y 287 49 20 $true
  T $s $data[10].rows[$j][1] 370 $y 542 49 18 $false $muted
  if($j -lt 3){Line $s 48 ($y+45) 912 ($y+45)}
}
Bottom $s $data[10].bottom

# 12 — conclusion with concrete next milestone.
$s=Base 12 'A clear path to verified road repairs'
T $s $data[11].lead 48 153 842 65 25 $false $blue
Columns $s $data[11].items 253 312 119
Bottom $s $data[11].bottom

$deck.SaveAs($out,24)
$render="$build\renders"; New-Item -ItemType Directory -Force -Path $render | Out-Null
$deck.Export($render,'PNG',1600,900)
$deck.SaveAs('D:\Pothole\Road_Damage_Detection_Guide_Presentation.pdf',32)
$qa=@()
foreach($slide in $deck.Slides){
  foreach($sh in $slide.Shapes){
    if($sh.HasTextFrame -and $sh.TextFrame.HasText){
      $tr=$sh.TextFrame.TextRange
      if($tr.BoundHeight -gt ($sh.Height+2) -or $tr.BoundWidth -gt ($sh.Width+2)){
        $qa+=@{slide=$slide.SlideIndex;shape=$sh.Name;text=$tr.Text;shapeW=$sh.Width;shapeH=$sh.Height;boundW=$tr.BoundWidth;boundH=$tr.BoundHeight}
      }
    }
  }
}
$qa | ConvertTo-Json -Depth 5 | Set-Content -Encoding UTF8 "$build\text-overflow.json"
$script:shapes | ConvertTo-Json -Depth 5 | Set-Content -Encoding UTF8 "$build\layout-ledger.json"
$deck.Close(); $app.Quit()
[Runtime.InteropServices.Marshal]::ReleaseComObject($deck) | Out-Null
[Runtime.InteropServices.Marshal]::ReleaseComObject($app) | Out-Null
Write-Output "Created $out"
Write-Output "Text fit issues: $($qa.Count)"
$qa | ConvertTo-Json -Depth 5

