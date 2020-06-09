[console]::WindowWidth=110
[console]::WindowHeight=40
[console]::BufferWidth=[console]::WindowWidth

# Version 1.0
# Required paths in script - WinSCP, WinRAR, brg.txt(with rar archive pass on first row and Yandex login:pass on the second row)
# Optional - links to this script with no day check or overwrite params


Set-PSDebug -Trace 0
cd $PSScriptRoot
#$date = Get-Date -UFormat %d.%m.%Y
$dateToday = "{0:dd.MM.yyyy}" -f (get-date).AddDays(0)

$backupMain = "D:\YandexDisk\$dateToday"
$backupNumber = 5

$RAR_PATH = "C:\Program Files\WinRAR\rar.exe"
$RAR_ARCHIVE_PASSWORD = (Get-Content .\brg.txt)[0]
$WINSCP_PATH = ".\WinSCP-5.13.4-Portable\winscp.exe"
$YANDEX_PASSWORD = (Get-Content .\brg.txt)[1]


$include = @(
"$env:homedrive$env:homepath\Desktop\",
"$env:public\Desktop\",
"$env:appdata\",
"$env:localappdata\",
"D:\Download\",
"D:\Documents\",
'D:\Steam',
'C:\Portable'
) | % {"`"$_`""}

$exclude = @(
"D:\Documents\Electronic Arts",
'D:\Steam\steamapps'
) | % {"-x`"$_`""}

$rarArgList = @"
a -ibck -m0 -r -v1g -hp$RAR_ARCHIVE_PASSWORD $exclude "$backupMain\backup.rar" $include
"@


function brgcls{
  cls
  "`n`n`n`n`n`n`n`n"
  return;
}


function BrgWait($timer){
  for($i = $timer; $i -ge 0; $i--){
    Write-Progress -Activity 'Waiting' -Status " " -PercentComplete (100 - $i*100/$timer) -SecondsRemaining ($i)
    start-sleep -Seconds 1
  }
}


function RemoveOldBackups {
  # REMOVE BLOCK #
  "-Remove- old backups"
  brgcls

  $scpArgList = @"
/xmllog=".\WinSCP.log" /ini=nul /command "open davs://$YANDEX_PASSWORD@webdav.yandex.ru/" "option batch continue"
"@
  for ($i = $backupNumber*2+1; $i -lt $backupNumber*2+11; $i++){
    $dateForSCP = "{0:dd.MM.yyyy}" -f (get-date).AddDays(-$i)
    $scpArgList += @"
 "rm ""/Backup/$dateForSCP"""
"@
  }
  $scpArgList += @"
 "exit"
"@
  
  Start-Process -FilePath "$WINSCP_PATH" -ArgumentList "$scpArgList" -NoNewWindow -Wait
  "-Delete- Done"
  BrgWait 20


  # COPY MAIN BACKUP TO ./BACKUP/ DIRECTORY #
  "`n`n`n"
  "`nCOPY MAIN BACKUP TO ./BACKUP/ DIRECTORY"

  $scpArgList = @"
/xmllog=".\WinSCP.log" /ini=nul /command "open davs://$YANDEX_PASSWORD@webdav.yandex.ru/" "option batch continue"
"@
  for ($i = 1; $i -lt 5; $i++){
    $dateForSCP = "{0:dd.MM.yyyy}" -f (get-date).AddDays(-$i)
    $scpArgList += @"
 "cp ""$dateForSCP"" ""/Backup/$dateForSCP"""
"@
  }
  $scpArgList += @"
 "exit"
"@
  
  Start-Process -FilePath "$WINSCP_PATH" -ArgumentList "$scpArgList" -NoNewWindow -Wait
  "-COPY MAIN BACKUP- Done"
  BrgWait 180

  MakeNewBackup
  exit
}


Function MakeNewBackup {
  brgcls
  #Set-PSDebug -Trace 1
  "`ndelete main backup"

  Stop-Process -Name "YandexDisk2" -Force

  $scpArgList = @"
/xmllog=".\WinSCP.log" /ini=nul /command "open davs://$YANDEX_PASSWORD@webdav.yandex.ru/" "option batch continue"
"@
  for ($i = 0; $i -lt 5; $i++){
    $dateForSCP = "{0:dd.MM.yyyy}" -f (get-date).AddDays(-$i)
    $scpArgList += @"
 "rm ""$dateForSCP"""
"@
  Remove-Item -Path (($backupMain -replace ".{11}$")+"\$dateForSCP") -Force -Recurse
  }
  $scpArgList += @"
 "exit"
"@
  
  Start-Process -FilePath "$WINSCP_PATH" -ArgumentList "$scpArgList" -NoNewWindow -Wait
  "-main backup delete- Done"
  BrgWait 180

  new-item "$backupMain" -itemtype directory
  Start-Process -FilePath "$RAR_PATH" -ArgumentList "$rarArgList" -NoNewWindow -Wait
  New-Item "$backupMain\$dateToday" -ItemType file


  $findYandexDisk = get-childitem -path "$env:appdata\Yandex\YandexDisk2" -include "YandexDisk2.exe" -recurse
  Start-Process -FilePath $findYandexDisk -ArgumentList "-autostart"
  Set-PSDebug -Trace 0
  ""
  ""
  ""
  write-host "Done" -ForegroundColor Magenta
  BrgWait 10
  exit
}


function BrgStart() {
  #check if backup already exists
  if (Test-Path -Path "$backupMain\$dateToday") {
    exit
  }

  #check if day is even
  Get-Date -UFormat %d | % {
    if($_ % 2 -eq 0 ) {
      RemoveOldBackups
    } else {
      exit
    }
  }
  
  exit
}


#-------------------------------------------------------------------------------------------------------------
$param = $args[0]
if ("$param" -eq "-noDayCheck"){
  RemoveOldBackups
}
if ("$param" -eq "-overwrite"){
  MakeNewBackup
}
BrgStart
exit