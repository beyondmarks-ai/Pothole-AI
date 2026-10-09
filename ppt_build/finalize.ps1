$ErrorActionPreference='Stop'
$path='D:\Pothole\Road_Damage_Detection_Guide_Presentation.pptx'
$app=New-Object -ComObject PowerPoint.Application
$p=$app.Presentations.Open($path,0,0,0)
foreach($sh in $p.Slides.Item(12).Shapes){
  if($sh.HasTextFrame -and $sh.TextFrame.HasText -and $sh.TextFrame.TextRange.Text -like 'One connected record:*'){
    $sh.TextFrame.TextRange.Text='One record connects each road report to a verified repair.'
  }
}
$fit=@(); $overlap=@(); $offcanvas=@()
foreach($s in $p.Slides){
  $boxes=@()
  foreach($sh in $s.Shapes){
    if($sh.HasTextFrame -and $sh.TextFrame.HasText){
      $t=$sh.TextFrame.TextRange
      if($t.BoundHeight -gt $sh.Height+2 -or $t.BoundWidth -gt $sh.Width+2){$fit+=@{slide=$s.SlideIndex;text=$t.Text}}
      $b=@{text=$t.Text;x=$t.BoundLeft;y=$t.BoundTop;w=$t.BoundWidth;h=$t.BoundHeight}
      if($b.x -lt 0 -or $b.y -lt 0 -or ($b.x+$b.w) -gt 960 -or ($b.y+$b.h) -gt 540){$offcanvas+=@{slide=$s.SlideIndex;text=$t.Text}}
      foreach($other in $boxes){
        if($b.x -lt $other.x+$other.w-1 -and $b.x+$b.w -gt $other.x+1 -and $b.y -lt $other.y+$other.h-1 -and $b.y+$b.h -gt $other.y+1){$overlap+=@{slide=$s.SlideIndex;a=$b.text;b=$other.text}}
      }
      $boxes+=,$b
    }
  }
}
$report=@{slides=$p.Slides.Count;textFitIssues=$fit;textOverlapIssues=$overlap;offCanvasText=$offcanvas}
$report | ConvertTo-Json -Depth 8 | Set-Content -Encoding UTF8 'D:\Pothole\ppt_build\final-qa.json'
$p.Save()
$p.Slides.Item(12).Export('D:\Pothole\ppt_build\renders\Slide12.PNG','PNG',1600,900)
$p.SaveAs('D:\Pothole\Road_Damage_Detection_Guide_Presentation.pdf',32)
$p.Close();$app.Quit()
$report | ConvertTo-Json -Depth 8
